#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# twitter キーワードチェック
# 特に重要なキーワードが流れてきた場合、slackにおしらせする
# キーワード設定ファイル: checklist.txt
# 設定ファイル書式: チャンネル名|キーワード
# tiarrametro DBに接続するので、DBに取得していないチャンネルは取得不可
import datetime
import pprint

import sys
import pathlib
import re
from datetime import datetime as dt
current_dir = pathlib.Path(__file__).resolve().parent
sys.path.append(f'{str(current_dir)}/python-lib/')
import MySQLdb
import swirhentv_util as swiutil

# argments section
SCRIPT_DIR = str(current_dir)
LIST_FILE = f'{SCRIPT_DIR}/checklist.txt'
TDATETIME = dt.now()
DATETIME = TDATETIME.strftime('%Y/%m/%d-%H:%M:%S')
DATETIME_10MIN_AGO = (TDATETIME - datetime.timedelta(minutes=10)).strftime('%Y/%m/%d-%H:%M:%S')
YOUR_NICK = 'swirhen'

# database connect
connection = MySQLdb.connect(
    host='localhost',
    user='tiarra',
    passwd='arrati',
    db='tiarra')
cursor = connection.cursor()

# 10min ago all log select
select_sql = "select c.name, n.name, l.log, l.created_on" \
             " from channel c,log l ,nick n" \
             " where l.channel_id = c.id" \
             " and l.nick_id = n.id" \
            f" and l.created_on > '{DATETIME_10MIN_AGO}'" \
            f" and n.name not like '%{YOUR_NICK}%'"

logs = dict()
channel_p = ''
nick_p = ''
log_text_p = ''
date_p = ''
for row in cursor:
    channel = row[0]
    if not channel in logs:
        logs[channel] = []

    nick = row[1]
    log_text = row[2]
    date = row[3].strftime('%Y/%m/%d %H:%M:%S')

    # 1行前とchannel, nick, 投稿日時が違う場合のみ、1行前のものを配列に加える
    # 同じ場合はログに改行を加えて追加する
    if channel_p != '' and channel_p != channel and nick_p != nick and date_p != date:
        logs[channel_p].append([nick_p, log_text_p, date_p])
    else:
        log_text_p += f'\n{log_text}'

    channel_p = channel
    nick_p = nick
    log_text_p = log_text
    date_p = date

# 最後の行
logs[channel_p].append([nick_p, log_text_p, date_p])

pprint.pprint(logs)

