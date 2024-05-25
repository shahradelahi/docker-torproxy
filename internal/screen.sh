#!/bin/bash

kill_screen() {
  local _screenName="$1"
  if screen -list | grep -qE "\.$_screenName\t"; then
    log NOTICE "Killing screen session $_screenName"
    screen -S "$(screen -ls | grep -E "\.$_screenName\t" | awk '{print $1}')" -X quit
  fi
}
