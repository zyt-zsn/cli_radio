#!/usr/bin/bash +x
#
# Script name: dm-cli-radio
# Description: listen radio on line in terminal
# Dependencies: jq, fzf, mpv, pgrep, tput
# Contributors: zyt

export dbfile=~/.config/radio/stations.json
export fav_dbfile=~/.config/radio/favourite_stations.json
export RADIO_RUN_DIR=/run/user/1000/radio
export RADIO_MPV_SOCKET=/run/user/1000/radio/mpvsocket
# source /home/zyt/github/cli_radio/_helper.sh

# export dbfile=~/.config/radio/test.json
#list all values with respect of ".stationuuid:.query_key"
# paramter number 1
# paramter 1: query_key
# valid choices:
# 	changeuuid/stationuuid/serveruuid/name/url/url_resolved/homepage/favicon/tags/country/countrycode/state/language/languagecodes/votes/codec
function fetch_stations_value_with_uuid() {
	# echo ${FUNCNAME[0]}

	# local filter=""
	local filter=$1
	# cat stations.json | jq 'map(.stationuuid +": "+.name)|.[]'
	# [[**  (bookmark--jump-via "("jq map(f)" (front-context-string . "[.[] | f] and ma") (rear-context-string . "s equivalent to ") (position . 36067) (last-modified 26795 55807 531223 813000) (location . "man 1 jq") (man-args . "1 jq") (handler . Man-bookmark-jump) (defaults "jq - Command-line JSON processor" "*Man 1 jq*"))" 'switch-to-buffer-other-window)  **]]
	# cat stations.json | jq --arg f $filter '[.[]|.[$f]]|.[]'
	# cat stations.json | jq --arg f $filter 'map(.[$f])|.[]'

	# cat $dbfile | jq '.[]'|jq --arg f $filter '.stationuuid+":"+.[$f]'
	cat "$dbfile" | jq '.[]' | jq -r --arg f "$filter" '.stationuuid+":"+.[$f]' | sed 's/:[[:blank:]]*/:/g'
	# sed 's/^\"\(\\[trn]\|[[:blank:]]\)*\(.*\)\"$/\2/g'
}

#filter stations with filter value
# paramter1:
#	filtername:  tags, country, language
# paramter2
#	filter value
# paramter3:
#	true: include
#	false: exclude
function filter_stations() {
	# [[**  (bookmark--jump-via "("ref" (filename . "~/org-roam-files/20250823211333-network_radios.org") (front-context-string . "  	 export stati") (rear-context-string . "t-right pressed\n") (position . 6178) (last-modified 26796 6993 725141 184000) (defaults "20250823211333-network_radios.org"))" 'switch-to-buffer-other-window)  **]]
	local key=$1
	local val=$2
	# skip national flag parg
	[[ $key == "country" ]] && val=${val:2}
	# cat $dbfile | jq '.[]'| jq --arg k $key --arg v "$val" 'select(.[$k]==$v)'
	cat "$dbfile" | jq 'sort_by(.votes)|reverse[]' | jq --arg k "$key" --arg v "$val" 'select(.[$k]==$v)'
	# cat $dbfile | jq '.[]'| jq --arg k $key --arg v $val 'select(.[$k]==$v)'
}

function favourite_station_uuid_array() {
	# jq -r .[].stationuuid $fav_dbfile
	cat $fav_dbfile | jq -r .[].stationuuid
}
export -f favourite_station_uuid_array

