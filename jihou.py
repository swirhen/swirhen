# -*- coding: utf-8 -*-
import pathlib
import datetime
from discord_util import discord_post, discord_upload

current_dir = pathlib.Path(__file__).resolve().parent
SCRIPT_DIR = str(current_dir)
NEYOU_FILE = f'{SCRIPT_DIR}/neyou.jpg'
CHANNEL = 'jihou'
CHANNEL_OPEN = 'ztb_jihou'


if __name__ == '__main__':
    now = datetime.datetime.now()
    hour = int(now.strftime('%-H'))
    date = now.strftime('%Y/%-m/%-d (%A)')
    if hour == 0:
        post_str = f'{date} になりました。 {str(hour)} 時ごろをお知らせします。'
    elif hour == 12:
        post_str = f'{hour} 時ごろをお知らせします。おひるです。'
    elif hour == 15:
        post_str = f'{hour} 時ごろをお知らせします。おやつです。'
    else:
        post_str = f'{hour} 時ごろをお知らせします。'

    discord_post(CHANNEL, f'{post_str}')
    discord_post(CHANNEL_OPEN, f'{post_str}')
    if hour == 2:
        discord_upload(CHANNEL, NEYOU_FILE)
        discord_upload(CHANNEL_OPEN, NEYOU_FILE)
