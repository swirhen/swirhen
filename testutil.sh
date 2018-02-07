#!/usr/bin/env bash
# 各種疎通テストユーティリティ
# 機能予定
# ping
# telnet
# ntpdate
# dns(digg)
# proxy
# ログのテール
# ログのgrep
# 対象サーバーやポートは別ファイルでリスト化して数字[Enter]で選択出来るようにする
# 各種多段sshから同様のテストができる(多段sshの情報を別に持つかは検討)
# option: tmux & tmux-xpanesが入っていればマルチペイン化で同時表示

# グローバル変数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"
LIST_FILE=${SCRIPT_DIR}/serverlist.txt
SELECTMENU=0
MULTIPANEMODE=0
PING_LIST=()
TELNET_LIST=()
NTP_LIST=()
FTP_LIST=()
LFTP_LIST=()
DNS_LIST=()
PROXY_LIST=()
LOG_LIST=()

# yes/no
yesno() {
    read -p " (Y/N)? > " YESNO
    case "${YESNO}" in
        y | Y ) return 1;;
        n | N ) return 0;;
        * ) echo "prease input Y/N(y/n)."
        yesno
    esac
}

# yes/no 2
yesno2() {
    read -p "hit enter(Y)/N > " YESNO2
    case "${YESNO2}" in
        y | Y | "" ) return 1;;
        n | N ) return 0;;
        * ) echo "prease input enter or enter or Y/N(y/n)."
        yesno2
    esac
}

# hit enter key
plzenter() {
    read -p "hit enter key."
}

# please input
plzinput() {
    read -p "> " INPUT
    echo "${INPUT}"
}

# main menu
main_menu(){
    echo "*** main menu ***"
    echo "1: ping"
    echo "2: telnet"
    echo "3: ntpdate"
    echo "4: ftp"
    echo "5: lftp"
    echo "6: dns test"
    echo "7: proxy test"
    echo "8: tail log"
    echo "9: grep log"
    echo "q: quit"
    echo "please select operation."
    main_menu_i
}

# tmux / xpanes install check
tmuxcheck() {
    if [ "`tmux -V 2>/dev/null`" != "" -a "`xpanes -V 2>/dev/null`" != "" ]; then
        echo "terminal multiplexer(tmux) and xpanes detected."
        echo "enable multi-pane mode?"
        yesno
        if [ $? -eq 1 ]; then
            if [ "`tmux ls 2>/dev/null`" = "" ]; then
                echo "tmux の起動中セッションが見つかりません。マルチペインモードを有効にするには、tmuxのセッション上からこのシェルを起動してください"
                end
            else
                MULTIPANEMODE=1
            fi
        else
            MULTIPANEMODE=0
        fi
    fi
}

# read list file
readlist () {
    while read IDENTIFIER SERVER PORT
    do
        if [ "${IDENTIFIER:0:1}" != "#" ]; then
            if [[ ${IDENTIFIER} =~ p ]]; then
                PING_LIST+=( "${SERVER}" )
            fi
            if [[ ${IDENTIFIER} =~ t ]]; then
                TELNET_LIST+=( "${SERVER} ${PORT}" )
            fi
            if [[ ${IDENTIFIER} =~ n ]]; then
                NTP_LIST+=( "${SERVER}" )
            fi
            if [[ ${IDENTIFIER} =~ f ]]; then
                FTP_LIST+=( "${SERVER} ${PORT}" )
            fi
            if [[ ${IDENTIFIER} =~ l ]]; then
                LFTP_LIST+=( "${SERVER} ${PORT}" )
            fi
            if [[ ${IDENTIFIER} =~ d ]]; then
                DNS_LIST+=( "${SERVER}" )
            fi
            if [[ ${IDENTIFIER} =~ x ]]; then
                PROXY_LIST+=( "${SERVER}:${PORT}" )
            fi
            if [[ ${IDENTIFIER} =~ g ]]; then
                LOG_LIST+=( "${SERVER}" )
            fi
        fi
    done < ${LIST_FILE}
}

# menu input
main_menu_i() {
    SELECTMENU=`plzinput`
    case "${SELECTMENU}" in
        1 ) ping_test;;
        2 ) telnet_test;;
        3 ) ntpdate_test;;
        4 ) ftp_test;;
        5 ) lftp_test;;
        6 ) dns_test;;
        7 ) proxy_test;;
        8 ) tail_log;;
        9 ) grep_log;;
        q ) end;;
        * ) echo "prease input 1-9 or q."
        main_menu_i
    esac
}

# plz continue
plzcontinue() {
    echo "テストを継続しますか？ (enterかY で継続 / N で終了)"
    yesno2
    if [ "$?" -eq 1 ]; then
        clear
        main_menu
    else
        end
    fi
}

# end
end() {
    echo "end."
    exit 0
}

# ping test
ping_test () {
    clear
    echo "*** ${FUNCNAME[0]/_/ } ***"
    echo ""
    echo "# ping server lists:"
    cnt=1
    for PINGSRV in "${PING_LIST[@]}"
    do
        echo "${PINGSRV}"
        (( cnt++ ))
    done
    echo "pingを発行するサーバーを選択してください(1 - ${#PING_LIST[@]})."
    echo "複数に発行する場合は番号を続けて書いてください"
    echo "ex) 12357"
    PINGSRVS=`plzinput`
    for PINGSRV in `echo "${PINGSRVS}" | fold -s1`
    do
        PINGSRVS2+="\"${PING_LIST[${PINGSRV}]}\" "
        if [ ${MULTIPANEMODE} -eq 0 ]; then
            ping -c 3 -W 1 "${PING_LIST[${PINGSRV}]}"
        fi
    done
    if [ ${MULTIPANEMODE} -eq 1 ]; then
#        xpanes -c "ping -c 3 -W 1 {}" "${PINGSRVS2}"
        echo "xpanes -c \"ping -c 3 -W 1 {}\" \"${PINGSRVS2}\""
    fi
    plzcontinue
}

# telnet test
telnet_test () {
    clear
    echo "*** ${FUNCNAME[0]/_/ } ***"
    echo ""
    echo "under construction."
    plzcontinue
}

# ntpdate test
ntpdate_test () {
    clear
    echo "*** ${FUNCNAME[0]/_/ } ***"
    echo ""
    echo "under construction."
    plzcontinue
}

# dns test
dns_test () {
    clear
    echo "*** ${FUNCNAME[0]/_/ } ***"
    echo ""
    echo "under construction."
    plzcontinue
}

# proxy test
proxy_test () {
    clear
    echo "*** ${FUNCNAME[0]/_/ } ***"
    echo ""
    echo "under construction."
    plzcontinue
}

# tail log
tail_log () {
    clear
    echo "*** ${FUNCNAME[0]/_/ } ***"
    echo ""
    echo "under construction."
    plzcontinue
}

# grep log
grep_log () {
    clear
    echo "*** ${FUNCNAME[0]/_/ } ***"
    echo ""
    echo "under construction."
    plzcontinue
}

# ftp test
ftp_test() {
    clear
    echo "*** ${FUNCNAME[0]/_/ } ***"
    echo ""
    echo "under construction."
    plzcontinue
}

# lftp test
lftp_test() {
    clear
    echo "*** ${FUNCNAME[0]/_/ } ***"
    echo ""
    echo "under construction."
    plzcontinue
}

# main section
clear
echo "テストユーティリティ:"
echo "ある程度のターミナル解像度で使用してください"
echo ""

# リストファイル読み込み
readlist

# tmux xpanes存在チェック
tmuxcheck

# main menu
main_menu