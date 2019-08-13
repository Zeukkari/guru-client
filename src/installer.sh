#!/bin/bash
# install functions for giocon client ujo.guru / juha.palm 2019

main () {

	case "$command" in
		
			basic)
				sudo apt install xterm
				exit $?
				;;

			mqtt-client)
				mosquitto_client_install $@
				exit $?
				;;

			mqtt-server)
				mosquitto_server_install $@
				exit $?
				;;

			conda|anaconda|letku)
				conda_install $@
				error_code="$?"			
				[ -z $error_code ] || echo "conda install failed with code: $error_code"
				exit $error_code
				exit $?
				;;

			django|freeman)
				conda install django
				conda list |grep django 
				exit $?
				;;

			alpine|pine|email)
				alpine_install $@
				exit $?
				;;

			programmer|pk2)
				command=$GURU_BIN/install-pk2.sh
				gnome-terminal --geometry=80x28 -- /bin/bash -c "$command; exit; $SHELL; "
				exit $?
				;;

			mpsyt|player|play)			
				$GURU_CALL play install $@
				exit $error
				;;

			kaldi|listener)
				kaldi_install 4
				exit $?
				;;

			edoypts|edi)
				echo "TODO"
				exit $?
				;;

			help|-h|--help|*) 		# hardly never updated help printout
			 	printf "usage: guru install [MODULE] \nmobules: \n"
				printf 'conda           anaconda python environment manger \n'
				printf 'django          web framework for python people\n'
				printf 'kaldi           the ears, brains and.. lot of learning \n'
				printf 'mpsyt|player    players for terminal, music, video, youtube \n'
				printf 'programmer|pk2  pickit2 pic mcu programmer \n'		
	esac

}


yes_no () {
	[ "$1" ] || return 2
	read -p "$1 [y/n]: " answer
	[ $answer ] || return 1
	[ $answer == "y" ]  && return 0 
	return 1
}

mosquitto_client_install () { 	#not tested

	echo "install client"
	# sudo apt-get update && sudo apt-get upgrade || return $?
	# sudo apt install mosquitto-clients || return $?
	# sudo add-apt-repository ppa:certbot/certbot || return $?
	# sudo apt-get update || return $?
	# sudo apt-get install certbot || return $?
	# sudo ufw allow http

	#continue: https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-the-mosquitto-mqtt-messaging-broker-on-ubuntu-16-04
	return 0
}

mosquitto_server_install () { 	#not tested

	# sudo apt-get update && sudo apt-get upgrade || return $?
	# sudo apt install mosquitto mosquitto-clients || return $?
	
	
	ln -s /etc/mosquitto/conf.d/default.conf $GURU_CFG/mosquitto.default.conf

	if yes_no "setup password login?"; then 
		pass=1
		echo "setting up password login"
		read -p "mqtt client username :" username
		[ "$username" ] || return 668
		# sudo mosquitto_passwd -c /etc/mosquitto/passwd $username && printf "allow_anonymous false\npassword_file /etc/mosquitto/passwd\n" >>/etc/mosquitto/conf.d/default.conf || return 668
		# sudo systemctl restart mosquitto || return $?

		read -p "password for testing :" password
		[ "$password" ] || return 671
		# mosquitto_pub -h localhost -t "test" -m "hello login" -p 1883 -u $username -P $password && echo "loalhost 1883 passed" || echo "failed loalhost 8883 "
	fi

	if yes_no "setup encryption?"; then 
		enc=1
		echo "setting up ssl encryption"
		# sudo ufw allow 8883
		# printf '# ujo.guru mqtt setup \nlistener 1883 localhost\n\nlistener 8883\ncertfile /etc/letsencrypt/live/mqtt.ujo.guru/cert.pem\ncafile /etc/letsencrypt/live/mqtt.ujo.guru/chain.pem\nkeyfile /etc/letsencrypt/live/mqtt.ujo.guru/privkey.pem' >/etc/mosquitto/conf.d/default.conf
		# sudo systemctl restart mosquitto
		if [ $pass ]; then 
			echo "pass"
			# mosquitto_pub -h localhost -t "test" -m "hello encryption" -u $username P $password -p 8883 --capath /etc/ssl/certs/ && echo "localhost 8883 passed" || echo "localhost 8883 failed"
		else  
			echo "pass"
			# mosquitto_pub -h localhost -t "test" -m "hello encryption" -p 8883 --capath /etc/ssl/certs/ && echo "localhost 8883 passed" || echo "localhost 8883 failed"
		fi
	fi
	
	if yes_no "setup certificates?"; then 
		cert=1
		echo "setting up certificate login"
		# sudo add-apt-repository ppa:certbot/certbot || return $?
		sudo apt-get update || return $?
		# sudo apt-get install certbot || return $?
		# sudo ufw allow http
		# sudo certbot certonly --standalone --standalone-supported-challenges http-01 -d mqtt.ujo.guru
		echo "to renew certs automatically add following line to crontab (needs to be done manually)"
		echo '15 3 * * * certbot renew --noninteractive --post-hook "systemctl restart mosquitto"'
		read -p "press any key to continue.. "
		# sudo crontab -e	

		if [ $enc ]; then 
			echo "pass"
		# mosquitto_pub -h localhost -t "test" -m "hello 8883" -p 8883 --capath /etc/ssl/certs/ && echo "loalhost 8883 passed" || echo "failed loalhost 8883 "
		fi
	fi
	# Testing 
	echo "mosquitto server successfully installed"

	return 0
}

