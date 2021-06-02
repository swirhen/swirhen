#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# torrent file 汎用クロール
# リストに指定したキーワードでnyaaおよびsukebei.nyaaをクロールしたデータベースを検索し、ヒットしたらseedをダウンロードしておく
# import section
import os
import git
import pathlib
import sys
import urllib.request
from datetime import datetime as dt
current_dir = pathlib.Path(__file__).resolve().parent
sys.path.append('/data/share/movie/sh/python-lib/')
import swirhentv_util as swiutil
import sqlite3

# arguments section
GIT_ROOT_DIR = '/home/swirhen/sh'
SCRIPT_DIR = str(current_dir)
CHECKLIST_FILE = f'{SCRIPT_DIR}/checklist.txt'
URL_LIST_FILE = f'{SCRIPT_DIR}/urllist.txt'
DL_URL_LIST_FILE = f'{SCRIPT_DIR}/download_url.txt'
LAST_CHECK_DATE_FILE = f'{SCRIPT_DIR}/last_check_date.txt'
FEED_DB = f'{SCRIPT_DIR}/nyaatorrent_feed.db'
CONN = sqlite3.connect(FEED_DB)
CUR = CONN.cursor()
TDATETIME = dt.now()
DATETIME = TDATETIME.strftime('%Y/%m/%d %H:%M:%S')
DATE = TDATETIME.strftime('%Y%m%d')
DOWNLOAD_DIR = f'/data/share/temp/torrentsearch/{DATE}'
SLACK_CHANNEL = 'torrent-search'

# nyaa データベース検索
def search_seed_list(category, keyword, last_check_date=''):
    select_sql = 'select title, link' \
                 ' from feed_data f' \
                f' where category = "{category}"' \
                f' and title like "%{keyword}%"'
    if last_check_date != '':
        select_sql += f' and created_at > "{last_check_date}"'
    select_sql += ' and not exists' \
                 '(select link from download_url d where f.link = d.link)'

    print(select_sql)
    result = list(CUR.execute(select_sql))
    return result


if __name__ == '__main__':
    # 最終取得時刻
    with open(LAST_CHECK_DATE_FILE) as file:
        last_check_date = file.read().splitlines()[0]
    # 今回の取得時刻
    now_date = dt.now().strftime('%Y-%m-%d %H:%M')
    swiutil.writefile_new(LAST_CHECK_DATE_FILE, now_date)

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
    # カテゴリ、キーワードでキーワードリスト検索、URLリスト内に存在しない場合、ダウンロードしてリストに加える
    for check_category in check_list:
        for check_keyword in check_list[check_category]:
            search_result = search_seed_list(check_category, check_keyword, last_check_date)
            if len(search_result) > 0:
                for search_item in search_result:
                    item_title = search_item[0]
                    item_link = search_item[1]
                    if len(swiutil.grep_file2(DL_URL_LIST_FILE, item_link)) == 0:
                        hit_flag = True
                        if not os.path.isdir(DOWNLOAD_DIR):
                            os.mkdir(DOWNLOAD_DIR)
                        item_title = swiutil.truncate(item_title.translate(str.maketrans('/;!','___')), 247)
                        hit_result.append([check_category, item_title, check_keyword])
                        urllib.request.urlretrieve(item_link, f'{DOWNLOAD_DIR}/{item_title}.torrent')
                        swiutil.writefile_append(DL_URL_LIST_FILE, item_link)

    if hit_flag:
        post_str = f'@here 【swirhen.tv 汎用種調査 {DATETIME}】キーワードヒット: ダウンロードしました\n```# 結果\n'
        for result_item in hit_result:
            post_str += f'カテゴリ: {result_item[0]} キーワード: {result_item[2]} タイトル: {result_item[1]}\n'

        post_str += f'# ダウンロードしたseedファイル ({DOWNLOAD_DIR})\n'
        for result_item in hit_result:
            post_str += f'{result_item[1]}.torrent\n'

        post_str += '```'

        swiutil.multi_post(SLACK_CHANNEL, post_str)

        repo = git.Repo(GIT_ROOT_DIR)
        repo.git.commit(DL_URL_LIST_FILE, message='download_url.txt update')
        repo.git.pull()
        repo.git.push()
