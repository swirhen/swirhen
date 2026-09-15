#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# import section
import argparse
import sqlite3
import torrent_search_common as tsc

FEED_DB = tsc.FEED_DB
TARGET_CATEGORY = 'av'


# 中国語と判定されたav seedを表示し、明示指定時のみ削除する
def process_zh_seeds(delete=False):
    select_sql = 'select title, link from feed_data where category = ?'
    with sqlite3.connect(FEED_DB) as conn:
        search_result = conn.execute(select_sql, (TARGET_CATEGORY,))
        zh_seeds = [(title, link) for title, link in search_result if tsc.is_zh(title)]
        if delete and zh_seeds:
            conn.executemany('delete from feed_data where link = ?', [(link,) for _, link in zh_seeds])
    return zh_seeds


# main section
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='中国語と判定されたav seedを表示または削除します。')
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--dry-run', action='store_true', help='削除せず対象titleを表示します。')
    mode.add_argument('--delete', action='store_true', help='対象seedを削除します。')
    args = parser.parse_args()

    zh_seeds = process_zh_seeds(delete=args.delete)
    mode_name = 'deleted' if args.delete else 'dry-run'
    print(f'mode: {mode_name}')
    print(f'category: {TARGET_CATEGORY}')
    print(f'count: {len(zh_seeds)}')
    for title, _ in zh_seeds:
        print(title)
