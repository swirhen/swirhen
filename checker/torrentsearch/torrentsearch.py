#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# torrent file 汎用クロール
# リストに指定したキーワードでnyaaおよびsukebei.nyaaをクロールし、ヒットしたらseedをダウンロードしておく
# import section
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
def get_seed_list():
    # URLリストをループして、すべてのURLから最新フィードを取得
    # カテゴリ名,title,linkを配列に入れる
    all_seed_list = []
    for line in list(open(URL_LIST_FILE).read().splitlines()):
        cat = line.split()[0]
        url = line.split()[1]
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
    check_list = []
    for checkitem in list(open(CHECKLIST_FILE).read().splitlines()):
        check_category = checkitem.split('|')[0]
        check_keyword = checkitem.split('|')[1]
        check_list.append([check_category, check_keyword])

    hit_flag = 0
    hit_result = []
    # カテゴリと一致、キーワードと一致、URLリスト内に存在しない場合、ダウンロードしてリストに加える
    for seed_item in seedlist:
        item_category = seed_item[0]
        item_title = seed_item[1]
        item_link = seed_item[2]

        for check_item in check_list:
            check_category = check_item[0]
            check_keyword = check_item[1]
            if item_category == check_category and \
                re.search(check_keyword, item_title) and \
                swiutil.grep_file(DL_URL_LIST_FILE, item_link) == '':
                hit_flag = 1
                hit_result.append([item_category, item_title, check_keyword])
                urllib.request.urlretrieve(item_link, f'{DOWNLOAD_DIR}/{item_title}.torrent')
                swiutil.writefile_append(DL_URL_LIST_FILE, item_link)

    if hit_flag == 1:
        post_str = f'@here 【swirhen.tv 汎用種調査 {DATETIME}】キーワードヒット: ダウンロードしました\n```# 結果\n'
        for result_item in hit_result:
            post_str += f'カテゴリ: {result_item[0]} キーワード: {result_item[2]} タイトル: {result_item[1]}\n'

        post_str += '# ダウンロードしたseedファイル\n'
        for result_item in hit_result:
            post_str += f'{result_item[1]}.torrent\n'

        swiutil.slack_post(SLACK_CHANNEL, post_str)

        repo = git.Repo(SCRIPT_DIR)
        repo.git.commit(CHECKLIST_FILE, message='checklist.txt update')
        repo.git.commit(DL_URL_LIST_FILE, message='download_url.txt update')
        repo.git.pull()
        repo.git.push()