function fetch_filtered_stations_value_with_uuid2() {
	# local sta_json_array=$(filter_stations language spanish)
	[[ -d ${RADIO_RUN_DIR}/candidates/filtered ]] || mkdir ${RADIO_RUN_DIR}/candidates/filtered

	local sta_json_array=$1
	local k="$1"
	local v="$2"
	local refresh="$3"

	if [[ -f ${RADIO_RUN_DIR}/candidates/filtered/"$k"_"$v" && -z $refresh ]]; then
		cat ${RADIO_RUN_DIR}/candidates/filtered/"$k"_"$v"
	else
		[[ $k == "country" ]] && v=${v:2}
		local fav_uuids
		fav_uuids=$(favourite_station_uuid_array)
		cat $dbfile | jq -r --arg k "$k" --arg v "$v" --arg fav_uuids "$fav_uuids" '.[]|select(.[$k]|tostring==$v)|.stationuuid+if .stationuuid|inside($fav_uuids) then ":❤️" else ":  " end+.name' | tee ${RADIO_RUN_DIR}/candidates/filtered/"$k"_"$v"
	fi
}
function fetch_filtered_stations_value_with_uuid() {
	# local sta_json_array=$(filter_stations language spanish)
	local sta_json_array=$1
	local fav_uuids
	fav_uuids=$(favourite_station_uuid_array)

	echo -n "$sta_json_array" | jq -r --arg fav_uuids "$fav_uuids" '.stationuuid+if .stationuuid|inside($fav_uuids) then ":❤️ else ":  " end+.name'
	# echo -n "$sta_json_array" | jq -r '.stationuuid+":"+.["name"]'
}
export -f fetch_stations_value_with_uuid
export -f filter_stations
export -f fetch_filtered_stations_value_with_uuid2
export -f fetch_filtered_stations_value_with_uuid
#fetch station info from https://api.radio-browser.info/ and update local db file
# paramter 1:
# 	file path of database
# paramter 2:
#	search limit
function update_station_db() {
	local dbfile=$1
	local limit=$2
	curl -s -H 'Content-Type:application/json' -H 'User-Agent:ob-http' -d {\"limit\":$limit} https://de1.api.radio-browser.info/json/stations | jq '.' >$dbfile
}
function get_station_dbcashe() {
	echo station.json
}
#list all the supported searching key of station
function list_station_keys() {
	if [[ -f ${RADIO_RUN_DIR}/keys ]]; then
		cat ${RADIO_RUN_DIR}/keys
	else
		cat $dbfile | jq '.[1]' | jq -r 'keys|.[]' | tee ${RADIO_RUN_DIR}/keys
	fi
}

function countrycode2flag() {
	# [[**  (bookmark--jump-via "("Regional indicator symbol - Wikipedia" (front-context-string . "U+1F1Ex     🇦   ") (rear-context-string . "F1E5 omitted)  \n") (position . 14184) (last-modified 26803 9316 498769 941000) (location  . "https://en.wikipedia.org/wiki/Regional_indicator_symbol#Unicode_block") (handler . eww-bookmark-jump) (defaults "Regional indicator symbol - Wikipedia" "*eww*"))" 'switch-to-buffer-other-window)  **]]
	local f1
	local f2
	local code
	code="$1"
	f1=$(printf %X $((0x1F1E6 + $(printf "%d" "'${code:0:1}") - 65)))
	f2=$(printf %X $((0x1F1E6 + $(printf "%d" "'${code:1:1}") - 65)))
	printf "\U$f1\U$f2"
}
export -f countrycode2flag
function sed_countrycode_to_flag() {
	local countrycode="$1"
	echo "$(countrycode2flag "$countrycode")$2"
}
export -f sed_countrycode_to_flag
# list all valid chocies with respect of specific key
# paramter
#  k: query key name
function list_valid_candidates() {
	# cat test.json | jq '.' | jq 'unique_by(.["language"]).[]' | jq .name
	local k=$1

	[[ -d ${RADIO_RUN_DIR}/candidates ]] || mkdir ${RADIO_RUN_DIR}/candidates
	if [[ -f ${RADIO_RUN_DIR}/candidates/$k ]]; then
		cat ${RADIO_RUN_DIR}/candidates/"$k"
	else
		if [[ $k == "name" ]]; then
			local fav_uuids
			fav_uuids=$(favourite_station_uuid_array)
			cat $dbfile | jq -r --arg k "$k" --arg fav_uuids "$fav_uuids" '.|sort_by(.votes)|reverse[]|.stationuuid+if .stationuuid|inside($fav_uuids) then ":❤️" else ":  " end+.[$k]' | tee ${RADIO_RUN_DIR}/candidates/"$k"
		elif [[ "$k" == "country" ]]; then
			# jq -r --arg k "$k" '.|unique_by(.[$k]).[]|"\\#"+.countrycode+"\\#"+.[$k]' $dbfile| sed -e 's/\\#\(.*\)\\#\(.*\)/sed_countrycode_to_flag \1 "\2"/e' | tee ${RADIO_RUN_DIR}/candidates/"$k"
			# sed 的 e 标志是 GNU sed 扩展，在 BSD/macOS sed 中不可用。
			# 且sed受 sh 影响(如果sh不是/usr/bin/bash，本脚本(bash)导出的 sed_countrycode_to_flag 指令无法访问)
			# 改为跨平台替代方案：
			jq -r --arg k "$k" '.|unique_by(.[$k]).[]|"\\#"+.countrycode+"\\#"+.[$k]' $dbfile | while read -r line; do
				countrycode=$(echo "$line" | cut -d'#' -f2)
				name=$(echo "$line" | cut -d'#' -f3)
				sed_countrycode_to_flag "$countrycode" "$name"
			done | tee ${RADIO_RUN_DIR}/candidates/"$k"
		else
			jq -r --arg k "$k" '.|unique_by(.[$k]).[].[$k]' $dbfile| tee ${RADIO_RUN_DIR}/candidates/"$k"
		fi
	fi
}
export -f list_station_keys
export -f list_valid_candidates
function list_tags() {
	echo -n -e "tag1\ntag2\ntag3\ntag4"
}
export -f list_tags
# echo $(cat stations.json | jq 'map(.stationuuid +": "+.name)|.[]'| fzf --bind 'alt-right:reload(cat stations.json|jq "map(.stationuuid + \": \" + .tags)|.[]"),tab:reload(tags={fzf:query};cat stations.json|jq "select(.name==\"$tags\")")')

category=""
export category
state="select_filter_type"

#Check whether station designated by uuid is in target db file
#Paramter1: stationuuid
#Paramter2: station db file path
function station_in_dbfile() {
	local uuid=$1
	local db_file=$2
	[[ -n $(cat "$db_file" | jq '.[]' | jq --arg uuid "$uuid" 'select(.stationuuid==$uuid)') ]]
}
export -f station_in_dbfile
#Check whether station designated by uuid is in favourite radios
#Paramter: stationuuid
function station_in_favourites() {
	station_in_dbfile "$1" "$fav_dbfile"
}
export -f station_in_favourites
#add to favourite_stations
#paramter1
#	path of favourite station db file
#paramter2
#	stationuuid of radio station to add to favourites
function toggle_favourite() {
	local fav_db_file=$1
	local uuid=$2

	set +eo pipefail
	if ! station_in_favourites "$uuid"; then
		local station
		station=$(cat "$dbfile" | jq --arg uuid "$uuid" '.[]|select(.stationuuid==$uuid)')
		echo "$(echo "$(cat $fav_db_file | jq .[]) $station" | jq -s)" >$fav_db_file.swap
		rm -f $fav_db_file
		mv $fav_db_file.swap $fav_db_file
	else
		echo "$(cat $fav_db_file | jq --arg uuid "$uuid" '.[]|select(.stationuuid!=$uuid)' | jq -s)" >$fav_db_file.swap
		rm -f $fav_db_file
		mv $fav_db_file.swap $fav_db_file
	fi
}
export -f toggle_favourite
function set_current_layer() {
	if [[ "$1" =~ "favourites" ]]; then
		echo -e "$1" >${RADIO_RUN_DIR}/current_layer
	else
		[[ $1 -ge 1 ]] && [[ $1 -le 4 ]] && echo "$1" >${RADIO_RUN_DIR}/current_layer
	fi
}
function current_layer() {
	# cat ${RADIO_RUN_DIR}/current_layer
	[[ -f ${RADIO_RUN_DIR}/current_layer ]] && head -n 1 ${RADIO_RUN_DIR}/current_layer
}
#Get filter value of layer $1
#Parameter:
#$1: target layer
function value_of_layer() {
	[[ -f ${RADIO_RUN_DIR}/layer${1} ]] && cat ${RADIO_RUN_DIR}/layer"$1"
}

function current_layer_value() {
	head -n 1 "${RADIO_RUN_DIR}"/layer"$(current_layer)"
}

#Set filter value of layer $1 with value $2
function update_layer() {
	echo "$2" >"${RADIO_RUN_DIR}"/layer"$1"
}

#Clear filter value of layer $1 with value $2
function clear_layer() {
	echo "" >"${RADIO_RUN_DIR}"/layer"$1"
}
#Set filter value of current layer with $1
function update_current_layer() {
	update_layer "$(current_layer)" "$1"
}
function inc_layer() {
	local curval
	curval=$(current_layer_value)
	local val="$1"
	if [[ $(current_layer) -le 4 ]]; then
		[[ $(current_layer) -eq 3 ]] && val=$(echo "$val" | awk -F : '{print $2}')
		[ "$val" != "$curval" ] && update_layer "$(current_layer)" "$val" && clear_layer $(($(current_layer) + 1))
		set_current_layer $(($(current_layer) + 1))
	fi
}
function dec_layer() {
	if [[ $(current_layer) -gt 1 ]]; then
		set_current_layer $(($(current_layer) - 1))
	fi
}
function current_filter() {
	if [ "favourites" == "$(tail -n 1 ${RADIO_RUN_DIR}/current_layer)" ]; then
		echo ❤️收藏电台❤️:"$1"
	else
		local ret=""
		for ((i = 1; i < $(current_layer); i++)); do
			ret="$ret"/"$(value_of_layer $i)"
		done
		[[ -n $ret ]] && ret="$ret"/"$1" || ret="$1"
		echo -n -e "过滤器:$ret"
	fi
}
export -f current_filter
export -f inc_layer
export -f dec_layer
export -f set_current_layer
export -f current_layer_value
export -f current_layer
export -f value_of_layer
export -f update_layer
export -f clear_layer
export -f update_current_layer

#Reload candidate with respect value($2) of layer$1
function reload_layer() {
	local layer=$1
	local v="$2"
	local refresh="$3"
	case $layer in
	1)
		list_station_keys
		;;
	2)
		[[ -n $v ]] || v="$(value_of_layer 1)"
		# list_valid_candidates $(value_of_layer 1) ;;
		list_valid_candidates "$v"
		;;
	3)
		# fetch_filtered_stations_value_with_uuid2 "$(value_of_layer 1)" "$(value_of_layer 2)" ;;
		[[ -n $v ]] || v="$(value_of_layer 2)"
		fetch_filtered_stations_value_with_uuid2 "$(value_of_layer 1)" "$v" "$refresh"
		;;
	4)
		# preview_station "$2" "view_only" ;;
		# echo -n -e "1\n2\n3" ;;
		preview_station "$2" "view_only"
		;;
	esac
}
export -f reload_layer
# reload_layer 3
# echo $(value_of_layer 2) $(value_of_layer 3)
# fetch_filtered_stations_value_with_uuid "$(filter_stations $(value_of_layer 2) $(value_of_layer 3))"
# fetch_filtered_stations_value_with_uuid "$(filter_stations "country" )"
# exit
# set_current_layer 1
# update_layer 1 language
# echo "$(reload_layer $(current_layer))"

