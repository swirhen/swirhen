#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# torrent file 汎用クロール
# リストに指定したキーワードでnyaaおよびsukebei.nyaaをクロールしたデータベースを検索し、ヒットしたらseedをダウンロードしておく
# import section
import pathlib
import sys
from datetime import datetime as dt
current_dir = pathlib.Path(__file__).resolve().parent
sys.path.append(str(current_dir))
import torrent_search_common as tsc

# arguments section
GIT_ROOT_DIR = '/home/swirhen/sh'
SCRIPT_DIR = str(current_dir)
CHECKLIST_FILE = f'{SCRIPT_DIR}/checklist.txt'
IGNOREWORD_LIST_FILE = f'{SCRIPT_DIR}/igword.txt'
LAST_CHECK_DATE_FILE = f'{SCRIPT_DIR}/last_check_date.txt'
SLACK_CHANNEL = 'torrent-search'


if __name__ == '__main__':
    # 報告用日付
    tdatetime = dt.now()
    datetime_str = tdatetime.strftime('%Y/%m/%d %H:%M:%S')
    # ダウンロードディレクトリ
    date_str = tdatetime.strftime('%Y%m%d')
    download_dir = f'{tsc.DOWNLOAD_DIR_ROOT}/{date_str}'

    # 最終取得時刻
    with open(LAST_CHECK_DATE_FILE) as file:
        last_check_date = file.read().splitlines()[0]
    # 今回の取得時刻
    now_date = tdatetime.strftime('%Y-%m-%d %H:%M')

    # 無視ワードリスト取得(1行1ワード)
    ignore_word_list = []
    with open(IGNOREWORD_LIST_FILE) as file:
        ignore_word_list = file.read().splitlines()

    # チェックリスト取得(カテゴリごとのキーワード配列)
    check_list = {}
    with open(CHECKLIST_FILE) as file:
        for checkitem in file.read().splitlines():
            check_category, check_keyword = checkitem.split('|', 1)
            check_list.setdefault(check_category, []).append(check_keyword)

    hit_result = []
    # カテゴリ単位で新着seedを取得し、チェックリスト順にキーワードを割り当てる
    for check_category, keywords in check_list.items():
        seeds = tsc.find_undownloaded_seeds(check_category, last_check_date)
        matches = tsc.find_keyword_matches(seeds, keywords, ignore_word_list)
        downloaded_matches, failed_new_links, failed_retry_links = tsc.download_seeds(matches, download_dir)
        tsc.mark_downloaded(download_dir, [match[3] for match in downloaded_matches])
        tsc.mark_download_failed(failed_new_links)
        tsc.clear_download_failed(failed_retry_links)
        hit_result.extend(downloaded_matches)

    if hit_result:
        post_str = f'@here 【swirhen.tv 汎用種調査 {datetime_str}】キーワードヒット: ダウンロードしました\n```# 結果\n'
        for result_item in hit_result:
            post_str += f'カテゴリ: {result_item[0]} キーワード: {result_item[2]} タイトル: {result_item[1]}\n'

        post_str += f'# ダウンロードしたseedファイル ({download_dir})\n'
        for result_item in hit_result:
            post_str += f'{result_item[1]}.torrent\n'
        post_str += '```'

        # 報告
        tsc.discord_post(SLACK_CHANNEL, post_str)

    # 最後に最終取得時刻を記録
    tsc.writefile_new(LAST_CHECK_DATE_FILE, now_date)
