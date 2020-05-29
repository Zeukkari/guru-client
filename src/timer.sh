#!/bin/bash
# giocon work time tracker casa@ujo.guru (c) 2019
source $GURU_BIN/mount.sh
source $GURU_BIN/lib/deco.sh
source $GURU_BIN/lib/common.sh

timer.main () {

	command="$1"; shift
	case "$command" in

		        check|status|start|change|cancel|end|stop|report|log|edit|last)
					timer.$command "$@"
					return $?
					;;
		        *)
				 	echo "-- guru tool-kit timer help -----------------------------------------------"
					printf "start|change     start timer for target with last customer and project \n"
					printf "start at [TIME]  start timer at given time in format HH:MM \n"
					printf "end|stop         end current task \n"
					printf "end at [TIME]    end current task at given time in format HH:MM \n"
					printf "cancel           cancels the current task \n"
					printf "log              prints out 10 last tasks from log \n"
					printf "edit             opens work time log with %s \n" "$GURU_EDITOR"
					printf "report           creates report in .csv format and opens it with %s \n" "$GURU_OFFICE_DOC"
		            return 0
		            ;;
	esac
}


timer.check() {
	mount.system
	timer.status human && return 0 || return 100
	}


timer.status() {

	mount.system

	if [ ! -f "$GURU_FILE_TRACKSTATUS" ]; then
		msg "no timer tasks\n"
		return 0
	fi

 	source "$GURU_FILE_TRACKSTATUS"
 	timer_now=$(date +%s)
 	timer_state=$(($timer_now-$timer_start))
 	nice_start_date=$(date -d $start_date '+%d.%m.%Y')
 	hours=$(($timer_state/3600))
 	minutes=$(($timer_state%3600/60))
 	seconds=$(($timer_state%60))

 	[[ $hours > 0 ]] && print_h=" $hours hours and" || print_h=""
 	[[ $minutes > 0 ]] && print_m=" $minutes minutes" || print_m=""
 	[[ $hours > 0 ]] && print_s="" || print_s=" $seconds sesonds"

 	case "$1" in

 		-h|human)
			printf "working for $customer from $start_time $nice_start_date, now spend:$print_h$print_m$print_s to $project $task \n"
			;;

 		-t|table)
 			printf " Start date      | Start time  | Hours  | Minutes  | Seconds  | Customer  | Project  | Task \n"
			printf " --------------- | ----------- | ------ | -------- | -------- | --------- | -------- | ------------ \n"
			printf " $nice_start_date | $start_time | $hours | $minutes | $seconds | $customer | $project | $task\n"
 			;;

 		-c|csv)
 			printf "Start date;Start time;Hours;Minutes;Seconds;Sustomer;Project;Task \n"
 			printf "$nice_start_date;$start_time;$hours;$minutes;$seconds;$customer;$project;$task\n"
 			;;

 		old)
 			printf "$nice_start_date $start_time > $hours:$minutes:$seconds c:$customer p:$project t:$task\n"
	 		;;

 		simple|*)
		 	printf "$start_time > "'%.2d:%.2d:%.2d'" > $customer $project $task\n"\
	 					$(($timer_state/3600)) $(($timer_state%3600/60)) $(($timer_state%60))
 			;;
 	esac

	return 0
}


timer.last() {
    [ -f $GURU_FILE_TRACKLAST ] && cat $GURU_FILE_TRACKLAST || echo "no last task set"
}


timer.start() {

	mount.system

	[ -d "$GURU_LOCATION_WORKTRACK" ] || mkdir -p "$GURU_LOCATION_WORKTRACK"

	if [ -f "$GURU_FILE_TRACKSTATUS" ]; then
	 	timer.end at $(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M")
	fi

	case "$1" in

		at|from)
			shift																	#; echo "input: "$@

			if ! [ "$1" ]; then
				echo "pls. input start time"
				return 124
			fi

			if date -d "$1" '+%H:%M' >/dev/null 2>&1; then
				time=$(date -d "$1" '+%H:%M')
				shift																#; echo "time pass: "$@
			else
				time=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M") 		#; echo "now pass: "$@
			fi

			if date -d "$1" '+%Y%m%d' >/dev/null 2>&1; then
				date=$(date -d "$1" '+%Y%m%d')
				shift																#; echo "date pass: "$@
			else
				date=$(date -d "today" '+%Y%m%d')  									#; echo "today pass: "$@
   			fi
			;;

		*)
			date=$(date -d "today" '+%Y%m%d')
			time=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M") 			#; echo "no input pass:"$@
			;;
	esac

	start_date=$date																#; echo "start_date: "$start_date
	start_time=$time																#; echo "start_time: "$start_time
    nice_date=$(date -d $start_date '+%d.%m.%Y')									#; echo "nice_date: "$nice_date
   	timer_start=$(date -d "$start_date $start_time" '+%s')							#; echo "timer_start: "$timer_start

    [ -f $GURU_FILE_TRACKLAST ] && source $GURU_FILE_TRACKLAST	# customer, project, task only
   	[ "$1" ] &&	task="$1" || task="$last_task"
	[ "$2" ] &&	project="$2" || project="$last_project"
	[ "$3" ] &&	customer="$3" || customer="$last_customer"

    printf "timer_start=$timer_start\nstart_date=$start_date\nstart_time=$start_time\n" >$GURU_FILE_TRACKSTATUS
    printf "customer=$customer\nproject=$project\ntask=$task\n" >>$GURU_FILE_TRACKSTATUS
    printf "start: $nice_date $start_time $customer $project $task\n"
    return 0
}


