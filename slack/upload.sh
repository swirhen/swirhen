#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"
CHANNEL=$1
FILENAME=$2
TITLE=$3
TOKEN=`cat ${SCRIPT_DIR}/token`

curl -F channels=${CHANNEL} -F file=@"${FILENAME}" -F title=${TITLE} -F token=${TOKEN} https://slack.com/api/files.upload