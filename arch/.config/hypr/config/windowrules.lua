hl.window_rule({
  name = "windowrule-1",
  match = { class = ".*" },
  suppress_event = "maximize",
  opacity = "0.97 override 0.9 override",
})

hl.window_rule({
  name = "windowrule-2",
  match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
  no_focus = true,
})

hl.window_rule({
  name = "windowrule-3",
  match = { class = "^(org.pulseaudio.pavucontrol|blueman-manager|Impala|org.gnome.NautilusPreviewer|Omarchy)$" },
  float = true,
  center = true,
})

hl.window_rule({
  name = "windowrule-4",
  match = { class = "^(org.pulseaudio.pavucontrol|blueman-manager|Impala|org.gnome.NautilusPreviewer)$" },
  size = { 800, 600 },
})

hl.window_rule({
  name = "windowrule-5",
  match = { class = "xdg-desktop-portal-gtk", title = "^(Open.*Files?|Save.*Files?|All Files|Save)" },
  float = true,
  center = true,
})

hl.window_rule({
  name = "windowrule-paradox-launcher",
  match = { class = "Paradox Launcher" },
  float = true,
  center = true,
})

hl.window_rule({
  name = "windowrule-hoi4",
  match = { class = "hoi4" },
  fullscreen = true,
  opacity = "1 1",
})

hl.window_rule({
  name = "windowrule-6",
  match = { class = "steam" },
  float = true,
  opacity = "1 1",
})

hl.window_rule({
  name = "windowrule-7",
  match = { class = "steam", title = "Steam" },
  center = true,
})

hl.window_rule({
  name = "windowrule-8",
  match = { class = "steam_app_0" },
  fullscreen = true,
  opacity = "1 1",
})

hl.window_rule({
  name = "windowrule-9",
  match = { class = "com.libretro.RetroArch" },
  fullscreen = true,
  opacity = "1 1",
})

hl.window_rule({
  name = "windowrule-10",
  match = { class = "^(Chromium|chromium|google-chrome|google-chrome-unstable|zen|firefox)$" },
  opacity = "1 override 0.97 override",
})

hl.window_rule({
  name = "windowrule-11",
  match = { initial_title = "^(youtube.com_/)$" },
  opacity = "1 override 1 override",
})

hl.window_rule({
  name = "windowrule-12",
  match = { class = "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$" },
  opacity = "1 override 1 override",
})

hl.window_rule({
  name = "windowrule-13",
  match = { class = "^(com.libretro.RetroArch|steam)$" },
  opacity = "1 override 1 override",
})

hl.window_rule({
  name = "windowrule-14",
  match = { tag = "pip" },
  float = true,
  pin = true,
  size = { 600, 338 },
  keep_aspect_ratio = true,
  border_size = 0,
  opacity = "1 1",
  move = { "((monitor_w*1)-window_w-40)", "((monitor_h*0.04))" },
})

hl.window_rule({
  name = "windowrule-15",
  match = { class = "org.kde.*", title = "^(Open.*Files?|Save.*Files?|All Files|Save|Open.*Ark?|Extract.*Ark?)" },
  center = true,
})

hl.window_rule({
  name = "windowrule-16",
  match = { initial_class = "^(sykes.gtk.example)$" },
  opacity = "1 override 1 override",
})

hl.window_rule({
  name = "windowrule-17",
  match = { initial_class = "^(Microsoft.*)$" },
  opacity = "1 override 1 override",
})

hl.window_rule({
  name = "windowrule-18",
  match = { class = "ghidra-Ghidra" },
  tile = true,
  opacity = "1 override 1 override",
})

hl.window_rule({
  name = "windowrule-19",
  match = { title = "(Tip of the Day)" },
  float = true,
  center = true,
})

hl.window_rule({
  name = "windowrule-20",
  match = { class = "^jetbrains-.+$" },
  tag = "+jb",
  center = false,
})

hl.window_rule({
  name = "windowrule-21",
  match = { tag = "jb" },
  float = true,
  no_initial_focus = true,
  stay_focused = false,
  opacity = "1 override 0.85 override",
})

hl.window_rule({
  name = "windowrule-23",
  match = { class = "^jetbrains-.*$", title = ".*(Tooltip).*$" },
  no_focus = true,
})

hl.window_rule({
  name = "windowrule-24",
  match = { class = "^jetbrains-.*$", title = ".*(Dialog|Tooltip|Popup|Menu).*$" },
  float = true,
})

hl.window_rule({
  name = "windowrule-25",
  match = { class = "^jetbrains-.*$", title = ".*(Settings|Preferences|Project Structure).*$" },
  float = true,
  no_initial_focus = false,
  center = true,
})

hl.window_rule({
  name = "windowrule-26",
  match = { class = "^jetbrains-.*$", title = "^win.*$" },
  float = true,
  no_initial_focus = false,
})
