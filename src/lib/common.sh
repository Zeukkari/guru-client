# guru client common "libraries"

msg() {
    #function for ouput messages and make log notifications. input "message string"
    [ "$1" ] || return 0
    printf "$@" >$GURU_ERROR_MSG
    [ $VERBOSE ] && printf "$@"

    if ! [ "$GURU_SYSTEM_STATUS"=="ready" ]; then return 0; fi
    if ! [ -f "$GURU_LOG" ]; then return 0; fi

    if [ $LOGGING ]; then
        printf "$@" |sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g' >>"$GURU_LOG"
    fi
}

export -f msg
source $GURU_BIN/lib/os.sh
source $GURU_BIN/lib/deco.sh
source $GURU_BIN/counter.sh

