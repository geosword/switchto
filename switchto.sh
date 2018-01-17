#!/bin/bash
# FOR THE BASH SCRIPT
# $1 is the string to look for in the title of windows
# $2 is unused (but must be a value), it used to be, but I havent changed how this program is launched in my keyboard shortcuts, so remains for the time being.
# $3 is the program to launch if switchto.sh doesnt find $1 in any windows on the current desktop


# FOR THE FUNCTION:
# $1 is the list of PIDS we need to make sure we're grepping the right window IDs
# $2 is the string to grep for in the titlebar of the windows.
# $3 is the desktop id on which to search
function switchfocus {
	# ${3}|
	WID=$(${WMCTRL} -lp | ${GREP} -E "[0-9]x[0-9a-z]{8}\s(-1|\s${3})" | ${GREP} -iE "${2}" | ${GREP} -E " ${1} " | ${AWK} '{print $1}')
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

PIDS=$(${PIDOF} ${3} | ${SED} 's/\s/|/g')

if [[ ! -z ${PIDS} ]]; then
	log "PIDS is $PIDS" 
	switchfocus ${PIDS} ${1} ${DID};
	if [ "$?" = "1" ]; then
		# it all went well
		log "Switched to the window for ${1} on ${DID}"
		exit 0
	fi
fi

# hack for multiple sublime instances. By Default sublime will only load one instance of the editor. As such, if you are on a desktop without an active sublime instance, it will simply put focus on the instance on the other desktop (assuming it exists) cheerfully leaving you on the sublime-less desktop. This hack loads a new instance on the current desktop
# remove this while if block if you dont use sublime
if [[ -z $WID ]]; then
	log "Checking if its sublime or not"
	BINNAME=$(basename ${3})
	log "Binname is ${BINNAME}"
	if [ "${BINNAME}" = "subl3" ]; then
	# it is sublime, so we'll launch a new instance here with the new instance flag, and then make a call switch to it
		log "Launching sublime with -n"
		/usr/bin/subl3 -n &
		# now switch to it. We need to wait for it to load though
		# TODO this is crude.
		sleep 0.25 
		switchfocus ${PIDS} ${1} ${DID}
		exit 0
	fi
fi
# its something else that can launch multiple instances without pointless command line switches
# the application is either not running, or not on this desktop, so launch another
log "The application is running but on a different desktop, so run it on this one"
${3} &
