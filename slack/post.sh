#!/usr/bin/env bash
CHANNEL=$1
TEXT=$2
TOKEN=xoxb-174571085203-atZINJtqPodyH87qgVHPZs58

curl -XPOST -d "token=${TOKEN}" -d "channel=${CHANNEL}" -d "text=${TEXT}" -d "username=swirhentv" -d "link_names=1" "https://slack.com/api/chat.postMessage"
