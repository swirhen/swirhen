import subprocess
import os
import time
import re
import slackbot_settings
from datetime import datetime
from slackbot.bot import respond_to
from slacker import Slacker
slack = Slacker(slackbot_settings.API_TOKEN)


@respond_to('^ *reload.*')
def reload(message):
    message.reply(slackbot_settings.HOSTNAME + ' slackbot 自己更新します')
    cmd = './upres.sh 2 ' + message._body['channel']
    call_cmd(cmd)


@respond_to('^ *reboot.*')
def reboot(message):
    message.reply(slackbot_settings.HOSTNAME + ' slackbot 再起動します')
    cmd = './upres.sh 0 ' + message._body['channel']
    call_cmd(cmd)


@respond_to('^ *update.*')
def update(message):
    message.reply(slackbot_settings.HOSTNAME + ' slackbot 自己更新 & 再起動します')
    cmd = './upres.sh 1 ' + message._body['channel']
    call_cmd(cmd)


def call_cmd(cmd):
    ret = subprocess.call(cmd, shell=True)
    return ret


def exec_cmd(cmd):
    ret = subprocess.check_output(cmd, shell=True, universal_newlines=True)
    return ret


def file_upload(filename, filetitle, filetype, message):
    if os.path.getsize(filename) == 0:
        message.send('```(no log)```')
    else:
        slack.files.upload(
            filename,
            filename=filetitle,
            filetype=filetype,
            channels=message._body['channel'],
        )
