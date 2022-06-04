#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# diablo2 resurrected diablo clone tracker from diablo2.io
# diablo2.io の diablo clone tracker apiを取得し、変化があったら通知する
# import section
from audioop import add
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
API_URI='https://diablo2.io/dclone_api.php'
SCRIPT_DIR = str(current_dir)
PROGRESS_ASIA = f'{SCRIPT_DIR}/asia.txt'
PROGRESS_US = f'{SCRIPT_DIR}/us.txt'
PROGRESS_EU = f'{SCRIPT_DIR}/eu.txt'
PROGRESS_ASIA_L = f'{SCRIPT_DIR}/asia_l.txt'
PROGRESS_US_L = f'{SCRIPT_DIR}/us_l.txt'
PROGRESS_EU_L = f'{SCRIPT_DIR}/eu_l.txt'
H_PROGRESS_ASIA_L = f'{SCRIPT_DIR}/asia_l_h.txt'
H_PROGRESS_US_L = f'{SCRIPT_DIR}/us_l_h.txt'
H_PROGRESS_EU_L = f'{SCRIPT_DIR}/eu_l_h.txt'
ADDFLAG_ASIA = f'{SCRIPT_DIR}/asia.add'
ADDFLAG_US = f'{SCRIPT_DIR}/us.add'
ADDFLAG_EU = f'{SCRIPT_DIR}/eu.add'
ADDFLAG_ASIA_L = f'{SCRIPT_DIR}/asia_l.add'
ADDFLAG_US_L = f'{SCRIPT_DIR}/us_l.add'
ADDFLAG_EU_L = f'{SCRIPT_DIR}/eu_l.add'
H_ADDFLAG_ASIA_L = f'{SCRIPT_DIR}/asia_l_h.add'
H_ADDFLAG_US_L = f'{SCRIPT_DIR}/us_l_h.add'
H_ADDFLAG_EU_L = f'{SCRIPT_DIR}/eu_l_h.add'
DISCORD_CHANNEL = 'diablo-clone-tracker'
DISCORD_CHANNEL2 = 'diablo-clone-tracker-pub'
DISCORD_CHANNEL2L = 'diablo-clone-tracker-pub_l'
DISCORD_CHANNEL2HL = 'diablo-clone-tracker-pub_l_h'

