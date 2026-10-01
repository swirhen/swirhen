# -*- coding: utf-8 -*-
# きょうのいちまい
# すいれんさんの待ち受け画像貯蔵ディレクトリ(2021年以降)から画像を1枚ランダムで表示する
# 直近100枚からは表示しない
# import section
import os
import subprocess
import random
import pathlib
import requests
from datetime import datetime as dt

# arguments section
current_dir = pathlib.Path(__file__).resolve().parent
SCRIPT_DIR = str(current_dir)
RECENT_LIST = f'{SCRIPT_DIR}/today_picture_recent.txt'
DISCORD_WEBHOOK_URI_FILE = f'{SCRIPT_DIR}/discord_webhook_url'
PIC_DIR = '/data/share/temp/wallpaper'
CHANNEL = 'ztb_today_pic'


# discord channel decision
def get_discord_webhook_url(target_channel):
    result = ''
    with open(DISCORD_WEBHOOK_URI_FILE) as file:
        for line in file.read().splitlines():
            channel = line.split()[0]
            webhook_uri = line.split()[1]
            if channel == target_channel:
                result = webhook_uri
                break
    return result


# discordにpostする
def discord_post(channel, text):
    discord_webhook_uri = get_discord_webhook_url(channel)
    if discord_webhook_uri != '':
        main_content = {
            'content': text.replace('@channel', '@here')
        }
        try:
            requests.post(discord_webhook_uri, main_content)
        except Exception as e:
            print(e)


def choice_the_picture(urlflag=False, recent_list=RECENT_LIST, year=''):
    if year == '':
        pyear = str(int(dt.now().strftime('%Y')) - 1)
        fileset = set(subprocess.run(f'find {PIC_DIR} -type f -newermt "2020-12-31"', shell=True, stdout=subprocess.PIPE).stdout.decode().strip().splitlines())
    else:
        pyear = str(int(year) - 1)
        fileset = set(subprocess.run(f'find {PIC_DIR} -type f -newermt "2020-12-31" ! -newermt "{year}-12-31"', shell=True, stdout=subprocess.PIPE).stdout.decode().strip().splitlines())

    recent_filelist = []
    if os.path.exists(recent_list):
        with open(recent_list) as file:
            recent_filelist = file.read().splitlines()
    choiced_file_path = random.choice(list(fileset - set(recent_filelist)))

    if urlflag:
        return choiced_file_path.replace('/data', 'http://swirhen.tv')
    else:
        return (recent_filelist[-99:] + [choiced_file_path])


def today_picture_normal():
    filelist = choice_the_picture()
    discord_post(CHANNEL, 'どどんどどんどんどん！ 画像ちゃん！\n'
                 f'{filelist[-1].replace("/data", "http://swirhen.tv")}')
    with open(RECENT_LIST, mode='w') as file:
        file.write('\n'.join(filelist))


if __name__ == '__main__':
    today_picture_normal()
