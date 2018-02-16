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
XPANES_TMP=${SCRIPT_DIR}/xptmp
SELECTMENU=0
MULTIPANEMODE=0
PING_LIST=${SCRIPT_DIR}/ping_list
TELNET_LIST=${SCRIPT_DIR}/telnet_list
NTP_LIST=${SCRIPT_DIR}/ntp_list
FTP_LIST=${SCRIPT_DIR}/ftp_list
LFTP_LIST=${SCRIPT_DIR}/lftp_list
DNS_LIST=${SCRIPT_DIR}/dns_list
PROXY_LIST=${SCRIPT_DIR}/proxy_list
LOG_LIST=${SCRIPT_DIR}/log_list
URL_LIST=${SCRIPT_DIR}/url_list
DIG_URL="mec-proxy.gslb.in.mec.co.jp"

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
    read -p "hit enter/q > " YESNO2
    case "${YESNO2}" in
        "" ) return 1;;
        q | Q ) return 0;;
        * ) echo "prease input enter or q."
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
    rm -f ${PING_LIST}
    rm -f ${TELNET_LIST}
    rm -f ${NTP_LIST}
    rm -f ${FTP_LIST}
    rm -f ${LFTP_LIST}
    rm -f ${DNS_LIST}
    rm -f ${PROXY_LIST}
    rm -f ${URL_LIST}
    rm -f ${LOG_LIST}
    while read IDENTIFIER SERVER PORT
    do
        if [ "${IDENTIFIER:0:1}" != "#" ]; then
            if [[ ${IDENTIFIER} =~ p ]]; then
                echo "${SERVER}" >> ${PING_LIST}
            fi
            if [[ ${IDENTIFIER} =~ t ]]; then
                echo "${SERVER} ${PORT}" >> ${TELNET_LIST}
            fi
            if [[ ${IDENTIFIER} =~ n ]]; then
                echo "${SERVER}" >> ${NTP_LIST}
            fi
            if [[ ${IDENTIFIER} =~ f ]]; then
                echo "${SERVER} ${PORT}" >> ${FTP_LIST}
            fi
            if [[ ${IDENTIFIER} =~ l ]]; then
                echo "${SERVER} ${PORT}" >> ${LFTP_LIST}
            fi
            if [[ ${IDENTIFIER} =~ d ]]; then
                echo "@${SERVER}" >> ${DNS_LIST}
            fi
            if [[ ${IDENTIFIER} =~ x ]]; then
                echo "${SERVER}:${PORT}" >> ${PROXY_LIST}
            fi
            if [[ ${IDENTIFIER} =~ g ]]; then
                echo "${SERVER}" >> ${LOG_LIST}
            fi
            if [[ ${IDENTIFIER} =~ u ]]; then
                echo "${SERVER}" >> ${URL_LIST}
            fi
        fi
    done < ${LIST_FILE}
}

# main menu
main_menu(){
    echo "*** main menu ***"
    echo "1: ping"
    echo "2: telnet"
    echo "3: ntpdate"
    echo "4: ftp"
    echo "5: lftp"
    echo "6: dns(dig)"
    echo "7: proxy"
    echo "8: tail log"
    echo "9: grep log"
    echo "q: quit"
    echo "please select operation."
    main_menu_i
}

# menu input
main_menu_i() {
    SELECTMENU=`plzinput`
    case "${SELECTMENU}" in
        1 ) test_main "ping" ${PING_LIST};;
        2 ) test_main "telnet" ${TELNET_LIST};;
        3 ) test_main "ntpdate" ${NTP_LIST} "-q";;
        4 ) test_main "ftp" ${FTP_LIST};;
#        5 ) test_main "lftp" ${LFTP_LIST};;
        5 ) uc;;
        6 ) test_main "dig" ${DNS_LIST} ${DIG_URL};;
        7 ) test_main "proxy" ${PROXY_LIST};;
        8 ) test_main "tail" ${LOG_LIST} "-f";;
        9 ) test_main "grep" ${LOG_LIST};;
        q ) end;;
        * ) echo "prease input 1-9 or q."
        main_menu_i
    esac
}

