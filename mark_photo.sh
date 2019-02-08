#!/bin/bash

# exec >>/tmp/mark-photo.log 2>&1
# set -x

PHOTO_PATH="$1"
CAM="$2"

echo "file '${PHOTO_PATH}'" >>/tmp/camera-${CAM}-images.txt
