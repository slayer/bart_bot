#!/bin/bash

DIR=$(dirname $BASH_SOURCE)

FILE_PATH=$1
TOKEN=$(cat ${DIR}/token)
CHAT_IDS=$(cat ${DIR}/chats)


for chat_id in ${CHAT_IDS}; do
  curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendVideo" \
          -F chat_id=${chat_id} \
          -F video="@${FILE_PATH}"
done

