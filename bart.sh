#!/bin/bash
#
PATH='/usr/bin:/usr/sbin:/bin:/sbin'

TOKEN=$(cat token)
RUPOR=$(cat rupor)
CHATS=$(cat chats)
offset_file=/tmp/telegram_offset
LOGGER="cat >>/tmp/bart.log" # or logger -t "bart"
API="https://api.telegram.org/bot$token"
CURL="curl -k -s"
GET="$CURL -X GET"
POST="$CURL -X POST -H 'Charset: UTF-8'"

send_msg () {
	local chat=$1; shift
  local msg="$1"; shift
  local params=$@
	$POST $API/sendMessage \
          -d chat_id=$chat \
          -d parse_mode=${PARSE:-HTML} \
          --data-urlencode text="$msg" \
          $params &>1 | $LOGGER
}

send_all() {
  local msg="$1"
  for chat in ${CHATS}; do
    send_msg $chat "${msg}"
  done
}

reply() {
	local msg_id="$1"; shift
	local origin="$1"; shift
	local toReturn="$1"
	$POST $API/sendMessage  -d reply_to_message_id=$msg_id \
                          -d chat_id=$origin \
                          -d parse_mode=HTML \
                          --data-urlencode text="$toReturn" 2>&1 | $LOGGER
}


keyboard='{"keyboard": [["/snap \uD83D\uDCF7","/guard \uD83D\uDC6E","/relay \uD83D\uDCA1"],["/system \uD83D\uDCCA","/reboot \uD83D\uDCA9","/menu \uD83D\uDD25"]],"resize_keyboard":true,"one_time_keyboard":false}'

send_all "I am waked up!"
send_all "Waiting for your command, bro" -d "reply_markup=${keyboard}"

offset=0
if [ -f "$offset_file" ]; then
	offset=$( cat $offset_file )
else
	echo $offset > $offset_file
fi

while sleep 1; do
	updates=$($GET $API/getUpdates?offset=$offset)
	status=$(jq -s "$updates" -e $.ok)
	if [ $status = 'true' ]; then
		update_ids=$(jq -s "$updates" -e $.result[*].update_id)
		for update_id in $update_ids; do
			offset=$((update_id+1))
			echo $offset > $offset_file
			origin=$(jq -s "$updates"  -e "$.result[@.update_id=$update_id].message.chat.id")
			msg_id=$(jq -s "$updates"  -e "$.result[@.update_id=$update_id].message.message_id")
			command=$(jq -s "$updates" -e "$.result[@.update_id=$update_id].message.text")
			is_a_cmd=$(jq -s "$updates" -e "$.result[@.update_id=$update_id].message.entities[*].type")
			query_ans=$(jq -s "$updates" -e "$.result[@.update_id=$update_id].callback_query.id")
			origin_ans=$(jq -s "$updates"  -e "$.result[@.update_id=$update_id].callback_query.message.chat.id")
			if [[ "$origin" != "$RUPOR" && "$origin_ans" != "$RUPOR" ]];then
				$POST $API/sendMessage -d reply_to_message_id=$msg_id -d chat_id=$origin -d parse_mode=Markdown --data-urlencode text="This is a Private bot." >/dev/null 2>&1
				$POST $API/leaveChat -d chat_id=$origin >/dev/null 2>&1
			else
				if [ "$is_a_cmd" ==  "bot_command" ]; then
					cmd=$(echo $command |  awk '{print $1}')
					DATE=`date +%Y-%m-%d_%H:%M:%S`
					case "$cmd" in
						("/guard")
							echo "[ $DATE ] Run /guard command !" | logger -t "telegram_bot" -p daemon.info
							informex_guard=$("tg_guard.sh")
							reply $msg_id $origin "\${informex_guard}"
							;;
						("/menu")
							echo "[ $DATE ] Run /menu command !" | logger -t "telegram_bot" -p daemon.info
							$POST $API/sendMessage -d chat_id=$RUPOR -d "reply_markup=${keyboard}" -d "text=Please insert command:" >/dev/null 2>&1
							;;
						("/reboot")
							echo "[ $DATE ] Run /reboot command !" | logger -t "telegram_bot" -p daemon.info
							informex_reboot=$("tg_reboot.sh")
							reply $msg_id $origin "\${informex_reboot}"
							;;
						("/relay")
							echo "[ $DATE ] Run /relay command !" | logger -t "telegram_bot" -p daemon.info
							informex_relay=$("tg_relay.sh")
							reply $msg_id $origin "\${informex_relay}"
							;;
						("/snap")
							echo "[ $DATE ] Run /snap command !" | logger -t "telegram_bot" -p daemon.info
							informex_system=$("tg_snap.sh")
							reply $msg_id $origin "\${informex_system}"
							;;
						("/system")
							echo "[ $DATE ] Run /system command !" | logger -t "telegram_bot" -p daemon.info
							informex_system=$("tg_system.sh")
							reply $msg_id $origin "\${informex_system}"
							;;
						(*)
							echo "[ $DATE ] $cmd command not enabled" | logger -t "telegram_bot" -p daemon.info
							informex_unknown="This command is not enabled."
							reply $msg_id $origin "\${informex_unknown}"
							;;
					esac
				#else
				#	$POST $API/sendMessage -d reply_to_message_id=$msg_id -d chat_id=$origin -d parse_mode=Markdown --data-urlencode text="Is not a command." >/dev/null 2>&1
				fi
			fi
		done
	fi
done &
