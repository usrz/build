#!/bin/bash

if test -z "${GITHUB_API_TOKEN}" ; then
  echo "Missing variable GITHUB_API_TOKEN"
  exit 1
fi

echo ""
echo "Checking out Repository:"
echo ""
git clone \
  --depth 1 \
  --branch "gh-pages" \
  "https://git:${GITHUB_API_TOKEN}@github.com/usrz/repository.git" \
  "target/repository" || exit 1
cd "target/repository"

echo ""
echo "Repository at revision:"
echo ""
git rev-parse HEAD || exit 1
git config user.email "builds@circleci.com" || exit 1
git config user.name "CircleCI Buil Agent" || exit 1

echo ""
echo "Gathering parameters and copying Ivy descriptor:"
echo ""
eval `cat ../ivy-github.xml | grep '<info' | cut -d\  -f2- | cut -d/ -f1`
echo "  organisation=${organisation}"
echo "        module=${module}"
echo "      revision=${revision}"
mkdir -p "releases/${organisation}/${module}/${revision}" || exit 1
cp "../ivy-github.xml" "releases/${organisation}/${module}/${revision}/ivy.xml" || exit 1

OLD_DIR=`pwd`;
for DIR in releases libraries ; do
  echo ""
  echo "Processing directory \"${DIR}\""
  echo ""
  echo "Recreating files:"
  echo ""
  find "${DIR}" -type f -name index.html -delete
  find "${DIR}" -type d  -empty -print -delete
  find "${DIR}" -type d | while read NEW_DIR ; do
    echo -n .
    cd "${NEW_DIR}"
    {
      echo "<!DOCTYPE html>"
      echo "<html>"
      echo "  <head>"
      echo "    <title>Index of: ${NEW_DIR}</title>"
      echo "  </head>"
      echo "  <body>"
      echo "    <h1>Index of: ${NEW_DIR}</h1>"
      echo "    <ul>"
      echo "      <li class=\"up\"><a href=\"..\">..</a></li>"
      for FILE in `ls -1` ; do
        if [[ $FILE == "index.html" ]] || [[ $FILE == .* ]] ; then
          continue
        fi
        if test -d "$FILE" ; then
          FILE="${FILE}/"
          CLASS="dir"
        else
          CLASS="file"
        fi
        printf "      <li class=\"%s\"><a href=\"%s\">%s</a></li>\n" "${CLASS}" "${FILE}" "${FILE}"
      done
      echo "    </ul>"
      echo "  </body>"
      echo "</html>"
    } > index.html
    cd "${OLD_DIR}"
  done
  echo ". Done!"
  echo ""
  echo "Adding to git:"
  echo ""
  git add --verbose "${DIR}" || exit 1
done

if git diff-index --quiet HEAD -- ; then
  echo ""
  echo "No changes (Skipping commit)"
#else
  echo ""
  echo "Committing:"
  echo ""
  git commit --allow-empty --verbose -a -m "Built new indexes" || exit 1
  echo ""
  echo "Pushing changes:"
  echo ""
  git push origin gh-pages || exit 1
fi
echo ""
echo "Cleaning up:"
echo ""
cd "../.." || exit 1
rm -rf "target/repository" || exit 1