# set_current_layer 2
# update_layer $(current_layer) chinese
# echo "$(reload_layer $(current_layer))"

# set_current_layer 3
# echo "$(reload_layer $(current_layer) 'country')"
# exit

function reload_script() {
	local state=$1
	local radio_search_filter_k
	local radio_search_filter_v
	case $state in
	select_filter_type)
		list_station_keys
		;;
	select_filter_value)
		radio_search_filter_k=$2
		list_valid_candidates $radio_search_filter_k
		;;
	favourite_stations)
		cat "$fav_dbfile" | jq -r '.[]|(.stationuuid+":"+.name)' | sed 's/:[[:blank:]]*/:/g'
		;;
	filter_stations | *)
		read radio_search_filter_v <${RADIO_RUN_DIR}/filter_v
		read radio_search_filter_k <${RADIO_RUN_DIR}/filter_k
		if [[ $radio_search_filter_k == "country" ]]; then
			# skip national flag parg
			radio_search_filter_v=${radio_search_filter_v:2}
		fi
		fetch_filtered_stations_value_with_uuid "$(filter_stations "$radio_search_filter_k" "$radio_search_filter_v")"
		;;
	esac
}
export -f reload_script
#parmeter stationuuid
function preview_station() {
	local uuid="$1"
	local countrycode

	uuid=$(echo "$uuid" | awk -F : '{print $1}')
	station=$(cat $dbfile | jq --arg uuid "$uuid" '.[]|select(.stationuuid==$uuid)')
	# export stationuuid=$(echo $(cat stations.json | jq 'map(.name +": "+.stationuuid)|.[]'| fzf --delimiter ":" --with-nth 1 --accept-nth 2 --preview 'uuid=$(echo {2}|sed "s/\"$//g");echo $(cat stations.json | jq ".[]"| jq "select(.stationuuid==\"$uuid\")")|jq "pick(.name, .url, .homepage, .country, .language, .votes, .codec, .tags, .countrycode)" && echo $(cat stations.json | jq ".[]"| jq "select(.stationuuid==\"$uuid\")")|jq .url|xargs mpv >/dev/null 2>&1 '|sed 's/\"$//g'));cat stations.json | jq '.[]'| jq 'select(.stationuuid==env.stationuuid)|.url'|xargs mpv
	if [ ${#station} -gt 1 ]; then
		[ $2 = "play" ] && echo $(echo $station | jq -r '.name+"|"+.url') >${RADIO_RUN_DIR}/listening_radio
		# https://en.wikipedia.org/wiki/Regional_indicator_symbol#Unicode_block
		# [[**  (bookmark--jump-via "("Regional indicator symbol - Wikipedia" (front-context-string . "U+1F1Ex     🇦   ") (rear-context-string . "F1E5 omitted)  \n") (position . 14184) (last-modified 26803 9316 498769 941000) (location  . "https://en.wikipedia.org/wiki/Regional_indicator_symbol#Unicode_block") (handler . eww-bookmark-jump) (defaults "Regional indicator symbol - Wikipedia" "*eww*"))" 'switch-to-buffer-other-window)  **]]
		countrycode=$(echo $station | jq -r .countrycode)
		flag=$(countrycode2flag $countrycode)
		station_info=$(echo $station | jq -r --arg flag "$flag" '("📻:\t"+.name, "ID:\t"+.stationuuid, "🔖:\t"+.tags, "🌎:\t"+.url, "🏚️:\t"+.home, $flag+":\t"+.country, "语言:\t"+.language, "👍:\t"+(.votes|tostring))')
		echo -n -e "$station_info"
		if [[ -f ${RADIO_RUN_DIR}/listening_radio ]] && [ $2 == "play" ]; then
			# if [[ -f ${RADIO_RUN_DIR}/listening_radio ]]; then
			local radion
			read radio <${RADIO_RUN_DIR}/listening_radio
			kill_background_radio_player
			# setsid -f mpv --user-agent="CliRadio#$uuid" --loop-playlist=force "$(echo "$radio" | awk -F "|"  '{print $2}')" &>/dev/null &
			nohup mpv --input-ipc-server="$RADIO_MPV_SOCKET" --user-agent="CliRadio#$uuid" --loop-playlist=force "$(echo "$radio" | awk -F "|" '{print $2}')" &>/dev/null &
		# 	while true;do
		# 		echo -e "\033[2J"
		# 		echo -e "$station_info"
		# 		echo -e "Currently listening:" $radio
		# 		sleep 8
		# 	done
		fi
	fi
	# station_info="$(cat $dbfile | jq -r --arg uuid $uuid '.[]|select(.stationuuid==$uuid)|("电台名称:"+.name, "标签分类:"+.tags, "播放链接:"+.url, "官方网址:"+.home, "国家:"+.country, "语言:"+.language, "听众投票数:"+(.votes|tostring))')"
}
export -f preview_station

function background_radio_player_pid() {
	set -e -o pipefail
	pgrep --full -a CliRadio | awk '{print $1}'
}
function background_radio_player_state() {
	set -e -o pipefail
	local pid=$(background_radio_player_pid)
	if [[ -n "$pid" ]]; then
		[[ $(ps --no-header --format stat --pid $pid) =~ T ]] && echo "paused" || echo "playing"
	else
		echo "none"
	fi
}
function toggle_backgound_radio() {
	set -e -o pipefail
	# [[**  (bookmark--jump-via "("PROCESS STATE CODES" (front-context-string . "Here are the  di") (rear-context-string . "TE CODES\n       ") (position . 23163) (last-modified 26826 20816 474909 90000) (location . "man 1 ps") (man-args . "1 ps") (handler . Man-bookmark-jump) (defaults "ps - report a snapshot of the current processes."	   "*Man 1 ps*"))" 'switch-to-buffer-other-window)  **]]
	local pid=$(background_radio_player_pid)
	[[ $(ps --no-header --format stat --pid $pid) =~ T ]] && kill -SIGCONT $pid || kill -SIGSTOP $pid
}
function background_station_uuid() {
	set -e -o pipefail
	echo $(pgrep --full -a CliRadio | awk -F 'Radio#' '{print $2}' | awk '{print $1}')
}
function kill_background_radio_player() {
	local pid
	pid=$(background_radio_player_pid)
	if [[ -n $pid ]]; then
		kill -9 $pid
		while [[ -n $(background_radio_player_pid) ]]; do
			:
		done
	fi
}
export -f kill_background_radio_player
export -f toggle_backgound_radio
export -f background_station_uuid
export -f background_radio_player_pid
export -f background_radio_player_state
function station_info() {
	local uuid="$1"
	local countrycode

	[[ -d ${RADIO_RUN_DIR}/stations/ ]] || mkdir ${RADIO_RUN_DIR}/stations
	if [[ -f ${RADIO_RUN_DIR}/stations/$uuid ]]; then
		cat ${RADIO_RUN_DIR}/stations/$uuid
	else
		station=$(cat $dbfile | jq --arg uuid "$uuid" '.[]|select(.stationuuid==$uuid)')
		if [ ${#station} -gt 1 ]; then
			countrycode=$(echo $station | jq -r .countrycode)
			flag=$(countrycode2flag $countrycode)
			station_info=$(echo $station | jq -r --arg flag "$flag" '("📻:\t"+.name, "ID:\t"+.stationuuid, "🔖:\t"+.tags, "🌎:\t"+.url, "🏚️:\t"+.home, $flag+":\t"+.country, "语言:\t"+.language, "👍:\t"+(.votes|tostring))')
			echo -n -e "$station_info" | tee ${RADIO_RUN_DIR}/stations/$uuid
		fi
	fi
}
export -f station_info
function current_playing_station_prompt() {
	case $(background_radio_player_state) in
	playing)
		echo -n -e "播放中${YELLOW}${BOLD}Ctrl+t${RESET} to ⏸️\n" "$(station_info $(background_station_uuid))"
		;;
	paused)
		echo -n -e "暂停中${YELLOW}${BOLD}Ctrl+t${RESET} to ▶️\n" "$(station_info $(background_station_uuid))"
		;;
	*) ;;
	esac
}
function current_playing_station_info() {
	[[ -n $(background_radio_player_pid) ]] && station_info "$1"
}
export -f current_playing_station_info
export -f current_playing_station_prompt
# fetch_filtered_stations_value_with_uuid $(filter_stations "$(value_of_layer 2)" "$(value_of_layer 3)")
# filter_stations "$(value_of_layer 2)" "$(value_of_layer 3)"

# fetch_filtered_stations_value_with_uuid2 language english
# fetch_filtered_stations_value_with_uuid "$(filter_stations language 'english')"
# fetch_filtered_stations_value_with_uuid "$(filter_stations language 'chinese')"
# fetch_filtered_stations_value_with_uuid "$(filter_stations language 'german')"
# fetch_filtered_stations_value_with_uuid "$(filter_stations country "The Netherlands")"
# station_info $(background_station_uuid)
# exit

# borrowed from yt-x (https://github.com/Benexl/yt-x.git)
init_pretty_print() {
	# if [ "$PRETTY_PRINT" = "true" ]; then
	# [[**  (bookmark--jump-via "("basic color table" (front-context-string . "ANSI Color Codes") (rear-context-string) (position . 1) (last-modified 26826 31382 823895 104000) (location . "https://talyian.github.io/ansicolors/") (handler . eww-bookmark-jump) (defaults "" "*eww*"))" 'switch-to-buffer-other-window)  **]]
	# [[**  (bookmark--jump-via "("terminfo - terminal capability (String Capability Name)" (front-context-string . "TI        TC  De") (rear-context-string . "bility Name     ") (position . 47304) (last-modified 26826 31517 4719 214000) (location . "man 5 terminfo") (man-args . "5 terminfo") (handler . Man-bookmark-jump) (defaults "ps - report a snapshot of the current processes."	   "*Man 1 ps*" "terminfo - terminal capability database"	   "*Man 5 terminfo*"))" 'switch-to-buffer-other-window)  **]]
	RED=$(tput setaf 1)
	GREEN=$(tput setaf 2)
	YELLOW=$(tput setaf 3)
	BLUE=$(tput setaf 4)
	MAGENTA=$(tput setaf 5)
	CYAN=$(tput setaf 6)
	BOLD=$(tput bold)
	RESET=$(tput sgr0)
	# fi
	export RED
	export GREEN
	export YELLOW
	export BLUE
	export MAGENTA
	export CYAN
	export RESET
	export BOLD
}

function main() {
	init_pretty_print
	[ -d ${RADIO_RUN_DIR} ] || mkdir -p ${RADIO_RUN_DIR}
	# update_station_db test.json 10
	[[ -n $(current_layer) ]] || set_current_layer 1

	local filter_value
	label="$(echo -n -e "--请选择分类标准--" | lolcat -f)"
	filter_value=$(
		echo -n "$(reload_layer $(current_layer))" |
			fzf --style full --preview-label " 电台信息 " \
				--delimiter ":" \
				--exact --reverse --tac --ansi --sync --input-label-pos 5:top --input-label ' 分类器 ' \
				--border --with-nth -1 --border-label $label --prompt "请选择: " \
				--bind 'ctrl-r:pos(100)' \
				--bind 'ctrl-p:execute-silent(pkill -9 mpv;preview_station {1} "play")+transform-preview-label(echo {1})+transform-header-label(current_playing_station_prompt)+transform-header([ $(current_layer) = 3 ] && echo -n -e "$(station_info {1})")' \
				--bind 'load:transform-query(current_layer_value)+rebind(right,ctrl-l,left,ctrl-h)+transform-header-label(current_playing_station_prompt)+transform-header(current_playing_station_info $(background_station_uuid))' \
				--bind 'focus:preview(reload_layer $(( $(current_layer) + 1 )) {1})+transform-preview-label(echo {-1})+transform-input-label(current_filter {-1})' \
				--bind 'ctrl-t:execute-silent(toggle_backgound_radio)+transform-header-label(current_playing_station_prompt)' \
				--bind 'ctrl-a:execute-silent(toggle_favourite $fav_dbfile {1})+reload-sync(reload_layer $(current_layer) "" refresh)' \
				--bind 'ctrl-f:execute-silent(set_current_layer "3\nfavourites")+reload-sync(reload_script favourite_stations)+transform-border-label(echo $label)' \
				--bind 'right,ctrl-l:unbind(right,ctrl-l,left,ctrl-h)+execute-silent(inc_layer {})+reload-sync(reload_layer $(current_layer) {})+transform-border-label(echo $label)' \
				--bind 'left,ctrl-h:unbind(right,ctrl-l,left,ctrl-h)+execute-silent(dec_layer)+reload-sync(reload_layer $(current_layer) "")+transform-border-label(echo $label)'
	)

	# --bind 'ctrl-r:pos(echo $(( $SRANDOM % $FZF_TOTAL_COUNT )) )'\
	# --bind 'enter:execute-silent(preview_station {1} "play")+accept'\
	# --bind 'focus:execute-silent(update_layer $(( $(current_layer) )) {})+preview(reload_layer $(( $(current_layer) + 1 )) {1})+transform-preview-label(echo {1})'\
	# --bind 'ctrl-h:execute-silent(set_current_layer $(( $(current_layer) - 1 )))+reload(reload_layer $(current_layer) $(value_of_layer (( $(current_layer) + 1 )) ))+transform-prompt(echo 电台: )+transform-border-label(echo $label)+transform-input-label(echo " 电台 ")' \
	# --bind 'focus:execute-silent(update_layer $(( $(current_layer) )) {})+preview(reload_layer $(( $(current_layer) + 1 )) {1})+transform-preview-label(echo {1})+transform-header([ $(current_layer) = 3 ] && station_info {1})'\

	if [[ -n "$filter_value" ]]; then
		kill_background_radio_player
		# echo play radio
		preview_station "$filter_value" "play"
		# pgrep --full -a CliRadio | awk '{print $1}'
		until [[ -n $(background_radio_player_pid) ]]; do
			:
		done
		# disown -a
	fi
	exit 0
}
# testzyt
main
# favourite_station_uuid_array
# list_station_keys
# list_valid_candidates language
# list_valid_candidates country

# filter_stations language english
# filter_stations language italian
# uuid="da3527f7-b71e-49e0-a9d5-57102350ffc5"
# station_in_favourites $uuid
# fetch_filtered_stations_value_with_uuid "$(filter_stations language 'english')"
# fetch_filtered_stations_value_with_uuid "$(filter_stations language 'chinese')"
# fetch_filtered_stations_value_with_uuid "$(filter_stations language 'german')"
# fetch_filtered_stations_value_with_uuid "$(filter_stations country "The Netherlands")"
# filter_stations country "The Netherlands"
