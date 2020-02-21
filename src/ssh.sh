#!/bin/bash
## bash script to add SSH key to remote service provider
# tested: 2/2020 ubuntu desktop 18.04 and mint cinnamon 19.2 

ssh_main() {
    # main selector off ssh functions
    command="$1"
    shift
    case "$command" in 
        
        key|keys)            
            key_main "$@"
            ;;

        help)
            printf "guru ssh tools\n\nUsage:\n\t$0 [command] [variables]\n"
            printf "\nCommands:\n"
            printf " key|keys    key management tools, try '%s ssh key help' for more info.\n" "$GURU_CALL"
            printf "\nAny on known ssh command is passed trough to open-ssh client\n"
            printf "\nExample:\n\t %s ssh key add %s \n" "$GURU_CALL" "$GURU_ACCESS_POINT_SERVER" 
            ;;
        *)
        ssh "$@"

    esac
}


key_main() {
    # ssh key tools
    local command="$1"
    shift
    case "$command" in

        ps|active)
            ssh-add -l
            ;;
        
        ls|files)
            ls "$HOME/.ssh" |grep "rsa" |grep -v "pub"
            ;;

        add)
            ssh_add_key "$@"
            ;;
        rm)
            ssh_rm_key "$@"
            ;;
        help|*)
            printf "guru ssh key tools\n\nUsage:\n\t$0 [command] [variables]\n"
            printf "\nCommands:\n"
            printf " ps        list of keys \n"
            printf " ls        list of keys files\n"
            printf " add       adds keys to server [server_selection] [variables] \n"
            printf " rm        remove from remote server server [key_file] \n"          
            printf "\nExample:\n\t %s ssh key add %s \n\n" "$GURU_CALL" "$GURU_ACCESS_POINT_SERVER" 
            ;;
    esac

}

ssh_rm_key() {
    # remove local keyfiles (not from server known hosts) TODO
    echo "key file not found" > "$GURU_ERROR_MSG"
    [ -f "$HOME/.ssh/$input""_id_rsa" ] && [ -f "$HOME/.ssh/$input""_id_rsa.pub" ] || exit 127
    
    [ "$1" ] && local input="$1" ||read -r -p "key title (no '_id_rsa') : " input
    
    read -r -p "Are you sure to delete files '$input""_id_rsa' and '$input""_id_rsa.pub'? " answer
    [ "$input" ] || return 127
    if [ "${answer^^}" == "Y" ]; then 
        [ -f "$HOME/.ssh/$input""_id_rsa" ] && rm -f "$HOME/.ssh/$input""_id_rsa"
        [ -f "$HOME/.ssh/$input""_id_rsa.pub" ] && rm -f "$HOME/.ssh/$input""_id_rsa.pub"
    fi
}


ssh_add_key(){
    # [1] ujo.guru, [2] git.ujo.guru, [3] github, [4] bitbucket

    # Install requirements
    xclip -help >/dev/null 2>&1 ||sudo apt install xclip

    [ -d "$HOME/.ssh" ] || mkdir "$HOME/.ssh"
    error="1"  # Warning "1" is default exit code

    # Select git service provider
    [ "$1" ] && remote="$1" ||read -r -p "[1] ujo.guru, [2] git.ujo.guru, [3] github, [4] bitbucket, [5] other: " remote
    shift 

    case "$remote" in
        
        1|ujo.guru)
            add_key_accesspoint "$@"
            error="$?"
            ;;
        2|git.ujo.guru)
            add_key_my-git "$@"
            error="$?"
            ;;
        3|github)
            add_key_github "$@"
            error="$?"
            ;;
        4|bitbucket)
            add_key_bitbucket "$@"
            error="$?"
            ;;        
        5|other)
            add_key_other "$@"
            error="$?"
            ;;   
        help|*)
           printf "Add key to server and rule to '~/.ssh/config' \n\nUsage:\t%s ssh key add [selection] [variables]\n" "$GURU_CALL"
           printf "\nSelections:\n"
           printf " 1|%s    \t add key to access point server \n" "$GURU_ACCESS_POINT_SERVER"    
           printf " 2|git.ujo.guru  add key to own git server \n"
           printf " 3|github        add key to github.com [user_email] \n"
           printf " 4|bitbucket     add key to bitbucket.org [user_email] \n"
           printf " 5|other         add key to any server [domain] [port] [user_name] \n"
           printf "\nWithout variables script asks input during process\n"
           printf "\nExample: %s ssh key add github \n" "$GURU_CALL"
           printf "\t %s ssh key add other %s %s %s\n\n" "$GURU_CALL" "$GURU_ACCESS_POINT_SERVER" "$GURU_ACCESS_POINT_SERVER_PORT" "$GURU_USER"
    esac

    return "$error"
}


