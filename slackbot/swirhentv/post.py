# -*- coding: utf-8 -*-
# slack発言モジュール
# tokenが @swirhentv のものなので、プライベートグループへの発言は @swirhentv がchannnelにjoinしている必要あり
# 第1引数：発言チャンネル
# 第2引数：発言内容
# 第3引数：ユーザ名(省略可)
# 第4引数：アイコン画像のid(省略可)
# アイコン画像IDの例：http://www.webpagefx.com/tools/emoji-cheat-sheet/

from slacker import Slacker
import sys
import slackbot_settings

def usage():
    print ('usage: ', args[0], '[post_channel] [post_text] (username) (icon_emoji)')
    sys.exit(1)

if __name__ == '__main__':
    args = sys.argv

    if len(args) < 3:
        usage()

    channel = args[1]
    text = args[2]

    if len(args) >= 4:
        username = args[3]
    else:
        username = "swirhentv"

    if len(args) >= 5:
        icon_emoji = args[4]
    else:
        icon_emoji = ""

    slack = Slacker(slackbot_settings.API_TOKEN)
    slack.chat.post_message(
        channel,
        text,
        username=username,
        icon_emoji=icon_emoji,
        link_names=1,
        )

