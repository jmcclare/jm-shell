#! /bin/bash

#
# Our custom bash prompt styles.
#
# By default, this sets our very informative extensive prompt style.
#
# Commands:
#   prompt_on - sets our 'extensive' prompt style, the default
#   prompt_off - sets our 'minimal' prompt style, good for troubleshooting,
#       low-res or legacy terminals.
#
# To set other styles, change the $PROMPT_STYLE variable, like so:
#
#   PROMPT_STYLE=kirby
#
# Available prompt styles:
#
#   extensive - our default, highly informative prompt
#   minimal - nothing but a black and white dollar sign
#   kirby - an ASCII art Kirby that dances as you enter commands
#   erection - an erection that grows boundlessly as you enter commands
#   divider - an early version of extensive. similar, but less features.
#

#
# Some prompt styles taken and modified from the following:
#
# Emilis Dambauskas:
#   http://emilis.github.com/2011/09/12/customized-bash-prompt.html
# Tom Ryder:
#   http://blog.sanctum.geek.nz/bash-prompts/
# /r/linux:
#   http://www.reddit.com/r/linux/comments/w8nrk/bash_prompts/
# /r/commandline:
#   http://www.reddit.com/r/commandline/comments/rgsad/better_prompt_with_lots_of_information_and_title/
#


#
# Colors can be found here under "ANSI colours":
#   http://www.pixelbeat.org/docs/terminal_colours/
#
# Further color resources:
#   http://blog.sanctum.geek.nz/bash-prompts/
#   https://wiki.archlinux.org/index.php/Color_Bash_Prompt
#
#   When using color codes in your PS1, make sure you surround them with the
#   delimiters \[ and \]
#   These mark whatever they surround as non-printing characters. If you don't
#   use these, you will see odd bugs whenever something needs to reposition the
#   cursor, like when doing a history search with Ctrl-r.
#


#
# Determine this file’s location.
#
# Based on a StackExchange answer: https://unix.stackexchange.com/a/351658
# Plus the bash variable is set using this answer’s technique:
# https://unix.stackexchange.com/a/153061
#
JMSHELL_MAIN="${BASH_SOURCE[0]}"
JMSHELL_DIR="$(cd "$(dirname "${JMSHELL_MAIN}")" && pwd)"
unset JMSHELL_MAIN


function prompt_main {
    #
    # Properly set our standard $PROMPT_COMMAND.
    #

    # Ensure the prompt style begins set to extensive (my favourite).
    #
    # You can switch to another style at any time by setting the PROMPT_STYLE
    # variable to its name. See prompt_command() for the proper names.
    #PROMPT_STYLE=extensive

    # Reset this again here to make sure it doesn’t have ignorespace. We will
    # make sure commands beginning with a space are not saved permanently in
    # the history file. We can’t have ignorespace here or we won’t be able to
    # detect commands with a space when we are saving the shell log file or
    # redrawing the last command in the extensive style. We filter commands
    # starting with a space out of the history file when we manually remove
    # duplicates from it.
    HISTCONTROL=ignoredups:erasedups

    PROMPT_COMMAND='prompt_command'

    if [ ! -z "${DESK_NAME}" ]
    then
        (prompt_log_shell_command "# New shell opened for desk ${DESK_NAME}" > /dev/null &)
    else
        (prompt_log_shell_command '# New shell opened.' > /dev/null &)
    fi
}


#
# Outputs a specified length of divider characters.
#
# This does not output any newlines.
#
# $1 - number of characters to output. Defaults to 2
# $2 - divider character to use. Defaults to long dash: ─
# 
function prompt_fill
{
    local length
    local divider

    if [ -z $1 ]; then
        let length=3
    else
        let length=$1
    fi

    if [ -z "${2}" ]; then
        # This character doesn't join seamlessly in terminus or inconsolata
        # fonts.
        #divider='—'
        # This is the character that tmux uses as a window divider.
        divider='─'
    else
        divider=$2
    fi

    while [ "$length" -gt "0" ]
    do
        #fill="-${fill}" # fill with dashes to work on 
        # Use a solid dash
        #fill="─${fill}" # fill with dashes to work on 
        echo -n "${divider}"
        let length=${length}-1
    done
}


