#!/bin/bash
source $GURU_BIN/keyboard.sh

## TODO total bullshit, rewrite all!
uninstall.main () {

    command="$1" ; shift
    case "$command" in
        config) uninstall.remove "$@" ; [[ $HOME/.config/guru ]] && rm -rf $HOME/.config/guru ;;
          help) echo "usage:    $GURU_CALL uninstall [config|help]" ;;
        status) echo TBD ;;
             *) uninstall.remove "$@"
                exit "$?"
    esac
}

## TODO total bullshit, rewrite all!
uninstall.remove () {

    if [ ! -f "$HOME/.bashrc.giobackup" ]; then
            echo "not installed, aborting.."
            return 135
        fi

    mv -f "$HOME/.bashrc.giobackup" "$HOME/.bashrc"
    rm -f "$HOME/.gururc2"
    rm -fr "$HOME/bin"
    #[[ $HOME/.config/guru ]] && rm -rf "$HOME/.config/guru"
    keyboard.main rm all
    echo "guru-client removed"
    return 0
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    [[ -f "$HOME/.gururc2" ]] && source "$HOME/.gururc2"
    uninstall.main "$@"
fi

