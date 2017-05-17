#!/bin/bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ${BASEDIR}
# ZSH
ln -s ${BASEDIR}/.zshrc ~/.zshrc

# Vim
ln -s ${BASEDIR}/.vimrc ~/.vimrc

# Tmux
ln -s ${BASEDIR}/.tmux.conf ~/.tmux.conf
ln -s ${BASEDIR}/.tmuxinator.zsh ~/.tmuxinator.zsh