conda_install () {

	conda list && return 13 || echo "no conda installed"

	sudo apt-get install -y libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6

	[ "$1" ] && conda_version=$1 || conda_version="2019.03"
	conda_installer="Anaconda3-$conda_version-Linux-x86_64.sh"
	conda_sum=45c851b7497cc14d5ca060064394569f724b67d9b5f98a926ed49b834a6bb73a

	curl -O https://repo.anaconda.com/archive/$conda_installer
	sha256sum $conda_installer >installer_sum
	printf "checking sum, if exit it's invalid: "
	cat installer_sum |grep $conda_sum && echo "ok" || return 11

	chmod +x $conda_installer
	bash $conda_installer -u && rm $conda_installer installer_sum || return 12
	source ~/.bashrc 
	echo 'conda install done, next run setup by typing: "'$GURU_CALL' set conda"'
	return 0
}


kaldi_install(){
	
	if [  $1 == ""  ]; then
		read -p "how many cores you like to use for compile?  : " cores
	    cores=8		
	fi
	echo "installing kaldi.."
	sudo apt install g++ subversion
	cd git 
	mkdir speech 
	cd speech
	git clone https://github.com/kaldi-asr/kaldi.git kaldi --origin upstream
	cd tools
	./extras/check_dependencies.sh # || kato mitä palauttaa, nyt testaan ensin. Interlillä äly hidas repo ~10min/220MB
	sudo ./extras/install_mkl.sh -sp debian intel-mkl-64bit-2019.2-057 # Onko syytä pointtaa noi tiukasti versioon?
	make -j $cores
	cd ../src/
	./configure --shared
	make depend -j $cores
	make -j $cores
	return $?
}


alpine_install () {

	target_cfg=$HOME/.pinerc	
	if ! $(alpine -v >>/dev/null); then 
		echo "installing alpine"
		sudo apt install alpine
	else
		echo "installed"			
	fi
	
	echo "setting up alpine: TODO"
	return 0
	
	# [ -f $target_cfg ] && mv -f $target_cfg $GURU_CFG/.pinerc.original
	
	# echo "personal-name=$GURU_USER"				>$target_cfg
	# echo "user-domain=ujo.guru"					>$target_cfg

	# read -p "imput "
	# imap.gmail.com/ssl/user=YOURUSERNAME@GMAIL.COM

	# export GURU_EMAIL="juha.palm@ujo.guru casa@ujo.guru" 
	# export GURU_GMAIL="juha.palm@gmail.com regressio@gmail.com" 
	# export GURU_PMAIL="juha.palm@protonmail.com regressio@protonmail.com" 
}

command="$1" 
shift
main $@




#git add functions.sh; git commit -m"  "
#git add gururc.sh; git commit -m"  "
#git add installer.sh; git commit -m"  "
#git add noter.sh; git commit -m"  "
#git add play.sh; git commit -m"  "
#git add scan.sh; git commit -m"  "
#git add timer.sh; git commit -m"  "
