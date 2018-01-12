#!/bin/bash
XDOTOOL=$(which xdotool)
WMCTRL=$(which wmctrl)
GREP=$(which grep)
AWK=$(which awk)
PIDOF=$(which pidof)
SED=$(which sed)

DID=$(${WMCTRL} -d | ${GREP} -E "^[0-9]  \*" | ${AWK} '{print $1}')
APD=($(${WMCTRL} -l | ${GREP} -iE "${1}" | ${AWK} '{print $2}'))

# Thanks to http://hacking.elboulangero.com/2015/12/06/bash-logging.html for this
log()     { [[ -t 1 ]] &&     echo "$@" || logger -t $(basename $0) "$@"; }
log_err() { [[ -t 2 ]] && >&2 echo "$@" || logger -t $(basename $0) -p user.err "$@"; }

#TODO make the logger commands only log if a certain flag is set.
log "switchto launched with ${1} and ${3}"

PIDS=$(${PIDOF} ${1} | ${SED} 's/\s/|/g')

log "PIDS is $PIDS"
WID=$(${WMCTRL} -lp | ${GREP} -E "[0-9]x[0-9a-z]{8}\s\s${DID}" | ${GREP} -iE "${1}" | ${GREP} -E " ${PIDS} " | ${AWK} '{print $1}')
log "WID is ${WID}"
if [[ ! -z $WID ]]; then 
  log "Got the WID of a suitable candidate, switching to that"
  
  # switch to the window we found
  ${WMCTRL} -i -a ${WID}
 else
   # the application is running, but not on this desktop, so launch another
   log "The application is running but on a different desktop, so run it on this one"
   ${3} &
fi
