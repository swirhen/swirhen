import subprocess
import os
import time
import re
import slackbot_settings
from datetime import datetime
from slackbot.bot import respond_to
from slacker import Slacker
slack = Slacker(slackbot_settings.API_TOKEN)


@respond_to('^ *でかした.*')
@respond_to('^ *よくやった.*')
def doya(message):
    message.send('(｀･ω･´)ﾄﾞﾔｧ...')


@respond_to('^ *sdl')
def seed_download(message):
    message.send('やるー')
    cmd = '/data/share/movie/sh/autodl.sh'
    call_cmd(cmd)


@respond_to('^ *tdl')
def torrent_download(message):
    message.send('やるー')
    launch_dt = datetime.now().strftime('%Y%m%d%H%M%S')
    logfile = 'temp/torrent_download_' + launch_dt + '.temp'
    filetitle = 'torrent_download_' + launch_dt
    cmd = './tdl.sh &> {0}'.format(logfile)
    call_cmd(cmd)
    message.reply('おわた(｀･ω･´)')
    time.sleep(1)
    file_upload(logfile, filetitle, 'text', message)
    time.sleep(1)
    os.remove(logfile)


@respond_to('^ *mre')
def movie_rename(message):
    message.send('やるー')
    launch_dt = datetime.now().strftime('%Y%m%d%H%M%S')
    logfile = 'temp/mre' + launch_dt + '.temp'
    filetitle = 'movie_rename_' + launch_dt
    cmd = './mre.sh &> {0}'.format(logfile)
    call_cmd(cmd)
    message.reply('おわた(｀･ω･´)')
    time.sleep(1)
    file_upload(logfile, filetitle, 'text', message)
    time.sleep(1)
    os.remove(logfile)


@respond_to('^ *rmm')
def movie_rename2(message):
    message.send('やるー')
    launch_dt = datetime.now().strftime('%Y%m%d%H%M%S')
    logfile = 'temp/rmm_' + launch_dt + '.temp'
    filetitle = 'movie_rename_' + launch_dt
    cmd = './rmm.sh &> {0}'.format(logfile)
    call_cmd(cmd)
    message.reply('おわた(｀･ω･´)')
    time.sleep(1)
    file_upload(logfile, filetitle, 'text', message)
    time.sleep(1)
    os.remove(logfile)


@respond_to('^ *(.*) の種ない？')
@respond_to('^ *tss (.*)')
def torrent_search(message, argment):
    message.send('さがすー')
    resultfile='temp/tss.result'
    if os.path.exists(resultfile):
        os.remove(resultfile)

    cmd = './tss.sh {0}'.format(argment)
    call_cmd(cmd)
    if os.path.exists(resultfile):
        uri=open(resultfile).read()
        message.reply(uri + ' にあったよ')
    else:
        message.send('なかったよ(´･ω･`)')


@respond_to('^ *reload.*')
def reload(message):
    message.reply(slackbot_settings.HOSTNAME + ' slackbot 自己更新します')
    cmd = './update.sh 2 ' + message._body['channel']
    call_cmd(cmd)


@respond_to('^ *reboot.*')
def reboot(message):
    message.reply(slackbot_settings.HOSTNAME + ' slackbot 再起動します')
    cmd = './update.sh 0 ' + message._body['channel']
    call_cmd(cmd)


@respond_to('^ *update.*')
def update(message):
    message.reply(slackbot_settings.HOSTNAME + ' slackbot 自己更新 & 再起動します')
    cmd = './update.sh 1 ' + message._body['channel']
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
