# attest-release-scripts

> Scripts used for releasing Attest products.

## Disclaimer

These scripts are run from our CI processes "as-is". If unexpected/breaking changes are made to any of these scripts, it's very likely a deployment or build of something else will break. Please be extra cautious when working in this repository.

## Usage

These scripts are meant to be run from within CircleCI. You probably don't want to run any of these scripts locally.

The scripts make the following assumptions:

- [`jq`](https://stedolan.github.io/jq/) is available on `$PATH`
- [`github-release`](https://github.com/aktau/github-release) is in `$GOPATH/bin`
- `GITHUB_TOKEN` is exported (and valid)
- `CIRCLE_PROJECT_REPONAME` is exported
- `CIRCLE_PROJECT_USERNAME` is exported

## Scripts

### node-github-release.sh

Creates GitHub Releases in Node (and Lerna) projects. Will derive the release name from the "version" key in `lerna.json` or `package.json`.

### java-github-release.sh

Creates GitHub Releases in Java projects. Will derive the release name from the "version" key in `pom.xml`.

### ruby-github-release.sh

Creates GitHub Releases in Ruby projects. Will derive the release name from the "version" key in `*.gemspec`.

## License

MPL-2.0
