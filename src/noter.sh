#!/bin/bash
# note generator

main () {
	
	variable=$1
	
	case $command in

				report)					
					[ $1 ] && notefile=$(note_file $1) || notefile=$(note_file $(date +%Y%m%d))					
					$GURU_CALL document $notefile $2					
					$GURU_OFFICE_DOC ${notefile%%.*}.odt &
					;;

				list|ls)
					list_notes $@
					;;

				yesterday|yd)
					open_note $(date +%Y%m%d -d "yesterday")
					;;

				monday|mon|maanantai|ma)
					open_note $(date +%Y%m%d -d "last-monday")
					;;

				tuesday|tue|tiistai|ti)
					open_note $(date +%Y%m%d -d "last-tuesday")
					;;

				wednesday|wed|kerskiviikko|ke)
					open_note $(date +%Y%m%d -d "last-wednesday")
					;;

				thursday|thu|torstai|to)
					open_note $(date +%Y%m%d -d "last-thursday")
					;;

				friday|fri|perjantai|pe)
					open_note $(date +%Y%m%d -d "last-friday")
					;;

				saturday|sat|lauvantai|lauantai|la)
					open_note $(date +%Y%m%d -d "last-saturday")
					;;

				sunday|sun|sunnuntai|su)
					open_note $(date +%Y%m%d -d "last-sunday")
					;;

		        help)
				 	printf 'Usage: '$GURU_CALL' notes [command] <date> \n'            
		            echo "Commands:"            
					printf 'open|edit         open given date notes (use time format YYYYMMDD) \n'
					printf 'list              list of notes. first parameter is month (MM), second year (YYYY) \n' 
					printf 'report            open note with template to '$GURU_OFFICE_DOC' \n' 
					printf '<yesteerday|yd>   open yesterdays notes \n' 
					printf '<weekday|wkd>     open last week day notes \n' 
					printf 'without command or input open todays notes, exist or not\n'
		            ;;

				open|edit)
					open_note "$1"
					;;

				fromweb|web)
					make_html_md $@

					;;

				*) 			
					if [ ! -z "$command" ]; then 
						open_note "$command"
					else
						make_note
					fi
	esac
}


make_html_md() {

	[ $1 ] && url=$1 || read -p "url: " url
	[ $2 ] && filename=$2 || read -p "filename: " filename
	tempfile=/tmp/noter.temp
	[ -f $tempfile ] && rm -f $tempfile
	
	echo "converting $url to $filename"
	curl --silent $url | pandoc --from html --to markdown_strict -o $tempfile
	sed -e 's/<[^>]*>//g' $tempfile >$filename
	[ -f $tempfile ] && rm -f $tempfile
}





list_notes() {

		[ $1 ] && month=$1 || month=$(date +%m)
		[ $2 ] && year=$2 || year=$(date +%Y)

		noteDir=$GURU_NOTES/$GURU_USER/$year/$month
		
		if [ -d $noteDir ]; then 
			ls $noteDir | grep .md | grep -v "~" 
		else
			printf "no folder exist. "			 
			exit 126
		fi
}


make_note() {

		templateDir="$GURU_NOTES/$GURU_USER/template"
		templateFile="template.$GURU_USER.$GURU_TEAM.md"
		template="$templateDir/$templateFile"
		noteDir=$GURU_NOTES/$GURU_USER/$(date +%Y/%m)
		noteFile=$GURU_USER"_notes_"$(date +%Y%m%d).md
		note="$noteDir/$noteFile"

		[[  -d "$noteDir" ]] || mkdir -p "$noteDir"
		[[  -d "$templateDir" ]] || mkdir -p "$templateDir"

		if [[ ! -f "$note" ]]; then 	    
			    printf "$noteFile $(date +%H:%M:%S)\n\n# $GURU_NOTE_HEADER $GURU_REAL_NAME $(date +%-d.%-m.%Y)\n\n" >$note			    
			    [[ -f "$template" ]] && cat "$template" >>$note || printf "customize your template to $template" >>$note			    
		fi

		open_note "$(date +%Y%m%d)"
}

note_file () {

	input=$1

	if [ "$input" ]; then 		# YYYYMMDD only
		year=${input::-4}		# Tässä paukkuu jos open parametri ei ole oikeassa formaatissa
		date=${input:6:2}
		month=${input:4:2}
		noteDir=$GURU_NOTES/$GURU_USER/$year/$month
		noteFile=$GURU_USER"_notes_"$year$month$date.md
	else
		printf "no date given"
		exit 124
	fi

	echo "$noteDir/$noteFile"

}


open_note() {

	note="$(note_file $1)"
	projectFolder=$GURU_NOTES/$GURU_USER/project 
	[ -f $projectFolder ] || mkdir -p $projectFolder
	
	if [[ ! -f "$note" ]]; then 
		printf  "no note for given day. "
		exit 125
	fi

	case $GURU_EDITOR in
	
		subl)
			projectFile=$projectFolder/notes.sublime-project
			[ -f $projectFile ] || printf "{\n\t"'"folders"'":\n\t[\n\t\t{\n\t\t\t"'"path"'": "'"'$GURU_NOTES/$GURU_USER'"'"\n\t\t}\n\t]\n}\n" >$projectFile
			subl --project "$projectFile" -a 
			subl "$note" --project "$projectFile" -a 		
			return $?
			;;
		*)
			$GURU_EDITOR "$note" 
			return $?
	esac			
	
}

command=$1
shift
main $@
exit $?

