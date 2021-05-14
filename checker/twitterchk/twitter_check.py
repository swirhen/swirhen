#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# twitter キーワードチェック
# 特に重要なキーワードが流れてきた場合、slackにおしらせする
# キーワード設定ファイル: checklist.txt
# 設定ファイル書式: チャンネル名|キーワード
# tiarrametro DBに接続するので、DBに取得していないチャンネルは取得不可
import datetime
import sys
import pathlib
import re
from datetime import datetime as dt
current_dir = pathlib.Path(__file__).resolve().parent
sys.path.append('/data/share/movie/sh/python-lib/')
import MySQLdb
import swirhentv_util as swiutil

# argments section
SCRIPT_DIR = str(current_dir)
CHECKLIST_FILE = f'{SCRIPT_DIR}/check_list.txt'
TDATETIME = dt.now()
DATETIME = TDATETIME.strftime('%Y/%m/%d %H:%M:%S')
playback_minutes = 10
args = sys.argv
if len(args) > 1 and args[1] != '':
    playback_minutes = args[1]
DATETIME_QUERY_START = (TDATETIME - datetime.timedelta(minutes=int(playback_minutes))).strftime('%Y/%m/%d %H:%M:%S')
YOUR_NICK = 'swirhen'
# debug(自分も含める)
if len(args) > 2 and args[2] != '':
    YOUR_NICK = 'fasdlkjhsaldkjfhsadlkjfhs'
# debug 範囲指定
if len(args) == 6:
    DATETIME_QUERY_START = args[4]
    DATETIME = args[5]
SLACK_CHANNEL = 'twitter-keyword-search'

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
             f" and l.created_on => '{DATETIME_QUERY_START}'" \
             f" and l.created_on =< '{DATETIME}'" \
             f" and n.name not like '%{YOUR_NICK}%'" \
             " order by l.created_on"

cursor.execute(select_sql)

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

    # 1行前とchannel, nick, 投稿日時が同じ場合はログに改行を加えて追加する
    # 違う場合、1行前のものを配列に加える
    if channel_p != '':
        if channel_p == channel and nick_p == nick and date_p == date:
            log_text_p += f'\n{log_text}'
        else:
            logs[channel_p].append([nick_p, log_text_p, date_p])
            log_text_p = log_text

    channel_p = channel
    nick_p = nick
    date_p = date

# ループ終了 最後の行
logs[channel_p].append([nick_p, log_text_p, date_p])

cursor.close()

# チェックリスト取得
check_list = dict()
with open(CHECKLIST_FILE) as file:
    for checkitem in list(file.read().splitlines()):
        check_channel = checkitem.split('|')[0]
        if not check_channel in check_list:
            check_list[check_channel] = []

        check_keyword = checkitem.split('|')[1]
        check_list[check_channel].append(check_keyword)

# debug
if len(args) == 4 and args[3] != '':
    ch = args[3].split('|')[0]
    kw = args[3].split('|')[1]
    if not ch in check_list:
        check_list[ch] = []
    check_list[ch].append(kw)

result = []
for channel in check_list.keys():
    if not channel in logs:
        continue

    for log in logs[channel]:
        nick = log[0]
        text = log[1]
        date = log[2]
        for keyword in check_list[channel]:
            if re.search(keyword, text.replace('\n','_')):
                result.append(f'チャンネル: {channel} キーワード: {keyword}\n[{date}] <{nick}> {text}')

if len(result) > 0:
    post_str = f'@here 【twitter log検索 ({DATETIME_QUERY_START} - {DATETIME})】keyword hit!:\n' \
                '```' + '\n'.join(result) + '```'
    swiutil.slack_post(SLACK_CHANNEL, post_str)
