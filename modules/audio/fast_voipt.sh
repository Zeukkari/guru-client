#!/bin/bash
# phone bridge voip tunnel POC
# assuming /git/trx is place for trx stuff

# host variables
app_udb_port=1350
remote_tcp_port=10001
sender_address=127.0.0.1
sender_tcp_port=10000
# new ones
sender_device="default"
listener_device="default"

voipt.main () {
    voipt.arguments $@
    local function=$1 ; shift
    case $function in
            install|open|toggle|close|ls|help)
                        voipt.$function $@
                        return $? ;;
                    *)  [[ $verbose ]] && echo "unknown command $function"
                        return 1 ;;
        esac
}

voipt.arguments () {

    remote_ssh_port=22
    remote_user=$USER

    TEMP=`getopt --long -o "vh:u:p:d:" "$@"`
    eval set -- "$TEMP"
    while true ; do
        case "$1" in
            -v ) verbose=true        ; shift ;;
            -h ) remote_address=$2   ; shift 2 ;;
            -u ) remote_user=$2      ; shift 2 ;;
            -p ) remote_ssh_port=$2  ; shift 2 ;;
            -d ) sender_device=$2    ; shift 2 ;;
             * ) break
        esac
    done

    [[ $remote_address ]] || read -p "remote address: " remote_address

    # check message
    local _arg="$@"
    [[ "$_arg" != "--" ]] && _message="${_arg#* }"
}


voipt.open () {
    voipt.start_listener $listener_device || echo "start listener error $?"
    voipt.start_sender $sender_device || echo "start sender error $?"
}


voipt.close () {
    voipt.close_listener || echo "close sender error $?"
    voipt.close_sender || echo "close listener error $?"
}


voipt.close_listener () {
    ssh -p $remote_ssh_port $remote_user@$remote_address "pkill rx ; pkill socat"
}


voipt.close_sender () {
    #gnome-terminal --geometry=36x4 --hide-menubar --zoom=0.5 --
    pkill tx
    pkill socat
    local pid=$(ps aux | grep ssh | grep "$sender_tcp_port" | tr -s " " | cut -f2 -d " ")
    [[ $pid ]] && kill $pid
    return 0
}


voipt.start_listener () {
    # assuming listener is remote and sender is local
    local _device=$1
    gnome-terminal --geometry=36x4 --hide-menubar --zoom=0.5 -- \
        ssh -p $remote_ssh_port $remote_user@$remote_address \
        $HOME/git/trx/rx -d $_device -h $sender_address -p $app_udb_port

    gnome-terminal --geometry=36x4 --hide-menubar --zoom=0.5 -- \
        ssh -p $remote_ssh_port $remote_user@$remote_address \
        "pkill socat; socat tcp4-listen:$remote_tcp_port,reuseaddr,fork UDP:$sender_address:$app_udb_port"
    return 0
}


voipt.start_sender () {
    # set needed to send voip over ssh tunnel
    local _device=$1

    # open tunnel to listener
    gnome-terminal --geometry=36x4 --hide-menubar --zoom=0.5 -- \
        ssh -L $sender_tcp_port:$sender_address:$remote_tcp_port $remote_user@$remote_address -p $remote_ssh_port

    # wait tunnel to build up. TIP: is not work remotely, try to increase this
    sleep 3

    echo "device $_device"
    # open soumd device input and send voip to port listened by socat
    gnome-terminal --geometry=36x4 --hide-menubar --zoom=0.5 -- \
        /tmp/trx/tx -d $_device -h $sender_address -p $app_udb_port

    # stuff udp traffic to tcp port for tunneling
    gnome-terminal --geometry=36x4 --hide-menubar --zoom=0.5 -- \
        socat udp4-listen:$app_udb_port,reuseaddr,fork tcp:$sender_address:$sender_tcp_port
}


voipt.help () {
    echo  "voipt help "
    echo
    echo   "usage:    $GURU_CALL voipt [ls|open|close|help|install]"
    echo  "commands:"
    echo
    echo  " ls           list of active tunnels "
    echo  " open         open voip tunnel to host "
    echo  " close        close voip tunnel "
    echo  " install      install trx "
    echo  " help         this help "
    echo
    return 0
}


voipt.install () {
    # assume debian
    sudo apt-get install -y libasound2-dev libopus-dev libopus0 libortp-dev libopus-dev libortp-dev wireguard socat || return $?
    cd /tmp
    git clone http://www.pogo.org.uk/~mark/trx.git || return $?
    cd trx
    sed -i 's/ortp_set_log_level_mask(NULL, ORTP_WARNING|ORTP_ERROR);/ortp_set_log_level_mask(ORTP_WARNING|ORTP_ERROR);/g' tx.c
    make && [[ $verbose ]] && echo "success" || return $?
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        voipt.main $@
        exit $?
    fi

