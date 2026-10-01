# -*- coding: utf-8 -*-
# discord投稿系の共通モジュール (today_picture / jihou から利用)
import pathlib
import requests

SCRIPT_DIR = str(pathlib.Path(__file__).resolve().parent)
DISCORD_WEBHOOK_URI_FILE = f'{SCRIPT_DIR}/discord_webhook_url'


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


# discordにuploadする
def discord_upload(channel, filename):
    discord_webhook_uri = get_discord_webhook_url(channel)
    if discord_webhook_uri != '':
        with open(filename, 'rb') as file:
            files = {'param_name': (pathlib.Path(filename).name, file)}
            try:
                requests.post(discord_webhook_uri, files=files)
            except Exception as e:
                print(e)
