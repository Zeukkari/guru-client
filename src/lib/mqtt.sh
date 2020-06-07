#!/bin/bash
# guru tool-kit mqtt tools

source $GURU_BIN/lib/common.sh

mqtt.main () {

    [[ "$1" ]] && _action="$1" ; shift
    case $_action in 
                       install) mqtt.$_action               ;;
              remove|uninstall) mqtt.remove-all             ;;
                anonymous|anom) mqtt.setup-anonymous-login  ;;
                 password|pass) mqtt.setup-password-login   ;;
                  keylogin|key) mqtt.setup-key-login        ;;
            certification|cert) mqtt.setup-certification    ;;                
                        rmuser) mqtt.remove-user $@         ;;
                       adduser) mqtt.add_user $@            ;;
                      testuser) mqtt.test-user $@           ;;
                             *) echo "non valid action" 
                                mqtt.help
        esac        

}


mqtt.help () {
    echo "-- guru tool-kit phone help -----------------------------------------------"
    printf "usage:\t %s phone [action] \n" "$GURU_CALL"
    printf "\nactions:\n"
    printf " help              help printout \n"
    printf "\nexample:     %s phone mount \n" "$GURU_CALL"
    printf "             %s phone camera \n" "$GURU_CALL"
    printf "             %s phone terminal \n" "$GURU_CALL"
}


mqtt.install () {   
    echo "install mosquitto server and client.."
    sudo apt-get update && sudo apt install -y mosquitto mosquitto-clients && DONE "mqtt server" || FAILED "error $?"
}



mqtt.add_user () {        
    [[ $1 ]] && _username=$1 || read -p "user: " _username
    sudo mosquitto_passwd /etc/mosquitto/passwd "$_username" 
}


mqtt.test-user () {
    printf "testing password login \n"
    [[ $1 ]] && _username=$1 || read -p "user: " _username
    [[ $2 ]] && _password=$2 || read -s -p "password: " _password
    mosquitto_pub -h localhost -t "test" -m "hello $username" -p 1883 -u $_username -P $_password && PASSED "$_username@localhost:1883" || FAILED "$_username@localhost:1883"
}


mqtt.remove-user () {
    local _username=$1
    printf "removing $_username password \n"
    sudo mosquitto_passwd -D /etc/mosquitto/passwd "$_username" 
    sudo systemctl restart mosquitto || WARNING "unable to restart server"   
}


mqtt.setup-password-login () {
    printf "setup password login only \n"
    echo "need sudo permissions" ; sudo ls >/dev/null  
    read -p "mqtt client username: " username 
    sudo mv -f /etc/mosquitto/conf.d/default.conf /etc/mosquitto/conf.d/default.conf.old
    printf "allow_anonymous false\npassword_file /etc/mosquitto/passwd\n" | sudo tee -a /etc/mosquitto/conf.d/default.conf 
    sudo systemctl restart mosquitto || WARNING "unable to restart server"        
    # allow firewall port
    sudo ufw allow 1883
    
   # testing
    printf "testing password login \n"
    read -s -p "password: " password
    #mosquitto_sub -h localhost -p 1883 -u $username -P $password -t "test" #&& PASSED "seems that login is" || FAILED "sub: unable to connect server" &
    mosquitto_pub -h localhost -t "test" -m "hello $username" -p 1883 -u $username -P $password && PASSED "password localhost 1883" || FAILED "password localhost 1883"
}


mqtt.setup-anonymous-login () {
    printf "setup anonymous login \n"
    echo "need sudo permissions" ; sudo ls >/dev/null          
    sudo mv -f /etc/mosquitto/conf.d/default.conf /etc/mosquitto/conf.d/default.conf.old
    printf "allow_anonymous true\n" | sudo tee -a /etc/mosquitto/conf.d/default.conf || return 125
    sudo systemctl restart mosquitto || WARNING "unable to restart server"       
    # allow firewall port
    sudo ufw allow 1883
    mosquitto_pub -h localhost -t "test" -m "hello anonymous" -p 1883 && PASSED "seems that login is" || FAILED "anonymous localhost 1883"
}


mqtt.setup-certification () {
    echo "TBD setup key login only" 
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
        source "$HOME/.gururc"
        mqtt.main "$@"
    fi



    # if install.question "setup encryption?"; then
    #     enc=true
    #     echo "setting up ssl encryption"
    #     echo sudo ufw allow 8883
    #     echo printf '# ujo.guru mqtt setup \nlistener 1883 localhost\n\nlistener 8883\ncertfile /etc/letsencrypt/live/mqtt.ujo.guru/cert.pem\ncafile /etc/letsencrypt/live/mqtt.ujo.guru/chain.pem\nkeyfile /etc/letsencrypt/live/mqtt.ujo.guru/privkey.pem' >/etc/mosquitto/conf.d/default.conf
    #     echo sudo systemctl restart mosquitto
    #     if [ $pass ]; then
    #         echo "pass"
    #         echo mosquitto_pub -h localhost -t "test" -m "hello encryption" -u $username P $password -p 8883 --capath /etc/ssl/certs/ && echo "localhost 8883 passed" || echo "localhost 8883 failed"
    #     else
    #         echo "certs"
    #         echo mosquitto_pub -h localhost -t "test" -m "hello encryption" -p 8883 --capath /etc/ssl/certs/ && echo "localhost 8883 passed" || echo "localhost 8883 failed"
    #     fi
    # fi

    # if install.question "setup certificates?"; then
    #     cert=1
    #     echo "setting up certificate login"
    #     echo sudo add-apt-repository ppa:certbot/certbot || return $?
    #     sudo apt-get update || return $?
    #     echo sudo apt-get install certbot || return $?
    #     echo sudo ufw allow http
    #     echo sudo certbot certonly --standalone --standalone-supported-challenges http-01 -d mqtt.ujo.guru
    #     echo "to renew certs automatically add following line to crontab (needs to be done manually)"
    #     echo '15 3 * * * certbot renew --noninteractive --post-hook "systemctl restart mosquitto"'
    #     read -p "press any key to continue.. "
    #     echo sudo crontab -e

    #     if [ $enc ]; then
    #         echo "pass"
    #     echo mosquitto_pub -h localhost -t "test" -m "hello 8883" -p 8883 --capath /etc/ssl/certs/ && echo "loalhost 8883 passed" || echo "failed loalhost 8883 "
    #     fi
    # fi
    # Testing
    

    # [[ "$1" ]] && _action="$1"  
    # shift    
    # case $_action in 
    #           install|remove)  mosquitto $_action  ;;                          ;;
    #           remove-all)                                   ;;
    #                          *) echo "non valid action" 
    #                             echo "anonymous, password, certification or empty (install tools)"
    #     esac      