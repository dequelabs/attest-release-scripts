#!/bin/bash

set -e

throw() { 
  echo "$@" 1>&2
  exit 1
}

# Validate arguments
if [ $# -eq 0 ]
  then
    throw "No arguments supplied. Please specify md files to convert as first argument and output directory as second argument"
fi


# ensure npx exists in path
if ! [ -x "$(command -v npx)" ]; then
  throw "npx is not available"
fi

# save args to variables
inputDir=$1
destDir=$2

# convert markdown files from given input directory
# Note: IFS (Internal field seperator) is set to spaces, to allow for file names with space characters
# Note: -f - disable file globbing (see - https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html)
IFS=$'\n'
set -f

files=$(find "$inputDir" -type f -name '*.md')

for file in $files
  do 
    # replace path to specified output directory
    newPath="${file/$inputDir/$destDir}"
    # get dir of new path
    dir=$(dirname -- "$newPath")
    # make dir
    mkdir -p "$dir"
    # replace md extenstion with html
    outputFile="${newPath/.md/.html}"
    # convert
    npx showdown makehtml -i "$file" -o "$outputFile" --tables
done

unset IFS 
set +f

echo "Converted MD to HTML!"