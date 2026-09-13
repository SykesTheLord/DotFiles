OMARCHY_ZSH_COLORS="$HOME/.config/omarchy/current/zsh-theme-colors.zsh"

_omarchy_load_colors() {
  if [[ -f "$OMARCHY_ZSH_COLORS" ]]; then
    source "$OMARCHY_ZSH_COLORS"
  else
    _BRACKET="%{${fg_bold[blue]}%}"
    _ACCENT="%{${fg[cyan]}%}"
    _GIT="%{${fg_bold[green]}%}"
    _RUBY="%{${fg[yellow]}%}"
    _RESET="%{$reset_color%}"
  fi
}

_omarchy_rebuild_prompt() {
  PROMPT="${_BRACKET}[ ${_ACCENT}%t ${_BRACKET}]  [ ${_ACCENT}%n@%m:%~\$(git_prompt_info)\$(ruby_prompt_info)${_BRACKET} ]${_RESET}
$ "
  ZSH_THEME_GIT_PROMPT_PREFIX="${_GIT}("
  ZSH_THEME_GIT_PROMPT_SUFFIX=")${_RESET}"
  ZSH_THEME_GIT_PROMPT_CLEAN="✔"
  ZSH_THEME_GIT_PROMPT_DIRTY="✗"
}

# Reload colors and rebuild prompt whenever omarchy-zsh-colors-set updates the file
_omarchy_precmd() {
  local mtime
  mtime=$(stat -c %Y "$OMARCHY_ZSH_COLORS" 2>/dev/null || echo 0)
  if [[ "$mtime" != "$_OMARCHY_COLORS_MTIME" ]]; then
    _OMARCHY_COLORS_MTIME="$mtime"
    _omarchy_load_colors
    _omarchy_rebuild_prompt
  fi
}

_omarchy_load_colors
_omarchy_rebuild_prompt
_OMARCHY_COLORS_MTIME=$(stat -c %Y "$OMARCHY_ZSH_COLORS" 2>/dev/null || echo 0)

add-zsh-hook precmd _omarchy_precmd
