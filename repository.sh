#!/bin/bash

if test -z "${GITHUB_API_TOKEN}" ; then
  echo "Missing variable GITHUB_API_TOKEN"
  exit 1
fi
echo

# Un-authenticated GIT checkout
echo ""
echo "Checking out Repository:"
echo ""
git clone \
  --verbose \
  --depth 1 \
  --branch "gh-pages" \
  "https://git@github.com/usrz/repository.git" \
  "target/repository" || exit 1
cd "target/repository" || exit 1

# Configure the repository
echo ""
echo "Configuring repository at revision:"
echo ""
echo "https://git:${GITHUB_API_TOKEN}@github.com" > "${PWD}/.git/credentials"
git config credential.helper "store --file=\"${PWD}/.git/credentials\"" || exit 1
git config user.email "builds@circleci.com" || exit 1
git config user.name "CircleCI Buil Agent" || exit 1
git rev-parse HEAD || exit 1

echo ""
echo "Gathering parameters and copying Ivy descriptor:"
echo ""
eval `cat ../ivy-github.xml | grep '<info' | cut -d\  -f2- | cut -d/ -f1`
echo "  organisation=${organisation}"
echo "        module=${module}"
echo "      revision=${revision}"
mkdir -p "releases/${organisation}/${module}/${revision}" || exit 1
cp "../ivy-github.xml" "releases/${organisation}/${module}/${revision}/ivy.xml" || exit 1

# Call "make_indexes.sh" to generate the pages
bash ./make_indexes.sh || exit 1

# Now figure out if there's anything to commit
if git diff-index --quiet HEAD -- ; then
  echo ""
  echo "No changes (Skipping commit)"
else
  echo ""
  echo "Committing:"
  echo ""
  if test -n "${CIRCLE_BUILD_NUM}" ; then
    git commit --verbose -a -m "Built new indexes (${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME} build ${CIRCLE_BUILD_NUM})" || exit 1
  else
    git commit --verbose -a -m "Built new indexes (on `hostname -f` at `date -u`)" || exit 1
  fi
  echo ""
  echo "Pushing changes:"
  echo ""
  git push --verbose origin gh-pages || exit 1
fi

# And finally clean up this whole thing...
echo ""
echo "Cleaning up:"
echo ""
cd "../.." || exit 1
rm -rf "target/repository" || exit 1


