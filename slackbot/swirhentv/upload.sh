#!/usr/bin/env bash
script_dir="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"
channel=$1
filename=$2
filetitle=$3
if [ "" != "$4" ]; then
  filetype=$4
else
  filetype=text
fi

DATETIME="`date '+%Y%m%d'`"
token=`cat ${script_dir}/token`

echo "curl -F channels=${channel} -F file=@${filename} -F title=\"${filetitle}\" -F token=${token} -F filetype=${filetype} https://tyoro.slack.com/api/files.upload -k"

curl -F channels=${channel} -F file=@${filename} -F title=${filetitle} -F token=${token} https://slack.com/api/files.upload -k