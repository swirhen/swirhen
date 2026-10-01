#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# import section
import sys,re,pathlib,sqlite3
import urllib.request
from bs4 import BeautifulSoup
current_dir = pathlib.Path(__file__).resolve().parent
sys.path.append(str(current_dir / 'python-lib'))
import torrent_search_common as ts

WINDOWS_RESERVED_FILENAMES = {
    'CON', 'PRN', 'AUX', 'NUL',
    'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
    'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
}
FEED_DB = '/home/swirhen/sh/checker/torrentsearch/nyaatorrent_feed.db'


# 文字列カット(指定バイト数より多い場合文字単位で削除)
def truncate(in_str, num_bytes, encoding='utf-8'):
    while len(in_str.encode(encoding)) > num_bytes:
        in_str = in_str[:-1]
    return in_str


# フォルダ名の安全化(Windows禁止文字・制御文字を置換)
# 末尾の空白・ドットはWindowsで使用できないため除去
# ファイル名上限255 bytesに制限
def sanitize_filename(title, max_bytes=255):
    filename = re.sub(r'[<>:"/\\|?*\x00-\x1f]', '_', title).rstrip(' .')
    if not filename:
        filename = '_'
    if filename.split('.')[0].upper() in WINDOWS_RESERVED_FILENAMES:
        filename = f'_{filename}'
    return truncate(filename, max_bytes)


# fantiaのタイトル取得(入れたキーワードは頭につけて「 - 」で連結して返す)
def get_fantia_title(keyword, regexp='\<.*?\>|\ -.*|【.*?】', uri='https://fantia.jp/posts/'):
    id = re.sub(r'\D', '', keyword)
    if id and int(id) <= 3000000:
        uri = 'https://fantia.jp/products/'
    try:
        html = urllib.request.urlopen(uri + id)
    except Exception as e:
        return 'NORESULTSFOUND'
    soup = BeautifulSoup(html, "html.parser")
    title = re.sub(regexp, '', str(soup.find('title'))).strip()
    rtitle = keyword + " - " + title
    ret = sanitize_filename(rtitle)
    return ret


# avのタイトル取得(sukebeiのDBからとる)
def get_av_title(keyword, regexp='\+\+\+|\[.*?\]', cut=True):
    result = ts.search_seed_ext('av', keyword)
    
    if len(result) == 0:
        return 'NORESULTSFOUND'
    else:
        title = result[0][1]
        title = re.sub(regexp, '', title).strip()
        if cut:
            ret = sanitize_filename(title)
        else:
            if len(title.encode('utf-8')) > 255:
                title = title + '### ' + str(len(title.encode('utf-8'))) + 'bytes'
            ret = title
    return ret


# nyaa データベース検索
def search_seed_ext(category, keyword):
    with sqlite3.connect(FEED_DB) as conn:
        cur = conn.cursor()
        select_sql = 'select category, title, link, download_dir' \
                     ' from feed_data'
        if category != 'all':
            select_sql += f' where category = "{category}"' \
                          f' and title like "%{keyword}%"'
        else:
            select_sql += f' where title like "%{keyword}%"'
        return list(cur.execute(select_sql))


# main section
if __name__ == '__main__':
    args = sys.argv
    mode = args[1]
    keyword = args[2]
    uri = None
    regexp = None
    ret = None
    if len(args) > 3:
        regexp = args[3]
        if regexp == '':
            if mode == 'f':
                regexp = '\<.*?\>|\ -.*|【.*?】'
            elif mode == 'a':
                regexp = '\+\+\+|\[.*?\]'
    if len(args) > 4:
        uri = args[4]
    
    if mode == 'f':
        if len(args) == 4:
            ret = get_fantia_title(keyword, regexp)
        elif len(args) == 5:
            ret = get_fantia_title(keyword, regexp, uri)
        else:
            ret = get_fantia_title(keyword)
    elif mode == 'a':
        if len(args) == 4:
            ret = get_av_title(keyword, regexp)
        elif len(args) == 5:
            ret = get_av_title(keyword, regexp, False)
        else:
            ret = get_av_title(keyword)

    if ret is not None:
        print(ret)