#
# Background and setup work for the extensive prompt style.
#
# Gathers some data for variables. Maintains a duplicate-free, merged history
# file.
#
# Other styles are free to call this as well.
#
function prompt_pre_command
{

    #
    # $prompt_enter_seconds is initialized by the debug handler,
    # handle_debug(), right after a prompt command is entered. It gets set to
    # $SECONDS at that instant. The prompt command, and subsequently this
    # function, get called when the command is finished. At this point, we
    # calculate how many seconds passed between entering the command and its
    # completion.
    #
    let last_command_duration=${SECONDS}-${prompt_enter_seconds}


    # We have to explicitly add the running and stopped jobs. Calling the jobs
    # command without options will list all jobs that have changed since you
    # last ran it, not the ones running or suspended right now.
    #
    # The grep expressions leave only the first line of any job listing. This
    # prevents jobs running multi-line commands from having each of their
    # displayed lines counted.
    num_jobs=$(jobs -r | grep '^\[[0-9]*\][ +-]  Running ' | wc -l | tr -d " ")
    let num_jobs=${num_jobs}+$(jobs -s | grep '^\[[0-9]*\][ +-]  Stopped ' | wc -l | tr -d " ")


    # If this is an xterm set the title to user@host:dir
    #case "$TERM" in
    #xterm*|rxvt*)
        #local bname=`basename "${PWD/$HOME/~}"`
        #echo -ne "\033]0;${bname}: ${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007"
        #;;
    #*)
        #;;
    #esac


    # Set the title to user@host:dir for any TERM type, including screen and
    # tmux
    #local bname=`basename "${PWD/$HOME/~}"`
    #echo -ne "\033]0;${bname}: ${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007"
    # Set just a user@hostname"path string
    echo -ne "\033]0;${USER}@${HOSTNAME}:${PWD/$HOME/~}\007"


    #
    # Update history file and append new items from it.
    #

    # Make sure the history file and its directory exist.
    if [ ! -d "$(dirname "${HISTFILE}")" ]
    then
        touch "$(dirname "${HISTFILE}")"
    fi
    if [ ! -f "${HISTFILE}" ]
    then
        touch "${HISTFILE}"
    fi

    # This little trick runs the commands silently in the background in a
    # subshell that will not report jobs to this one.
    # NOTE: Unfortunately, the subshell also does not have access to this
    # shell's history.
    #bash -c 'history -a 1>/dev/null & history -n 1>/dev/null &'

    # This is a clever way to run things in the background without getting
    # background job messages, but it's actually running the commands in a
    # subshell, so they will not record and update the current shell's history.
    #(history -a &) 1>/dev/null
    #(history -n &) 1>/dev/null


    # Sadly, our only choice is to run these in sequence.
    #history -a 1>/dev/null
    #history -n 1>/dev/null

    #
    # Updated based on the following:
    #
    # * http://unix.stackexchange.com/questions/18212/bash-history-ignoredups-and-erasedups-setting-conflict-with-common-history
    # * https://ss64.com/bash/history.html
    # * http://wiki.bash-hackers.org/internals/shell_options
    # * https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html
    #

    # Append the history lines not already read from the history file to the
    # current history list.
    #history -n

    # Write out the current history to the history file.
    #history -w

    # Take history lines from the current shell that have not yet been appended
    # to the history file and append them to the history file.
    #
    # history -n has the odd side effect of placing history from other shells
    # ahead after the current shell's history items. I frequently hit 'up' to
    # repeat a command only to get a command from another shell.
    #
    # Using this instead will at least place the last command from the current
    # shell at the end of the history list.
    #
    # Thankfully, this is somehow smart enough not to write the current shell's
    # history to the history file over and over. It seems to only write lines
    # from the current shell that have not already been written to the file.
    # This is probably because of the erasedups option I add to the HISTCONTROL
    # environment variable in prompt_main.
    #
    # This only prevents duplicate entries in the current shell's list. It does
    # not clear duplicates in the history file when it appends its list there.
    # To clear those, you need to run the awk command below either periodically
    # (cron job), after each command or when a new shell is created.
    if (("$(wc -l "${HISTFILE}" | awk '{ print $1 }')" == 0))
    then
        # Edge case: If the history file is empty, use the -w (write) command.
        # -a seems to do nothing in this case.
        history -w
    else
        history -a
    fi

    # Remove duplicate entries from the history file.
    #
    # Unfortunately, this must either be run when a new shell is created,
    # periodically (cron job), or after each command to keep the history free
    # of duplicates.
    #
    # Running it periodically will waste time when no user has been entering
    # commands. I zealously run it after each command. Running it when a new
    # interactive shell is opened is probably wisest.
    #
    # Command based on: http://stackoverflow.com/a/1444448
    # We use a temp file because awk does not get in-place editing until
    # version 4.1.0 (May 2013).
    # $HISTFILE is usually ~/.bash_history
    # This has one small problem. It leaves the first instance of any command.
    # This is annoying when you want to hit the up arrow or use reverse history
    # search to find the exact command you just entered.
    #awk '!x[$0]++' $HISTFILE > ~/tmp/bash_history_no_dupes && mv ~/tmp/bash_history_no_dupes $HISTFILE

    if ! which tac > /dev/null 2>&1
    then
        # For systems without the tac command (Mac OS) use a sed command that does the same thing.
        #
        # From StackOverflow: https://stackoverflow.com/a/744093
        tac_cmd='sed 1!G;h;$!d'
    else
        tac_cmd='tac'
    fi

    # cat the history file in reverse line order to a temp file
    #$tac_cmd $HISTFILE > ~/tmp/bash_history_reversed
    # remove duplicates from the temp file and dump them to another temp file
    #awk '!x[$0]++' ~/tmp/bash_history_reversed > ~/tmp/bash_history_no_dupes
    # cat the reversed de-duped temp file in reverse line order back into the
    # history file (overwriting it)
    #$tac_cmd ~/tmp/bash_history_no_dupes > $HISTFILE

    # Better method of the above with secure temp file and no intermediate
    # files for reversing.
    hsttmp=$(mktemp -q /tmp/XXXXXXXX)
    # Reverse the line order of the bash history file.
    # Have awk remove duplicate lines.
    # have grep filter out lines that start with spaces.
    # Switch it back to original order and output to a temp file.
    # Overwrite $HISTFILE with the temp file.
    if [ -f $hsttmp ]
    then
        $tac_cmd $HISTFILE | awk '!x[$0]++' | grep -E '^[^ ]' | $tac_cmd > $hsttmp && mv $hsttmp $HISTFILE

        # Run this in a background shell to speed things up a tiny bit.
        (chmod go-rwx $HISTFILE &) 1>/dev/null
    fi

    # Clear the current shell’s history.
    history -c

    # Read the history file and append its contents to the current shell’s
    # history.
    history -r

    #
    # If you don’t want to use a separate command like awk with a temp file,
    # you should be able to accomplish the same thing with the following.
    #
    # XXX: This method will not work. See the notes below by `history -w`
    #
    # Make sure your `~/.bashrc`, has the following:
    #   
    #   HISTCONTROL=ignoreboth:erasedups
    #   shopt -s histappend
    #
    # In your `$PROMPT_COMMAND`, do the following.
    #
    #   history -a; history -c; history -r; history -w; history -c; history -r
    #
    # This will give you a current (in the current shell’s history buffer) and
    # stored (in the history file) history with everything from the past and
    # other shells, then the command you just entered, with any previous
    # duplicates of that command (and any duplicates) removed.
    #
    # Here is how it works.
    #
    # `HISTCONTROL=ignoreboth:erasedups` — `ignoreboth`: `ignorespace`, don’t
    #   record commands starting with a space anywhere, and `ignoredups`,
    #   ignore lines that match the previous history entry (in the current
    #   shell). `erasedups`: erase any previous duplicates of each history
    #   entry when saving the current history to the file with `history -w`.
    #
    # `shopt -s histappend` — Append the current shell’s history to the history
    #   file when the shell exits. This is probably not necessary when you are
    #   using `history -a` or `history -w`, but I leave it just in case; it’s
    #   harmless.
    #
    # `history -a` — Append any unsaved lines in the history buffer to the
    #   history file. This puts the command you just entered after any commands
    #   that have been recently saved from other shells. This does not trigger
    #   `erasedups`.
    #
    # `history -c; history -r` — Clear the history buffer and reload it from
    #   the file. This updates the history buffer with the full history from
    #   the file, including any commands that were saved to the history file
    #   from other shells.
    #
    # `history -w` — Write the full history buffer from the file. This triggers
    #   `erasedups`, which will erase any previous duplicates of the last
    #   command (or any commands) from the history file. It does not erase any
    #   duplicates from the current history buffer.
    #   
    #   XXX: It turns out that history -w does not crawl through your entire
    #   history file and remove duplicates. This was probably intended for
    #   performance reasons, but it means the method I use above with another
    #   command to filter that file is the only one that will work.
    #
    #   Depending on how `history -w` worked, this method could be more
    #   efficient than what I’m using, but that’s a moot point.
    #
    # The `; history -c; history -r` at the end serves only to have any
    # duplicates of the previous command removed from your current shell’s
    # history buffer. They will already be removed from the history file. To do
    # this, it re‐reads the file after `history -w` clears the duplicates. For
    # performance reasons, you can skip this last part. Any duplicate of the
    # previous command will still be in your shell’s history buffer only until
    # after you enter your next command.
    #


    # Set variables to get the current cursor position. This helps when the
    # cursor is not bumped down to a new clean line after cancelling a command
    # and we end up drawing the prompt after the ^C. A prompt that starts with
    # a full line divider will run over onto the next line.
    #
    # From: http://stackoverflow.com/a/2575525
    # based on a script from http://invisible-island.net/xterm/xterm.faq.html
    #
    # XXX: Disabled because it was preventing tmux from attaching properly.
    #exec < /dev/tty
    #oldstty=$(stty -g)
    #stty raw -echo min 0
    ## on my system, the following line can be replaced by the line below it
    #echo -en "\033[6n" > /dev/tty
    ## tput u7 > /dev/tty    # when TERM=xterm (and relatives)
    #IFS=';' read -r -d R -a pos
    #stty $oldstty
    ## change from one-based to zero based so they work with: tput cup $row $col
    #PRE_PROMPT_CURSOR_ROW=$((${pos[0]:2} - 1))    # strip off the esc-[
    #PRE_PROMPT_CURSOR_COL=$((${pos[1]} - 1))
    #
    # Some other attempts.
    # XXX: Do NOT experiment with this without testing by opening a new
    # terminal. You could leave your shell completely borked.
    #PRE_PROMPT_CURSOR_COORDS="`tput u7`"
    #dummy="`echo -en '\033[6n'; IFS=';' read -r -d R -a PRE_PROMPT_CURSOR_COORDS`"
    #PRE_PROMPT_CURSOR_ROW=$((${PRE_PROMPT_CURSOR_COORDS[0]:2} - 1))    # strip off the esc-[
    #PRE_PROMPT_CURSOR_COL=$((${PRE_PROMPT_CURSOR_COORDS[1]} - 1))
}


