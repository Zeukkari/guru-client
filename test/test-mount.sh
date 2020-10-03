# don't run, let teset.sh handle shit
# guru toolkit mount tester

source $GURU_BIN/mount.sh         # TODO: meaby double not sure, check later

mount.test () {
    mount.system
    local test_case="$1"
    local _err=("$0")
    case "$test_case" in
               1) mount.check               ; return $? ;;  # 1) quick check
               2) mount.test_list           ; return $? ;;  # 2) list of stuff
               3) mount.test_info           ; return $? ;;  # 3) information
               4) mount.test_mount          ; return $? ;;  # 4) out of system action
               5) mount.test_unmount        ; return $? ;;  # 5) return
               6) mount.test_default_mount  ; return $? ;;  # 6) touch hot files
               7) mount.test_known_remote   ; return $? ;;  # 7) return
           clean) mount.clean_test          ; return $? ;;  # make clean
     release|all) mount.check        || _err=("${_err[@]}" "21")  # 1) quick check
                  mount.test_list           || _err=("${_err[@]}" "22")  # 2) list of stuff
                  mount.test_info           || _err=("${_err[@]}" "23")  # 3) information
                  mount.test_mount          || _err=("${_err[@]}" "24")  # 4) out of system action
                  mount.test_unmount        || _err=("${_err[@]}" "25")  # 5) return
                  mount.test_default_mount  || _err=("${_err[@]}" "26")  # 5) return
                  mount.test_known_remote   || _err=("${_err[@]}" "27")  # 7) return
                  mount.clean_test          || _err=("${_err[@]}" "29")  # make clean
                  if [[ ${_err[1]} -gt 0 ]]; then echo "error: ${_err[@]}"; return ${_err[1]}; else return 0; fi ;;
               *) msg "test case '$test_case' not written\n"
                  return 1
    esac
}


mount.clean_test () {
    local error=0

    if unmount.defaults ; then
            PASSED "${FUNCNAME[0]} unmount"
            error=0
        else
            FAILED "${FUNCNAME[0]} unmount"
            error=10
        fi

    if mount.defaults ; then
            PASSED "${FUNCNAME[0]} mount"
            error=$((error))
        else
            FAILED "${FUNCNAME[0]} mount"
             error=21
        fi
    if ((_error>9)) ; then return 28 ; fi
    return 0
}


mount.test_mount () {

    if mount.remote "/home/$GURU_USER_NAME/usr/test" "$HOME/tmp/test_mount" ; then
            PASSED "${FUNCNAME[0]}"
            return 0
        else
            FAILED "${FUNCNAME[0]}"
            return 22
        fi
}


mount.test_unmount () {
    local _mount_point="$HOME/tmp/test_mount"

    if unmount.remote "$_mount_point" ; then
            PASSED "${FUNCNAME[0]}"
            rm -rf "$H_mount_point" || WARNING "error when removing $_mount_point "
            return 0
        else
            FAILED "${FUNCNAME[0]}"
            return 23
        fi
}


mount.test_default_mount (){
    local _err=0

    msg "file server default folder mount \n"       # to test online ignore
    if mount.defaults ; then
            PASSED "${FUNCNAME[0]} mount"
            _err=0
        else
            FAILED "${FUNCNAME[0]} mount"
            _err=$((_err+10))
        fi
    sleep 1

    msg "un-mount defaults \n"                      # to test unmount
    if unmount.defaults ; then
            PASSED "${FUNCNAME[0]} unmount"
            _err=$_err
        else
            FAILED "${FUNCNAME[0]} unmount"
            _err=$((_err+10))
        fi
    sleep 1

    msg "re-mount defaults \n"                      # to test re-mount
    if mount.defaults ; then
            PASSED "${FUNCNAME[0]} mount"
            _err=$_err
        else
            FAILED "${FUNCNAME[0]} mount"
            _err=$((_err+10))
        fi

    if ((_err>9)) ; then return 29 ; fi
    return 0
}


mount.test_known_remote () {
    # Test that
    local _err=("$0")
    unmount.known_remote audio ; _err=("${_err[@]}" "$?")
    mount.known_remote audio ;   _err=("${_err[@]}" "$?")        # Second error in list is to validate result

    if [[ ${_err[2]} -gt 0 ]]; then
            echo "error: ${_err[@]}"
            FAILED "${FUNCNAME[0]}"
            return ${_err[2]};                                 # Return error
        else
            PASSED "${FUNCNAME[0]}"
            return 0
        fi
}


mount.test_list () {
    msg "sshfs list check: "
    mount.system || return 24                       # be sure that system is mounted

   if mount.list | grep "/.data" >/dev/null; then             # if "Track" is in output pass
        PASSED "${FUNCNAME[0]}"
        return 0
    else
        FAILED "${FUNCNAME[0]}"
        return 24
    fi
}


mount.test_info () {
    msg "sshfs list check: "
    mount.system || return 25                       # be sure that system is mounted

    if mount.info | grep "$GURU_SYSTEM_MOUNT" >/dev/null ; then      # if "Track" is in output pass
        PASSED "${FUNCNAME[0]}"
        return 0
    else
        FAILED "${FUNCNAME[0]}"
        return 25
    fi
}
