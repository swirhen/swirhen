#!/usr/bin/env bash
# �e��a�ʃe�X�g���[�e�B���e�B
# �@�\�\��
# ping
# telnet
# ntpdate
# dns(digg)
# proxy
# ���O�̃e�[��
# ���O��grep
# �ΏۃT�[�o�[��|�[�g�͕ʃt�@�C���Ń��X�g�����Đ���[Enter]�őI���o����悤�ɂ���
# �e�푽�issh���瓯�l�̃e�X�g���ł���(���issh�̏���ʂɎ����͌���)
# option: tmux & tmux-xpanes�������Ă���΃}���`�y�C�����œ����\��

# �O���[�o���ϐ�
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
                echo "tmux �̋N�����Z�b�V������������܂���B�}���`�y�C�����[�h��L���ɂ���ɂ́Atmux�̃Z�b�V�����ォ�炱�̃V�F�����N�����Ă�������"
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
    echo "�e�X�g���p�����܂����H (enter �Ōp�� / q �ŏI��)"
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
        echo "grep �������ݒ肵�Ă�������"
        OPTION=`plzinput`
        if [ "${OPTION}" != "" ]; then
            echo "grep word��ݒ肵�܂���: ${OPTION}"
        else
            echo "grep word �ɋ󔒂͐ݒ�ł��܂���"
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
    echo "${TEST_CMD} �ΏۃT�[�o�[��I�����Ă�������(0 - ${cnt})."
    echo "�����ɔ��s����ꍇ�͔ԍ����X�y�[�X�ő����ď����Ă�������"
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
        echo "���ʂ��m�F������ Ctrl-D�ŃE�C���h�E����Ă�������"
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
    echo "�e�X�g�I��"
    echo ""

    plzcontinue
}

# main section
clear
echo "�e�X�g���[�e�B���e�B:"
echo "������x�̃^�[�~�i���𑜓x�Ŏg�p���Ă�������"
echo ""

# ���X�g�t�@�C���ǂݍ���
readlist

# tmux xpanes���݃`�F�b�N
tmuxcheck

# main menu
main_menu