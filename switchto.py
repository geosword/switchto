#!/usr/bin/python3
import sys
import re
import subprocess
import argparse
import os.path
import shutil
import logging
import logging.handlers


# the if checks to see if this file is running, or if its being included. If its being included, we dont want to check that parameters have been passed (this is mainly so
# we can import into a testing class)

# POTENTIALLY HELPFULL INFORMATION: you can get the WID of the currently active window with ```xprop -root _NET_ACTIVE_WINDOW```


def whichwmctrl():
    return shutil.which("wmctrl")


def whichxpropbin():
    return shutil.which("xprop")


def wmctrl(params):
    out = subprocess.Popen(
        [_wmctrlbin] + params, stdout=subprocess.PIPE, stderr=subprocess.STDOUT
    )
    return out.communicate()


def xpropbin(params):
    out = subprocess.Popen(
        [_xpropbin] + params, stdout=subprocess.PIPE, stderr=subprocess.STDOUT
    )
    return out.communicate()


def startthis(filetorun):
    commandlist = filetorun.split()
    # check the execurable actually exists
    swlog("startthis: requested starting [" + filetorun + "]")
    if os.path.isfile(commandlist[0]):
        swlog("startthis: starting " + str(commandlist))
        p = subprocess.Popen(commandlist, stdout=None, stderr=None, close_fds=True)


# I do intend on actually having this run wmctrl and return the current desktop id. but for now. It assumes there is only one desktop and you are on it


def currentDesktop():
    swlog("currentDesktop: returning 0 because thats what I do at the moment")
    return 0


def switchToWindow(wid):
    # check the WID actually exists
    # print('switch to window ' + wid)
    swlog("switchToWindow: switching to window with wid [" + wid + "]")
    stdout, stderr = wmctrl(["-i", "-a", wid])


def stringDecode(s):
    return s.decode("utf-8")


def getActiveWID():
    swlog("getActiveWID: getting the active wid from xpropbin")
    # TODO make this function less brittle. e.g. what if the output format of xprop changes? - could probably just search for a regex that matches a hex number
    stdout, stderr = xpropbin(["-root", "_NET_ACTIVE_WINDOW"])
    line = stringDecode(stdout).split()
    # WIDs are returned in hexadecimal, however the output of WIDs in xpropbin vs wmctrl differs slightly:
    # 0x6a00005 xprop
    # 0x06a00005 wmctrl (leading 0 after x)
    # One solution would be to convert the hex number to a decimal, but that would mean conversion to decimal per line on the search functions, and list*Windows functions
    # so instead we're going to add in a leading 0.
    return re.sub(r"^0x", "0x0", line[4])


def listAllWindows():
    swlog("listAllWindows: running wmctrl to get all windows")
    stdout, stderr = wmctrl(["-l", "-G", "-p", "-x"])
    stdout = stringDecode(stdout)
    fields = ["wid", "did", "pid", "hpos", "vpos", "hsize", "vsize", "class"]
    windows = []
    wids = {}
    # NOTE at the moment, the window title is not captured because it generally has spaces in, and we're also splitting on spaces - so it makes getting it hard.
    # My python fu isnt strong enough to get the title, so Im leaving it out. Mainly because we can "search" for windows using "class"
    swlog(
        "listAllWindows: Filtering out the -1 desktop items, and creating the wid index as we go"
    )
    for line in stdout.splitlines():
        window = dict(zip(fields, line.split()))
        # If the desktop ID is -1 then its not actually a window, but a screen (or a plasma "start" bar)
        if int(window["did"]) >= 0:
            windows.append(window)
            wids[window["wid"]] = len(windows) - 1
    return windows, wids


def getByClass(windows, wclass):
    swlog("getByClass: finding windows by class [" + wclass + "]")
    matches = []
    wids = {}
    for i in windows:
        if i["class"].lower() == wclass.lower():
            matches.append(i["wid"])
            wids[i["wid"]] = len(matches) - 1
    if len(matches) > 0:
        swlog("getByClass: returning found matches")
        return matches, wids
    else:
        swlog("getByClass: NO MATCHES found, returning empty list and dictionary")
        return [], {}


def writeClassWids(wclass, wids, path):
    swlog("writeClassWids: Writing wids to " + path + "/" + wclass + ".tmp")
    with open(path + "/" + wclass.lower() + ".tmp", "w") as f:
        for item in wids:
            f.write("%s\n" % item)
    # using 'with' means f will be closed once we're done here (presumably in the function)


# This will will return an mwidx


def loadClassWids(wclass, path):
    swlog("loadClassWids: Loading wids from " + path + "/" + wclass + ".tmp")
    with open(path + "/" + wclass.lower() + ".tmp") as f:
        wids = f.read().splitlines()
    return wids


def swlog(message):
    if args.log:
        log.debug(message)


# compare a list of wids with whats in windows. This is so we can remove any stale wids that might have been read from a (window) class file