timer.end() {

	mount.system

	if [ -f $GURU_FILE_TRACKSTATUS ]; then
		source $GURU_FILE_TRACKSTATUS 														#; echo "timer start "$timer_start
	else
		msg "timer not started"
		return 13
	fi


	case "$1" in

		at|to|till)
			shift																	#; echo "input: "$@

			if ! [ "$1" ]; then
				echo "pls. input end time"
				return 124
			fi


			if date -d "$1" '+%H:%M' >/dev/null 2>&1; then							# Some level of format check
				time=$(date -d "$1" '+%H:%M')
				shift																#; echo "time pass: "$@
			else
				time=$(date -d @$(( (($(date +%s)) / 900) * 900)) "+%H:%M") 		#; echo "now pass: "$@
			fi

			if date -d "$1" '+%Y%m%d' >/dev/null 2>&1; then
				date=$(date -d "$1" '+%Y%m%d')
				shift																#; echo "date pass: "$@
			else
				date=$(date -d "today" '+%Y%m%d')  									#; echo "today pass: "$@
   			fi
			;;

		*)
			date=$(date -d "today" '+%Y%m%d')
			time=$(date -d @$(( (($(date +%s) + 900) / 900) * 900)) "+%H:%M") 			#; echo "no input pass:"$@
			;;
	esac

	end_date=$date																	#; echo "end_date: "$end_date
	end_time=$time																	#; echo "end_time: "$end_time
	timer_end=$(date -d "$end_date $end_time" '+%s')								#; echo "timer end "$timer_end
	dot_start_date=$(date -d $start_date '+%Y.%m.%d')								#; echo "nice_start_date: "$nice_start_date
	dot_end_date=$(date -d $end_date '+%Y.%m.%d')									#; echo "nice_end_date: "$nice_end_date
	nice_start_date=$(date -d $start_date '+%d.%m.%Y')								#; echo "nice_start_date: "$nice_start_date
	nice_end_date=$(date -d $end_date '+%d.%m.%Y')									#; echo "nice_end_date: "$nice_end_date

	(( spend_sec = timer_end - timer_start )) 										#; echo "spend_sec: "$spend_sec
	(( spend_min = spend_sec / 60 )) 												#; echo "spend_min: "$spend_min
	(( spend_hour = spend_min / 60 ))												#; echo "spend_hour: "$spend_hour
	(( spend_min_div = spend_min % 60 ))											#; echo "spend_min_div: "$spend_min_div

	spend_min_dec=$(python -c "print(int(round($spend_min_div * 1.6666, 0)))") 		#; echo "spend_min_dec: "$spend_min_dec
	hours="$spend_hour.$spend_min_dec"												#; echo "hours: "$hours

	if [[ "$nice_start_date" == "$nice_end_date" ]]; then
		option_end_date=""
	else
		option_end_date=" ($nice_end_date)"
	fi

	printf "end: $nice_start_date $start_time - $end_time$option_end_date $hours h:$minutes $customer $project $task\n"

	[ -f $GURU_FILE_TRACKDATA ] || printf "Start date  ;Start time ;End date ;End time ;Hours ;Customer ;Project ;Task \n">$GURU_FILE_TRACKDATA
	[[ $hours > 0.11 ]] && printf "$dot_start_date;$start_time;$dot_end_date;$end_time;$hours;$customer;$project;$task\n">>$GURU_FILE_TRACKDATA

	printf "last_customer=$customer\nlast_project=$project\nlast_task=$task\n" >$GURU_FILE_TRACKLAST

	rm $GURU_FILE_TRACKSTATUS
	return 0
}


timer.stop () {
	timer.end "$@"
	return 0
}


timer.change() {
	timer.start "$@"
	return $?
}


timer.cancel() {

 	mount.system

	if [ -f $GURU_FILE_TRACKSTATUS ]; then
		rm $GURU_FILE_TRACKSTATUS
		echo "canceled"
	else
		echo "not active timer"
	fi
	return 0
}


timer.log () {
	printf "last logged records:\n$(tail $GURU_FILE_TRACKDATA | tr ";" "  ")\n"
	return 0
}


timer.edit  () {
	mount.system
	$GURU_EDITOR "$GURU_FILE_TRACKDATA" &
	return $?
}


timer.report() {
	mount.system

	[ "$1" ] && team="$1" || team="$GURU_TEAM"								#; echo "team :"$team
	report_file="work-track-report-$(date +%Y%m%d)-$team.csv" 				#; echo "report_file: "$report_file
	output_folder=$HOME/Documents											#; echo "output_folder: $output_folder"
	[ "$team" == "all" ] && team=""
	[ -f $GURU_FILE_TRACKDATA ] || return 13
	cat $GURU_FILE_TRACKDATA |grep "$team" |grep -v "invoiced" >"$output_folder/$report_file"
	$GURU_OFFICE_DOC $output_folder/$report_file &
	timer.end $""
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$HOME/.gururc"
    source "$GURU_BIN/functions.sh"
	source "$GURU_BIN/mount.sh"
	timer.main "$@"
	exit $?
fi

