#! /usr/bin/bash +x
#
# Script name: random_radio
# Description: randomly play an English or Chinese radio station,
#              excluding the station that is currently playing
# Dependencies: jq, mpv, pgrep, shuf

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/_helper.sh"

# UUIDs of all currently playing stations (from the mpv user-agent)
function current_station_uuids() {
	pgrep --full -a CliRadio 2>/dev/null |
		awk -F 'Radio#' '{print $2}' |
		awk '{print $1}' |
		grep -E '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' || true
}

function stop_radio_player() {
	local -a pids
	mapfile -t pids < <(pgrep --full -a CliRadio 2>/dev/null | awk '{print $1}')
	if ((${#pids[@]} > 0)); then
		kill -9 "${pids[@]}" 2>/dev/null || true
		for ((i = 0; i < 100; i++)); do
			[[ -z $(pgrep --full -a CliRadio 2>/dev/null) ]] && break
			sleep 0.05
		done
	fi
	rm -f "$RADIO_MPV_SOCKET"
}

function play_station() {
	local uuid="$1"
	local name="$2"
	local url="$3"

	[[ -d $RADIO_RUN_DIR ]] || mkdir -p "$RADIO_RUN_DIR"
	printf '%s|%s\n' "$name" "$url" >"$RADIO_RUN_DIR/listening_radio"
	nohup mpv --input-ipc-server="$RADIO_MPV_SOCKET" \
		--user-agent="CliRadio#$uuid" \
		--loop-playlist=force "$url" &>/dev/null &
}

function main() {
	local current_uuids
	local candidate
	local uuid
	local name
	local url
	local country
	local language

	current_uuids=$(current_station_uuids)

	candidate=$(
		jq -c --arg cur "$current_uuids" '
			($cur | split("\n") | map(select(length > 0))) as $cur_uuids |
			unique_by(.stationuuid)
			| .[]
			| select(((.language // "") | ascii_downcase | test("english|chinese")))
			| select(((.url // "") | length > 0))
			| select(.stationuuid as $id | ($cur_uuids | index($id) | not))
			| {stationuuid, name, url, country, language}
		' "$dbfile" | shuf -n 1
	)

	if [[ -z "$candidate" ]]; then
		echo "没有可播放的英文或中文电台" >&2
		exit 1
	fi

	uuid=$(jq -r '.stationuuid' <<<"$candidate")
	name=$(jq -r '.name' <<<"$candidate" | sed 's/^[[:space:]]*//')
	url=$(jq -r '.url' <<<"$candidate")
	country=$(jq -r '.country' <<<"$candidate")
	language=$(jq -r '.language' <<<"$candidate")

	stop_radio_player
	play_station "$uuid" "$name" "$url"

	echo "正在播放: $name"
	echo "国家/地区: $country"
	echo "语言: $language"
	echo "链接: $url"
}

main
