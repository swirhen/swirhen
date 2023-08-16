#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# twitter検索：ホロ絵師RTチェック
# #Twitter@t3でswirhenがRTしたIDのツイートを精査して、
# ホロファンアートのハッシュタグがあり、かつリストにIDが無い場合は
# #twitter絵描きさんのリストに入れる
# キーワード設定ファイル: ekakisan.txt
# import section
import datetime
import sys
import git
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
TIG_GROUP_XML = '/home/swirhen/dotfile/TIG/Configs/swirhen/Groups.xml'
CHECK_CHANNEL = '#Twitter@t3'
TDATETIME = dt.now()
DATETIME = TDATETIME.strftime('%Y/%m/%d %H:%M:%S')
playback_minutes = 10
args = sys.argv
if len(args) == 2:
    playback_minutes = args[1]
DATETIME_QUERY_START = (TDATETIME - datetime.timedelta(minutes=int(playback_minutes))).strftime('%Y/%m/%d %H:%M:%S')
if len(args) == 3:
    DATETIME_QUERY_START = args[1]
    DATETIME = args[2]
YOUR_NICK = 'swirhen'
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

    # 1行前とchannel, nick, <s>投稿日時</s>が同じ場合はログに改行を加えて追加する
    # 違う場合、1行前のものを配列に加える
    if channel_p == channel and nick_p == nick:
        log_text_p += f'\n{log_text}'
    else:
        if channel_p != '':
            logs[channel_p].append([nick_p, log_text_p, date_p])
        log_text_p = log_text

    channel_p = channel
    nick_p = nick
    date_p = date

# ループ終了 最後の行
logs[channel_p].append([nick_p, log_text_p, date_p])

cursor.close()

result = []
# 絵師RTリスト追加チェック
for log in logs[CHECK_CHANNEL]:
    nick = log[0]
    text = log[1]
    date = log[2]

    if re.search('♻', text.replace('\n','_')):
        # RTマークで発言を分割(複数発言が繋がってしまった場合を考慮)
        tweets = text.replace('\n','_').split('♻')
        for tweet in tweets:
            if re.search(' RT @', tweet) and \
                re.search(r'#soraArt|#ロボ子Art|#miko_Art|#ほしまちぎゃらりー|#メルArt|#アロ絵|#はあとart|#絵フブキ|#祭絵|#あくあーと|#シオンの書物|#百鬼絵巻|#しょこらーと|#プロテインザスバル|#みおーん絵|#絵かゆ|#できたてころね|#AZKiART|#ぺこらーと|#絵クロマンサー|#しらぬえ|#ノエラート|#マリンのお宝|#かなたーと|#みかじ絵|#つのまきあーと|#TOWART|#ルーナート|#LamyArt|#ねねアルバム|#ししらーと|#絵まる|#GambaRisu|#ioarts|#HoshinovArt|#anyatelier|#Reinessance|#graveyART|#絵ニックス|#callillust|#ameliaRT|#いなート|#gawrt|#inART|#artsofashes|#teamates|#callioP|#スケベなアロ絵|#肌色まつり|#まつりは絵っち|#エロおにぎり|#オークアート|#沈没後悔日記|#glAMErous|#IRySart|#illustrayBAE|#ベーアート|#faunline|#kronillust|#galaxillust|#クロニーラ|#holoCouncil|#omegallery|#drawMEI|#ムメ絵|#FineFaunart|絵ーちゃん|#Laplus_Artdesu|#Luillust|#こよりすけっち|#さかまた飼育日記|#いろはにも絵を|#Zetacrylic|#inKaela|#AeruSeni|#のどかあーと|#BaelzBrush', tweet):
                rt_nick = re.sub(r'.*RT\ @(.*?):.*', r'\1', tweet)
                if len(swiutil.grep_file(CHECKLIST_FILE, rt_nick)) == 0:
                    result.append(f'リストに無いホロ絵師ID({rt_nick})がRTされたのでリスト追加:\n[{date}] <{nick}> ♻{tweet.replace("_"," ")}')
                    swiutil.writefile_append(CHECKLIST_FILE, rt_nick)
                    swiutil.tweeet(f'ie {rt_nick}', '#Console@t')

if len(result) > 0:
    post_str = f':arrow_forward: @here 【twitter log検索(ホロ絵師リスト追加チェック)\n({DATETIME_QUERY_START} - {DATETIME})】:\n' \
                '```' + '\n'.join(result) + '```'
    swiutil.multi_post(SLACK_CHANNEL, post_str)
    swiutil.discord_post(SLACK_CHANNEL2, post_str.replace('@here ', ''))
    repo = git.Repo('/home/swirhen/sh')
    repo.git.commit(CHECKLIST_FILE, message='ekakisan.txt update')
    repo.git.pull()
    repo.git.push()
    repo2 = git.Repo('/home/swirhen/dotfile')
    repo2.git.commit(TIG_GROUP_XML, message='new ekakisan')
    repo2.git.pull()
    repo2.git.push()