# under construction
uc() {
    clear
    echo "under construction."
    plzcontinue
}

# plz continue
plzcontinue() {
    echo "テストを継続しますか？ (enter で継続 / q で終了)"
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
    rm -f ${PING_LIST}
    rm -f ${TELNET_LIST}
    rm -f ${NTP_LIST}
    rm -f ${FTP_LIST}
    rm -f ${LFTP_LIST}
    rm -f ${DNS_LIST}
    rm -f ${PROXY_LIST}
    rm -f ${URL_LIST}
    rm -f ${LOG_LIST}
    rm -f ${XPANES_TMP}
    echo "end."
    exit 0
}

# test main logic
test_main() {
    TEST_CMD=$1
    SERVER_LIST_FILE=$2
    OPTION=$3

    SERVER_LIST=()
    while read SERVER
    do
        SERVER_LIST+=( "${SERVER}" )
    done < ${SERVER_LIST_FILE}

    clear
    echo "*** ${TEST_CMD} test ***"
    if [ "${TEST_CMD}" = "grep" ]; then
        echo "grep する語句を設定してください"
        OPTION=`plzinput`
        if [ "${OPTION}" != "" ]; then
            echo "grep wordを設定しました: ${OPTION}"
        else
            echo "grep word に空白は設定できません"
            test_main ${TEST_CMD} ${SERVER_LIST_FILE}
        fi
    fi

    echo ""
    echo "# ${TEST_CMD} server lists:"
    echo "--"

    cnt=0
    for SRV in "${SERVER_LIST[@]}"
    do
        echo "${cnt}: ${SRV}"
        (( cnt++ ))
    done
    (( cnt-- ))
    echo "--"
    echo "${TEST_CMD} 対象サーバーを選択してください(0 - ${cnt})."
    echo "複数に発行する場合は番号をスペースで続けて書いてください"
    echo "ex) 0 1 3 5"
    SRVS=`plzinput`
    rm -f ${XPANES_TMP}
    if [ ${MULTIPANEMODE} -eq 1 ]; then
        for SRV in ${SRVS}
        do
            if [ "${SERVER_LIST[${SRV}]}" != "" ]; then
                echo "${SERVER_LIST[${SRV}]}" >> ${XPANES_TMP}
            fi
        done
        echo "結果を確認したら Ctrl-Dでウインドウを閉じてください"
        sleep 1
        if [ "${TEST_CMD}" = "proxy" ]; then
            cat ${XPANES_TMP} | xpanes -c "echo \"proxy test to {}\"; curl -LI -x {} http://www.google.com/ -o /dev/null -w '%{http_code}\n' -s"
        else
            cat ${XPANES_TMP} | xpanes -c "${TEST_CMD} ${OPTION} {}"
        fi
    else
        for SRV in ${SRVS}
        do
            if [ "${SERVER_LIST[${SRV}]}" != "" ]; then
                echo ""
                echo "# ${TEST_CMD} test: to ${SERVER_LIST[${SRV}]}"
                if [ "${TEST_CMD}" = "proxy" ]; then
                    echo "curl -LI -x ${SERVER_LIST[${SRV}]} http://www.google.com/ -o /dev/null -w '%{http_code}\\n' -s"
                    curl -LI -x ${SERVER_LIST[${SRV}]} http://www.google.com/ -o /dev/null -w '%{http_code}\n' -s
                else
                    echo "${TEST_CMD} ${OPTION} \"${SERVER_LIST[${SRV}]}\""
                    ${TEST_CMD} ${OPTION} "${SERVER_LIST[${SRV}]}"
                fi
            fi
        done
    fi

    echo ""
    echo "テスト終了"
    echo ""

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