function prompt_post_command
{
	# set a harmless local dummy variable to keep this function from being
	# blank.
	local a=0

	# We were manually calling _z here, but it is better to let z’s setup #
	# script append the proper call to _z to $PROMPT_COMMAND after this ps1 config #
	# sets it. That happens in ~/.bashrc where we source this before z’s setup
	# script.
}


#
# Log the last command to the shell log file.
#
# This file differs from the history in that it stores the date, command, and
# the directory the shell was in when the command was run.
#
# You should run this in handle_debug() when promp_debug_marks is 0 to capture
# the path the shell was at before any directory changes caused by the command.
# You should also run it in the background because it’s fine in a subshell and
# nothing else depends on it.
#
function prompt_append_shell_log
{
    local current_command_entry="$(history 1)"


    # for debugging
    #if [[ "${prompt_in_exit_trap}" = '0' ]]
    #then
        #echo "In prompt_append_shell_log called by exit trap. DESK_NAME: ${DESK_NAME}, current_command_entry: ${current_command_entry}" >> /tmp/shell-log-debug
    #fi

    # for debugging
    #env >> /tmp/shell-log-debug
    # Output ALL shell veriables but not defined functions
    #( set -o posix ; set ) >> /tmp/shell-log-debug

    # For debugging
	#echo "In prompt_append_shell_command, history 1: ${current_command_entry}" >> /tmp/shell-log-debug
	#echo "In prompt_append_shell_command, BASH_HISTORY: ${BASH_HISTORY}" >> /tmp/shell-log-debug


    # Only log after the first command in a shell has been entered. Otherwise
    # this will re‐log the last command placed in the history by some other
    # shell session.
	#
	# NOTE: This shouldn’t get called while $prompt_new_shell is still 0
	# because the debug_handler should set it to 1 before this.
	if [[ "${prompt_new_shell}" = '0' ]]
	then
		return
	fi

    # This is how I test to see if the exit keyboard shortcut was entered
    # (Ctrl-d). I don’t know how to test for that directly, but this is what
    # $BASH_COMMAND gets set to after it’s entered.
    if [[ "${BASH_COMMAND}" = '[ "$SHLVL" = 1 ]' ]]
    then
        # Change the command entry to logout, but add a note in a comment.
        (prompt_log_shell_command 'logout  # Used <Ctrl-d>.' > /dev/null &)
        return
    fi

    # Do not log commands that start with a space. This is part of how we
    # manually enforce bash’s ignorespace HISTCONTROL option by default.
    if echo "${current_command_entry}" | grep -Eq '^ *[0-9]+   '
    then
		# for debugging
		#echo "command starting with a space found at $(date)" >> /tmp/shell-log-debug
        return
    fi

    if [[ "${BASH_COMMAND}" = 'prompt_command' ]]
    then
        # For debugging
        #echo "$(date) blank command entered" >> /tmp/shell-log-debug

        (prompt_log_shell_command '# Blank command entered.' > /dev/null &)
        return
    fi


    #
    # If we’ve made it here, we’re handling the regular, numbered command we
    # fetched from the history.
    #

    # Remove the leading command number before logging.
    # Use -E instead of -r for portability. See `man sed` on GNU Linux systems
    # for more.
    current_command_entry="$(echo "${current_command_entry}" | sed -E 's/^ *[0-9]+ +//')"

	(prompt_log_shell_command "${current_command_entry}" > /dev/null &)
}


