#!/bin/sh

set -e
set -o xtrace


CURRENT_TIME=$(date "+%Y-%m-%dT%H:%M:%S")
OUTPUT=~/Vrr_Automation/logs/disable_vrr.log

touch $OUTPUT

lsb_release -a 2>&1 >> $OUTPUT

echo "" >> $OUTPUT

echo "KERNEL:"  `uname -r` >> $OUTPUT

echo "" >> $OUTPUT

echo "MESA:"  `glxinfo | grep "renderer"` >> $OUTPUT
echo "" >> $OUTPUT

output_capable=$(drm_info | grep "vrr_capable" | grep "= 1" )

vrr_capable_DRM_PROPERTY=$(echo "$output_capable" | grep -oP '= \K\d+')

if [ $vrr_capable_DRM_PROPERTY -eq 0 ]; then
  exit 1  #FAIL
fi

gsettings set org.gnome.mutter experimental-features "[]"

glxgears -fullscreen &
sleep 5

output_enable=$(drm_info | grep "VRR_ENABLED" | head -n 1)

VRR_ENABLE_DRM_PROPERTY=$(echo "$output_enable=" | grep -oP '= \K\d+')

echo "The VRR_ENABLE DRM Property value is: $VRR_ENABLE_DRM_PROPERTY" >> $OUTPUT
echo "" >> $OUTPUT

frame_sync=$(grep "frame_sync_enabled" /var/log/syslog | tail -n 1)
frame_sync_enabled=$(echo "$frame_sync" | grep -oP ' = \K\d+')

`pkill glxgears`

if [ $VRR_ENABLE_DRM_PROPERTY -eq 0 ] && [ $frame_sync_enabled -eq 0 ]; then
  echo "Disable VRR Test case is PASS"
  exit 0  # PASS
else
  echo "Disable VRR Test case is FAIL"
  exit 1  # FAIL
fi

