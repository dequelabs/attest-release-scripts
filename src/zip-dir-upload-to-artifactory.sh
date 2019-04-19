#!/bin/bash

set -e

throw() { 
  echo "$@" 1>&2
  exit 1
}

# Check and validate arguments, if no arguments exit
if [ $# -eq 0 ]
  then
    throw "No arguments supplied. Please specify name of the directory to zip as first argument."
fi

# ensure artifactory environment variables are available
if [ -z "$ARTIFACTORY_REPO" ] 
  then
    throw "Environment variable $ARTIFACTORY_REPO is not set."
fi
if [ -z "$ARTIFACTORY_API_KEY" ] 
  then
    throw "Environment variable $ARTIFACTORY_API_KEY is not set."
fi

# check if `package.json` exists
if [ ! -e package.json ]
  then
    throw "No package.json file exists."
fi

# ensure jq exists in path
if ! [ -x "$(command -v jq)" ]; then
  throw "Error: jq is not installed."
fi

# save args to variables
directory=$1
prefix=$2
name=$3
version=$4

# get `name` from `package.json` of the library, if not supplied as an argument 
if [ -z "$name" ]
  then
    name=$(< package.json jq -r .name)
fi

# get `version` from `package.json` of the library, if not supplied as an argument 
if [ -z "$version" ]
  then
    version=$(< package.json jq -r .version)
fi

# navigate to specified directory
cd "$directory" || throw "$directory does not exist, cannot navigate."

# construct zip file name and append `prefix` if specified
zipname="v$version-$(date +"%Y-%m-%d-%H-%M-%S").zip"

if [ -n "$prefix" ] 
  then
    zipname="$prefix-$zipname"
fi

# zip contents of directory
echo "Zipping Contents!"
zip -r "$zipname" ./*

# enumerate zip files and upload
find . -name "*.zip" | while read -r f 
  do
    remote_file="$ARTIFACTORY_REPO/$name/$zipname"
    echo "Uploading zip \"$f\" to \"$remote_file\""
    curl \
      -H "X-JFrog-Art-Api:$ARTIFACTORY_API_KEY" \
      -T "$f" \
      "$remote_file"
done

echo "Done!"