add_key_accesspoint () {        
    # function to add keys to ujo.guru access point server 

    local key_file="$HOME/.ssh/$GURU_ACCESS_POINT_SERVER"'_id_rsa'

    ## Generate keys
    echo "key file exist /user interrupt" >"$GURU_ERROR_MSG"
    ssh-keygen -t rsa -b 4096 -C "$GURU_USER" -f "$key_file" && echo "Key OK" || return 22
    chmod 600 "$key_file"

    ## Start agent and add private key
    echo "ssh-agent do not start" >"$GURU_ERROR_MSG"
    eval "$(ssh-agent -s)" && echo "Agent OK" || return 23
    
    echo "ssh-add error" >"$GURU_ERROR_MSG"
    ssh-add "$key_file" && echo "Key add OK" || return 24    
   
    echo "ssh-copy-id error" >"$GURU_ERROR_MSG"
    ssh-copy-id -p "$GURU_ACCESS_POINT_SERVER_PORT" -i "$key_file" "$GURU_ACCESS_POINT_SERVER" 


    # add domain based rule to ssh config
    if [ "$(grep -e ujo.guru < $HOME/.ssh/config)" ]; then 
        echo "Rule already exist OK"
    else
        printf "\nHost *ujo.guru \n\tIdentityFile %s\n" "$key_file" >> "$HOME/.ssh/config" && echo "Domain rule add OK" || return 26
    fi
    
    return 0
}


add_key_github () {
    # function to setup ssh key login with github 
    
    local key_file="$HOME/.ssh/github_id_rsa"
    local ssh_key_add_url="https://github.com/settings/ssh/new"

    [ "$1" ] && user_email="$1" || read -r -p "github login email: " user_email

    ## Generate keys
    ssh-keygen -t rsa -b 4096 -C "$user_email" -f "$key_file" && echo "Key OK" || return 22
    chmod 600 "$key_file"

    ## Start agent and add private key
    eval "$(ssh-agent -s)" && echo "Agent OK" || return 23
    ssh-add "$key_file" && echo "Key add OK" || return 24    

    # Paste public key to github
    xclip -sel clip < "$key_file.pub" && echo "Key copy to clipboard OK" || return 25

    # Open remote profile settings
    printf "\nOpening github settings page to firefox.\n Paste public key (stored to clipboard) to text box and use %s@%s as a 'Title'.\n\n" "$USER" "$HOSTNAME"
    firefox "$ssh_key_add_url" &
    read -r -p "After key is added, continue by pressing enter.. "

    # add domain based rule to ssh config
    if [ "$(grep -e github.com < $HOME/.ssh/config)" ]; then 
        echo "Rule already exist OK"
    else
        printf "\nHost *github.com \n\tIdentityFile %s\n" "$key_file" >> "$HOME/.ssh/config" && echo "Domain rule add OK" || return 26
    fi
    
    return 0
}


add_key_bitbucket () {
    # function to setup ssh key login with bitbucket.

    local key_file="$HOME/.ssh/bitbucket_id_rsa"
    local ssh_key_add_url="https://bitbucket.org"                               # no able to generalize beep link
    
    [ "$1" ] && user_email="$1" || read -r -p "bitbucket login email: " user_email

    ## Generate keys
    ssh-keygen -t rsa -b 4096 -C "$user_email" -f "$key_file" && echo "Key OK" || return 22
    chmod 600 "$key_file"

    ## Start agent and add private key
    eval "$(ssh-agent -s)" && echo "Agent OK" || return 23
    ssh-add "$key_file" && echo "Key add OK" || return 24    

    # Paste public key to github
    xclip -sel clip < "$key_file.pub" && echo "Key copy to clipboard OK" || return 25
    
    # Open remote profile settings
    printf "\nOpening bitbucket.prg to firefox\n Login to Bitbucket, go to 'View Profile' and then 'Settings'.\n Select on 'SSH keys' and then 'Add key'\n Then paste the key into the text box, add 'Title' %s@%s and click 'Add key'.\n\n" "$USER" "$HOSTNAME"
    firefox "$ssh_key_add_url" &
    read -r -p "After key is added, continue by pressing enter.. "

    # add domain based rule to ssh config
    if [ "$(grep -e bitbucket.org < $HOME/.ssh/config)" ]; then 
        echo "Rule already exist OK"
    else
        printf "\nHost *bitbucket.org \n\tIdentityFile %s\n" "$key_file" >> "$HOME/.ssh/config" && echo "Domain rule add OK" || return 26
    fi
    
    return 0
}


add_key_other() {
    
    [ "$1" ] && server_domain="$1" ||read -r -p "domain: " server_domain   
    [ "$2" ] && server_port="$2" ||read -r -p "port: " server_port  
    [ "$3" ] && user_name="$3" ||read -r -p "user name: " user_name

    local key_file="$HOME/.ssh/$server_domain"'_id_rsa'

    ## Generate keys
    ssh-keygen -t rsa -b 4096 -C "$user_name" -f "$key_file" && echo "Key OK" || return 22
    chmod 600 "$key_file"

    ## Start agent and add private key
    eval "$(ssh-agent -s)" && echo "Agent OK" || return 23
    ssh-add "$key_file" && echo "Key add OK" || return 24    

    ssh-copy-id -i "$key_file" "$user_name@$server_domain" -p "$server_port"

    # add domain based rule to ssh config
    if [ "$(grep -e ujo.guru < $HOME/.ssh/config)" ]; then 
        echo "Rule already exist OK"
    else
        printf "\nHost *$server_domain \n\tIdentityFile %s\n" "$key_file" >> "$HOME/.ssh/config" && echo "Domain rule add OK" || return 26
    fi

    return 0
}


# if not runned from terminal, use as library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ssh_main "$@"
    exit "$?"
fi

