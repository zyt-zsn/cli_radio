#! /usr/bin/bash +x

export dbfile=~/.config/radio/stations.json

# export dbfile=~/.config/radio/test.json
export fav_dbfile=~/.config/radio/favourite_stations.json
#list all values with respect of ".stationuuid:.query_key"
# paramter number 1
# paramter 1: query_key
# valid choices:
# 	changeuuid/stationuuid/serveruuid/name/url/url_resolved/homepage/favicon/tags/country/countrycode/state/language/languagecodes/votes/codec
function fetch_stations_value_with_uuid(){
	# echo ${FUNCNAME[0]}
	
	# local filter=""
	local filter=$1
	# cat stations.json | jq 'map(.stationuuid +": "+.name)|.[]'
	# [[**  (bookmark--jump-via "("jq map(f)" (front-context-string . "[.[] | f] and ma") (rear-context-string . "s equivalent to ") (position . 36067) (last-modified 26795 55807 531223 813000) (location . "man 1 jq") (man-args . "1 jq") (handler . Man-bookmark-jump) (defaults "jq - Command-line JSON processor" "*Man 1 jq*"))" 'switch-to-buffer-other-window)  **]]
	# cat stations.json | jq --arg f $filter '[.[]|.[$f]]|.[]'
	# cat stations.json | jq --arg f $filter 'map(.[$f])|.[]'

	# cat $dbfile | jq '.[]'|jq --arg f $filter '.stationuuid+":"+.[$f]'
	cat $dbfile|jq '.[]'|jq -r --arg f $filter '.stationuuid+":"+.[$f]'|sed 's/:[[:blank:]]*/:/g'
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
function filter_stations(){
	# [[**  (bookmark--jump-via "("ref" (filename . "~/org-roam-files/20250823211333-network_radios.org") (front-context-string . "  	 export stati") (rear-context-string . "t-right pressed\n") (position . 6178) (last-modified 26796 6993 725141 184000) (defaults "20250823211333-network_radios.org"))" 'switch-to-buffer-other-window)  **]]
	local key=$1
	local val=$2

	# cat $dbfile | jq '.[]'| jq --arg k $key --arg v "$val" 'select(.[$k]==$v)'
	cat $dbfile | jq 'sort_by(.votes)|reverse[]'| jq --arg k $key --arg v "$val" 'select(.[$k]==$v)'
	# cat $dbfile | jq '.[]'| jq --arg k $key --arg v $val 'select(.[$k]==$v)'
}


function favourite_station_uuid_array(){
	# jq -r .[].stationuuid $fav_dbfile
	cat $fav_dbfile | jq -r .[].stationuuid 
}
export -f favourite_station_uuid_array

function fetch_filtered_stations_value_with_uuid(){
	# local sta_json_array=$(filter_stations language spanish) 
	local sta_json_array=$1
	local fav_uuids=$(favourite_station_uuid_array)

	# zyt=$(jq -r .[].stationuuid favourite_stations.json)
	# cat favourite_stations.json | jq --arg fav_uuids "$zyt" '.[].stationuuid+if .[].stationuuid|inside($fav_uuids) then ":💘" else ":" end+"name"'
	# cat favourite_stations.json|jq .[] | jq --arg fav_uuids "$zyt" '.stationuuid+if .stationuuid|inside($fav_uuids) then ":💘" else ":" end+.name'
	echo -n "$sta_json_array" | jq -r --arg fav_uuids "$fav_uuids" '.stationuuid+if .stationuuid|inside($fav_uuids) then ":💘" else ":  " end+.name'

	# echo -n "$sta_json_array" | jq -r '.stationuuid+":"+.["name"]'
}
export -f fetch_stations_value_with_uuid
export -f filter_stations
export -f fetch_filtered_stations_value_with_uuid
#fetch station info from https://api.radio-browser.info/ and update local db file
# paramter 1:
# 	file path of database
# paramter 2:
#	search limit
function update_station_db(){
	local dbfile=$1
	local limit=$2
	curl -s -H 'Content-Type:application/json' -H 'User-Agent:ob-http' -d {\"limit\":$limit} https://de1.api.radio-browser.info/json/stations|jq '.' > $dbfile
}
function get_station_dbcashe(){
	echo station.json
}

#list all the supported searching key of station
function list_station_keys(){
	cat $dbfile|jq '.[1]'|jq -r 'keys|.[]'
}
# list all valid chocies with respect of specific key
# paramter
#  k: query key name
function list_valid_condidates(){
	# cat test.json | jq '.' | jq 'unique_by(.["language"]).[]' | jq .name
	local k=$1
	if [[ $k=="name" ]]
	then
		local fav_uuids=$(favourite_station_uuid_array)
		# echo -n "$sta_json_array" | jq -r --arg fav_uuids "$fav_uuids" '.stationuuid+if .stationuuid|inside($fav_uuids) then ":💘" else ":  " end+.name'
		# cat $dbfile | jq '.'|jq -r --arg fav_uuids "$fav_uuids" 'unique_by(.name).[]|if .stationuuid|inside($fav_uuids) then ":💘" else ":  " end+.[$k]'
		# cat $dbfile | jq '.'|jq -r --arg k $k --arg fav_uuids "$fav_uuids" 'unique_by(.name).[]|if .stationuuid|inside($fav_uuids) then ":💘" else ":  " end+.[$k]'
		# cat $dbfile | jq '.'|jq -r --arg k $k --arg fav_uuids "$fav_uuids" '.[]|.stationuuid+if .stationuuid|inside($fav_uuids) then ":💘" else ":  " end+.[$k]'
		cat $dbfile | jq '.'|jq -r --arg k $k --arg fav_uuids "$fav_uuids" 'sort_by(.votes)|reverse[]|.stationuuid+if .stationuuid|inside($fav_uuids) then ":💘" else ":  " end+.[$k]'
		# cat $dbfile | jq '.'|jq -r --arg k $k 'unique_by(.[$k]).[].[$k]'
	else
		cat $dbfile | jq '.'|jq -r --arg k $k 'unique_by(.[$k]).[].[$k]'
	fi
}
export -f list_station_keys
export -f list_valid_condidates
function list_tags(){
	echo -n -e "tag1\ntag2\ntag3\ntag4"
}
export -f list_tags
# echo $(cat stations.json | jq 'map(.stationuuid +": "+.name)|.[]'| fzf --bind 'alt-right:reload(cat stations.json|jq "map(.stationuuid + \": \" + .tags)|.[]"),tab:reload(tags={fzf:query};cat stations.json|jq "select(.name==\"$tags\")")')

category=""
export radio_search_filter
export category
state="select_filter_type"


#Check whether station designated by uuid is in target db file
#Paramter1: stationuuid
#Paramter2: station db file path
function station_in_dbfile(){
	local uuid=$1
	local db_file=$2
	[[ -n $(cat "$db_file" | jq '.[]'| jq --arg uuid $uuid 'select(.stationuuid==$uuid)') ]]
}
export -f station_in_dbfile
#Check whether station designated by uuid is in favourite radios
#Paramter: stationuuid
function station_in_favourites(){
	station_in_dbfile "$1" "$fav_dbfile" 
}
export -f station_in_favourites
#add to favourite_stations
#paramter1
#	path of favourite station db file
#paramter2
#	stationuuid of radio station to add to favourites
function add_to_favourite(){
	local fav_db_file=$1
	local uuid=$2

	set +eo pipefail
	if ! station_in_favourites $uuid
	# if [[ -z $(cat $fav_db_file | jq '.[]'| jq --arg uuid $uuid 'select(.stationuuid==$uuid)') ]]
	then
		# echo "uuid"--$uuid
		# echo $
		local station=$(cat $dbfile | jq --arg uuid "$uuid" '.[]|select(.stationuuid==$uuid)')
		echo "$(echo "$(cat $fav_db_file|jq .[]) $station" | jq -s .)" > $fav_db_file.swap
		rm -f $fav_db_file
		mv $fav_db_file.swap $fav_db_file
		# echo "station"--$station
		# echo -n "$(cat $fav_db_file) $station"
	# 	echo Add to favourite
	# else
	# 	echo found
	fi
}
export -f add_to_favourite
function reload_script(){
	local state=$1
	case $state in
		select_filter_type)
			list_station_keys ;;
		select_filter_value)
			export radio_search_filter=$2
			list_valid_condidates $radio_search_filter ;;
		favourite_stations)
			cat "$fav_dbfile" | jq -r '.[]|(.stationuuid+":"+.name)'|sed 's/:[[:blank:]]*/:/g';;
		filter_stations|*)
			read radio_search_filter < /tmp/filter_type_pipe

			fetch_filtered_stations_value_with_uuid "$(filter_stations $radio_search_filter "$2")" ;;
	esac
}
export -f reload_script
#parmeter stationuuid
function preview_station(){
	local uuid=$1
	# export stationuuid=$(echo $(cat stations.json | jq 'map(.name +": "+.stationuuid)|.[]'| fzf --delimiter ":" --with-nth 1 --accept-nth 2 --preview 'uuid=$(echo {2}|sed "s/\"$//g");echo $(cat stations.json | jq ".[]"| jq "select(.stationuuid==\"$uuid\")")|jq "pick(.name, .url, .homepage, .country, .language, .votes, .codec, .tags, .countrycode)" && echo $(cat stations.json | jq ".[]"| jq "select(.stationuuid==\"$uuid\")")|jq .url|xargs mpv >/dev/null 2>&1 '|sed 's/\"$//g'));cat stations.json | jq '.[]'| jq 'select(.stationuuid==env.stationuuid)|.url'|xargs mpv
	station=$(cat $dbfile | jq --arg uuid "$uuid" '.[]|select(.stationuuid==$uuid)')
	if [ ${#station} -gt 1 ];then
		station_info=$(echo $station | jq -r '("电台名称:"+.name, "电台ID:"+.stationuuid, "标签分类:"+.tags, "播放链接:"+.url, "官方网址:"+.home, "国家:"+.country, "语言:"+.language, "听众投票数:"+(.votes|tostring))')
		mpv $(echo $station | jq -r .url)|\
		while true;do
			echo -e "\033[2J"
			echo -e "$station_info"
			sleep 8
		done
	fi
	# station_info="$(cat $dbfile | jq -r --arg uuid $uuid '.[]|select(.stationuuid==$uuid)|("电台名称:"+.name, "标签分类:"+.tags, "播放链接:"+.url, "官方网址:"+.home, "国家:"+.country, "语言:"+.language, "听众投票数:"+(.votes|tostring))')"
}
export -f preview_station
function main(){
	[ -p /tmp/filter_type_pipe ] || mkfifo /tmp/filter_type_pipe
	# update_station_db test.json 10
	# fetch_stations_value_with_uuid stationuuid name
	# fetch_stations_value_with_uuid stationuuid
	# fetch_stations_value_with_uuid tags
	label="$(echo -n -e "--请选择分类标准--" | lolcat -f)"

	local filter_value
	filter_value=$(echo -n "$(list_station_keys)"\
					   | fzf --style full\
							 --no-sort\
							 --exact\
							 --delimiter ":"\
							 --ansi\
							 --input-label ' 分类器 '\
							 --border\
							 --with-nth -1\
							 --border-label $label  --prompt "分类: "\
							 --bind 'ctrl-a:execute(add_to_favourite $fav_dbfile {1})'\
							 --bind 'ctrl-f:reload(reload_script favourite_stations)+transform-prompt(echo 收藏电台: )+transform-border-label(echo $label)+transform-input-label(echo " 电台 ")+clear-query' \
							 --bind 'ctrl-l:reload(reload_script filter_stations {} {q})+transform-prompt(echo 电台: )+transform-border-label(echo $label)+transform-input-label(echo " 电台 ")+clear-query' \
							 --bind 'ctrl-h:reload(reload_script select_filter_type {})+transform-prompt(echo 分类: )+transform-border-label(echo $label)+transform-input-label(echo " 分类器 ")+clear-query' \
							 --bind 'tab:execute-silent(echo {}>/tmp/filter_type_pipe&)+reload(reload_script select_filter_value {})+transform-prompt(echo {}:)+transform-border-label(echo "请选择"{})+transform-input-label(echo -e {}"[\e[7;33mC-h\e[0m返回分类选择器]")+clear-query'\
							 --preview 'preview_station {1}'
							 # --preview 'uuid={1};echo $(cat stations.json | jq ".[]"| jq "select(.stationuuid==\"$uuid\")")|jq -r .url|xargs mpv >/dev/null 2>&1 && echo $(cat stations.json | jq ".[]"| jq "select(.stationuuid==\"$uuid\")")'
							 # --preview 'uuid={1};echo $(cat stations.json | jq ".[]"| jq "select(.stationuuid==\"$uuid\")")|jq "pick(.url)"|xargs mpv >/dev/null && echo $(cat stations.json | jq ".[]"| jq "select(.stationuuid==\"$uuid\")")|jq "pick(.name, .url, .homepage, .country, .language, .votes, .codec, .tags, .countrycode)"'
				)

	echo $radio_search_filter:$filter_value
	exit 1
	# local candidates=$(fetch_stations_value_with_uuid name)
	local candidates=$(fetch_filtered_stations_value_with_uuid "$(filter_stations $radio_search_filter $filter_value)")
	[[  ${#filter_value} -gt 1 ]] || exit 1
	
	echo -n -e "$candidates" | fzf --delimiter ":"\
								   --with-nth -1\
								   --accept-nth 1\
								   --bind 'alt-right:reload(list_valid_condidates $radio_search_filter;set radio_seach_filter="country")'\
								   --bind 'tab:reload(fetch_filtered_stations_value_with_uuid "$(filter_stations language {q})")+clear-query'

								   # --bind 'alt-right:reload(fetch_stations_value_with_uuid "language")'\
}
# testzyt
main
# favourite_station_uuid_array
# list_station_keys
# list_valid_condidates language
# list_valid_condidates country

# filter_stations language english
# filter_stations language italian
# uuid="da3527f7-b71e-49e0-a9d5-57102350ffc5"
# station_in_favourites $uuid
# fetch_filtered_stations_value_with_uuid "$(filter_stations language 'english')"
# fetch_filtered_stations_value_with_uuid "$(filter_stations language 'chinese')"
# fetch_filtered_stations_value_with_uuid "$(filter_stations language 'german')"
# fetch_filtered_stations_value_with_uuid "$(filter_stations country "The Netherlands")"
# filter_stations country "The Netherlands"
