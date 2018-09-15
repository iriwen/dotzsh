__cursor_pos () {
  local pos
  exec {tty}<>/dev/tty
  echo -n '\e[6n' >&$tty; read -rsdR pos <&$tty
  exec {tty}>&-
  [[ $pos =~ '([0-9]+);([0-9]+)$' ]]
  print $match[1] $match[2]
}

__calc_height () {
  local pos
  typeset -i height left want
  pos=($(__cursor_pos))
  left=$(( LINES - pos[1] ))
  want=$(( LINES * 0.4 ))
  if (( left > want )); then
    height=$left
  else
    height=$want
  fi
  height=$(( height + 1)) # the prompt line is used too
  print $height
}

sk-vim-mru () {
  local file cmd
  cmd=${1:-vim}
  file=$(tail -n +2 ~/.vim/vim_mru_files | \
    sk --height $(__calc_height) --reverse -p "$cmd> ")
  if [[ -n $file ]]; then
    ${=cmd} $file
  else
    return 130
  fi
}

sk-search-history () {
  local cmd
  # TODO: preview at the right, multi-line, syntax-highlighted
  cmd=$(history -n 1 | \
    sk --height $(__calc_height) --reverse -p 'cmd> ')
  if [[ -n $cmd ]]; then
    BUFFER=$cmd
    (( CURSOR = $#BUFFER ))
    zle redisplay # for syntax highlight
  fi
}

sk-cd () {
  local dir
  dir=$(sort -nr ~/.local/share/autojump/autojump.txt | \
    awk '{print $2}' | \
    sk --height $(__calc_height) --reverse -p 'cd> ')
  if [[ -n $dir ]]; then
    zle push-line
    zle redisplay
    BUFFER="cd ${(q)dir}"
    zle accept-line
  else
    zle redisplay
  fi
}

if (( $+commands[sk] )); then
  zle -N sk-cd
  bindkey "\esd" sk-cd

  zle -N sk-search-history
  bindkey "\esr" sk-search-history

  vim-mru () { sk-vim-mru }
  if (( $+commands[vv] )); then
    vv-mru () { sk-vim-mru vv }
  fi

  if [[ -f /usr/share/skim/completion.zsh ]]; then
    . /usr/share/skim/completion.zsh
  fi
fi

# vim: se ft=zsh:
