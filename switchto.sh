#!/bin/bash
XDOTOOL=$(which xdotool)
WMCTRL=$(which wmctrl)

containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

DID=$(${WMCTRL} -d | grep -E "^[0-9]  \*" | awk '{print $1}')
APD=($(${WMCTRL} -l | grep -iE "${1}" | awk '{print $2}'))



# APD could output multiple lines if there are multiple instances loaded (on different or the same desktop), so we need to know if there is an instance on THIS
# desktop
if containsElement "${DID}" "${APD[@]}"; then
  ACTWINTITLE=$(${XDOTOOL} getactivewindow getwindowname)
  #if $1 appears in ACTWINTITLE then toggle maximize restore?
  ISACTIVEWINDOW=$(echo ${ACTWINTITLE} | grep -iE "${1}")
  # we will need this whatever happens
  # we COULD just ${WMCTRL} -a ${1} here, but that could reference the instance on another desktop, and it seems likely, that if
  # we are activing a program, we want the instance on THIS desktop, so lets find a reference to it, and activate that.
  WID=$(${WMCTRL} -l | grep -E "[0-9]x[0-9a-z]{8}\s\s${DID}" | grep -iE "${1}" | awk '{print $1}')
  
  # uncomment this if you want it to toggle maximized / restored when you hit the hotkey and the window is already active

  #if [[ ! -z "${ISACTIVEWINDOW}" ]]; then
  #  ${WMCTRL} -i -r ${WID} -b toggle,maximized_vert,maximized_horiz
  #fi
  ${WMCTRL} -i -a ${WID}
 else
   # the application is running, but not on this desktop, so launch another
   ${3} &
fi
