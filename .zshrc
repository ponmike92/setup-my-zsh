LOGFILE="$HOME/.cache/last_sh_command.log"
touch "$LOGFILE"

# Backup original stdout/stderr
ORIGINAL_STDOUT=$(tty)
ORIGINAL_STDERR=$(tty)

# Log commands and capture output
preexec() {
  # Исключаем из логгирования
  if [[ "$1" =~ ^(c|yazi|aider) ]]; then
    export SKIP_LOGGING=1
    return 0
  fi

  export SKIP_LOGGING=0
  echo "COMMAND: $1" >> "$LOGFILE"
  exec 3>&1 4>&2
  exec 1> >(tee -a "$LOGFILE" > "$ORIGINAL_STDOUT")
  exec 2> >(tee -a "$LOGFILE" > "$ORIGINAL_STDERR")
}

precmd() {
	if [ "$SKIP_LOGGING" != "1" ]; then
		{ exec 1>&3 2>&4; } 2>/dev/null
		{ exec 3>&- 4>&-; } 2>/dev/null
		echo "===== END =====" >> "$LOGFILE"
	fi
	unset SKIP_LOGGING
}

# Copy last command and output
c() {
  awk '
    BEGIN { last_cmd=""; last_output=""; in_output=0 }
    /COMMAND:/ {
      last_cmd=substr($0, index($0,":")+2);
      in_output=1;
      last_output="";
      next;
    }
    in_output && /===== END =====/ { in_output=0; next }
    in_output { last_output = last_output $0 "\n" }
    END {
      printf "%s\n%s", last_cmd, last_output
    }
  ' "$LOGFILE" | pbcopy
}

# PLUGIN MANAGER

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"


# PLUGINS

# load completions
autoload -Uz compinit && compinit -C -i

# plugins
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

# snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git

# replays the installation commands
zinit cdreplay -q


# HISTORY
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no

# Настройка автодополнения по словам
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# Настройка автодополнения по словам при нажатии на стрелку вправо
bindkey '^[[C' forward-word


# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
#zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# ALIASES
#alias y="yazi"
# alias ls="eza --color=always --icons=always --long --no-filesize --no-time --no-user"

ls() {
    if [[ "$1" == "-l" || "$1" == "-la" ]]; then
        eza --color=always --icons=always --long --no-filesize --no-time "$@"
    else
        eza --color=always --icons=always --long --no-filesize --no-time --no-user --no-permissions "$@"
    fi
}

# tmux: create session or attach to existing
t() {
  if tmux ls &> /dev/null; then
    tmux a
  else
    tmux
  fi
}


alias zi="zoxide edit"
alias a="aider"
alias op='code $(fzf -m --preview="bat --color=always {}")'
alias fzf="fzf -m --preview="bat —-color=always {}
alias fzf='nvim $(fzf -m --preview="bat —-color=always {}")'|
unalias gst
unalias gcmsg
alias gs='git status'
alias gc='git commit --message'
alias code="/usr/local/bin/code -r"


eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

export EDITOR=code

# for yazi to change directory when quit
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# aider
AIDER_CONFIG_PATH=./.config/aider

# default behaviour

eval "$(uv generate-shell-completion zsh)"

# bun completions
[ -s "/Users/ponomi/.bun/_bun" ] && source "/Users/ponomi/.bun/_bun"