# add check process module
# return add flag
def add_check(p_val, n_val, flag_file):
    if p_val < n_val:
        # 増加
        if os.path.isfile(flag_file):
            # フラグファイルがある→Trueを返す
            return True
        else:
            # フラグファイルがない→フラグファイルを作成
            swiutil.writefile_new(flag_file, '1')
            # 増分が1かつ数値が4以上→報告もする
            if int(n_val) - int(p_val) == 1 and int(n_val) > 3:
                return True
    elif p_val > n_val:
        # 減少
        if os.path.isfile(flag_file):
            # フラグファイルがある→フラグファイルを消す
            swiutil.deletefile(flag_file)
    
    return False


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
    asia_chg_flg_l = False
    us_chg_flg_l = False
    eu_chg_flg_l = False
    asia_add_flg_l = False
    us_add_flg_l = False
    eu_add_flg_l = False
    with open(PROGRESS_ASIA_L) as f:
        p_asia_l = f.readline()[0]
    with open(PROGRESS_US_L) as f:
        p_us_l = f.readline()[0]
    with open(PROGRESS_EU_L) as f:
        p_eu_l = f.readline()[0]
    asia_chg_flg_h_l = False
    us_chg_flg_h_l = False
    eu_chg_flg_h_l = False
    asia_add_flg_h_l = False
    us_add_flg_h_l = False
    eu_add_flg_h_l = False
    with open(H_PROGRESS_ASIA_L) as f:
        h_p_asia_l = f.readline()[0]
    with open(H_PROGRESS_US_L) as f:
        h_p_us_l = f.readline()[0]
    with open(H_PROGRESS_EU_L) as f:
        h_p_eu_l = f.readline()[0]

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
            if item['hc'] == '2':
                if item['ladder'] == '2':
                    if item['region'] == '1':
                        n_us = item['progress']
                        if n_us != p_us:
                            swiutil.writefile_new(PROGRESS_US, n_us)
                            us_chg_flg = True
                        us_add_flg = add_check(p_us, n_us, ADDFLAG_US)
                    elif item['region'] == '2':
                        n_eu = item['progress']
                        if n_eu != p_eu:
                            swiutil.writefile_new(PROGRESS_EU, n_eu)
                            eu_chg_flg = True
                        eu_add_flg = add_check(p_eu, n_eu, ADDFLAG_EU)
                    elif item['region'] == '3':
                        n_asia = item['progress']
                        if n_asia != p_asia:
                            swiutil.writefile_new(PROGRESS_ASIA, n_asia)
                            asia_chg_flg = True
                        asia_add_flg = add_check(p_asia, n_asia, ADDFLAG_ASIA)
                elif item['ladder'] == '1':
                    if item['region'] == '1':
                        n_us_l = item['progress']
                        if n_us_l != p_us_l:
                            swiutil.writefile_new(PROGRESS_US_L, n_us_l)
                            us_chg_flg_l = True
                        us_add_flg_l = add_check(p_us_l, n_us_l, ADDFLAG_US_L)
                    elif item['region'] == '2':
                        n_eu_l = item['progress']
                        if n_eu_l != p_eu_l:
                            swiutil.writefile_new(PROGRESS_EU_L, n_eu_l)
                            eu_chg_flg_l = True
                        eu_add_flg_l = add_check(p_eu_l, n_eu_l, ADDFLAG_EU_L)
                    elif item['region'] == '3':
                        n_asia_l = item['progress']
                        if n_asia_l != p_asia_l:
                            swiutil.writefile_new(PROGRESS_ASIA_L, n_asia_l)
                            asia_chg_flg_l = True
                        asia_add_flg_l = add_check(p_asia_l, n_asia_l, ADDFLAG_ASIA_L)
            elif item['hc'] == '1':
                if item['ladder'] == '1':
                    if item['region'] == '1':
                        h_n_us_l = item['progress']
                        if h_n_us_l != h_p_us_l:
                            swiutil.writefile_new(H_PROGRESS_US_L, h_n_us_l)
                            us_chg_flg_h_l = True
                        us_add_flg_h_l = add_check(h_p_us_l, h_n_us_l, H_ADDFLAG_US_L)
                    elif item['region'] == '2':
                        h_n_eu_l = item['progress']
                        if h_n_eu_l != h_p_eu_l:
                            swiutil.writefile_new(H_PROGRESS_EU_L, h_n_eu_l)
                            eu_chg_flg_h_l = True
                        eu_add_flg_h_l = add_check(h_p_eu_l, h_n_eu_l, H_ADDFLAG_EU_L)
                    elif item['region'] == '3':
                        h_n_asia_l = item['progress']
                        if h_n_asia_l != h_p_asia_l:
                            swiutil.writefile_new(H_PROGRESS_ASIA_L, h_n_asia_l)
                            asia_chg_flg_h_l = True
                        asia_add_flg_h_l = add_check(h_p_asia_l, h_n_asia_l, H_ADDFLAG_ASIA_L)

    if force_flg or us_chg_flg or eu_chg_flg or asia_chg_flg:
        if us_add_flg or eu_add_flg or asia_add_flg:
            post_str = '@here 【diablo2.io diablo clone tracker】(連続の増加を検知)'
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
        swiutil.discord_post(DISCORD_CHANNEL2, post_str)


    if force_flg or us_chg_flg_l or eu_chg_flg_l or asia_chg_flg_l:
        if us_add_flg_l or eu_add_flg_l or asia_add_flg_l:
            post_str = '@here 【diablo2.io diablo clone tracker(ladder)】(連続の増加を検知)'
        else:
            post_str = '【diablo2.io diablo clone tracker(ladder)】'

        if force_flg:
            post_str += '(定時チェック)\n'
        else:
            post_str += '\n'

        if asia_chg_flg_l:
            post_str += f'アジア(**変更あり！**)：{p_asia_l} -> {n_asia_l}\n'
        else:
            post_str += f'アジア：{n_asia_l}\n'
        if us_chg_flg_l:
            post_str += f'US(**変更あり！**)：{p_us_l} -> {n_us_l}\n'
        else:
            post_str += f'US：{n_us_l}\n'
        if eu_chg_flg_l:
            post_str += f'EU(**変更あり！**)：{p_eu_l} -> {n_eu_l}\n'
        else:
            post_str += f'EU：{n_eu_l}\n'

        swiutil.discord_post(DISCORD_CHANNEL2L, post_str)


    if force_flg or us_chg_flg_h_l or eu_chg_flg_h_l or asia_chg_flg_h_l:
        if us_add_flg_h_l or eu_add_flg_h_l or asia_add_flg_h_l:
            post_str = '@here 【diablo2.io diablo clone tracker(hardcore-ladder)】(連続の増加を検知)'
        else:
            post_str = '【diablo2.io diablo clone tracker(hardcore-ladder)】'

        if force_flg:
            post_str += '(定時チェック)\n'
        else:
            post_str += '\n'

        if asia_chg_flg_h_l:
            post_str += f'アジア(**変更あり！**)：{h_p_asia_l} -> {h_n_asia_l}\n'
        else:
            post_str += f'アジア：{h_n_asia_l}\n'
        if us_chg_flg_h_l:
            post_str += f'US(**変更あり！**)：{h_p_us_l} -> {h_n_us_l}\n'
        else:
            post_str += f'US：{h_n_us_l}\n'
        if eu_chg_flg_h_l:
            post_str += f'EU(**変更あり！**)：{h_p_eu_l} -> {h_n_eu_l}\n'
        else:
            post_str += f'EU：{h_n_eu_l}\n'

        swiutil.discord_post(DISCORD_CHANNEL2HL, post_str)


if __name__ == "__main__":
    # main section
    args = sys.argv
    if len(args) == 2 or dt.now().minute == 0:
        main(True)
    else:
        main()
