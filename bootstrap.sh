#!/bin/bash

# Check if the files we have to create already exist
if test -f "ivy.xml" ; then
  echo -e '\033[31mFailure: the file "\033[33mivy.xml\033[31m" already exists.\033[0m'
  exit 1
fi

if test -f "build.xml" ; then
  echo -e '\033[31mFailure: the file "\033[33mbuild.xml\033[31m" already exists.\033[0m'
  exit 1
fi

# Use pretty colors while asking questions
echo -e ''
echo -e '\033[34mEnter project details:\033[0m'

ORGANISATION=""
while test -z "${ORGANISATION}" ; do
  echo -n -e '      \033[32mOrganisation\033[0m []: '
  read -e ORGANISATION || echo
done

MODULE=""
while test -z "${MODULE}" ; do
  echo -n -e '       \033[32mModule name\033[0m []: '
  read -e MODULE || echo
done

REVISION=""
while test -z "${REVISION}" ; do
  echo -n -e '     \033[32mRevision\033[0m [\033[33m0.0.0\033[0m]: '
  read -e REVISION || { echo ; continue; }
  if test -z "${REVISION}" ; then REVISION="0.0.0" ; fi
done

# Let's go!
echo -e ''

# Prepare our "build.xml" file
echo -e '\033[34mCreating "\033[33mbuild.xml\033[34m"...\033[0m'
cat <<EOF > build.xml
<?xml version="1.0" encoding="UTF-8"?>

<project name="${ORGANISATION}.${MODULE}">
  <import file="build/build-shared.xml" />
</project>
EOF

# Prepare our "ivy.xml" file
echo -e '\033[34mCreating "\033[33mivy.xml\033[34m"...\033[0m'
cat <<EOF > ivy.xml
<?xml version="1.0" encoding="UTF-8"?>
<ivy-module version="2.0">

  <info organisation="${ORGANISATION}" module="${MODULE}" revision="${REVISION}"/>

  <configurations>
    <conf name="default" visibility="public"/>
    <conf name="compile" visibility="private" extends="default"/>
    <conf name="testing" visibility="private" extends="compile"/>
  </configurations>

  <publications>
      <artifact name="${MODULE}" type="bin" ext="jar" conf="default"/>
      <artifact name="${MODULE}" type="src" ext="zip" conf="default"/>
      <artifact name="${MODULE}" type="doc" ext="zip" conf="default"/>
  </publications>

  <dependencies>
    <dependency org="org.usrz.libs" name="testing" rev="latest.release" conf="testing-&gt;logging"/>
  </dependencies>

</ivy-module>
EOF

# Create our ".gitignore" file
echo -e '\033[34mCreating "\033[33m.gitignore\033[34m"...\033[0m'
cat <<EOF > .gitignore
.*
target
EOF

# Create our source directories
echo -e '\033[34mCreating source directories...\033[0m'
mkdir -p "source/main/${ORGANISATION//.//}/${MODULE//.//}"
mkdir -p "source/test/${ORGANISATION//.//}/${MODULE//.//}"

# Initializing GIT
echo -e '\033[34mInitialising GIT repository...\033[0m'
git add -f build.xml ivy.xml .gitignore
git commit -a -m "Initial commit"

# All done
echo -e "\033[34mProject \"\033[33m${ORGANISATION}.${MODULE}-${REVISION}\033[34m\" initialised!\033[0m"
echo ''
