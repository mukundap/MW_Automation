#!/bin/sh

set -e
set -o xtrace


CURRENT_TIME=$(date "+%Y-%m-%dT%H:%M:%S")
OUTPUT=~/Vrr_Automation/logs/refresh_rate_60.log

touch $OUTPUT

lsb_release -a 2>&1 >> $OUTPUT

echo "" >> $OUTPUT

echo "KERNEL:"  `uname -r` >> $OUTPUT

echo "" >> $OUTPUT

echo "MESA:"  `glxinfo | grep "renderer" ` >> $OUTPUT
echo "" >> $OUTPUT

output_capable=$(drm_info | grep "vrr_capable" | grep "= 1" )

vrr_capable_DRM_PROPERTY=$(echo "$output_capable" | grep -oP '= \K\d+')

if [ $vrr_capable_DRM_PROPERTY -eq 0 ]; then
  exit 1  #FAIL
fi

gsettings set org.gnome.mutter experimental-features "['variable-refresh-rate']"

MANGOHUD_CONFIG=fps_limit=60 mangohud glxgears -fullscreen &

sleep 5

output_enable=$(drm_info | grep "VRR_ENABLED" | grep "= 1" )

VRR_ENABLE_DRM_PROPERTY=$(echo "$output_enable=" | grep -oP '= \K\d+')

echo "The VRR_ENABLE DRM Property value is: $VRR_ENABLE_DRM_PROPERTY" >> $OUTPUT

if [ $VRR_ENABLE_DRM_PROPERTY -eq 0 ]; then
  exit 1  #FAIL
fi

syslog_output=$(grep "FPS" /var/log/syslog | tail -n 2)

Render_Frame_Rate_value=$(echo "$syslog_output" | grep -oP 's: \K\d+')

Flipped_Refresh_Rate_value=$(echo "$syslog_output" | grep -oP 'Rate: \K\d+')

Missed_flips_60=$((Render_Frame_Rate_value - Flipped_Refresh_Rate_value))

`pkill glxgears`
sleep 2

MANGOHUD_CONFIG=fps_limit=90 mangohud glxgears -fullscreen &
sleep 5

VRR_ENABLE_DRM_PROPERTY=$(echo "$output_enable" | grep -oP '= \K\d+')

if [ $VRR_ENABLE_DRM_PROPERTY -eq 0 ]; then
  exit 1  #FAIL
fi

syslog_output=$(grep "FPS" /var/log/syslog | tail -n 2)

Render_Frame_Rate_value=$(echo "$syslog_output" | grep -oP 's: \K\d+')

Flipped_Refresh_Rate_value=$(echo "$syslog_output" | grep -oP 'Rate: \K\d+')

Missed_flips_90=$((Render_Frame_Rate_value - Flipped_Refresh_Rate_value))

`pkill glxgears`
sleep 2

MANGOHUD_CONFIG=fps_limit=120 mangohud glxgears -fullscreen &
sleep 5

VRR_ENABLE_DRM_PROPERTY=$(echo "$output_enable" | grep -oP '= \K\d+')

if [ $VRR_ENABLE_DRM_PROPERTY -eq 0 ]; then
  exit 1  #FAIL
fi

syslog_output=$(grep "FPS" /var/log/syslog | tail -n 2)

Render_Frame_Rate_value=$(echo "$syslog_output" | grep -oP 's: \K\d+')

Flipped_Refresh_Rate_value=$(echo "$syslog_output" | grep -oP 'Rate: \K\d+')

Missed_flips_120=$((Render_Frame_Rate_value - Flipped_Refresh_Rate_value))

`pkill glxgears`

if [ $Missed_flips_60 -le 2 ] && [ $Missed_flips_90 -le 2 ] && [ $Missed_flips_120 -le 2 ]
then
  exit 0  # PASS

else
  exit 1  # FAIL
fi

