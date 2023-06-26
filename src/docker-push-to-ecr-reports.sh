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
  echo "  If \$PROD_ECR is not set, will push to the \$DEV_ECR and append"
  echo "  a \"-production\" suffix to the image. This functionality will be"
  echo "  removed once all services are setup to deploy to their production"
  echo "  ECRs."
  echo ""
  echo "  Options"
  echo "    --dockerfile=[path]    Path to the Dockerfile (defaults to \".\")"
  echo "    --docker-args=[args]   Arguments to pass to \`docker build\`"
  echo "    --suffix=[suffix]      Suffix to add to the image tag"
  echo "    --force                Force the script to push a \"dev\" image"
  echo ""
}

function main() {
  readonly Branch="$CIRCLE_BRANCH"
  # Always use 8 characters. This ensures consistency with image tags.
  readonly Version=$(git rev-parse --short=8 HEAD)
  local Repo=""
  local Secret=""
  local Key=""
  local Suffix=""
  local Dockerfile="."
  local DockerArgs=""
  local Force=false
  local ReleasePattern="release-([[:digit:]]+)"
  local ReleasePreviewPattern="release-preview-([[:digit:]]+).([[:digit:]]+).([[:digit:]]+)"

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
    --force)
      Force=true
      shift
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

  if [ "$Force" = true ]; then
    # If the script was run with `--force`, we'll _always_ push a "dev" image to the dev ECR.
    echo "Warning: --force flag provided. Ignoring branch and pushing a \"dev\" image!"
    Repo=$DEV_ECR
    Secret=$DEV_AWS_SECRET_ACCESS_KEY
    Key=$DEV_AWS_ACCESS_KEY_ID
  else
    # Otherwise, try to figure out what ECR to deploy to based on the Git branch.
    if [ "$Branch" = "master" ]; then

      # If PROD_ECR is set, push to it.
      # Not all services have this variable set, so we need to fallback to the dev ECR/"-production" suffix hack.
      if [ -z "$PROD_ECR" ]; then
        # Deploy master commits to our development ECR for now. We don't want to give CI access to AWS prod, so instead, we simply deploy to dev with a `-production` suffix.
        Repo=$DEV_ECR
        # Do not overwrite the user-provided suffix.
        if [ -z "$Suffix" ]; then
          Suffix="-production"
        fi
        Secret=$DEV_AWS_SECRET_ACCESS_KEY
        Key=$DEV_AWS_ACCESS_KEY_ID
      else
        Repo=$PROD_ECR
        # When pushing to the prod ECR, we must use prod creds.
        [ -z "$PROD_AWS_SECRET_ACCESS_KEY" ] && throw "PROD_ECR set, missing PROD_AWS_SECRET_ACCESS_KEY"
        [ -z "$PROD_AWS_ACCESS_KEY_ID" ] && throw "PROD_ECR set, missing PROD_AWS_ACCESS_KEY_ID"
        Secret=$PROD_AWS_SECRET_ACCESS_KEY
        Key=$PROD_AWS_ACCESS_KEY_ID
      fi
    elif [ "$Branch" = "release" ] || [[ "$Branch" =~ $ReleasePattern ]] || [[ "$Branch" =~ $ReleasePreviewPattern ]]; then
      # Deploy release commits to our QA ECR.
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
  fi

  [ -z "$Repo" ] && throw "Unable to set ECR"
  [ -z "$Key" ] && throw "Unable to set AWS access key ID"
  [ -z "$Secret" ] && throw "Unable to set AWS secret access key"

  echo "Authenticating with AWS"
  AWS_ACCESS_KEY_ID=$Key AWS_SECRET_ACCESS_KEY=$Secret aws ecr get-login --no-include-email --region us-east-1 | /bin/bash

  echo "Building, tagging and pushing version $Version$Suffix"
  # shellcheck disable=SC2086
  docker build $DockerArgs -t "$Repo:$Version$Suffix" "$Dockerfile"
  docker push "$Repo:$Version$Suffix"

  echo "Done!"
}

main "$@"