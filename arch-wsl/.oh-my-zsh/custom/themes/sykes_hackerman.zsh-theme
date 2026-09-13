# sykes_hackerman: the sykes prompt layout with the hackerman palette baked in.
# Standalone (no Omarchy color files or hooks); uses 24-bit colors, so it looks
# the same regardless of the terminal palette.
#
#   brackets  #82FB9C  accent
#   time/path #d1fffe  bright cyan
#   git       #9cf7c2  bright green
#
# Keep in sync with HACKERMAN_WT_SCHEME in archWslSetup.sh and
# arch-wsl/.config/btop/themes/hackerman.theme.

PROMPT='%B%F{#82FB9C}[ %F{#d1fffe}%t %F{#82FB9C}]  [ %F{#d1fffe}%n@%m:%~$(git_prompt_info)$(ruby_prompt_info)%B%F{#82FB9C} ]%f%b
$ '

ZSH_THEME_GIT_PROMPT_PREFIX='%B%F{#9cf7c2}('
ZSH_THEME_GIT_PROMPT_SUFFIX=')%f%b'
ZSH_THEME_GIT_PROMPT_CLEAN="✔"
ZSH_THEME_GIT_PROMPT_DIRTY="✗"