#
# Command that actually writes an entry to the shell log file.
#
# Parameters:
#
#   $1 — string — command text to log
#
# A new log entry with the following format will be added:
#
#   $(date)<Tab>${PWD}<Tab>${1}
#
# This assumes the command text has any leading space or command numbers from
# the output of `history` already removed. It logs the command text as‐is.
#
function prompt_log_shell_command
{
    if [ -z "${1}" ]
    then
        return
    fi

    if [ ! -z "${BASHSHELLLOGFILE}" ]
    then
        local bash_shell_logfile="${BASHSHELLLOGFILE}"
    else
        local bash_shell_logfile=~/.local/share/bash/shell.log
    fi

    if [ ! -d "$(dirname "${bash_shell_logfile}")" ]
    then
        mkdir -p "$(dirname "${bash_shell_logfile}")"
    fi

    if [ -z "${BASHSHELLLOGFILELEN}" ]
    then
        if [ -z "${HISTFILESIZE}" ]
        then
            BASHSHELLLOGFILELEN=10000

        elif (("${HISTFILESIZE}" >= 0))
        then
            BASHSHELLLOGFILELEN=$HISTFILESIZE
        else
            BASHSHELLLOGFILELEN=10000
        fi
    fi

    if (("${BASHSHELLLOGFILELEN}" > 0))
    then
        echo "$(date)	${PWD}	${1}" >> "${bash_shell_logfile}"

        #
        # Trim the file.
        #
        # The -i option’s usage is completely incompatible between BSD and GNU
        # sed. Worse, the BSD version of sed in Mac OS leaves dotfiles behind
        # and does not clean them up.
        #
        # To avoid a slow, hacky way of detecting BSD sed (I was grepping the
        # man page) I am using the same work around for both environments. I
        # manually output to a temp file, then move the temp file to the
        # original after sed is finished. This is what the -i option does.
        #
        # Here is the equivalent GNU sed command using the -i option:
        #
        #    sed --in-place= -e :a -e '$q;N;'"${BASHSHELLLOGFILELEN}"',$D;ba' "${bash_shell_logfile}"
        #
        sed -e :a -e '$q;N;'"${BASHSHELLLOGFILELEN}"',$D;ba' "${bash_shell_logfile}" > "${bash_shell_logfile}".tmp; mv "${bash_shell_logfile}".tmp "${bash_shell_logfile}"

    elif [[ ${BASHSHELLLOGFILELEN} == 0 ]]
    then
        if [ -f "${bash_shell_logfile}" ]
        then
            rm "${bash_shell_logfile}"
        fi
    fi
}


#
# Called just before $PS1 (the prompt) is displayed.
#
# Do some necessary backgorund work and set the prompt to whatever
# $PROMPT_STYLE specifies.
#
# Initialize this to Bash’s true to tell anything concerned that this is a
# newly opened interactive shell. We set this to false at the end of
# prompt_command.
prompt_new_shell=0
function prompt_command
{
    # Local variables shared by functions called by this one.
    local num_jobs
    local last_command_duration

    #
    # My debug handler, handle_debug(), gets called a few times from entering a
    # prompt command to the display of the next prompt after the command exits.
    # It increments $prompt_debug_marks to track which stage of the prompt
    # process it is being called at. prompt_command() is only called once
    # before the new prompt is displayed, so I reset $prompt_debug_marks here.
    #
    let prompt_debug_marks=0

    # Set $PS1 according to what $PROMPT_STYLE is set to. We either set $PS1
    # directly here, or call a function that sets it and also runs the pre and
    # post commands.
    #
    # TODO: Create new styles:
    #   * extensive-mono
    #   * extensive-dark — for light backgrounds
    #
    case "${PROMPT_STYLE}" in
        standard|default) prompt_standard_style ;;
        standard-mono|default-mono) prompt_standard_mono_style ;;
        tweaked) prompt_tweaked_style ;;
        extensive) prompt_extensive_style ;;
        fast) PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ ' ;;
        fast-mono) PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ ' ;;
        minimal) PS1='\$ ' ;;
        kirby) prompt_kirby_style ;;
        erection) prompt_erection_style ;;
        divider) prompt_divider_style ;;
        *) prompt_extensive_style ;;
    esac

    # After the first prompt_command has been run we no longer consider the
    # shell new. Mark this as Bash’s false.
    prompt_new_shell=1
}


