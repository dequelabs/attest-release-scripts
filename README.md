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

### zip-dir-upload-to-artifactory.sh

The `zip-dir-upload-to-artifactory` script zip's a given directory and uploads the zip file to artifactory (agora). The script accepts 2 arguments, in the below order respectively:

| Argument | Description |
|---|---|
| dir ($1) | **(Mandatory)** the directory to zip |
| prefix ($2) | **(Optional)** a prefix to the zip file name |
| name ($2) | **(Optional)** name used as path under artifactory repository to where the zip file will be uploaded |
| version ($2) | **(Optional)** version number used to construct the zip file name |

**Usage:**

```
zip-dir-upload-to-artifactory.sh dist "next-$(git rev-parse --short HEAD)"
``` 

where argument, `dist`  is the directory to zip and `next-$(git rev-parse --short HEAD)` is an optional prefix to the generated zip file name.

>Note: The `zip-dir-upload-to-artifactory` script is put together for use in CI (circle), and expects `ARTIFACTORY_REPO` and `ARTIFACTORY_API_KEY` as environment variables. Ensure these are configured and available when used in other setups.

### md-to-html

The `md-to-html` script converts a given collection of markdown files to html. The script accepts 2 arguments in the below order respectively:

| Argument | Description |
|---|---|
| inputDir ($1) | **(Mandatory)** input directory containing markdown files to convert |
| destDir ($1) | **(Mandatory)** destination directory to created the converted html files |

**Usage:**

```
md-to-html.sh docs output
``` 

where argument, `docs` are the markdown files and `output` is the directory in which the html files are created.

## License

MPL-2.0
