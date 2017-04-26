#!/usr/bin/env bash
CHANNEL=$1
FILENAME=$2
TITLE=$3
TOKEN=xoxb-174571085203-atZINJtqPodyH87qgVHPZs58

curl -F channels=${CHANNEL} -F file=@${FILENAME} -F title=${TITLE} -F token=${TOKEN} https://slack.com/api/files.upload