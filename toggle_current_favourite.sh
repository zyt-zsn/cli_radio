#! /usr/bin/bash +x
#
# Script name: toggle_current_favourite
# Description: add the currently playing station to the favourite list,
#              or remove it from the list if it is already a favourite
# Dependencies: jq, pgrep

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/_helper.sh"

# UUID of the currently playing station (from the mpv user-agent)
function current_station_uuid() {
	pgrep --full -a CliRadio 2>/dev/null |
		awk -F 'Radio#' '{print $2}' |
		awk '{print $1}' |
		grep -E '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' |
		head -n 1 || true
}

function ensure_favourite_db() {
	local dir
	dir=$(dirname "$fav_dbfile")
	[[ -d $dir ]] || mkdir -p "$dir"
	if [[ ! -f $fav_dbfile ]] || ! jq -e 'type == "array"' "$fav_dbfile" &>/dev/null; then
		echo '[]' >"$fav_dbfile"
	fi
}

function station_in_favourites() {
	local uuid="$1"
	jq -e --arg uuid "$uuid" 'any(.[]; .stationuuid == $uuid)' "$fav_dbfile" &>/dev/null
}

function replace_favourite_db() {
	local tmp
	tmp=$(mktemp "${fav_dbfile}.XXXXXX") || return 1
	cat >"$tmp" &&
		mv "$tmp" "$fav_dbfile" ||
		{ rm -f "$tmp"; return 1; }
}

function main() {
	local uuid
	local name
	local station

	uuid=$(current_station_uuid)
	if [[ -z $uuid ]]; then
		echo "当前没有正在播放的电台" >&2
		exit 1
	fi

	ensure_favourite_db

	name=$(jq -r --arg uuid "$uuid" '.[] | select(.stationuuid == $uuid) | .name' "$dbfile" | head -n 1)

	if station_in_favourites "$uuid"; then
		jq --arg uuid "$uuid" 'map(select(.stationuuid != $uuid))' "$fav_dbfile" | replace_favourite_db || {
			echo "取消收藏失败" >&2
			exit 1
		}
		echo "已取消收藏: $name"
	else
		station=$(jq -c --arg uuid "$uuid" '.[] | select(.stationuuid == $uuid)' "$dbfile")
		if [[ -z $station ]]; then
			echo "未在电台数据库中找到当前电台: $uuid" >&2
			exit 1
		fi
		jq --argjson station "$station" '. + [$station]' "$fav_dbfile" | replace_favourite_db || {
			echo "添加收藏失败" >&2
			exit 1
		}
		echo "已添加收藏: $name"
	fi
}

main
