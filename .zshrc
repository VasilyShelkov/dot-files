# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export TERM='xterm-256color'

# ZSH has a spelling corrector
setopt CORRECT

# Path to your oh-my-zsh installation.
export ZSH=/Users/vasilyshelkov/.oh-my-zsh
export PGDATA='/usr/local/var/postgres'
export PGHOST=localhost
export PATH="$PATH:`yarn global bin`"

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="agnoster"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  zsh-nvm
  command-not-found
  git
  history
  nvm
  sudo
  themes
  web-search
  zsh-syntax-highlighting
  yarn
  yarn-autocompletions
  tmuxinator
  docker
  encode64
)

export EDITOR="vim"
export USE_EDITOR=$EDITOR
export VISUAL=$EDITOR

source $ZSH/oh-my-zsh.sh

# User configuration
function get_pwd(){
  git_root=$PWD
  while [[ $git_root != / && ! -e $git_root/.git ]]; do
    git_root=$git_root:h
  done
  if [[ $git_root = / ]]; then
    unset git_root
    prompt_short_dir=%~
  else
    parent=${git_root%\/*}
    prompt_short_dir=${PWD#$parent/}
  fi
  echo $prompt_short_dir
}

# The prompt
PROMPT='$ret_status %{$fg[white]%}$(get_pwd) $(git_prompt_info)%{$reset_color%}%{$reset_color%} '

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[cyan]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[yellow]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}✓%{$reset_color%}"

alias ev='vim ~/.vimrc'
alias ez='vim ~/.zshrc'
alias et='vim ~/.tmux.conf'
alias ete='vim ~/.tern-config'
alias mux='tmuxinator'

export NVM_DIR="/Users/vasilyshelkov/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

source ~/.tmuxinator.zsh

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# key mappings have changed in iterm settings as well
bindkey "^[a" beginning-of-line
bindkey "^[e" end-of-line
