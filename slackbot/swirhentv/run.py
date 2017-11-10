# -*- coding: utf-8 -*-
import os
from slackbot.bot import Bot


def main():
    pid = os.getpid()
    f = open(os.getcwd() + '/slackbot.pid', 'w')
    f.write(str(pid))
    f.close()
    bot = Bot()
    bot.run()
 
if __name__ == "__main__":
    main()
