#! /usr/bin/bash +x

source /home/zyt/github/cli_radio/_helper.sh

function background_radio_player_pid(){
	set -e -o pipefail
	pgrep --full -a CliRadio | awk '{print $1}'
}

function background_radio_uuid(){
	set -e -o pipefail
	pgrep --full -a "CliRadio#[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}" | awk -F '[# ]' '{print $4}'
}
function background_radio_player_state(){
	set -e -o pipefail

	if [[ -S "$RADIO_MPV_SOCKET" ]]; then
		[[ $(echo '{ "command": ["get_property", "pause"] }' | socat - "$RADIO_MPV_SOCKET" | jq .data) = true ]] && echo "paused" || echo "playing"
	else
		local pid
		pid=$(background_radio_player_pid)
		[[ -n $pid ]] && [[ $(ps --no-header --format stat --pid $pid) =~ T  ]] && echo "paused" || echo "playing"
	fi
}

dbfile=~/.config/radio/stations.json

function current_playing_station_prompt(){
	set +e +o pipefail
	local uuid
	local radio_name
	uuid=$(background_radio_uuid)
	if [[ -n "$uuid" ]]; then
		if [[ -f ${RADIO_RUN_DIR}/listening_radio ]];then
			radio_name=$(awk -F "|" '{print $1}' ${RADIO_RUN_DIR}/listening_radio)
		else
			if [[ -f $RADIO_RUN_DIR/stations/${uuid} ]];then
				radio_name=$(head -n 1 $RADIO_RUN_DIR/stations/"$uuid" | awk -F ":" '{print $2}')
			else
				radio_name=$(jq -r --arg uuid "$uuid" '.[]|select (.stationuuid==$uuid)|.name' $dbfile)
			fi
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
