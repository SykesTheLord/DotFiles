# Load omarchy-generated 24-bit color variables (written by omarchy-zsh-colors-set hook)
OMARCHY_ZSH_COLORS="$HOME/.config/omarchy/current/zsh-theme-colors.zsh"
if [[ -f "$OMARCHY_ZSH_COLORS" ]]; then
  source "$OMARCHY_ZSH_COLORS"
else
  # Fallback: approximate sykes_custom_theme colors using named ANSI codes
  _BRACKET="%{${fg_bold[blue]}%}"
  _ACCENT="%{${fg[cyan]}%}"
  _GIT="%{${fg_bold[green]}%}"
  _RUBY="%{${fg[yellow]}%}"
  _RESET="%{$reset_color%}"
fi

PROMPT="${_BRACKET}[ ${_ACCENT}%t ${_BRACKET}]  [ ${_ACCENT}%n@%m:%~\$(git_prompt_info)\$(ruby_prompt_info)${_BRACKET} ]${_RESET}
$ "

ZSH_THEME_GIT_PROMPT_PREFIX="${_GIT}("
ZSH_THEME_GIT_PROMPT_SUFFIX=")${_RESET}"
ZSH_THEME_GIT_PROMPT_CLEAN="✔"
ZSH_THEME_GIT_PROMPT_DIRTY="✗"
