#!/bin/bash

PHOTO_PATH=$1
TOKEN=$(cat token)
CHAT_IDS=$(cat chats)


for chat_id in ${CHAT_IDS}; do
  curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendPhoto" \
          -F chat_id=${chat_id} \
          -F photo="@${PHOTO_PATH}"
done

