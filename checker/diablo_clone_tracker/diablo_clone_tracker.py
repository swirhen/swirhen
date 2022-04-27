#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# diablo2 resurrected diablo clone tracker from diablo2.io
# diablo2.io の diablo clone tracker apiを取得し、変化があったら通知する
# import section
import os
import pathlib
import sys
import urllib.request
from datetime import datetime as dt
import json
current_dir = pathlib.Path(__file__).resolve().parent
sys.path.append('/data/share/movie/sh/python-lib/')
import swirhentv_util as swiutil
import bot_util as bu

# arguments section
API_URI='https://diablo2.io/dclone_api.php?ladder=2&hc=2'
SCRIPT_DIR = str(current_dir)
PROGRESS_ASIA = f'{SCRIPT_DIR}/asia.txt'
PROGRESS_US = f'{SCRIPT_DIR}/us.txt'
PROGRESS_EU = f'{SCRIPT_DIR}/eu.txt'
DISCORD_CHANNEL = 'diablo-clone-tracker'

# main module
def main(force_flg=False):
    asia_chg_flg = False
    us_chg_flg = False
    eu_chg_flg = False
    asia_add_flg = False
    us_add_flg = False
    eu_add_flg = False
    with open(PROGRESS_ASIA) as f:
        p_asia = f.readline()[0]
    with open(PROGRESS_US) as f:
        p_us = f.readline()[0]
    with open(PROGRESS_EU) as f:
        p_eu = f.readline()[0]

    req = urllib.request.Request(API_URI)
    try:
        with urllib.request.urlopen(req) as response:
            json_string = response.read()
    except Exception as e:
        print(e)
    else:
        dict_from_api = json.loads(json_string)

    if len(dict_from_api) > 0:
        for item in dict_from_api:
            if item['region'] == '1':
                n_us = item['progress']
                if n_us != p_us:
                    swiutil.writefile_new(PROGRESS_US, n_us)
                    us_chg_flg = True
                if n_us > p_us:
                    us_add_flg = True
            elif item['region'] == '2':
                n_eu = item['progress']
                if n_eu != p_eu:
                    swiutil.writefile_new(PROGRESS_EU, n_eu)
                    eu_chg_flg = True
                if n_eu > p_eu:
                    eu_add_flg = True
            elif item['region'] == '3':
                n_asia = item['progress']
                if n_asia != p_asia:
                    swiutil.writefile_new(PROGRESS_ASIA, n_asia)
                    asia_chg_flg = True
                if n_asia > p_asia:
                    asia_add_flg = True

    if force_flg or us_chg_flg or eu_chg_flg or asia_chg_flg:
        if us_add_flg or eu_add_flg or asia_add_flg:
            post_str = '@here 【diablo2.io diablo clone tracker】'
        else:
            post_str = '【diablo2.io diablo clone tracker】'

        if force_flg:
            post_str += '(定時チェック)\n'
        else:
            post_str += '\n'

        if asia_chg_flg:
            post_str += f'アジア(**変更あり！**)：{p_asia} -> {n_asia}\n'
        else:
            post_str += f'アジア：{n_asia}\n'
        if us_chg_flg:
            post_str += f'US(**変更あり！**)：{p_us} -> {n_us}\n'
        else:
            post_str += f'US：{n_us}\n'
        if eu_chg_flg:
            post_str += f'EU(**変更あり！**)：{p_eu} -> {n_eu}\n'
        else:
            post_str += f'EU：{n_eu}\n'

        swiutil.discord_post(DISCORD_CHANNEL, post_str)

if __name__ == "__main__":
    # main section
    args = sys.argv
    if len(args) == 2 or dt.now().minute == 0 or dt.now().minute == 30:
        main(True)
    else:
        main()
