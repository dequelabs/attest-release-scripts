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

### docker-push-to-ecr.sh

Build and deploy a Docker image to ECR.

Requires the following environment variables to be exported:

- `CIRCLE_BRANCH` (always set by CircleCI)
- `DEV_AWS_SECRET_ACCESS_KEY` (set by the `html-team` CircleCI context)
- `DEV_AWS_ACCESS_KEY_ID` (set by the `html-team` CircleCI context)
- `DEV_ECR` (your service's dev ECR)
- `QA_ECR` (your service's QA ECR)

```
docker-push-to-ecr.sh [options]

  Build and push a Docker image to ECR. Uses the current Git SHA as the
  image's version number and $CIRCLE_BRANCH to derive which ECR to
  push to.

  If $PROD_ECR is not set, will push to the $DEV_ECR and append
  a "-production" suffix to the image. This functionality will be
  removed once all services are setup to deploy to their production
  ECRs.

  Options
    --dockerfile=[path]    Path to the Dockerfile (defaults to ".")
    --docker-args=[args]   Arguments to pass to `docker build`
    --suffix=[suffix]      Suffix to add to the image tag
    --force                Force the script to push a "dev" image
```

The `--force` flag is useful for testing Docker deployments. It should only be used in "special" scenarios (eg repository/service setup).

**Examples**

Build/push `./Dockerfile` with no additional arguments passed to Docker with the default image tag:

```
./docker-push-to-ecr.sh
```

Build/push `./service/Dockerfile` and set the `npm_auth` [build-arg](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg):

```
./docker-push-to-ecr.sh --docker-args="--build-arg npm_auth='$NPM_AUTH_PRIVATE' --dockerfile="./service"
```

Build/push `./Dockerfile` with the `-stephentest` suffix:

```
./docker-push-to-ecr.sh --suffix="-stephentest"
```

### zip-dir-upload-to-artifactory.sh

The `zip-dir-upload-to-artifactory` script zip's a given directory and uploads the zip file to artifactory (agora). The script accepts 2 arguments, in the below order respectively:

| Argument      | Description                                                                                          |
| ------------- | ---------------------------------------------------------------------------------------------------- |
| dir (\$1)     | **(Mandatory)** the directory to zip                                                                 |
| prefix (\$2)  | **(Optional)** a prefix to the zip file name                                                         |
| name (\$2)    | **(Optional)** name used as path under artifactory repository to where the zip file will be uploaded |
| version (\$2) | **(Optional)** version number used to construct the zip file name                                    |

**Usage:**

```
zip-dir-upload-to-artifactory.sh dist "next-$(git rev-parse --short HEAD)"
```

where argument, `dist` is the directory to zip and `next-$(git rev-parse --short HEAD)` is an optional prefix to the generated zip file name.

> Note: The `zip-dir-upload-to-artifactory` script is put together for use in CI (circle), and expects `ARTIFACTORY_REPO` and `ARTIFACTORY_API_KEY` as environment variables. Ensure these are configured and available when used in other setups.

### md-to-html

The `md-to-html` script converts a given collection of markdown files to html. The script accepts 2 arguments in the below order respectively:

| Argument       | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| inputDir (\$1) | **(Mandatory)** input directory containing markdown files to convert      |
| destDir (\$1)  | **(Mandatory)** destination directory to created the converted html files |

**Usage:**

```
md-to-html.sh docs output
```

where argument, `docs` are the markdown files and `output` is the directory in which the html files are created.

## License

MPL-2.0
