#!/bin/bash
XDOTOOL=$(which xdotool)
WMCTRL=$(which wmctrl)
GREP=$(which grep)
AWK=$(which awk)

containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

DID=$(${WMCTRL} -d | ${GREP} -E "^[0-9]  \*" | ${AWK} '{print $1}')
APD=($(${WMCTRL} -l | ${GREP} -iE "${1}" | ${AWK} '{print $2}'))



# APD could output multiple lines if there are multiple instances loaded (on different or the same desktop), so we need to know if there is an instance on THIS
# desktop
if containsElement "${DID}" "${APD[@]}"; then
  # we will need this whatever happens
  # we COULD just ${WMCTRL} -a ${1} here, but that could reference the instance on another desktop, and it seems likely, that if
  # we are activing a program, we want the instance on THIS desktop, so lets find a reference to it, and activate that.
  WID=$(${WMCTRL} -l | ${GREP} -E "[0-9]x[0-9a-z]{8}\s\s${DID}" | ${GREP} -iE "${1}" | ${AWK} '{print $1}')
  
  # uncomment the below you want it to toggle maximized / restored when you hit the hotkey and the window is already active

  #ACTWINTITLE=$(${XDOTOOL} getactivewindow getwindowname)
  #ISACTIVEWINDOW=$(echo ${ACTWINTITLE} | ${GREP} -iE "${1}")

  #if [[ ! -z "${ISACTIVEWINDOW}" ]]; then
  #  ${WMCTRL} -i -r ${WID} -b toggle,maximized_vert,maximized_horiz
  #fi

  # END ncomment the above you want it to toggle maximized / restored when you hit the hotkey and the window is already active

  # switch to the window we found
  ${WMCTRL} -i -a ${WID}
 else
   # the application is running, but not on this desktop, so launch another
   ${3} &
fi
