#! /usr/bin/bash +x

source /home/zyt/github/cli_radio/_helper.sh

function background_radio_player_pid(){
	set -e -o pipefail
	pgrep --full -a CliRadio | awk '{print $1}'
}
function background_radio_player_state(){
	set -e -o pipefail
	local pid
	pid=$(background_radio_player_pid)
	[[ $(ps --no-header --format stat --pid "$pid") =~ T  ]] && echo "paused" || echo "playing"
}

function toggle_backgound_radio(){
	set -e -o pipefail

	if [[ -S "$RADIO_MPV_SOCKET" ]]; then
		# [[**  (bookmark--jump-via "("mpv JSON IPV Commands " (buffer-name . "*Man 1 mpv*") (front-context-string . "y\n              ") (rear-context-string . "     set_propert") (front-context-region-string) (rear-context-region-string) (visits . 0) (time 27312 36441 327482 974000) (created 27312 36441 327482 974000) (position . 993908) (location . "man 1 mpv") (man-args . "1 mpv") (handler . Man-bookmark-jump))" 'switch-to-buffer-other-window)  **]]
		if [[ $(echo '{ "command": ["get_property", "pause"] }' | socat - "$RADIO_MPV_SOCKET" | jq .data) = false ]]; then
			echo '{ "command": ["set_property", "pause", true] }' | socat - "$RADIO_MPV_SOCKET"
		else
			echo '{ "command": ["set_property", "pause", false] }' | socat - "$RADIO_MPV_SOCKET"
		fi
	else
		# [[**  (bookmark--jump-via "("PROCESS STATE CODES" (front-context-string . "Here are the  di") (rear-context-string . "TE CODES\n       ") (position . 23163) (last-modified 26826 20816 474909 90000) (location . "man 1 ps") (man-args . "1 ps") (handler . Man-bookmark-jump) (defaults "ps - report a snapshot of the current processes."	   "*Man 1 ps*"))" 'switch-to-buffer-other-window)  **]]
		local pid
		pid=$(background_radio_player_pid)
		if [[ -n $pid ]]; then
			if [[ $(ps --no-header --format stat --pid "$pid") =~ T  ]]; then
				kill -SIGCONT "$pid"
			else
				kill -SIGSTOP "$pid"
			fi
		else
			# bash -c radio.sh
			kitty -T "radio-menu" --class floating-term -e dm-radio.sh
			# kitty
		fi
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