def reconcileWids(wids1, wids2):
    # wids1 is the wids from disk, so could be out of date
    # wids2 is from the most recent search so will NOT be out of date
    # TODO There MUST BE an easier way than this!!! we need the intersection of wids1 & wids2 UNION wids2 RETAINING ORDER
    # TODO: Notice that in the second loop, we're appening to wids1, is there a situation where that is NOT appropriate?
    # e.g. The WID that was first is closed, in this instance, it will be tacked on the end.
    # I think thats ok, because then the wid that was second (and presumably still exists) would become first. if the second doesnt exist either, the third, and so on.
    swlog("reconcileWids: checking for stale entries in wids1 based on wids2")
    for i, item in enumerate(wids1):
        if item not in wids2:
            del wids1[i]
    swlog("reconcileWids: checking for missing entries in wids1 based on wids2")
    for item in wids2:
        if item not in wids1:
            wids1.append(item)
    swlog("reconcileWids: creating index for wids1")
    for i, item in enumerate(wids1):
        mwidx[item] = i
    return wids1, mwidx


_wmctrlbin = whichwmctrl
# If __name__ == main is here to see if its being included or run directly. This is so that it can be included in the test scripts.
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="a simple program to output the product of two ini config files, with later files overriding earlier values"
    )
    parser.add_argument(
        "-c",
        "--class",
        required=True,
        dest="wclass",
        help="Window class to search for normally looks like string.string e.g. konsole.konsole",
    )
    parser.add_argument(
        "-e",
        "--exec",
        required=True,
        dest="runprog",
        help="The file to run if no window titles contain the string passed via -t|--title",
    )
    parser.add_argument(
        "-w",
        "--wmctrl",
        required=False,
        dest="wmctrl",
        default=whichwmctrl(),
        help="the full path name to the instance of wmctrl you want to use. defaults to the output of `which wmctrl`",
    )
    parser.add_argument(
        "-x",
        "--xpropbin",
        required=False,
        dest="xpropbin",
        default=whichxpropbin(),
        help="the full path name to the instance of xpropbin you want to use. defaults to the output of `which xpropbin`",
    )
    parser.add_argument(
        "-t",
        "--temp",
        required=False,
        dest="tempdir",
        default="/var/tmp/switchto/",
        help="Path to a directory that switchto can store temporary state information in",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        required=False,
        dest="log",
        action="store_true",
        help="Enables logging",
    )
    args = parser.parse_args()

# _wmctrlbin exists so that we can still run unit tests, although I suspect its mere existence implies im doing something wrong, and there is a better way to do this
_wmctrlbin = args.wmctrl
_xpropbin = args.xpropbin

# initialise the logging
log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)

handler = logging.handlers.SysLogHandler(address="/dev/log")
formatter = logging.Formatter("%(module)s.%(funcName)s: %(message)s")
handler.setFormatter(formatter)

log.addHandler(handler)

swlog(
    "Starting switchto.py with class ["
    + args.wclass
    + "] and executable ["
    + args.runprog
    + "]"
)
# check the temp folder exists, Create it if not
if not os.path.isdir(args.tempdir):
    os.mkdir(args.tempdir)

windows, widx = listAllWindows()

activeWid = getActiveWID()
matchingWindows, mwidx = getByClass(windows, args.wclass)

if len(matchingWindows) == 0:
    swlog("No matching classes, running executable")
    # no matches. We'll go into launching an instance here
    # check if there are any pids with the listed exe first
    # https://stackoverflow.com/questions/3516007/run-process-and-dont-wait#
    startthis(args.runprog)
    sys.exit(0)
else:
    # get the active window
    if len(matchingWindows) > 1:
        swlog("Found multiple matches for class [" + args.wclass + "]")
        activeWid = getActiveWID()
        # check for a temp file with wids for this class. It will give us an ordered list of the previously active wids, so we can cycle through them
        if os.path.isfile(args.tempdir + "/" + args.wclass.lower() + ".tmp"):
            # load the wids into a list
            loadedMatchingWindows = loadClassWids(args.wclass, args.tempdir)
            # then remove any wids we loaded, that no longer exist from the list / might have been created since the last run
            loadedMatchingWindows, mwidx = reconcileWids(
                loadedMatchingWindows, matchingWindows
            )
            # If none of the wids in the tempfile are still current, we'll just carry on using the search results we got earlier
            swlog(
                "This is the list after reconcilliation: " + str(loadedMatchingWindows)
            )
            if len(loadedMatchingWindows) > 0:
                matchingWindows = loadedMatchingWindows
        # only move through the available wids in this class IF the currently active windows class and the desired class is the same
        if windows[widx[activeWid]]["class"] == args.wclass:
            swlog(
                "switching to window with the same wclass ["
                + args.wclass
                + "] so cycling the head"
            )
            # remove the first match from the head of the list
            swlog(
                "popping this off the head of the list ["
                + matchingWindows[mwidx[activeWid]]
                + "]"
            )
            matchingWindows.pop(mwidx[activeWid])
            # Now add it to the end of the list
            matchingWindows.append(activeWid)
        # write the wids back to the tempfile
        writeClassWids(args.wclass, matchingWindows, args.tempdir)

    # Do the switch
    switchToWindow(matchingWindows[0])
sys.exit(0)
