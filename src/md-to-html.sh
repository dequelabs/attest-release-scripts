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

# create dir, if destination directory does not exist
mkdir -p "$destDir"

# convert markdown files from given input directory
# Note: IFS (Internal field seperator) is set to spaces, to allow for file names with space characters
# Note: -f - disable file globbing (see - https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html)
IFS=$'\n'
set -f

for file in $(find $inputDir -name '*.md')
  do 
    filename=$(basename -- "$file")
    filename="${filename%.*}"
    output="$destDir/${filename}.html"  
    npx showdown makehtml -i "$file" -o "$output" --tables
done

unset IFS 
set +f

echo "Converted MD to HTML!"