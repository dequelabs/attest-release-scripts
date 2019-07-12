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

# Ensure a single .gemspec file is present.
GEMSPEC_COUNT=$(find . -type f -name "*.gemspec" | wc -l | tr -d "[:space:]")
[ "$GEMSPEC_COUNT" != "1" ] && throw "Expecting a single .gemspec file"

# Find .gemspec file.
GEMSPEC_FILE=$(ls ./*.gemspec)

# Parse the version number (strip either single or double quotes around the version number if any)
PKG_VERSION=$(perl -nle 'print "$1" if m{spec\.version\s+=\s(.*)}' "$GEMSPEC_FILE" | tr -d "'" | tr -d '"')

# Ensure we read a version.
[[ -z $PKG_VERSION ]] && throw "Unable to parse version"

echo "Releasing v$PKG_VERSION"

# Create a release.
github-release.v0 release \
  --user "$CIRCLE_PROJECT_USERNAME" \
  --repo "$CIRCLE_PROJECT_REPONAME" \
  --tag "v$PKG_VERSION" \
  --name "Release $PKG_VERSION" \
  --description "Public v$PKG_VERSION release"