function prompt_git
{
    git branch &>/dev/null || return 1
    HEAD="$(git symbolic-ref HEAD 2>/dev/null)"
    BRANCH="${HEAD##*/}"
    [[ -n "$(git status 2>/dev/null | \
        grep -E 'working (directory|tree) clean')" ]] || STATUS="!"
    printf '(git:%s)' "${BRANCH:-unknown}${STATUS}"
}
function prompt_hg
{
    hg branch &>/dev/null || return 1
    BRANCH="$(hg branch 2>/dev/null)"
    [[ -n "$(hg status 2>/dev/null)" ]] && STATUS="!"
    printf '(hg:%s)' "${BRANCH:-unknown}${STATUS}"
}
function prompt_svn
{
    svn info &>/dev/null || return 1
    URL="$(svn info 2>/dev/null | \
        awk -F': ' '$1 == "URL" {print $2}')"
    ROOT="$(svn info 2>/dev/null | \
        awk -F': ' '$1 == "Repository Root" {print $2}')"
    BRANCH=${URL/$ROOT}
    BRANCH=${BRANCH#/}
    BRANCH=${BRANCH#branches/}
    BRANCH=${BRANCH%%/*}
    [[ -n "$(svn status 2>/dev/null)" ]] && STATUS="!"
    printf '(svn:%s)' "${BRANCH:-unknown}${STATUS}"
}
function prompt_vcs
{
    prompt_git || prompt_svn || prompt_hg
}


#
# Sets $PS1 to the default bash color prompt style.
#
# This is meant to be run as the last step of $PROMPT_COMMAND.
#
function prompt_standard_style
{
    prompt_pre_command

    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

    prompt_post_command
}


#
# Sets $PS1 to the default bash color prompt style.
#
# This is meant to be run as the last step of $PROMPT_COMMAND.
#
function prompt_standard_mono_style
{
    prompt_pre_command

    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '

    prompt_post_command
}




#
# Sets $PS1 to our tweaked style.
#
# This is meant to be run as the last step of $PROMPT_COMMAND.
#
function prompt_tweaked_style
{
    prompt_pre_command

    # The \j shows the number of background jobs.
    PS1='[\j] ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

    prompt_post_command
}


#
# Sets $PS1 to nothing but a grey dollar sign prompt.
#
# This is meant to be run as the last step of $PROMPT_COMMAND.
#
function prompt_minimal_style
{
    prompt_pre_command

    PS1='\$ '

    prompt_post_command
}


#
# Sets $PS1 to our extensive style.
#
# This is meant to be run as the last step of $PROMPT_COMMAND.
#
function prompt_extensive_style
{
    prompt_pre_command

    # max before displaying elapsed time
    local elapsed_threshold=4
    # max before displaying system load average
    local load_threshold_1=1
    # max before displaying system load average highlighted
    local load_threshold_2=4

    PS1=''
    local fillsize=${COLUMNS}
    local fill=''


    # Define some color shortcuts
    source "${JMSHELL_DIR}"/colors.sh

    local divider_color="\[${IBlack}\]"
    local jobs_color="\[${Green}\]"
    if [[ $PROMPT_STYLE == 'extensive-dark' ]]
    then
        local location_color="\[${Blue}\]"
        local prompt_color="\[${BBlue}\]"
    else
        local location_color="\[${Yellow}\]"
        local prompt_color="\[${BYellow}\]"
    fi
    local ro_location_color="\[${Color_Off}\]"


    # Add the last command's exit status, if not zero.
    #
    # We set $prompt_last_exit_status in prompt_handle_debug.
    if [ ! $prompt_last_exit_status -eq 0 ]
    then
        local exit_status="─── exit: \[${BRed}\]${prompt_last_exit_status} ${divider_color}"
        # Make this unstyled version so we can count the characters accurately
        # for the fill
        local exit_status_base="─── exit: ${prompt_last_exit_status} "
        let fillsize=${fillsize}-${#exit_status_base}
    fi


    # Add the last command's elapsed runtime if it is >= the threshold (above).
    if [ ! -z "${last_command_duration}" ] && ((${last_command_duration} > ${elapsed_threshold}))
    then
        # Calculate seconds, minutes, hours and remainders
        local elapsed_s=${last_command_duration}
        local elapsed_sr=$(expr ${elapsed_s} % 60)
        local elapsed_m=$(expr ${elapsed_s} / 60)
        local elapsed_mr=$(expr ${elapsed_m} % 60)
        local elapsed_h=$(expr ${elapsed_m} / 60)
        local elapsed_hr=$(expr ${elapsed_h} % 24)
        local elapsed_d=$(expr ${elapsed_h} / 24)

        local elapsed_time=''
        if ((${elapsed_d} > 0)); then
            elapsed_time="${elapsed_d}d,${elapsed_hr}h,${elapsed_mr}m,${elapsed_sr}s"
        elif ((${elapsed_h} > 0)); then
            elapsed_time="${elapsed_h}h,${elapsed_mr}m,${elapsed_sr}s"
        elif ((${elapsed_m} > 0)); then
            elapsed_time="${elapsed_m}m,${elapsed_sr}s"
        else
            elapsed_time="${elapsed_s}s";
        fi
        elapsed_time="─── ${elapsed_time} "

        let fillsize=${fillsize}-${#elapsed_time}
    fi


    # Show the system load average from the past five minutes if it's >= the
    # threshold (above). Highlight the number if it's >= the second threshold.

    if [ -f /proc/loadavg ]
    then
        local load_stat=$(cut -d' ' -f1 /proc/loadavg)
        local int_load_stat=$(echo $load_stat | cut -d. -f1)
    else
        # Load average cannot be retrieved on this system. Fill in harmless
        # values that will not trigger status output.
        local load_stat='1.00'
        local int_load_stat=${load_threshold_1}
    fi

    if ((${int_load_stat} > ${load_threshold_1}))
    then
        local load_stat_color=${divider_color}
        if ((${int_load_stat} > ${load_threshold_2}))
        then
            load_stat_color="\[${Red}\]"
        fi
        local load_base="─── load: ${load_stat} "
        local load="─── load: ${load_stat_color}${load_stat}${divider_color} "
        let fillsize=${fillsize}-${#load_base}
    fi


    # Show the current battery level and activity, if less than 100%

    # Make sure acpi is installed.
    #
    # Some versions of which output to stderr when a command is not found, so
    # make sure that is silent too.
    if which acpi > /dev/null 2>&1
    then
        local battery_level="$(acpi 2> /dev/null | head -n 1 | awk '{print $4}' | tr -d " " | tr -d "," | tr -d "%")"
        # On systems that have acpi installed, but not power_supply status
        # supported, it will only output errors. Check for this.
        if [ ! -z "${battery_level}" ]
        then
            local batt_activity="$(acpi | cut -d' ' -f3 | cut -d, -f1 | head -n 1)"

            if [ ${batt_activity} = "Charging" ]
            then
                batt_arrow='↑'
            elif [ ${batt_activity} = "Discharging" ]
            then
                batt_arrow='↓'
            fi

            # Make this unstyled version so we can count the characters accurately
            # for the fill
            local battery_icon_base=''
            local battery_icon=''

            local batt_standard_color="\[${IGreen}${On_Green}\]"
            local batt_arrow_standard_color="\[${Color_Off}${Green}\]"
            local batt_low_color="\[${IYellow}${On_Yellow}\]"
            local batt_arrow_low_color="\[${Color_Off}${Yellow}\]"
            local batt_critical_color="\[${IRed}${On_Red}\]"
            local batt_arrow_critical_color="\[${Color_Off}${Red}\]"

            case "${battery_level}" in
                100)    battery_icon="" ;;
                9[0-9])
                    battery_icon_base="█${batt_arrow}"
                    battery_icon="${batt_standard_color}█${batt_arrow_standard_color}${batt_arrow}${divider_color}" ;;
                8[0-9])
                    battery_icon_base="▇${batt_arrow}"
                    battery_icon="${batt_standard_color}▇${batt_arrow_standard_color}${batt_arrow}${divider_color}" ;;
                7[0-9])
                    battery_icon_base="▆${batt_arrow}"
                    battery_icon="${batt_standard_color}▆${batt_arrow_standard_color}${batt_arrow}${divider_color}" ;;
                6[0-9])
                    battery_icon_base="▅${batt_arrow}"
                    battery_icon="${batt_standard_color}▅${batt_arrow_standard_color}${batt_arrow}${divider_color}" ;;
                5[0-9])
                    battery_icon_base="▄${batt_arrow}"
                    battery_icon="${batt_standard_color}▄${batt_arrow_standard_color}${batt_arrow}${divider_color}" ;;
                4[0-9])
                    battery_icon_base="▃${batt_arrow}"
                    battery_icon="${batt_low_color}▃${batt_arrow_low_color}${batt_arrow}${divider_color}" ;;
                3[0-9])
                    battery_icon_base="▂${batt_arrow}"
                    battery_icon="${batt_low_color}▂${batt_arrow_low_color}${batt_arrow}${divider_color}" ;;
                *)
                    battery_icon_base="▁${batt_arrow}"
                    battery_icon="${batt_critical_color}▁${batt_arrow_critical_color}${batt_arrow}${divider_color}" ;;
            esac
            if [ ! "${battery_icon_base}" = "" ]
            then
                battery_icon_base='─── '${battery_icon_base}' '
                battery_icon='─── '${battery_icon}' '
            fi
            let fillsize=${fillsize}-${#battery_icon_base}
        fi
    fi


    # Add an indicator if we are currently running Midnight Commander
    if [ ! -z "${MC_SID}" ]
    then
        local mc_base="─── MC "
        local mc="─── \[${BCyan}\]MC${divider_color} "
        let fillsize=${fillsize}-${#mc_base}
    fi


    # Add an indicator if we are inside a Vim shell
    if [ ! -z "${VIM}" ]
    then
        local vim_base="─── Vim "
        local vim="─── \[${BGreen}\]Vim${divider_color} "
        let fillsize=${fillsize}-${#vim_base}
    fi


    # Add an indicator if we are in a desk
    if [ ! -z "${DESK_NAME}" ]
    then
        local desk_base="─── desk: ${DESK_NAME} "
        local desk="─── desk: \[${BBlue}\]${DESK_NAME}${divider_color} "
        let fillsize=${fillsize}-${#desk_base}
    fi


    # Add an indicator if we are in a Python virtualenv
    if [ ! -z "${VIRTUAL_ENV}" ]
    then
        if [[ $PROMPT_STYLE == extensive-dark ]]
        then
            # One of the official Python colours
            #local py_symbol_color=$BBlue
            #local virtualenv_name_color=$Blue

            # Typical reptilian green
            local py_symbol_color=$BGreen
            local virtualenv_name_color=$Green
        else
            # Official Python colours
            #local py_symbol_color=$BBlue
            #local virtualenv_name_color=$Yellow

            # Typical reptilian green
            local py_symbol_color=$BGreen
            local virtualenv_name_color=$Green
        fi

        local virtualenv_name="$(basename $VIRTUAL_ENV)"

        if [ -z "${PROMPT_VENV_INDICATOR}" ]
        then
            #PROMPT_VENV_INDICATOR='🐍'
            # The clever snake unicode character (🐍) was causing problems because
            # different terminal emulators handle it differently. In some you
            # need to count it as 2 characters for spacing and add an extra
            # space to $virtualenv_base. In others it only takes up 1. Some
            # terminal and font combinations don’t even render extended
            # characters like this.
            #
            # I changed the default to V for “virtual environment”.
            PROMPT_VENV_INDICATOR='V'
        fi

        local virtualenv_base="─── ${PROMPT_VENV_INDICATOR}${PROMPT_VENV_INDICATOR_PADDING} ${virtualenv_name} "
        local virtualenv="─── \[${py_symbol_color}\]${PROMPT_VENV_INDICATOR} \[${virtualenv_name_color}\]${virtualenv_name}${divider_color} "
        let fillsize=${fillsize}-${#virtualenv_base}
    fi


    # Show the date and time
    local datetime="─── "$(/bin/date +"%a %b %d, %H:%M:%S")
    let fillsize=${fillsize}-${#datetime}


    # Add a bit of extra divider to the start of the line
    local divider_indent="──────"
    let fillsize=${fillsize}-${#divider_indent}

    fill="$(prompt_fill ${fillsize})"


    # move the cursor left 2 spaces to account for a possible ^C cancel code at
    # the start of the line.
    echo -ne "\033[2D"
    #
    # That had the slight disadvantage of wiping out the ^C in some cases. It's
    # good to be able to scroll back and see that in the output to know how the
    # command was terminated.
    # Better way. Use the $PRE_PROMPT_CURSOR_COL variable we set in prompt_command to detect this.
    # NOTE: I went back to the simple method above because the method I had for
    # getting the cursor position gave me no output when I attached to a tmux
    # session. I was lucky it didn't kill output altogether for basic terminal
    # sessions.
    #if [ "$PRE_PROMPT_CURSOR_COL" -gt "0" ]; then
        ## move the cursor left $COL spaces to account for a possible ^C cancel code.
        ##echo -ne "\033[${COL}D"

        ## Better, simply move down one line so we don't (again) overwrite the
        ## ^C. It's useful to see it.
        #echo
    #fi

    # Add the divider/status line
    PS1=${PS1}${divider_color}${divider_indent}${exit_status}${elapsed_time}${fill}${mc}${vim}${desk}${virtualenv}${load}${battery_icon}${datetime}


    # Start next line and reset fillsize
    PS1=${PS1}"\n${location_color}"
    fillsize=${COLUMNS}


    # Show the number of running background jobs, if any.
    if ((${num_jobs} > 0))
    then
        local jobs="${jobs_color}[${num_jobs}] ${location_color}"
        # Make this unstyled version so we can count the characters accurately
        # for the fill
        local jobs_base="[${num_jobs}] "
        let fillsize=${fillsize}-${#jobs_base}
    fi


    # Get the current dir with $HOME abbreviated as ~
    local sedhome=$(printf "%s\n" "$HOME" | sed 's/[][\.*^$(){}?+|/]/\\&/g')
    local current_dir=$(pwd | sed "s/${sedhome}/~/g")


    # Add the user@host:path text

    # Mark the current directory in a different color if it is read-only.
    local current_dir_color
    if [[ -w "${PWD}" ]]
    then
        current_dir_color="${location_color}"
    else
        current_dir_color="${ro_location_color}"
    fi

    local current_location_base="${USER}@${HOSTNAME}:${current_dir}"
    local current_location="${USER}@${HOSTNAME}:${current_dir_color}${current_dir}${location_color}"
    let fillsize=${fillsize}-${#current_location_base}


    # Add the number of items in current dir (files, directories, symlinks)

    # We discard error output from ls because it's almost always harmless;
    # usually from corrupted files and mount points.
    #
    # The -1 option ensures `wc -l` gets each entry on a single line.
    # The -A option tells it to list files starting with a '.', but not the
    # implied '.' and '..'.
    # The -U option tells it to list files in their default directory order. No
    # sorting. This gives much better performance when we're only looking for a
    # count anyway.
    local fcount=$(/bin/ls -1AU 2>/dev/null | /usr/bin/wc -l | sed 's: ::g')

    # This isn't necessary with the -A option above.
    #let fcount=${fcount}-2

    fcount="   ${fcount} items"
    let fillsize=${fillsize}-${#fcount}


    # NOTE: Diabled because it’s not very useful. Kept here for reference.
    # # Add the total size of files in the current dir
    # 
    # # We discard error output from ls because it's almost always harmless;
    # # usually from corrupted files and mount points.
    # #
    # # The -l option displays files with details in a list. We filter out the
    # # total shown on the first line.
    # #
    # # This older version used an overly fancy grep command to do what `head -n
    # # 1` can.
    # #local fsize=$(/bin/ls -lAUh 2>/dev/null | /bin/grep -m 1 total | sed "s/total //")
    # local fsize=$(/bin/ls -lAUh 2>/dev/null | /usr/bin/head -n 1 | sed "s/total //")
    # fsize=", ${fsize}"
    # let fillsize=${fillsize}-${#fsize}


    # Add version control system status for the current directory (if any).
    local vcs_base="$(prompt_vcs)"
    local vcs="${vcs_base}"
    if [ ! -z $vcs_base ]
    then
        # Add some space, to the front, now that we know we're displaying
        # something.
        vcs_base="  ${vcs_base}"
        vcs="${vcs_base}"
        let fillsize=${fillsize}-${#vcs_base}
    fi


    fill="$(prompt_fill ${fillsize} ' ')"


    # Add the current location/status line
    if ((${fillsize} >= 0))
    then
        PS1=${PS1}"${jobs}${current_location}${fcount}${fsize}${vcs}${fill}"
    else
        # move the path down to it's own line

        current_location_base="${USER}@${HOSTNAME}"
        current_location="${current_location_base}"
        let fillsize=${COLUMNS}-${#jobs_base}-${#current_location_base}-${#fcount}-${#fsize}-${#vcs_base}
        fill="$(prompt_fill ${fillsize} ' ')"

        PS1=${PS1}"${jobs}${current_location}${fill}${fcount}${fsize}${vcs}"
        PS1=${PS1}"\n"
        PS1=${PS1}${current_dir}
    fi


    # Set it to the regular text colour (Color_Off) before the newline so that
    # the next line is marked with regular text colour instead of whatever we
    # left it on above. Otherwise the cursor will be drawn with those colors,
    # despite what we end the prompt with.
    PS1=${PS1}"\[${Color_Off}\]\n${prompt_color}\$\[${Color_Off}\] "


    export PS1


    # Unset our color shortcut variables
    source "${JMSHELL_DIR}"/colors_unset.sh

    prompt_post_command
}


#
# Sets a stylized prompt with a divider above it:
#
function prompt_divider_style
{
    prompt_pre_command
    
    # Emilis' original status line
    #PS1="$status_style"'$fill \t\n'"$PROMPT_STYLE"'${debian_chroot:+($debian_chroot)}\u@\h:\w [\j]\$'"$command_style "
    
    # Our status line adds a few more placements of style variables and the current
    # number of running processes.

    # Use the $PRE_PROMPT_CURSOR_COL variable we set in prompt_command to
    # detect a possible ^C at the start of the line.
    #if [ "$PRE_PROMPT_CURSOR_COL" -gt "0" ]; then
        ## Simply move down one line so we don't start drawing the divider on
        ## the same line as the ^C or overwrite it. It's useful to see it.
        #echo
    #fi
    
    local fill='$(let fillsize=${COLUMNS}-21; prompt_fill ${fillsize})'

    # Set some styles
    local reset_style='\[\033[00m\]'
    local status_style=$reset_style'\[\033[0;90m\]' # gray color; use 0;37m for white
    #local PROMPT_STYLE=$reset_style
    local PROMPT_STYLE='\[\033[0;33m\]'	# orange
    #local credentials_style='\[\033[0;32m\]'	# regular green
    local credentials_style='\[\033[0;31m\]'	# orange
    local hostname_style='\[\033[0;33m\]'	# orange
    local path_style='\[\033[0;34m\]'	# blue
    local processes_style='\[\033[0;32m\]'	# blue
    #local command_style=$reset_style'\[\033[1;29m\]' # bold white
    #local command_style=$reset_style'\[\033[1;33m\]' # bold yellow
    local command_style=$reset_style

    # grey style
    PS1=${status_style}${fill}' \d, \t\n'"$PROMPT_STYLE"'${debian_chroot:+($debian_chroot)}\u@\h'"$PROMPT_STYLE"':'"$PROMPT_STYLE"'\w'"$PROMPT_STYLE"' [\j]\$'"$command_style "

    # colourful style
    #PS1=${status_style}${fill}' \d, \t\n'"$credentials_style"'${debian_chroot:+($debian_chroot)}\u@\h'"$PROMPT_STYLE"':'"$path_style"'\w'"$PROMPT_STYLE"' ['"$processes_style"'\j'"$PROMPT_STYLE"']\$'"$command_style "
    
    prompt_post_command
}


#
# Sets a ridiculous dancing Kirby prompt.
#
function prompt_kirby_style
{
    prompt_pre_command

    #uncomment one of the KIRBY_FRAMES
    KIRBY_FRAMES=("<('.'<)" "^('.')^" "(>'.')>" "^('.')^")
    #KIRBY_FRAMES=("٩(●̮̮̃•̃)۶" "٩(-̮̮̃-̃)۶" "٩(͡๏̯͡๏)۶" "٩(-̮̮̃•̃)۶" "٩(×̯×)۶")
    #KIRBY_FRAMES=("<('o'<)  " "^( '-' )^" " (>‘o’)> " "v( ‘.’ )v" "<(' .' )>" "<('.'<)  " "^( '.' )^" " (>‘.’)> " "v( ‘.’ )v" "<(' .' )>")
    export PS1="\[\033[00;93m\]${KIRBY_FRAMES[KIRBY_IDX]}\[\033[00m\] $ORIG_PS1"; export KIRBY_IDX=$(expr $(expr $KIRBY_IDX + 1) % ${#KIRBY_FRAMES[@]})

    prompt_post_command
}


#
# Turns your prompt into a growing erection.
#
ERECTION_SIZE=0
prompt_erection_style () {
    prompt_pre_command

    local erection="8"
    for ((i=0; i<$ERECTION_SIZE; i++))
    do
        erection="${erection}="
    done
    erection="${erection}D"

    ERECTION_SIZE=$((${ERECTION_SIZE}+1))

    export PS1=$erection" "

    prompt_post_command
}


#
# Our DEBUG signal handler.
#
# After a command is entered, re-draw it in bold and reset the color for the
# command output.
#
# We're hacking a bit here in that we're not actually using this signal to
# print or record debugging information. We're using this signal to run
# commands right after a command is entered on the command line.
#
# We initialize some variables below, and we also modify some of them in
# prompt_command.
#
# Initialize these for our $PROMPT_HANDLER and DEBUG signal handler
prompt_enter_seconds=0
# Initialize this to 2 so that our handle_debug will not do anything after
# ~/.bashrc loads this file. Our $PROMPT_COMMAND will initialize it properly to
# 0 when it is first displayed.
prompt_debug_marks=2
# Initialize this.
prompt_last_exit_status=0
function prompt_handle_debug
{
    local current_last_exit_status=$?
    #echo "in handle_debug: $?, debug_marks: $prompt_debug_marks"
    # For debugging
    #local current_command_entry="$(history 1)"
	#echo "In handle_debug, history 1: ${current_command_entry}, prompt_debug_marks: ${prompt_debug_marks}" >> /tmp/shell-log-debug
	#echo "In handle_debug, BASH_HISTORY: ${BASH_HISTORY}, prompt_debug_marks: ${prompt_debug_marks}" >> /tmp/shell-log-debug

    # We reset $prompt_debug_marks in our $PROMPT_COMMAND (see prompt_command,
    # above). It is initialized to 2 when this files is sourced (above) to
    # prevent any of this code from running when the prompt is first creatd.
    #
    # The first debug call after $PROMPT_COMMAND runs is the one right after a
    # command is entered on the command line. It used to be the second because
	# I was running z’s command after the $PROMPT_COMMAND. Now _z is run in the
	# background after prompt_command.
    if [ "$prompt_debug_marks" = "0" ]
    then
        # Mark the seconds on the prompt timer that the last command was
        # entered. $prompt_enter_seconds is initialized to 0 in main().
        prompt_enter_seconds=${SECONDS}

        # This is done here to capture the path the shell was at before any
        # directory changes caused by the command.
        if [[ "${prompt_in_exit_trap}" = '0' ]]
        then
            local a=0

            # For debugging
            echo "In prompt_handle_debug during exit trap, DESK_NAME: $DESK_NAME, current_command: $current_command_entry, BASH_COMMAND: $BASH_COMMAND" >> /tmp/shell-log-debug
        else
            (prompt_append_shell_log > /dev/null &)
        fi

        #
        # Redraw the entered command in bold yellow for the "extensive" prompt
        # style only. We test for blank here because extensive is the default.
        #
        if [[ $PROMPT_STYLE == extensive || $PROMPT_STYLE == extensive-dark || $PROMPT_STYLE == '' ]]
        then
            #
            # If a blank command was entered, ${BASH_COMMAND} will remain set to
            # the last command run in this shell, which will be prompt_command in
            # our configuration.  Check for that before digging out the last
            # history command and re-printing it.
            #
            if [ ! "${BASH_COMMAND}" = "prompt_command" ]
            then
                # Move the cursor back up to the previous line and re-draw the command
                # in bold yellow

                # move up one line
                echo -ne '\033[1A'
                # move the cursor right two spaces - not needed because we're
                # re-drawing the prompt now.
                #echo -ne '\033[2C'
                # get the command just entered into the history
                local command=$(echo "$(history | tail -n1)" | sed 's/[ ]*[0-9]*  //')

                # change the color to the appropriate command color
                #
                # I can’t get the colors set properly here with the variables
                # in colors.sh, so I have to echo the escape codes this way.
                if [[ $PROMPT_STYLE == extensive-dark ]]
                then
                    # Change to bold blue
                    echo -ne '\033[1;34m'
                else
                    # Change to bold yellow
                    echo -ne '\033[1;33m'
                fi

                # Get the prompt symbol for this user (# for root, $ otherwise)
                if [ "${UID}" = "0" ]
                then
                    local prompt_symbol="#"
                else
                    local prompt_symbol="$"
                fi
                # re-write the command
                echo -n "${prompt_symbol} ${command}"

                # reset the color for command output
                echo -ne "\033[0m"

                # move the cursor down 1 line
                echo -ne '\033[1B'
                local shift_length=0
                # Get the length of the prompt + command
                let shift_length=2+${#command}
                # move the cursor left shift_length spaces
                echo -ne "\033[${shift_length}D"
            fi
        else
            # Reset the colors for the command output.
            echo -ne "\033[0m"
        fi
    fi

    if [ "$prompt_debug_marks" = "1" ]
    then
        # This should capture the correct last exit status. We want the exit
        # status set by the command that was entered and not by any parts of
        # PROMPT_COMMAND. Normally, the command is entered. The DEBUG signal
        # handler is called (this function), the command exits, the DEBUG
        # signal handler is called again.
        #
        # Note that this requires our prompt_command function to be the last
        # thing called before the prompt is shown. If you add other things to
        # your PROMPT_COMMAND they must either come before the call to
        # PROMPT_COMMAND, or be run in a subshell, ie. `(some_command >
        # /dev/null)`.
        prompt_last_exit_status=$current_last_exit_status
    fi

    # test output for debugging
    #echo -n " debug marks: ${prompt_debug_marks}"

    let prompt_debug_marks=${prompt_debug_marks}+1
}
trap 'prompt_handle_debug' DEBUG


function prompt_handle_exit
{
    # For debugging
    #current_command_entry="$(history 1)"
    #echo "In prompt exit trap, DESK_NAME: $DESK_NAME, current_command: $current_command_entry, BASH_COMMAND: $BASH_COMMAND" >> /tmp/shell-log-debug
    #echo "In prompt exit trap, DESK_NAME: $DESK_NAME" >> /tmp/shell-log-debug


    if [ ! -z "${DESK_NAME}" ]
    then
        # for debugging
        #echo "In prompt_append_shell_log called by exit trap. DESK_NAME: ${DESK_NAME}" >> /tmp/shell-log-debug

        (prompt_log_shell_command "# Exited shell for desk ${DESK_NAME}" > /dev/null &)
    else
        (prompt_log_shell_command "# Exited shell." > /dev/null &)
    fi
}
# The only thing that seems to set off this `exit` signal is exiting a Desk
# session.
#
# The exit handler has to run in a subshell like this (in round brackets) or
# you will get an extra, duplicate command entry logged. Running it in the
# background is not strictly necessary, but it helps a tiny bit for
# performance.
trap '(prompt_handle_exit > /dev/null &)' exit


prompt_main "${@}"
