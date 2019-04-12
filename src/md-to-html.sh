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
inputFiles=$1
destDir=$2

# create dir, if destination directory does not exist
if [ ! -d "$destDir" ]; then
  mkdir -p "$destDir"
fi

# ensure all given files are of type markdown
for file in $inputFiles; 
  do
    extension="${filename##*.}"
    if [ ! "$extension" = "md" ]
      then
        throw "$file is not of type markdown."
    fi
done

# convert files
for file in $inputFiles; 
  do
    filename=$(basename -- "$file")
    filename="${filename%.*}"
    output="$destDir/${filename}.html"  
    npx showdown makehtml -i "$file" -o "$output" --tables
done

echo "Converted MD to HTML!"