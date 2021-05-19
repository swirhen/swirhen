#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# torrent file 汎用クロール
# リストに指定したキーワードでnyaaおよびsukebei.nyaaをクロールし、ヒットしたらseedをダウンロードしておく
# import section
import os
import git
import pathlib
import re
import sys
import urllib.request
from datetime import datetime as dt
import xml.etree.ElementTree as elementTree
current_dir = pathlib.Path(__file__).resolve().parent
sys.path.append('/data/share/movie/sh/python-lib/')
import swirhentv_util as swiutil

# argments section
GIT_ROOT_DIR = '/home/swirhen/sh'
SCRIPT_DIR = str(current_dir)
CHECKLIST_FILE = f'{SCRIPT_DIR}/checklist.txt'
URL_LIST_FILE = f'{SCRIPT_DIR}/urllist.txt'
DL_URL_LIST_FILE = f'{SCRIPT_DIR}/download_url.txt'
TDATETIME = dt.now()
DATETIME = TDATETIME.strftime('%Y/%m/%d %H:%M:%S')
DATE = TDATETIME.strftime('%Y%m%d')
DOWNLOAD_DIR = f'/data/share/temp/torrentsearch/{DATE}'
SLACK_CHANNEL = 'torrent-search'

# すべてのフィード取得(ループ親)
def get_seed_list(category='all'):
    # URLリストをループして、すべてのURLから最新フィードを取得
    # カテゴリ名,title,linkを配列に入れる
    all_seed_list = []
    with open(URL_LIST_FILE) as f:
        for line in list(f.read().splitlines()):
            cat = line.split()[0]
            url = line.split()[1]
            if category == 'all' or category == cat:
                seed_list = get_seed_list_proc(cat, url)
                all_seed_list.extend(seed_list)

    return all_seed_list

# フィード取得(URLから)
def get_seed_list_proc(category, feed_uri):
    seed_list = []
    req = urllib.request.Request(feed_uri)
    with urllib.request.urlopen(req) as response:
        xml_string = response.read()

    xml_root = elementTree.fromstring(xml_string)

    for item in xml_root.findall('./channel/item'):
        seed_info = [category, item.find('title').text, item.find('link').text]
        seed_list.append(seed_info)

    return seed_list


if __name__ == '__main__':
    # フィード取得
    seedlist = get_seed_list()

    # チェックリスト取得
    check_list = dict()
    with open(CHECKLIST_FILE) as file:
        for checkitem in list(file.read().splitlines()):
            check_category = checkitem.split('|')[0]
            if not check_category in check_list:
                check_list[check_category] = []

            check_keyword = checkitem.split('|')[1]
            check_list[check_category].append(check_keyword)

    hit_flag = 0
    hit_result = []
    # カテゴリでキーワードリスト検索、キーワードと一致、URLリスト内に存在しない場合、ダウンロードしてリストに加える
    for seed_item in seedlist:
        item_category = seed_item[0]
        item_title = seed_item[1]
        item_link = seed_item[2]

        for check_keyword in check_list[item_category]:
            if re.search(check_keyword, item_title) and \
                len(swiutil.grep_file(DL_URL_LIST_FILE, item_link)) == 0:
                hit_flag = 1
                if not os.path.isdir(DOWNLOAD_DIR):
                    os.mkdir(DOWNLOAD_DIR)
                item_title = item_title.translate(str.maketrans('/;!','___'))
                hit_result.append([item_category, item_title, check_keyword])
                urllib.request.urlretrieve(item_link, f'{DOWNLOAD_DIR}/{item_title}.torrent')
                swiutil.writefile_append(DL_URL_LIST_FILE, item_link)

    if hit_flag == 1:
        post_str = f'@here 【swirhen.tv 汎用種調査 {DATETIME}】キーワードヒット: ダウンロードしました\n```# 結果\n'
        for result_item in hit_result:
            post_str += f'カテゴリ: {result_item[0]} キーワード: {result_item[2]} タイトル: {result_item[1]}\n'

        post_str += f'# ダウンロードしたseedファイル ({DOWNLOAD_DIR})\n'
        for result_item in hit_result:
            post_str += f'{result_item[1]}.torrent\n'

        post_str += '```'

        swiutil.slack_post(SLACK_CHANNEL, post_str)

        repo = git.Repo(GIT_ROOT_DIR)
        repo.git.commit(DL_URL_LIST_FILE, message='download_url.txt update')
        repo.git.pull()
        repo.git.push()
