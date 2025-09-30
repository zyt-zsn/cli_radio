#! /usr/bin/bash +x

source /home/zyt/github/cli_radio/_helper.sh

function background_radio_player_pid(){
	set -e -o pipefail
	pgrep --full -a CliRadio | awk '{print $1}'
}

function background_radio_uuid(){
	set -e -o pipefail
	pgrep --full -a CliRadio | awk -F '[# ]' '{print $4}'
}
function background_radio_player_state(){
	set -e -o pipefail
	local pid
	pid=$(background_radio_player_pid)
	[[ $(ps --no-header --format stat --pid $pid) =~ T  ]] && echo "paused" || echo "playing"
}

dbfile=~/.config/radio/stations.json

function current_playing_station_prompt(){
	set +e +o pipefail
	local uuid
	uuid=$(background_radio_uuid)
	if [[ -n "$uuid" ]]; then
		local radio_name
		if [[ -f $RADIO_RUN_DIR/stations/${uuid} ]];then
			radio_name=$(head -n 1 $RADIO_RUN_DIR/stations/"$uuid" | awk -F ":" '{print $2}')
		else
			radio_name=$(jq -r --arg uuid "$uuid" '.[]|select (.stationuuid==$uuid)|.name' $dbfile)
		fi
		if [[ $(background_radio_player_state) == "playing" ]];then
			echo -e "󰐹 $radio_name"
		else
			echo -e "󱈜 $radio_name"
		fi
	else
		echo -e "󱈜 "
	fi
}
current_playing_station_prompt
