"use strict";
var https = require('https');
var path = require('path');
var fs = require('fs');

/* ========================================================================== */
/* HELP PAGE                                                                  */
/* ========================================================================== */

function help() {
  console.log("Usage: %s %s <operation> [--options ...]", process.argv[0], process.argv[1])
  console.log("");
  console.log("  Operations:")
  console.log("");
  console.log("    release     Create a new GitHub release")
  console.log("    asset       Upload a new asset for a GitHub release");
  console.log("    upload      Upload a new file into the GitHub repository");
  console.log("");
  console.log("  Options:")
  console.log("");
  console.log("    --owner=<owner>       The owner of the GitHub repository");
  console.log("    --repo=<repo>         The name of the GitHub repository");
  console.log("    --token=<oauth token> The OAuth token to use for the GitHub API");
  console.log("");
  console.log("  Specific to 'release':")
  console.log("");
  console.log("    --tag=<tag name>      The tag name of the GitHub release");
  console.log("    --target=<commit>     The commit hash/branch/... for the tag");
  console.log("    --name=<name>         The name of the GitHub release");
  console.log("    --body=<body>         The body of the GitHub release (Markdown)");
  console.log("    --draft               Indicates that the release is a draft");
  console.log("    --prerelease          Indicates that the release is a prerelease");
  console.log("");
  console.log("  Specific to 'asset':")
  console.log("");
  console.log("    --tag=<tag name>      The tag name of the GitHub release");
  console.log("    --file=<file>         The file to upload as an asset");
  console.log("    --file-name=<name>    The file name of the asset to publish");
  console.log("    --content-type=<mime> The MIME content type of the asset to publish");
  console.log("");
  console.log("  Specific to 'upload':")
  console.log("");
  console.log("    --file=<file>         The file to upload as an asset");
  console.log("    --path=<name>         The file name of the asset to publish");
  console.log("    --message=<mime>      The commit message for this upload");
  console.log("    --branch=<mime>       The branch to upload the file to");
  console.log("");
  process.exit(-1);
}

/* ========================================================================== */
/* OPTIONS, ERRORS AND FAILURES                                               */
/* ========================================================================== */

function option(name, defaultValue) {
  if (options[name]) return options[name];
  if (defaultValue !== undefined) return defaultValue;
  error("Missing '--%s=...' option", name);
}

function error() {
  console.error.apply(null, arguments);
  console.error("Try '--help'...");
  process.exit(1);
}

function failure(error, status) {
  if (status) {
    console.error("An HTTP/%d error occurred", status);
  } else {
    console.error("An error occurred");
  }
  if (error) {
    if (typeof(error) === 'string') console.error(error);
    else console.error(JSON.stringify(error, undefined, 2));
  }
  process.exit(1);
}

/* ========================================================================== */
/* SIMPLE ENVIRONMENT PROCESSING AND COMMAND LINE PARSING                     */
/* ========================================================================== */
var operation = null;
var options = {};

/* From the environment */
if (process.env['GITHUB_API_TOKEN'])        options.token  = process.env['GITHUB_API_TOKEN'];
if (process.env['CIRCLE_PROJECT_USERNAME']) options.owner  = process.env['CIRCLE_PROJECT_USERNAME'];
if (process.env['CIRCLE_PROJECT_REPONAME']) options.repo   = process.env['CIRCLE_PROJECT_REPONAME'];
if (process.env['CIRCLE_SHA1'])             options.target = process.env['CIRCLE_SHA1'];

process.argv.forEach(function (value, index) {
  if (index < 2) return;
  var result = /^--([^=]+)(=(.*))?$/.exec(value);
  if (result) {
    options[result[1]] = result[3] || true;
  } else {
    operation = value;
  }
})

/* ========================================================================== */
/* SIMPLE COMMAND LINE VALIDATION                                             */
/* ========================================================================== */
var operations = {
  release: release,
  upload: upload,
  asset: asset
};

if ((!operation) || (operation == 'help') || options['help']) help();
if (!operations[operation]) error("Invalid operation '%s'", operation);

operations[operation]();


/* ========================================================================== */
/* CREATE A RELEASE                                                           */
/* ========================================================================== */
function release() {
  var token = option('token');
  var owner = option('owner');
  var repo = option('repo');
  var tag = option('tag');

  var release = {
    tag_name: tag,
    target_commitish: option('target'),
    name: option('name', 'Release ' + tag),
    body: option('body', ""),
    draft: option('draft', false),
    prerelease: option('prereleas', false)
  }

  console.error("Creating release '%s' of https://github.com/%s/%s", tag, owner, repo);

  var options = {
    hostname: 'api.github.com',
    port: 443,
    path: '/repos/' + owner + '/' + repo + '/releases',
    method: 'POST',
    headers: {
      'Authorization': 'token ' + token,
      'User-Agent': 'GitHubber/0.0 Node/' + process.version,
      'Content-Type': 'application/json'
    }
  };

  var request = https.request(options, function(response) {
    var status = response.statusCode;
    var headers = response.headers;
    var body = "";
    response.setEncoding('utf8');
    response.on('data', function (chunk) { body = body + chunk; });
    response.on('end',  function () { released(status, headers, JSON.parse(body)) });
  }).on('error', failure);

  request.write(JSON.stringify(release));
  request.end();

  /* ======================================================================== */

  function released(status, headers, response) {
    if (status != 201) return failure(response, status);

    console.error("Release '%s' (id=%d) available at %s", tag, response.id, response.html_url);
    process.exit(0);
  };
};

