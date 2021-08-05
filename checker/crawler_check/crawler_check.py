#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# URL crawl checker
# 引数1: URL
# 引数2: ファイル名
# 引数3: 除外行キーワード(複数ある場合は|で区切る)
# URLをファイル名に保存し、前回取得時と差分があれば報告
# import section
import os
import sys
import subprocess
import pathlib
import shutil
import urllib.request
current_dir = pathlib.Path(__file__).resolve().parent
sys.path.append('/data/share/movie/sh/python-lib/')
import swirhentv_util as swiutil

# argument section
SCRIPT_DIR = str(current_dir)
SLACK_CHANNEL = 'bot-open'


# main module
def main(uri, filename, ignore_keywords=''):
    true_filename = f'{SCRIPT_DIR}/temp/{filename}'
    temp_filename = f'{true_filename}.temp'
    try:
        req = urllib.request.Request(uri)
        data = urllib.request.urlopen(req).read()
    except Exception as e:
        print(f'# download error: {e}')
    else:
        with open(temp_filename, mode='wb') as file:
            file.write(data)
    
    if ignore_keywords != '':
        for ignore_keyword in ignore_keywords.split('|'):
            swiutil.sed_del(temp_filename, ignore_keyword)
    
    if os.path.exists(true_filename):
        diff_result = subprocess.run(f'diff "{temp_filename}" "{true_filename}" -I "^#"', shell=True, stdout=subprocess.PIPE).stdout.decode().strip().splitlines()
        if len(diff_result):
            post_str = ':earth_asia: @here [swirhen.tv url crawler] 取得したURLの変更を検知\n' \
                        f'取得URL: {uri}\n' \
                        '差分: \n' \
                        '```' + '\n'.join(diff_result) + '```'
            swiutil.multi_post(SLACK_CHANNEL, post_str)
        shutil.move(temp_filename, true_filename)
    else:
        print('nai node rename dake suru')
        shutil.move(temp_filename, true_filename)


if __name__ == "__main__":
    # main section
    args = sys.argv
    if len(args) == 3:
            main(args[1], args[2])
    elif len(args) == 4:
            main(args[1], args[2], args[3])
