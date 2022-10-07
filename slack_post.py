#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# slackへのpostするだけ
# import section
import sys
import pathlib
current_dir = pathlib.Path(__file__).resolve().parent
sys.path.append('/data/share/movie/sh/python-lib/')
import swirhentv_util as swiutil

# main section
if __name__ == '__main__':
    args = sys.argv
    if len(args) == 3:
        swiutil.slack_post(args[1], args[2])
    else:
        print('usage: python slack_post.py [channel] [text]')