/* ========================================================================== */
/* UPLOAD ASSETS TO A RELEASE                                                 */
/* ========================================================================== */
function asset() {
  var token = option('token');
  var owner = option('owner');
  var repo = option('repo');
  var tag = option('tag');

  var file = option('file');
  var filename = option('file-name', path.basename(file));
  var content;
  switch (path.extname(file)) {
    case '.json': content = 'application/json';         break;
    case '.html': content = 'text/html';                break;
    case '.txt':  content = 'text/plain';               break;
    case '.xml':  content = 'text/xml';                 break;
    case '.jpeg': content = 'image/jpeg';               break;
    case '.jpg':  content = 'image/jpeg';               break;
    case '.png':  content = 'image/png';                break;
    case '.gif':  content = 'image/gif';                break;
    case '.zip':  content = 'application/zip';          break;
    case '.jar':  content = 'application/java-archive'; break;
  }
  content = option('content-type', content);
  var size;

  try {
    var fd = fs.openSync(file, 'r');
    var stat = fs.fstatSync(fd);
    if (stat.isFile()) {
      size = stat.size;
    } else {
      failure("Path '" + file + "' is not a file");
    }
    fs.closeSync(fd);
  } catch (error) {
    failure(error);
  }

  console.error("Uploading file '%s' (%d bytes) for release '%s' of https://github.com/%s/%s", filename, size, tag, owner, repo);

  var options = {
    hostname: 'api.github.com',
    port: 443,
    path: '/repos/' + owner + '/' + repo + '/releases',
    method: 'GET',
    headers: {
      'Authorization': 'token ' + token,
      'User-Agent': 'GitHubber/0.0 Node/' + process.version
    }
  };

  var request = https.request(options, function(response) {
    var status = response.statusCode;
    var headers = response.headers;
    var body = "";
    response.setEncoding('utf8');
    response.on('data', function (chunk) { body = body + chunk; });
    response.on('end',  function () { listed(status, headers, JSON.parse(body)) });
  }).on('error', failure);

  request.end();

  /* ======================================================================== */

  function listed(status, headers, response) {
    if (status != 200) return failure(response, status);

    for (var i in response) {
      if (response[i].tag_name == tag) {
        sendfile(response[i].id);
        return;
      }
    }

    failure("ID for release '" + tag + "' not found");
  };

  /* ======================================================================== */

  function sendfile(id) {
    var options = {
      hostname: 'uploads.github.com',
      port: 443,
      path: '/repos/' + owner + '/' + repo + '/releases/' + id + '/assets?name=' + filename,
      method: 'POST',
      headers: {
        'Authorization': 'token ' + token,
        'User-Agent': 'GitHubber/0.0 Node/' + process.version,
        'Content-Type': content,
        'Content-Length': size
      }
    };

    var request = https.request(options, function(response) {
      var status = response.statusCode;
      var headers = response.headers;
      var body = "";
      response.setEncoding('utf8');
      response.on('data', function (chunk) { body = body + chunk; });
      response.on('end',  function () { uploaded(status, headers, JSON.parse(body)) });
    }).on('error', failure);

    fs.createReadStream(file)
      .on('open', function() { process.stderr.write("Writing...") })
      .on('data', function() { process.stderr.write(".")          })
      .on('end',  function() { process.stderr.write(". Done!")    })
      .on('error', failure)
      .pipe(request);

    function uploaded(status, headers, response) {
      process.stderr.write("\n");
      if (status != 201) return failure(response, status);
      process.stdout.write(response.browser_download_url + "\n");
    }
  };
};

/* ========================================================================== */
/* UPLOAD A FILE INTO A TREE                                                  */
/* ========================================================================== */
function upload() {
  var token = option('token');
  var owner = option('owner');
  var repo = option('repo');
  var file = option('file');
  var path = option('path');
  var message = option('message');
  var branch = option('branch', 'master');

  var content;
  try {
    content = fs.readFileSync(file, {encoding: 'base64'});
  } catch (error) {
    failure(error);
  }

  var details = {
    message: message,
    content: content
  }

  console.error("Uploading file '%s' to https://github.com/%s/%s/blob/%s/%s", file, owner, repo, branch, path);

  var options = {
    hostname: 'api.github.com',
    port: 443,
    path: '/repos/' + owner + '/' + repo + '/contents/' + path,
    method: 'PUT',
    headers: {
      'Authorization': 'token ' + token,
      'User-Agent': 'GitHubber/0.0 Node/' + process.version,
      'Content-Type': 'application/json'
    }
  };

  var request = https.request(options, function(response) {
    var status = response.statusCode;
    var headers = response.headers;
    var body = "";
    response.setEncoding('utf8');
    response.on('data', function (chunk) { body = body + chunk; });
    response.on('end',  function () { uploaded(status, headers, JSON.parse(body)) });
  }).on('error', failure);

  request.write(JSON.stringify(details));
  request.end();

  /* ======================================================================== */

  function uploaded(status, headers, response) {
    if (status != 201) return failure(response, status);
    console.error("New file '%s' created as %s", response.content.path, response.commit.sha);
  };
};

