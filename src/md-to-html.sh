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


# ensure showdown exists in path
if ! [ -x "$(command -v showdown)" ]; then
  throw "Showdown is not installed. Please install showdown and ensure it is made available at ./node_modules/.bin/showdown"
fi

# save args to variables
inputFiles=$1
destDir=$2

# create dir, if destination directory does not exist
if [ ! -d "$destDir" ]; then
  mkdir -p "$destDir"
fi

# convert files
for file in $inputFiles; 
  do
    filename=$(basename -- "$file")
    extension="${filename##*.}"
    filename="${filename%.*}"

    if [ ! "$extension" = "md" ]
      then
        throw "Only markdown files should be supplied as input"
    fi
    output="$destDir/${filename}.html"  
    ./node_modules/.bin/showdown makehtml -i "$file" -o "$output" --tables
done

echo "Converted MD to HTML!"