#!/bin/bash

set -e

throw() { 
  echo "$@" 1>&2
  exit 1
}

# Ensure required env vars are set.
[ -z "$GITHUB_TOKEN" ] && throw "GITHUB_TOKEN not set"
[ -z "$CIRCLE_PROJECT_REPONAME" ] && throw "CIRCLE_PROJECT_REPONAME not set"
[ -z "$CIRCLE_PROJECT_USERNAME" ] && throw "CIRCLE_PROJECT_USERNAME not set"

# Ensure https://github.com/aktau/github-release is installed.
# NOTE: we install it from gopkg (gopkg.in/aktau/github-release.v0), so the binary has a `.v0` suffix.
command -v github-release.v0 > /dev/null 2>&1 || throw "Unable to locate github-release binary"

# Read version number. Attempt `lerna.json` before `package.json`.
PKG_VERSION=
if [ -f lerna.json ]; then
  PKG_VERSION=$(jq -r .version < lerna.json)
elif [ -f package.json ]; then
  PKG_VERSION=$(jq -r .version < package.json)
else
  throw "No lerna.json or package.json found"
fi

# Ensure we read a version.
# NOTE: when given the `-r` flag, jq will return "null" for missing keys.
[[ -z $PKG_VERSION || "$PKG_VERSION" == "null" ]] && throw "Unable to parse version"

echo "Releasing v$PKG_VERSION"

# Create a release.
github-release.v0 release \
  --user "$CIRCLE_PROJECT_USERNAME" \
  --repo "$CIRCLE_PROJECT_REPONAME" \
  --tag "v$PKG_VERSION" \
  --name "Release $PKG_VERSION" \
  --description "Public v$PKG_VERSION release"