#!/usr/bin/env bash
upflg=$1
channel=$2
script_dir="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"

if [ "$channel" = "" ]; then
  channel="bot-sandbox"
fi

logfile="${script_dir}/temp/update_restart.log"
rm -f ${logfile}

if [ "${upflg}" = "1" -o "${upflg}" = "2" ]; then
  echo "*** slackbot 自己更新 ***" | tee -a ${logfile}

  echo "git pull" | tee -a ${logfile}
  git pull origin master --force | tee -a ${logfile}

  echo "chmod +x *.sh" | tee -a ${logfile}
  chmod +x *.sh | tee -a ${logfile}

  git commit -m 'chmod'
  git push origin master
fi

if [ "${upflg}" != "2" ]; then
  echo "*** slackbot 再起動 ***" | tee -a ${logfile}

  echo "kill `cat ${script_dir}/slackbot.pid`" | tee -a ${logfile}
  kill `cat ${script_dir}/slackbot.pid` | tee -a ${logfile}

  echo "python run.py" | tee -a ${logfile}
  python run.py | tee -a ${logfile} &
fi

if [ "${upflg}" = "1" ]; then
  python post.py "${channel}" "$HOSTNAME slackbot 自己更新 & 再起動しました
"'```'"`cat ${logfile}`"'```'
elif [ "${upflg}" = "2" ]; then
  python post.py "${channel}" "$HOSTNAME slackbot 自己更新しました
"'```'"`cat ${logfile}`"'```'
else
  python post.py "${channel}" "$HOSTNAME slackbot 再起動しました"
fi