#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# torrent file 汎用クロール
# リストに指定したキーワードでnyaaおよびsukebei.nyaaをクロールし、ヒットしたらseedをダウンロードしておく
# import section
import datetime
import pprint

import git
import glob
import math
import os
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
DL_URL_LIST_FILE = f'${SCRIPT_DIR}/download_url.txt'
TDATETIME = dt.now()
DATETIME = TDATETIME.strftime('%Y/%m/%d %H:%M:%S')
DATE = TDATETIME.strftime('%Y%m%d')
DOWNLOAD_DIR = f'/data/share/temp/torrentsearch/{DATE}'


# すべてのフィードリスト取得(ループ親)
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

# フィードリスト取得(URLから)
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
    hit_flag = 0
    check_list = []

    seedlist = get_seed_list()

    pprint.pprint(seedlist)
