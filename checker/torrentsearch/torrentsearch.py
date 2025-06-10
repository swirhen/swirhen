#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# torrent file 汎用クロール
# リストに指定したキーワードでnyaaおよびsukebei.nyaaをクロールしたデータベースを検索し、ヒットしたらseedをダウンロードしておく
# import section
import os
import pathlib
import sys
import urllib.request
from datetime import datetime as dt
current_dir = pathlib.Path(__file__).resolve().parent
sys.path.append('/data/share/movie/sh/python-lib/')
import swirhentv_util as swiutil
import bot_util as bu
import sqlite3

# arguments section
GIT_ROOT_DIR = '/home/swirhen/sh'
SCRIPT_DIR = str(current_dir)
CHECKLIST_FILE = f'{SCRIPT_DIR}/checklist.txt'
URL_LIST_FILE = f'{SCRIPT_DIR}/urllist.txt'
DL_URL_LIST_FILE = f'{SCRIPT_DIR}/download_url.txt'
LAST_CHECK_DATE_FILE = f'{SCRIPT_DIR}/last_check_date.txt'
FEED_DB = f'{SCRIPT_DIR}/nyaatorrent_feed.db'
DOWNLOAD_DIR_ROOT = '/data/share/temp/torrentsearch'
SLACK_CHANNEL = 'torrent-search'


# nyaa データベース検索(n日以内のリスト)
def search_seed_resent(category, offset_days):
    conn = sqlite3.connect(FEED_DB)
    cur = conn.cursor()
    fromdate = bu.get_now_datetime_str('YMD_SQL', f'{offset_days}d')
    select_sql = 'select title, link, pubdate' \
                 ' from feed_data f' \
                f' where category = "{category}"' \
                f' and pubdate > "{fromdate}"'

    result = list(cur.execute(select_sql))
    conn.close()
    return result


# nyaa データベース検索・ダウンロード
def search_seed(download_flg, category, keyword, last_check_date=''):
    date_str = dt.now().strftime('%Y%m%d')
    download_dir = f'{DOWNLOAD_DIR_ROOT}/{date_str}'

    # 検索
    conn = sqlite3.connect(FEED_DB)
    cur = conn.cursor()
    select_sql = 'select category, title, link, download_dir' \
                 ' from feed_data'
    if category != 'all':
        select_sql += f' where category = "{category}"' \
                      f' and title like "%{keyword}%"'
    else:
        select_sql += f' where title like "%{keyword}%"'
    if last_check_date != '':
        select_sql += f' and created_at > "{last_check_date}"'
    if download_flg:
        select_sql += ' and download_dir is Null'

    search_result = list(cur.execute(select_sql))
    conn.close()

    # ダウンロードしつつ、検索結果を配列へ
    hit_result = []
    link_values = []
    if len(search_result) > 0:
        for search_item in search_result:
            item_category = search_item[0]
            item_title = search_item[1]
            item_link = search_item[2]
            item_download_dir = search_item[3]
            if download_flg:
                hit_result.append([item_category, item_title, keyword, item_link])
                if not os.path.isdir(download_dir):
                    os.mkdir(download_dir)
                item_title = swiutil.truncate(item_title.translate(str.maketrans('/;!','___')), 247)
                try:
                    data = urllib.request.urlopen(item_link).read()
                except Exception as e:
                    print(e)
                else:
                    with open(f'{download_dir}/{item_title}.torrent', mode='wb') as file:
                        file.write(data)
                    link_values.append(item_link)
            else:
                hit_result.append([item_category, item_title, keyword, item_link, item_download_dir])

        # ダウンロード対象の更新
        if download_flg:
            conn = sqlite3.connect(FEED_DB)
            cur = conn.cursor()
            str_link_value = '", "'.join(link_values)
            update_sql = f'update feed_data set download_dir = "{download_dir}" where link in ("{str_link_value}")'
            cur.execute(update_sql)
            conn.commit()
            conn.close()

    return hit_result


# nyaa データベース検索(外部利用版)
def search_seed_ext(category, keyword):
    # 検索
    conn = sqlite3.connect(FEED_DB)
    cur = conn.cursor()
    select_sql = 'select category, title, link, download_dir' \
                 ' from feed_data'
    if category != 'all':
        select_sql += f' where category = "{category}"' \
                      f' and title like "%{keyword}%"'
    else:
        select_sql += f' where title like "%{keyword}%"'

    search_result = list(cur.execute(select_sql))
    conn.close()

    return search_result


if __name__ == '__main__':
    # 報告用日付
    tdatetime = dt.now()
    datetime_str = tdatetime.strftime('%Y/%m/%d %H:%M:%S')
    # ダウンロードディレクトリ
    date_str = tdatetime.strftime('%Y%m%d')
    download_dir = f'{DOWNLOAD_DIR_ROOT}/{date_str}'

    # 最終取得時刻
    with open(LAST_CHECK_DATE_FILE) as file:
        last_check_date = file.read().splitlines()[0]
    # 今回の取得時刻
    now_date = tdatetime.strftime('%Y-%m-%d %H:%M')

    # チェックリスト取得(カテゴリごとのキーワード配列)
    check_list = dict()
    with open(CHECKLIST_FILE) as file:
        for checkitem in list(file.read().splitlines()):
            check_category = checkitem.split('|')[0]
            if not check_category in check_list:
                check_list[check_category] = []

            check_keyword = checkitem.split('|')[1]
            check_list[check_category].append(check_keyword)

    hit_flag = False
    hit_result = []
    # チェックリストごとにカテゴリ、キーワードでキーワードリスト検索、ダウンロード
    for check_category in check_list:
        for check_keyword in check_list[check_category]:
            search_result = search_seed(True, check_category, check_keyword, last_check_date)
            if len(search_result) > 0:
                hit_result.extend(search_result)

    if len(hit_result) > 0:
        post_str = f'@here 【swirhen.tv 汎用種調査 {datetime_str}】キーワードヒット: ダウンロードしました\n```# 結果\n'
        for result_item in hit_result:
            post_str += f'カテゴリ: {result_item[0]} キーワード: {result_item[2]} タイトル: {result_item[1]}\n'

        post_str += f'# ダウンロードしたseedファイル ({download_dir})\n'
        for result_item in hit_result:
            post_str += f'{result_item[1]}.torrent\n'
        post_str += '```'

        # 報告
        swiutil.multi_post(SLACK_CHANNEL, post_str)

    # 最後に最終取得時刻を記録
    swiutil.writefile_new(LAST_CHECK_DATE_FILE, now_date)
