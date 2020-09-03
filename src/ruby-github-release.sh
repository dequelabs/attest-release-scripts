#!/bin/bash

set -e

throw() { 
  echo "$@" 1>&2
  exit 1
}

get_changelog () {
  changelog=""
  has_start_line=0
  while read -r line; do
    if [[ $has_start_line -eq 0 ]]; then
      # If we do not have a starting line, look for one.
      if [[ "$line" =~ \#\ \[?[[:digit:]] ]]; then
        has_start_line=1
      fi
    elif [[ $has_start_line -eq 1 ]]; then
      # If we do have a starting line, look for a closing line. Either exit the loop or append to the changelog.
      if [[ "$line" =~ \#\ \[?[[:digit:]] ]]; then
        break
      else
        changelog=$"$changelog\n$line"
      fi
    fi
  done <CHANGELOG.md

  # Ignore rule `SC2059` as we do *not* want newlines/etc escaped here.
  # shellcheck disable=SC2059
  printf "$changelog"
}

# Ensure required env vars are set.
[ -z "$GITHUB_TOKEN" ] && throw "GITHUB_TOKEN not set"
[ -z "$CIRCLE_PROJECT_REPONAME" ] && throw "CIRCLE_PROJECT_REPONAME not set"
[ -z "$CIRCLE_PROJECT_USERNAME" ] && throw "CIRCLE_PROJECT_USERNAME not set"

# Ensure https://github.com/aktau/github-release is installed.
# NOTE: we install it from gopkg (gopkg.in/aktau/github-release.v0), so the binary has a `.v0` suffix.
command -v github-release.v0 > /dev/null 2>&1 || throw "Unable to locate github-release binary"

# Given both of our ruby repositories are now monorepo structured, there is no top level gemspec file
# The version number can be inferred from package json
PKG_VERSION=$(grep 'version' package.json | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g' | tr -d '[:space:]')
# Ensure we read a version.
[[ -z $PKG_VERSION ]] && throw "Unable to parse version"

echo "Releasing v$PKG_VERSION"

# Create a release.
github-release.v0 release \
  --user "$CIRCLE_PROJECT_USERNAME" \
  --repo "$CIRCLE_PROJECT_REPONAME" \
  --tag "v$PKG_VERSION" \
  --name "Release $PKG_VERSION" \
  --description "$(get_changelog)"