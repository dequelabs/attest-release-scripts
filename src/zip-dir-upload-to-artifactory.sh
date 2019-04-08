#!/bin/bash

# Check and validate arguments, if no arguments exit
if [ $# -eq 0 ]
  then
    echo "No arguments supplied. Check usage."
    exit 1
fi

# ensure artifactory environment variables are available
if [[ -z $ARTIFACTORY_REPO || -z $ARTIFACTORY_API_KEY ]] 
  then
    echo "Artifactory environment variables are not set."
    exit 1
fi

# check if `package.json` exists
if [ ! -e package.json ]
  then
    echo "No package.json file exists."
    exit 1
fi

# Get name of the library from `package.json`
name=$(< package.json jq -r .name)

# Get version of the library from `package.json`
version=$(< package.json jq -r .version)

# Check if specified directory exists, if not exit
if [ ! -d "$1" ]
  then
    echo "Given directory $1, does not exist."
    exit 1 # fail
fi

# navigate to specified directory
cd "$1" || return

# construct zip file name and append `prefix` if specified
zipname=$([ -n "$2" ] && echo "$2-v$version-$(date +"%Y-%m-%d-%H-%M-%S").zip" || echo "v$version-$(date +"%Y-%m-%d-%H-%M-%S").zip")

# zip contents of directory
echo "Zipping Contents"
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

# navigate away from directory
cd - || return

echo "Done!"