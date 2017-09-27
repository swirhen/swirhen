#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"
LISTDIR="/data/share/movie/sh"
LISTFILE="checklist.txt"

MODE=$1
ARGS=( $@ )

if [ ${#ARGS[@]} -lt 2 ]; then
  exit 1
fi

if [ "${MODE}" = "i" ]; then
  i=0
  for TEXT in "${ARGS[@]}"
  do
    if [ ${i} -gt 0 ]; then
      echo "# insert: ${TEXT}"
#      echo "echo \"# 0 ${TEXT}\" >> \"${LISTFILE}\""
      echo "# 0 ${TEXT}" >> "${LISTFILE}"
    fi
    (( i++ ))
  done
  git diff "${LISTFILE}"
  git commit -m "LIST ADD FROM SLACKBOT" "${LISTFILE}"
  git pull
  git push origin master
elif [ "${MODE}" = "d" ]; then
  i=0
  for TEXT in "${ARGS[@]}"
  do
    if [ ${i} -gt 0 ]; then
      echo "# delete: ${TEXT}"
#      echo "sed -i -e '/${TEXT}/d' \"${LISTFILE}\""
      sed -i -e "/${TEXT}/d" "${LISTFILE}"
    fi
    (( i++ ))
  done
  git diff "${LISTFILE}"
  git commit -m "LIST ADD FROM SLACKBOT" "${LISTFILE}"
  git pull
  git push origin master
else
  exit 1
fi