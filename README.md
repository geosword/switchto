# switchto.sh
#blah

## Description 

A simple bash script that assists switching between windows in your window manager. It has been extensively tested in KDE, however should work in any window manager.
It works by accepting a string which it uses to search for active windows on the current desktop, once it finds one, it switches focus to that window. 
If such a window cannot be found, then it uses the third parameter to launch a program.

## Example Usage

```
./switchto.sh subl notused /usr/bin/subl
```

This will switch focus to Sublime if its running, if not, it will run it.

Parameter 1 is a string to search open windows for. This is egrepp'd for so you can use regular expressions
Parameter 2 is not used any more (Its a throw back from when xdotool was used to do the switching instead of wmctrl)
Parameter 3 is the program to run if Parameter 1 is not found anywhere in $(wmctrl -l)

It _is_ desktop aware, If Parameter 1 cannot be found on the _current desktop_ it will behave as if it is not running, and therefore run it.

## Requirements

You will need wmctrl and optionally xdotool. Search your distro's package manager for these.

## How To Use

Assign the example command line above to the shortcut keys of your choosing within your Window Manager of choice. For KDE (Plasma) for example:
1. Menu->Custom Shortcuts
2. Edit->New Group (I like to add all my own custom shortcuts into its own group for simple import / export on my laptop for instance )
3. New->Global Shortcut->Command/URL
4. Give it a name
5. Under the trigger tab, assign whatever keyboard shortcut you would like.
6. Under action, use the _full path_ to switchto.sh e.g. /home/geosword/tools/switchto.sh KCalc blah /usr/bin/kcalc
7. Click Apply / Save


Now when you press your hot key, if KCalc is loaded it will switch focus to that window, if not it will run it. Switch focus from that window, press your hotkey once more, and instead of another instance of KCalc, it will switch to the existing one.

## Disabled features

I thought it would be cool if the active window is already the one you are switching to, it would toggle between minimised, maximised and restored.
This proved difficult however, because there is no easy way to detected whether a window is maximised or not. (not impossible, just difficult) So settled for just toggling between maximised and restored. All that said, even after I added it as a feature, I didnt use it anywhere near as much as I thought I would (Mainly because restoring a window is generally a stepping stone to some other end, rather than the goal itself) So I have disabled it. Uncomment it to have that functionality

The code 

```
  #ACTWINTITLE=$(${XDOTOOL} getactivewindow getwindowname)
  #ISACTIVEWINDOW=$(echo ${ACTWINTITLE} | ${GREP} -iE "${1}")

  #if [[ ! -z "${ISACTIVEWINDOW}" ]]; then
  #  ${WMCTRL} -i -r ${WID} -b toggle,maximized_vert,maximized_horiz
  #fi
```

## Final notes

I wrote this because I find Alt-tab switching visually jarring. Also, I didnt want to have to remember a bunch of shortcuts for launching vs switching. Plasma allows switching by hotkey, and launching by another, but not with the same keys. 
I generally assign my most commonly used programs to the [qweasdzxc] key group & combine with Alt+Shift. For example:

* Alt+Shift+A terminal emulator
* Alt+Shift+X Browser
* Alt+Shift+Z Text Editor
* Alt+Shitf+D File Manager

I use these in conjunction with some redefined hot keys for minimize, maximize, switch window to desktop, switch window to screen etc.. 
