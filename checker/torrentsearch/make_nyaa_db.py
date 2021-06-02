#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# nyaatorrent make feed db
# import section
import pathlib
import subprocess
import sys
import sqlite3
import swirhentv_util as swiutil

# argment section
current_dir = pathlib.Path(__file__).resolve().parent
SCRIPT_DIR = str(current_dir)
FEED_DB = f'{SCRIPT_DIR}/nyaatorrent_feed.db'


def make_feed_data(argument=''):
    # TODO いったんコミット
