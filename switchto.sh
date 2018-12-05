#!/bin/bash
# FOR THE BASH SCRIPT
# $1 is the string to look for in the title of windows
# $2 is unused (but must be a value), it used to be, but I havent changed how this program is launched in my keyboard shortcuts, so remains for the time being.
# $3 is the program to launch if switchto.sh doesnt find $1 in any windows on the current desktop


# FOR THE FUNCTION:
# $1 is the list of PIDS we need to make sure we're grepping the right window IDs. If this is set to "skip" the PIDS wont be cross referenced. This MIGHT result in incorrect switching,
#	if for example you are editing a document called $2, then switchto might switch to that instead of the application you intended.
# 	This here purely for evolution. I suspect the real cause is running it via flatpak
# $2 is the string to grep for in the titlebar of the windows.
# $3 is the desktop id on which to search
function switchfocus {
	if [[ "${1}" != "skip" ]]; then
		WID=$(${WMCTRL} -lp | ${GREP} -E "[0-9]x[0-9a-z]{8}\s(-1|\s${3})" | ${GREP} -iE "${2}" | ${GREP} -E " ${1} " | ${AWK} '{print $1}')
	 else
		WID=$(${WMCTRL} -l | ${GREP} -E "[0-9]x[0-9a-z]{8}\s(-1|\s${3})" | ${GREP} -iE "${2}" | ${AWK} '{print $1}')
 	fi
	log "WID is ${WID}"
	if [[ ! -z $WID ]]; then 
	  log "Got the WID of a suitable candidate, switching to that"
	  
	  # switch to the window we found
	  ${WMCTRL} -i -a ${WID}
	  return 1
	fi
	return 0
}

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

if [ "${2}" == "skip" ]; then
	PIDS="skip"
 else
	PIDS=$(${PIDOF} ${3} | ${SED} 's/\s/|/g')
fi

if [[ ! -z ${PIDS} ]]; then
	log "PIDS is $PIDS" 
	switchfocus ${PIDS} ${1} ${DID}
	if [ "$?" = "1" ]; then
		# it all went well
		log "Switched to the window for ${1} on ${DID}"
		exit 0
	fi
fi

# its something else that can launch multiple instances without pointless command line switches
# the application is either not running, or not on this desktop, so launch another
log "The application is either not running or running on a different desktop, so run it on this one"
${3} &
