# -*- coding: utf-8 -*-
# slackモジュール(snippet)
# tokenが @swirhentv のものなので、プライベートグループへの発言は @swirhentv がchannnelにjoinしている必要あり
# 第1引数：発言チャンネル
# 第2引数：ファイル名
# 第3引数：ファイルタイトル
# 第4引数：ファイルタイプ(省略時plain text)
# ファイルタイプ例: https://api.slack.com/types/file#file_types

from slacker import Slacker
import sys
import slackbot_settings


def usage():
    print ('usage: ', args[0], '[post_channel] [file_name] [file_title] (filetype)')
    sys.exit(1)

if __name__ == '__main__':
    args = sys.argv

    if len(args) < 3:
        usage()

    channel = args[1]
    filename = args[2]
    filetitle = args[3]

    if len(args) > 4:
        filetype = args[4]
    else:
        filetype = 'text'

    slack = Slacker(slackbot_settings.API_TOKEN)
    slack.files.upload(
        filename,
        filename=filetitle,
        filetype=filetype,
        channels=channel,
        )

