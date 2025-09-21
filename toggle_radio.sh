#! /usr/bin/bash +x

function background_radio_player_pid(){
	set -e -o pipefail
	echo $(pgrep --full -a CliRadio | awk '{print $1}')
}
function background_radio_player_state(){
	set -e -o pipefail
	local pid=$(background_radio_player_pid)
	[[ $(ps --no-header --format stat --pid $pid) =~ T  ]] && echo "paused" || echo "playing"
}

function toggle_backgound_radio(){
	set -e -o pipefail
	# [[**  (bookmark--jump-via "("PROCESS STATE CODES" (front-context-string . "Here are the  di") (rear-context-string . "TE CODES\n       ") (position . 23163) (last-modified 26826 20816 474909 90000) (location . "man 1 ps") (man-args . "1 ps") (handler . Man-bookmark-jump) (defaults "ps - report a snapshot of the current processes."	   "*Man 1 ps*"))" 'switch-to-buffer-other-window)  **]]
	local pid=$(background_radio_player_pid)
	if [[ -n $pid ]]; then
		[[ $(ps --no-header --format stat --pid $pid) =~ T  ]] && kill -SIGCONT $pid || kill -SIGSTOP $pid
	else
		# bash -c radio.sh
		kitty -T "radio-menu" --class floating-term -e dm-radio.sh
		# kitty
	fi
}
function current_playing_station_prompt(){

	if [[ $(background_radio_player_state) == "playing" ]];then
		# echo -n -e "▶️"
		echo -n -e "▶️"
	else
		# echo -n -e "⏸️"
		echo -n -e "⏸️"
	fi
}
toggle_backgound_radio
