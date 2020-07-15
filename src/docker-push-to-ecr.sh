#!/bin/bash

set -e

function throw() {
  echo "Error: $*"
  exit 1
}

function usage() {
  echo "docker-push-to-ecr.sh [options]"
  echo ""
  echo "  Build and push a Docker image to ECR. Uses the current Git SHA as the"
  echo "  image's version number and \$CIRCLE_BRANCH to derive which ECR to"
  echo "  push to."
  echo ""
  echo "  Will append a \"-production\" suffix to production (master branch)"
  echo "  images."
  echo ""
  echo "  Options"
  echo "    --dockerfile=[path]    Path to the Dockerfile (defaults to \".\")"
  echo "    --docker-args=[args]   Arguments to pass to \`docker build\`"
  echo "    --suffix=[suffix]      Suffix to add to the image tag"
  echo ""
}

function main() {
  if [ $# -eq 0 ]; then
    usage
    exit 1
  fi

  readonly Branch="$CIRCLE_BRANCH"
  readonly Version=$(git rev-parse --short HEAD)
  local Repo=""
  local Secret=""
  local Key=""
  local Suffix=""
  local Dockerfile="."
  local DockerArgs=""

  for i in "$@"; do
    case $i in
    --suffix=*)
      Suffix="${i#*=}"
      shift
      ;;
    --dockerfile=*)
      Dockerfile="${i#*=}"
      shift
      ;;
    --docker-args=*)
      DockerArgs="${i#*=}"
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      throw "Unknown option provided: \"$i\""
      ;;
    esac
  done

  # Check env vars.
  [ -z "$CIRCLE_BRANCH" ] && throw "CIRCLE_BRANCH not set"
  [ -z "$DEV_AWS_SECRET_ACCESS_KEY" ] && throw "DEV_AWS_SECRET_ACCESS_KEY not set"
  [ -z "$DEV_AWS_ACCESS_KEY_ID" ] && throw "DEV_AWS_ACCESS_KEY_ID not set"
  [ -z "$DEV_ECR" ] && throw "DEV_ECR not set"
  [ -z "$QA_ECR" ] && throw "QA_ECR not set"

  # Ensure we figured out branch/SHA.
  [ -z "$Branch" ] && throw "Branch required - set \$CIRCLE_BRANCH."
  [ -z "$Version" ] && throw "Unable to derive version - is this a Git repo?"

  if [ "$Branch" = "master" ]; then
    # Deploy develop commits to our development ECR for now. We don't want to give CI access to AWS prod, so instead, we simply deploy to dev with a `-production` Suffix.
    Repo=$DEV_ECR
    # Do not overwrite the user-provided suffix.
    if [ -z "$Suffix" ]; then
      Suffix="-production"
    fi
    # TODO: These should be `PROD_` keys.
    Secret=$DEV_AWS_SECRET_ACCESS_KEY
    Key=$DEV_AWS_ACCESS_KEY_ID
  elif [ "$Branch" = "release" ]; then
    # Deploy develop commits to our QA ECR.
    Repo=$QA_ECR
    # Since QA is in the same AWS account as dev, we can re-use the keys.
    Secret=$DEV_AWS_SECRET_ACCESS_KEY
    Key=$DEV_AWS_ACCESS_KEY_ID
  elif [ "$Branch" = "develop" ]; then
    Repo=$DEV_ECR
    Secret=$DEV_AWS_SECRET_ACCESS_KEY
    Key=$DEV_AWS_ACCESS_KEY_ID
  else
    throw "Refusing to push from unsupported branch ($Branch)"
  fi

  [ -z "$Repo" ] && throw "Unable to set ECR"
  [ -z "$Key" ] && throw "Unable to set AWS access key ID"
  [ -z "$Secret" ] && throw "Unable to set AWS secret access key"

  echo "Authenticating with AWS"
  # AWS_ACCESS_KEY_ID=$Key AWS_SECRET_ACCESS_KEY=$Secret aws ecr get-login --no-include-email --region us-east-1 | /bin/bash

  echo "Building, tagging and pushing version $Version$Suffix"
  echo docker build "$DockerArgs" -t "$Repo:latest$Suffix" -t "$Repo:$Version$Suffix" "$Dockerfile"
  echo docker push "$Repo:latest$Suffix"
  echo docker push "$Repo:$Version$Suffix"

  echo "Done!"
}

main "$@"
