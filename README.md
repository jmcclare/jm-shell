# jm-shell #

A highly informative, customized Bash shell.

<img src="screenshot.png" />

## Features ##

### Divider / Status  Line ###

This is a dark grey line that divides the last command from the prompt. It also
shows some relevent info about the last command and the current environment.

* helpful colors and divider to separate commands
* time last command finished on the right
* shows error code of last command, if any
* shows total time of last command if over 4 seconds
* indicates if inside Vim, Midnight Commander, Python virtualenv (S), or [Desk](https://github.com/jamesob/desk)
* shows current system load average if over 1, in red if over 2
* shows battery charge status if laptop battery is less than full

### Current Location / Status Line ###

* shows username@hostname:path
* shows number of items in current directory
* path is in grey if not writeable
* path will drop down to the next line if it doesn’t fit
* shows number of background jobs on the left, if any
* gives info on source code repositories if current dir is in one (Subversion, Mercurial, Git)

### Prompt ###

* simple, bold yellow dollar sign
* input is standard grey while typing / autocompleting
* input is redrawn in bold yellow after entering

### Background Jobs ###

It keeps history entries unique, up to date among all open shells and with most
recent commands last (at the bottom). This is better for searching your command
history with the up arrows or `Ctrl-r`.

It also maintains a shell log file in `~/.local/share/bash/shell.log`

The regular bash history file has only unique commands for reverse history
searching. The shell log is a full history of your shell activity for
reference. It also logs a commented command to indicate new shells, closed
shells and blank lines entered.

Shell log entries look like this:

    Sun Apr  8 06:48:19 EDT 2018	/home/jmcclare	nvim ~/.config/user-dirs.dirs 

Each entry lists the time the command was entered, the command’s current
working directory, and the command. The fields are tab separated.

Both the history and the shell log file omit logging commands that begin with a
space. This is the same as Bash’s `ignorespace` or `ignoreboth` options, but it
does this no matter how those are set.

### Other Included Prompt Styles ###

#### standard and standard-mono ####

This is the default Bash prompt style configured in most default `~/.bashrc`
files.

Set `PROMPT_STYLE` to `standard` or `default` for the standard Bash color
prompt. Set it to `standard-mono` or `default-mono` for the non‐color version.

#### fast and fast-mono ####

This  the default Bash color prompt style. Setting this style also skips the
background jobs. It’s a bit better for performance on an overloaded system.

Set `PROMPT_STYLE` to `fast` for the standard Bash color prompt. Set it to
`fast-mono` for the non‐color version.

#### tweaked ####

A slight tweak of the default Bash color prompt style. Unlike the default, it
also runs the background jobs.

#### extensive ####

The style described at the top. This is the default style if you don’t set
`PROMPT_STYLE`.

Set `PROMPT_STYLE` to `extensive-dark` for a dark version that is more legible
on white terminal backgrounds.

#### minimal ####

Nothing but a grey dollar sign prompt. Also doesn’t run the background jobs. A
bit better for performance on an overloaded system.

#### kirby ####

Turns your prompt into a dancing Kirby!

    <('.'<)
    ^('.')^
    (>'.')>
    ^('.')^

#### erection ####

Another not‐so‐useful prompt. I’ll let you guess what it looks like. Don’t use
it for too long or you’ll run out of screen space.

#### divider ####

A divider line prompt similar to the extensive style, but it uses only standard
Bash prompt variables. A bit better for performance than the extensive style.


## Installation ##

Clone this repository into a directory like `~/.local/lib/jm-shell` with:

```bash
git clone git@github.com:jmcclare/jm-shell.git ~/.local/lib/jm-shell
```

Add the following to your `~/.bashrc`

```bash
# Source jm-shell custom prompt if it exists.
if [ -f "$HOME/.local/lib/jm-shell/ps1" ]
then
    source "$HOME/.local/lib/jm-shell/ps1"
fi
```

If you are using anything that adds something to your Bash `$PROMPT_COMMAND`,
like [fzf](https://github.com/junegunn/fzf), make sure you source `ps1` first.
The prompt command this PS1 adds must be the first part of your
`$PROMPT_COMMAND`.


## Configuration ##

You can set one of the other styles any time, or in your `~/.bashrc`, by
setting `PROMPT_STYLE`, like this:

```bash
PROMPT_STYLE=kirby
```

The default prompt style is `extensive`.

You can change the location of the shell log file by setting `$BASHSHELLLOGFILE`.

```bash
BASHSHELLLOGFILE=~/.bash-shell.log
```

The default location is `~/.local/share/bash/shell.log`

The history updater uses the standard Bash variables `HISTFILE`,
`HISTFILESIZE`, and `HISTSIZE`. It behaves as though `HISTCONTROL` is set to
`ignoreboth:erasedups` and it does a better job than both of those options
normally do.
