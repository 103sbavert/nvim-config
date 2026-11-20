#!/usr/bin/env zsh
(($#)) || exec zsh
[[ $1 == (--non-interactive|-c) ]] && shift
typeset -g NO_OMZ=1
[[ -r ${ZDOTDIR:-$HOME}/.zshrc ]] && source ${ZDOTDIR:-$HOME}/.zshrc
eval "${1-}"
