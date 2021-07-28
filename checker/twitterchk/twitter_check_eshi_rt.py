#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# twitter キーワードチェック
# 特に重要なキーワードが流れてきた場合、slackにおしらせする
# キーワード設定ファイル: checklist.txt
# 設定ファイル書式: チャンネル名|キーワード
# tiarrametro DBに接続するので、DBに取得していないチャンネルは取得不可
# import section
import datetime
import sys
import pathlib
import re
from datetime import datetime as dt
current_dir = pathlib.Path(__file__).resolve().parent
sys.path.append('/data/share/movie/sh/python-lib/')
import MySQLdb
import swirhentv_util as swiutil

# argument section
SCRIPT_DIR = str(current_dir)
CHECKLIST_FILE = f'{SCRIPT_DIR}/ekakisan.txt'
ART_HASHTAG_FILE = f'{SCRIPT_DIR}/art_hashtag.txt'
CHECK_CHANNEL = '#Twitter@t3'
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
SLACK_CHANNEL = 'twitter-search'
SLACK_CHANNEL2 = 'ztb_twitter-search'

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
            f" and l.created_on >= '{DATETIME_QUERY_START}'" \
            f" and l.created_on <= '{DATETIME}'" \
            f" and c.name = '{CHECK_CHANNEL}'" \
            f" and n.name = '{YOUR_NICK}'" \
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

result = []
for log in logs[channel]:
    nick = log[0]
    text = log[1]
    date = log[2]
    # キーワードチェック
    for keyword in check_list[channel]:
        if re.search(keyword, text.replace('\n','_')):
            result.append(f'チャンネル: {channel} キーワード: {keyword}\n[{date}] <{nick}> {text}')
            break

# 絵師RTリスト追加チェック
for log in logs[CHECK_CHANNEL]:
    nick = log[0]
    text = log[1]
    date = log[2]

    if re.search('♻', text.replace('\n','_')):
        rt_nick = re.sub(r'.*RT\ @(.*?):.*', r'\1',text)
        if swiutil.grep_file(CHECKLIST_FILE, rt_nick) == '':




if len(result) > 0:
    post_str = f'@here 【twitter log検索 ({DATETIME_QUERY_START} - {DATETIME})】keyword hit!:\n' \
                '```' + '\n'.join(result) + '```'
    swiutil.multi_post(SLACK_CHANNEL, post_str)
    swiutil.discord_post(SLACK_CHANNEL2, post_str.replace('@here ', ''))