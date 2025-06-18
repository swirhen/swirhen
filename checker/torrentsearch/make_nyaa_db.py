#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# nyaatorrent make feed db
# import section
import pathlib
import sys
from datetime import datetime as dt
import urllib.request
import sqlite3
import xml.etree.ElementTree as elementTree
sys.path.append('/data/share/movie/sh/python-lib/')
import swirhentv_util as swiutil

# argment section
current_dir = pathlib.Path(__file__).resolve().parent
SCRIPT_DIR = str(current_dir)
URL_LIST_FILE = f'{SCRIPT_DIR}/urllist.txt'
FEED_DB = f'{SCRIPT_DIR}/nyaatorrent_feed.db'


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
    try:
        with urllib.request.urlopen(req) as response:
            xml_string = response.read()
    except Exception as e:
        print(e)
    else:
        xml_root = elementTree.fromstring(xml_string)

        for item in xml_root.findall('./channel/item'):
            seed_info = [category, item.find('title').text.translate(str.maketrans('"\'','__')), item.find('link').text, item.find('pubDate').text[:-6]]
            seed_list.append(seed_info)

    return seed_list


def make_nyaa_data(category='all'):
    # URLリストをループして、すべてのURLから最新フィードを取得
    # カテゴリ名,title,link,pubDateを配列に入れる
    all_seed_list = []
    with open(URL_LIST_FILE) as f:
        for line in list(f.read().splitlines()):
            cat = line.split()[0]
            url = line.split()[1]
            if category == 'all' or category == cat:
                seed_list = get_seed_list_proc(cat, url)
                all_seed_list.extend(seed_list)

    conn = sqlite3.connect(FEED_DB)
    cur = conn.cursor()
    # 参考SQL
    drop_table_sql = 'drop table if exists feed_data'
    create_table_sql = 'create table if not exists feed_data(' \
                        ' category string,' \
                        ' title string,' \
                        ' link string unique,' \
                        ' pubdate timestamp,' \
                        ' created_at timestamp default (datetime(\'now\', \'localtime\'))),' \
                        ' download_dir string'
    delete_record_sql = 'delete from feed_data where category'

    values = []
    for seed_item in all_seed_list:
        item_category = seed_item[0]
        item_title = seed_item[1]
        item_link = seed_item[2]
        item_pubdate =  dt.strptime(seed_item[3], '%a, %d %b %Y %H:%M:%S')
        if item_category == 'av' and swiutil.is_zh(item_title):
            continue
        else:
            values.append(f'("{item_category}", "{item_title}", "{item_link}", "{item_pubdate}")')

    values_str = ', '.join(values)
    insert_sql = 'insert into feed_data(category, title, link, pubdate)' \
                f' values{values_str}' \
                ' on conflict(link) do nothing'
    try:
        cur.execute(insert_sql)
    except Exception as e:
        swiutil.multi_post('torrent-search', f'@channel sql insert error: {e}')
    else:
        conn.commit()
    conn.close()


# main section
if __name__ == '__main__':
    args = sys.argv
    arg = ''
    if len(args) > 1:
        arg = args[1]

    if arg == '':
        make_nyaa_data()
    else:
        make_nyaa_data(arg)
