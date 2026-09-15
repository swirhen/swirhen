#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# torrentsearch用の共通処理
# import section
import os
import re
import pathlib
from datetime import datetime as dt
import urllib.request
import sqlite3
import requests
import time
from zh_character_patterns import JAPANESE_PATTERN, SIMPLIFIED_CHINESE_PATTERN, TRADITIONAL_CHINESE_PATTERN

# arguments section
current_dir = pathlib.Path(__file__).resolve().parent
SCRIPT_DIR = str(current_dir)
DISCORD_WEBHOOK_URI_FILE = f'{SCRIPT_DIR}/discord_webhook_url'
FEED_DB = f'{SCRIPT_DIR}/nyaatorrent_feed.db'
DOWNLOAD_DIR_ROOT = '/data/share/temp/torrentsearch'
DOWNLOAD_TIMEOUT_SECONDS = 20
DOWNLOAD_RETRY_COUNT = 2
DOWNLOAD_RETRY_WAIT_SECONDS = 3
WINDOWS_RESERVED_FILENAMES = {
    'CON', 'PRN', 'AUX', 'NUL',
    'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
    'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
}


# discord channel decision
def get_discord_webhook_url(target_channel):
    result = ''
    with open(DISCORD_WEBHOOK_URI_FILE) as file:
        for line in file.read().splitlines():
            channel = line.split()[0]
            webhook_uri = line.split()[1]
            if channel == target_channel:
                result = webhook_uri
                break
    return result


# discordにpostする
def discord_post(channel, text):
    if len(text) > 2000:
        if text.split('\n')[0][0] == '@':
            discord_post(channel, text.split('\n')[0])
            text = re.sub('^.*\n', '', text)
        if re.search('```', text):
            text = text.replace('```', '')
        date_time = dt.now().strftime('%Y%m%d%H%M%S')
        post_file_temp = f'{SCRIPT_DIR}/discord_post_temp_{date_time}.txt'
        writefile_new(post_file_temp, text)
        discord_upload(channel, post_file_temp)
        os.remove(post_file_temp)
        return

    discord_webhook_uri = get_discord_webhook_url(channel)
    if discord_webhook_uri != '':
        main_content = {
            'content': text.replace('@channel', '@here')
        }
        try:
            requests.post(discord_webhook_uri, main_content)
        except Exception as e:
            print(e)


# discordにuploadする
def discord_upload(channel, filename):
    discord_webhook_uri = get_discord_webhook_url(channel)
    if discord_webhook_uri != '':
        with open(filename, 'rb') as file:
            files = {'param_name': (pathlib.Path(filename).name, file)}
            try:
                requests.post(discord_webhook_uri, files=files)
            except Exception as e:
                print(e)


# ファイル書き込み(新規)
def writefile_new(filepath, string):
    with open(filepath, 'w') as file:
        file.write(f'{string}\n')


# 文字列カット(指定バイト数より多い場合文字単位で削除)
def truncate(in_str, num_bytes, encoding='utf-8'):
    while len(in_str.encode(encoding)) > num_bytes:
        in_str = in_str[:-1]
    return in_str


# あまり厳密でない中国語判定処理
# ひらがな・カタカナを含む場合は日本語判定
# それ以外で、中国語にしかない漢字が検出されたら中国語判定
def is_zh(in_str):
    if re.search(JAPANESE_PATTERN, in_str):
        return False
    if re.search(SIMPLIFIED_CHINESE_PATTERN, in_str) or re.search(TRADITIONAL_CHINESE_PATTERN, in_str):
        return True
    else:
        return False


# ダウンロードファイル名の安全化(Windows禁止文字・制御文字を置換)
# 末尾の空白・ドットはWindowsで使用できないため除去
# ファイル名上限255 bytesから拡張子「.torrent」の8 bytesを除いた247 bytesに制限
def sanitize_filename(title, max_bytes=247):
    filename = re.sub(r'[<>:"/\\|?*\x00-\x1f]', '_', title).rstrip(' .')
    if not filename:
        filename = '_'
    if filename.split('.')[0].upper() in WINDOWS_RESERVED_FILENAMES:
        filename = f'_{filename}'
    return truncate(filename, max_bytes)


# 未ダウンロードの新着seedと、直近1時間に失敗したseedをカテゴリ単位で取得
def find_undownloaded_seeds(category, last_check_date):
    conditions = [
        'download_dir is null',
        '(created_at > ? and download_failed_at is null '
        "or download_failed_at > datetime('now', 'localtime', '-1 hour'))"
    ]
    parameters = [last_check_date]
    if category != 'all':
        conditions.append('category = ?')
        parameters.append(category)

    select_sql = 'select category, title, link, download_failed_at from feed_data where ' + ' and '.join(conditions)
    with sqlite3.connect(FEED_DB) as conn:
        return list(conn.execute(select_sql, parameters))


# チェックリスト順で最初に一致するキーワードを割り当てる
def find_keyword_matches(seeds, keywords, ignore_word_list):
    matches = []
    matched_links = set()
    for keyword in keywords:
        for category, title, link, download_failed_at in seeds:
            if link in matched_links or keyword not in title:
                continue
            if any(ignore_word in title for ignore_word in ignore_word_list):
                continue
            matches.append((category, title, keyword, link, download_failed_at is not None))
            matched_links.add(link)
    return matches


# seedファイルをダウンロードし、成功したものだけを返す
def download_torrent(link):
    for attempt in range(1, DOWNLOAD_RETRY_COUNT + 1):
        try:
            with urllib.request.urlopen(link, timeout=DOWNLOAD_TIMEOUT_SECONDS) as response:
                return response.read()
        except Exception as e:
            print(f'download failed ({attempt}/{DOWNLOAD_RETRY_COUNT}): {link}: {e}')
            if attempt < DOWNLOAD_RETRY_COUNT:
                time.sleep(DOWNLOAD_RETRY_WAIT_SECONDS)
    return None


def download_seeds(matches, download_dir):
    if not matches:
        return [], [], []

    os.makedirs(download_dir, exist_ok=True)
    downloaded_matches = []
    failed_new_links = []
    failed_retry_links = []
    for category, title, keyword, link, is_retry in matches:
        filename = sanitize_filename(title)
        data = download_torrent(link)
        if data is not None:
            with open(f'{download_dir}/{filename}.torrent', mode='wb') as file:
                file.write(data)
            downloaded_matches.append((category, title, keyword, link))
        elif is_retry:
            failed_retry_links.append(link)
        else:
            failed_new_links.append(link)
    return downloaded_matches, failed_new_links, failed_retry_links


# ダウンロード成功済みのseedをまとめて記録
def mark_downloaded(download_dir, links):
    update_sql = 'update feed_data set download_dir = ?, download_failed_at = null where link = ?'
    values = [(download_dir, link) for link in links]
    if values:
        with sqlite3.connect(FEED_DB) as conn:
            conn.executemany(update_sql, values)


# 初回失敗を記録し、次回のcron実行時に一度だけ再試行する
def mark_download_failed(links):
    update_sql = "update feed_data set download_failed_at = datetime('now', 'localtime') where link = ?"
    if links:
        with sqlite3.connect(FEED_DB) as conn:
            conn.executemany(update_sql, [(link,) for link in links])


# 再試行も失敗したseedは失敗記録を消し、以後の候補から除外する
def clear_download_failed(links):
    update_sql = 'update feed_data set download_failed_at = null where link = ?'
    if links:
        with sqlite3.connect(FEED_DB) as conn:
            conn.executemany(update_sql, [(link,) for link in links])


