#!/bin/sh

set -e

throw() {
  echo "Error: $*"
  exit 1
}

[ -z "$SLACK_CI_CHANNEL_RELEASE" ] && throw 'Environment variable '"$SLACK_CI_CHANNEL_RELEASE" 'is not set.'
[ -z "$SLACK_CI_CHANNEL_DEV" ] && throw 'Environment variable '"$SLACK_CI_CHANNEL_DEV" 'is not set.'

if [ "$CIRCLE_BRANCH" = "master" ] || [ "$CIRCLE_BRANCH" = "release" ]; then
  channel="$SLACK_CI_CHANNEL_RELEASE"
elif [ "$CIRCLE_BRANCH" = "develop" ]; then
  channel="$SLACK_CI_CHANNEL_DEV"
else
  echo "This branch is not develop, release, or master and will not send a message to slack"
  exit 0
fi

if [ "$SLACK_BUILD_STATUS" = "fail" ]; then
  # Provide error if no webhook is set and error. Otherwise continue
  if [ -z "${SLACK_WEBHOOK}" ]; then
    echo "NO SLACK WEBHOOK SET"
    echo "Please input your SLACK_WEBHOOK value either in the settings for this project, or as a parameter for this orb."
    exit 1
  else
    #If Failed
    curl -X POST -H 'Content-type: application/json' \
      --data "{ \
        \"channel\": \"${channel}\", \
        \"attachments\": [ \
          { \
            \"fallback\": \":red_circle: A $CIRCLE_JOB job has failed!\", \
            \"text\": \":red_circle: A $CIRCLE_JOB job has failed! $SLACK_MENTIONS\", \
            \"fields\": [ \
              { \
                \"title\": \"Project\", \
                \"value\": \"$CIRCLE_PROJECT_REPONAME\", \
                \"short\": true \
              }, \
              { \
                \"title\": \"Job Number\", \
                \"value\": \"$CIRCLE_BUILD_NUM\", \
                \"short\": true \
              } \
            ], \
            \"actions\": [ \
              { \
                \"type\": \"button\", \
                \"text\": \"Visit Job\", \
                \"url\": \"$CIRCLE_BUILD_URL\" \
              } \
            ], \
            \"color\": \"#ed5c5c\" \
          } \
        ] \
      } " "${SLACK_WEBHOOK}"
    echo "Job failed. Alert sent."
  fi
else
  echo "The job completed successfully"
  echo "No Slack notification sent."
fi
