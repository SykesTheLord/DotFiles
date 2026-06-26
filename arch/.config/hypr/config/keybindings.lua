local p = require("config.programs")
local mainMod     = p.mainMod
local terminal    = p.terminal
local fileManager = p.fileManager
local menu        = p.menu
local browser     = p.browser

-- Basic window/session controls
hl.bind(mainMod .. " + W",         hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())
hl.bind(mainMod .. " + V",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R",         hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J",         hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + ALT + W",   hl.dsp.exec_cmd("hyprctl dispatch plugin:xtd:closeunfocused"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }))

-- Switch / move windows to workspaces with mainMod (+ SHIFT) + [0-9]
for i = 1, 10 do
  local key = i % 10
  hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- OSD client (only display the OSD on the currently focused monitor)
local osdclient = "swayosd-client --monitor \"$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')\""

-- Laptop multimedia keys for volume and LCD brightness (with OSD)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(osdclient .. " --output-volume +5"),                       { locked = true, repeating = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(osdclient .. " --output-volume -5"),                       { locked = true, repeating = true, description = "Volume down" })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(osdclient .. " --output-volume mute-toggle"),              { locked = true, repeating = true, description = "Mute" })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd(osdclient .. " --input-volume mute-toggle"),               { locked = true, repeating = true, description = "Mute microphone" })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(osdclient .. " --device intel_backlight --brightness +5"), { locked = true, repeating = true, description = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(osdclient .. " --device intel_backlight --brightness -5"), { locked = true, repeating = true, description = "Brightness down" })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(osdclient .. " --playerctl next"),       { locked = true, description = "Next track" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(osdclient .. " --playerctl play-pause"), { locked = true, description = "Pause" })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(osdclient .. " --playerctl play-pause"), { locked = true, description = "Play" })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(osdclient .. " --playerctl previous"),   { locked = true, description = "Previous track" })

-- Custom binds
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("rfkill toggle bluetooth"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("pkill waybar; waybar & disown"))

-- Swap active window with the one next to it with mainMod + SHIFT + arrow keys
hl.bind("SUPER + SHIFT + left",  hl.dsp.window.swap({ direction = "l" }), { description = "Swap window to the left" })
hl.bind("SUPER + SHIFT + right", hl.dsp.window.swap({ direction = "r" }), { description = "Swap window to the right" })
hl.bind("SUPER + SHIFT + up",    hl.dsp.window.swap({ direction = "u" }), { description = "Swap window up" })
hl.bind("SUPER + SHIFT + down",  hl.dsp.window.swap({ direction = "d" }), { description = "Swap window down" })

-- Cycle through applications on active workspace
hl.bind("ALT + Tab", function()
  hl.dispatch(hl.dsp.window.cycle_next())
  hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end, { description = "Cycle to next window and reveal it on top" })

-- Screenshots
hl.bind("PRINT",         hl.dsp.exec_cmd("~/.config/hypr/UserScripts/Screenshots/screenshot.sh region"))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("~/.config/hypr/UserScripts/Screenshots/screenshot.sh window"))
hl.bind("CTRL + PRINT",  hl.dsp.exec_cmd("~/.config/hypr/UserScripts/Screenshots/screenshot.sh output"))

hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/UserScripts/Screenshots/screenshot.sh region"))
hl.bind("SUPER + CTRL + S",  hl.dsp.exec_cmd("~/.config/hypr/UserScripts/Screenshots/screenshot.sh output"))

-- Color picker
hl.bind("SUPER + PRINT", hl.dsp.exec_cmd("hyprpicker -a"))

-- Lock the system
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + C", hl.dsp.window.center())

hl.bind("SUPER + SHIFT + H", hl.dsp.exec_cmd("bash ~/.config/hypr/UserScripts/monitorselect/enableHdr.sh"))
hl.bind("SUPER + ALT + H",   hl.dsp.exec_cmd("bash ~/.config/hypr/UserScripts/monitorselect/disableHdr.sh"))

-- Clipboard history
hl.bind("SUPER + CTRL + V", hl.dsp.exec_cmd("cliphist list | wofi -S dmenu | cliphist decode | wl-copy"))

-- Lid switch binds are defined in config/overrides.lua, written by
-- UserScripts/select-keybind-rules/switch-keybinds.sh based on monitor count.

-- App keybinds (from AppKeybinds.conf)
hl.bind(mainMod .. " + E",         hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + return",    hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B",         hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + D",         hl.dsp.exec_cmd(terminal .. " -e lazydocker"))
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("swaync-client -t"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd(terminal .. " --title=Neovim -e nvim"))
hl.bind(mainMod .. " + O",         hl.dsp.exec_cmd("obsidian %U"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))

-- Gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "vertical",   action = "fullscreen" })
