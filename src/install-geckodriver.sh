#!/bin/bash

# Script to install geckodriver in CI
# Takes one argument, which is the desired geckodriver version
# Usage: bash install-geckodriver 0.24

set -e

throw() { 
  echo "$@" 1>&2
  exit 1
}

# Check if version is specified as first argument
[ -z "$1" ] && throw "Specify version of geckodriver to install"

curl -L -o "/tmp/geckodriver.tar.gz" "https://github.com/mozilla/geckodriver/releases/download/v$1/geckodriver-v$1-linux64.tar.gz"
tar -xvzf /tmp/geckodriver.tar.gz -C /tmp/
sudo mv "/tmp/geckodriver" "/opt/geckodriver"
chmod +x /opt/geckodriver
sudo ln -sf "/opt/geckodriver" "/usr/local/bin/geckodriver" 