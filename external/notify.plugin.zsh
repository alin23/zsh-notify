# vim: set nowrap filetype=zsh:
#
# See README.md.
#
fpath=($fpath $(dirname $0:A))

zstyle ':notify:*' resources-dir $(dirname $0:A)/resources
zstyle ':notify:*' parent-pid $PPID

# Notify an error with no regard to the time elapsed (but always only
# when the terminal is in background).
function notify-error {
    local title
    title="$1"
    session="$2"
    window="$3"
    pane="$4"
    notify-if-background error "$title" "$iterm_session" "$tmux_session" "$tmux_window" "$tmux_pane" < /dev/stdin &!
}

# Notify of successful command termination, but only if it took at least
# 30 seconds (and if the terminal is in background).
function notify-success() {
    local now diff start_time last_command command_complete_timeout title

    start_time=$1
    last_command="$2"
    title="$3"
    now=`date "+%s"`

    zstyle -s ':notify:' command-complete-timeout command_complete_timeout \
        || command_complete_timeout=30

    ((diff = $now - $start_time ))
    if (( $diff > $command_complete_timeout )); then
        notify-if-background success "$title" "$iterm_session" "$tmux_session" "$tmux_window" "$tmux_pane"<<< "$last_command" &!
    fi
}

# Notify about the last command's success or failure.
function notify-command-complete() {
    last_status=$?
    if [[ $last_status -gt "0" ]]; then
        notify-error "$title" "$iterm_session" "$tmux_session" "$tmux_window" "$tmux_pane" <<< $last_command
    elif [[ -n $start_time ]]; then
        notify-success "$start_time" "$last_command" "$title" "$iterm_session" "$tmux_session" "$tmux_window" "$tmux_pane"
    fi
    unset last_command start_time last_status title iterm_session tmux_session tmux_window tmux_pane
}

function store-command-stats() {
    last_command=$1
    start_time=`date "+%s"`
    if [[ `uname` == "Darwin" ]]; then
        iterm_session=`osascript -e 'tell application "iTerm" to get id of current session of current window'`
    fi

    if [[ -n "$TMUX" ]]; then
        tmux_session=`tmux display-message -p '#S'`
        tmux_window=`tmux display-message -p '#I'`
        tmux_pane=`tmux display-message -p '#D'`
    fi

    if [[ `uname` == "Darwin" ]]; then
        title=`osascript -e 'tell application "iTerm" to get name of current session of current window'`
    fi
    if [[ -n "$TMUX" ]]; then
        title=`tmux display-message -p '#W'`
    fi
}

if [[ -z "$PPID_FIRST" ]]; then
  export PPID_FIRST=$PPID
fi

autoload add-zsh-hook
autoload -U notify-if-background
add-zsh-hook preexec store-command-stats
add-zsh-hook precmd notify-command-complete
