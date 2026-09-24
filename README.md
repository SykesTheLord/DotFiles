# DotFiles

Personal dotfiles and setup scripts for Arch Linux (primary), Ubuntu, Debian, Fedora, and openSUSE. Configs are deployed via **direct file copying** — no symlinks, no stow.

## Distro Support

| Distro | Status | Desktop |
|---|---|---|
| Arch Linux | Full | Hyprland or Omarchy |
| Arch Linux on WSL | CLI/TUI tools, hackerman theme | Windows Terminal |
| Arch Linux (remote SSH dev box) | CLI/TUI tools, GitHub key import, QEMU guest agent, auto-updates | Headless |
| Ubuntu | Desktop + Server | i3 |
| Debian / Fedora / openSUSE | Minimal placeholder | — |

---

## Deploying Configs

**Copy repo → home directory:**
```bash
bash installDotfiles.sh [--dry-run]
```

**Sync live edits back → repo:**
```bash
bash updateDotFiles.sh [--dry-run]
```

Both scripts auto-detect the distro and copy only the relevant files (Arch under WSL uses `arch-wsl/` instead of `arch/`). `installDotfiles.sh` backs up any existing file to a `.bak` copy before overwriting. `--dry-run` prints what would happen without making changes.

> `~/.config/hypr/components/monitors.conf` is excluded from sync — it's machine-specific.

---

## Setup Scripts

### `linuxSetup.sh` — Common tools (all distros)

Installs: zsh, Docker, Terraform, direnv, tmux, fzf, ripgrep, Neovim, LSP servers, fonts, oh-my-zsh, TPM, Bicep CLI, Azure PowerShell module, and development directories (`~/Development/Personal`, `~/Development/Work`, etc.).

```bash
bash linuxSetup.sh
```

Detects the distro and runs the appropriate package manager commands. On Arch, also builds and installs `yay` if missing.

---

### `archDesktopInstall.sh` — Arch Hyprland desktop

Installs the full Hyprland desktop stack on top of a base Arch install: Hyprland, Waybar, Alacritty, rofi, swaync, pavucontrol, Bluetooth tools, VMware Workstation, udev rules, hyprpm plugins, and GTK/Qt theming.

```bash
bash archDesktopInstall.sh
```

Run after `linuxSetup.sh`. Deploys dotfiles at the end via `installDotfiles.sh`.

---

### `omarchyPostInstall.sh` — Omarchy layer

Layers personal preferences on top of a fresh [omarchy](https://github.com/basecamp/omarchy) install. Omarchy provides the Hyprland desktop environment; this script adds what it doesn't cover.

```bash
bash omarchyPostInstall.sh [--dry-run] [--restore-home <path>]
```

**What it installs:**
- **Languages & runtimes:** Go, JDK 11/17/21/25, Python pip/pipx, cmake, dotnet SDK 8/9/10
- **Dev tools:** Terraform, direnv, PowerShell, Bicep CLI
- **Apps:** Bitwarden, Claude Code, VMware Workstation, zen-browser (set as default browser)
- **Flatpak:** BudsLink (`io.github.maniacx.BudsLink`)
- **Shell:** zsh + oh-my-zsh + syntax-highlighting + autosuggestions plugins
- **Neovim:** Replaces omarchy-nvim with [SykesTheLord/NeoVimConfig](https://github.com/SykesTheLord/NeoVimConfig)

**What it configures:**
- `~/.config/hypr/hypridle.conf` — brightness dimming (30s), keyboard backlight + DPMS (120s), lock (150s), suspend (600s), using omarchy's `omarchy-system-lock/wake` wrappers
- `~/.config/hypr/windowrules.conf` — user-specific rules (Paradox Launcher, HOI4, Ghidra, JetBrains extended, media app opacity, KDE file pickers, etc.) sourced into Hyprland
- `~/.oh-my-zsh/custom/themes/sykes_omarchy.zsh-theme` — prompt that reads 24-bit colors from the active omarchy theme
- Registers an `omarchy-hook` so zsh colors update automatically on `omarchy-theme-set`

**Restoring a previous home directory:**
```bash
bash omarchyPostInstall.sh --restore-home /path/to/old/home
```
Rsyncs the old home in before deploying new configs. Automatically excludes all paths managed by omarchy (alacritty, waybar, mako, btop, fastfetch, walker, etc.) and by this script, so the fresh setup always takes precedence. Personal data, SSH keys, development directories, and app-specific configs are preserved.

---

### `archWslSetup.sh` — Arch Linux on WSL

Recreates the terminal side of the Omarchy machine on Arch under WSL, themed with Omarchy's **hackerman** palette. Runs in two stages:

```bash
# 1. As root on a fresh image: keyring, locale, sudo, user, /etc/wsl.conf (systemd + default user)
bash archWslSetup.sh --user <name>
#    then in PowerShell: wsl --terminate <distro>

# 2. As that user
bash archWslSetup.sh [--dry-run] [--skip-nvim] [--skip-terminal] [--skip-blackarch]
```

**Package sources:** both stages enable the **multilib** repository and add the **BlackArch** repository; each step is skipped once done, and `--skip-blackarch` opts out of BlackArch. BlackArch's `strap.sh` isn't used because its signature check is commented out. Instead the script downloads the BlackArch keyring pinned by version and SHA-256 (the tarball's signature was verified against the BlackArch Master key `CBA3C7D4798912702DCF568E67D8BDF42AD93F4E`). It installs the keys, fetches the mirrorlist, adds `[blackarch]` to `pacman.conf`, and installs `blackarch-keyring` and `blackarch-mirrorlist` so pacman keeps them current. No BlackArch tools are installed by default; add them with `sudo pacman -S <tool>` or a group such as `blackarch-webapp`.

Running from a Windows checkout (`/mnt/c/...`) works. `.gitattributes` forces LF line endings, but a clone made before that file existed still has CRLF, and the script stops with a fix command. To re-checkout such a clone with LF from Windows Git, run `git rm -r --cached . && git reset --hard`; this discards uncommitted changes.

**What it installs:** zsh + oh-my-zsh, Neovim, tmux, herdr, lazygit, lazydocker, btop, fastfetch, vim, fzf/ripgrep/fd/bat/eza/zoxide, jq, direnv, tldr, hyperfine, mise (Claude Code, Codex), Docker, Terraform, Go, Rust, network tools (dig, nc, telnet, whois, nmap, tcpdump), `downgrade`, `wslu` and `wl-clipboard`, plus the development toolchains below. The package set is aimed at development; desktop, media, personal and hardware tools from the Omarchy machine are left out. yay is built from the AUR (`yay-bin`), and herdr comes from the AUR because Omarchy's package repo isn't available.

**Development tooling:**

| Language | System | Neovim (Mason) |
|---|---|---|
| C / C++ | gcc, clang (clangd, clang-tidy), gdb, lldb, cmake, ninja, meson, bear, ccache, gtest, valgrind, cppcheck, strace/ltrace | clangd, clang-format, cpptools, cpplint, cmake-language-server, cmakelang, cmakelint |
| C# / .NET | .NET SDK 10/8 (LTS), ASP.NET Core runtimes 10/8, global tools `dotnet-ef` and `csharpier` | csharp-language-server 0.16.0, netcoredbg, csharpier |
| Java | JDK 17/21/25 LTS (default 25 via `archlinux-java`), Maven, Gradle | jdtls, java-debug-adapter, google-java-format, checkstyle |
| Python | python, pip, pipx, uv, ruff, pytest, ipython, debugpy | jedi-language-server, black, pylint, debugpy |
| Bash | shellcheck, shfmt, bats | bash-language-server, shellcheck, beautysh |

The Mason packages are installed by a headless Neovim that waits for them to finish, so LSP, debugging and formatting work on the first launch. `.zshrc` sets `JAVA_HOME`, `DOTNET_ROOT`, .NET telemetry opt-out, and CMake defaults (Ninja generator, `compile_commands.json` for clangd).

**Theme:** nothing depends on Omarchy tooling (no `omarchy/` files, Omarchy repo packages, or `omarchy-*` commands). The hackerman palette is baked into the `sykes_hackerman` oh-my-zsh theme (`arch-wsl/.oh-my-zsh/custom/themes/`). Neovim gets Omarchy's own `bjarneo/hackerman.nvim` (with `aether.nvim`), installed as a native package under `~/.local/share/nvim/site`. An `after/plugin/hackerman.lua` applies it over NeoVimConfig's default and switches lualine to `auto`, without touching the NeoVimConfig clone. btop gets a rendered `hackerman.theme`. tmux and herdr use the terminal palette, which the script sets by adding a Hackerman scheme to Windows Terminal's `settings.json`. It backs the file up first, applies the scheme (plus JetBrainsMono Nerd Font if installed) to the WSL profile, and unbinds `alt+enter` so tmux's split key works.

---

### `archRemoteSetup.sh` — Arch remote SSH dev box (QEMU guest)

Sets up a headless Arch box, running as a QEMU guest, as a remote SSH development machine. Runs in two stages:

```bash
# 1. As root on a fresh box: keyring, locale, sudo, user, GitHub SSH key import
bash archRemoteSetup.sh --user <name> [--github-user <name>]
#    prompts for whichever of --user/--github-user is omitted

# 2. As that user
bash archRemoteSetup.sh [--dry-run] [--skip-nvim] [--skip-blackarch] \
    [--skip-qemu-agent] [--skip-auto-update]
```

Stage 1 fetches the given GitHub user's public keys (`https://github.com/<user>.keys`) into the new user's `~/.ssh/authorized_keys`, locking the account's password in the process. Once a key is confirmed installed, it disables SSH password and root login (`PasswordAuthentication no`, `PermitRootLogin no`) so the box is only reachable with that key; `--skip-harden` leaves `sshd_config` alone.

Otherwise this mirrors `archWslSetup.sh`: same multilib/BlackArch handling, the same development package set and Mason install waiter, and it reuses `arch-wsl/`'s dotfiles directly (they're terminal-only and don't depend on WSL — the hackerman zsh theme uses 24-bit color, so it looks the same over plain SSH). It skips the WSL/Windows-only pieces: no `wsl.conf`, Windows Terminal integration, `wslu`, `wl-clipboard`, or `hackerman.nvim`.

**QEMU guest agent:** stage 2 installs and enables `qemu-guest-agent` (`--skip-qemu-agent` opts out), so the QEMU host can request clean shutdowns/reboots, freeze/thaw the filesystem for snapshots, and read the guest's IP.

**Unattended updates:** stage 2 also installs a systemd timer (`--skip-auto-update` opts out) that runs `pacman -Syu`, then AUR updates via `yay` as the dev user, then `paccache -rk2`, every **Monday, Wednesday and Saturday at 03:00**:

```bash
systemctl status arch-auto-update.timer   # next scheduled run
sudo systemctl start arch-auto-update.service   # run it now
journalctl -u arch-auto-update.service          # last run's output
```

Arch's rolling `linux` package has no live-patching feed to apply kernel security updates without a restart (`kpatch` exists, but it needs a patch hand-built against the exact kernel build, which doesn't scale to arbitrary Arch kernel bumps). Instead, once the timer detects the installed kernel no longer matches the running one, it reboots automatically — but only when nobody is logged in (`who`) and no Claude Code agent is running for the dev user (`pgrep -f claude`), so it never yanks the machine out from under an active session or an in-flight agent. If either check fails, the reboot is skipped and retried at the next Mon/Wed/Sat window; check `journalctl -t arch-auto-update` for deferrals.

---

### `NvimSetup.sh` — Neovim bootstrap

Installs Neovim and its dependencies, then clones [SykesTheLord/NeoVimConfig](https://github.com/SykesTheLord/NeoVimConfig) and runs its `install.sh`. The Neovim config is maintained in that separate repo (not stored here).

```bash
bash NvimSetup.sh
```

---

### `ubuntuServerInstalli3.sh` — Ubuntu i3 desktop

Sets up an i3 window manager desktop on Ubuntu server (or desktop). Installs i3, polybar, rofi, dunst, picom, and related tools.

```bash
bash ubuntuServerInstalli3.sh
```

---

## Repository Structure

```
DotFiles/
├── arch/                    # Arch Linux — primary, most complete
│   ├── .config/
│   │   ├── hypr/            # Hyprland (modular: monitors, keybinds, env, rules)
│   │   ├── waybar/          # Status bar
│   │   └── alacritty/       # Terminal
│   ├── .oh-my-zsh/custom/themes/
│   │   └── sykes_custom_theme.zsh-theme
│   ├── .scripts/            # Custom executables (tmux-sessionizer, wofi menus, etc.)
│   ├── .themes/             # GTK themes
│   ├── .icons/
│   └── .udev/               # Udev rules
├── omarchy/                 # Omarchy-specific overrides (deployed by omarchyPostInstall.sh)
│   ├── .config/hypr/
│   │   ├── hypridle.conf    # Custom idle/lock timeouts
│   │   └── windowrules.conf # User-specific window rules
│   ├── .oh-my-zsh/custom/themes/
│   │   └── sykes_omarchy.zsh-theme
│   └── .scripts/
│       └── omarchy-zsh-colors-set
├── arch-wsl/                # Arch on WSL: zsh, tmux, herdr, btop, git, mise + hackerman colors
│                            #   (also reused by archRemoteSetup.sh for the remote dev box)
├── ubuntu/                  # Ubuntu — desktop i3 + server variants
│   ├── .config/i3/
│   ├── .config/polybar/
│   └── .zshrc.server
├── debian/
├── fedora/
├── opensuse/
├── dotfiles_lib.sh          # Distro detection + file discovery (sourced by install/update)
├── installDotfiles.sh       # Deploy repo → home
├── updateDotFiles.sh        # Sync home → repo
├── linuxSetup.sh            # Common tool installation (all distros)
├── archDesktopInstall.sh    # Hyprland desktop setup (Arch)
├── omarchyPostInstall.sh    # Personal layer on top of omarchy
├── archWslSetup.sh          # Arch on WSL: CLI/TUI tools + hackerman theme
├── archRemoteSetup.sh       # Arch remote SSH dev box (QEMU guest): GitHub key import + hardening, guest agent, auto-updates
├── NvimSetup.sh             # Neovim bootstrap
└── ubuntuServerInstalli3.sh # Ubuntu i3 setup
```

---

## Shell & Terminal

- **Shell:** zsh with oh-my-zsh
- **Theme (Arch/standard):** `sykes_custom_theme` — two-line prompt showing time, user@host:path, git branch
- **Theme (Omarchy):** `sykes_omarchy` — same layout, but bracket and accent colors are sourced from the active omarchy color theme automatically
- **Tmux:** Dracula theme via TPM, with git and SSH session status

## Hyprland (Arch)

Config is split into modules under `arch/.config/hypr/components/`:
- `hyprland.conf` — main entry, sources all modules
- Separate files for monitors, keybinds, environment variables, window rules, autostart
- Custom systemd user services for battery monitoring and wallpaper
- Udev rules in `arch/.udev/rules.d/` for hardware integration

## Neovim

Config lives at [SykesTheLord/NeoVimConfig](https://github.com/SykesTheLord/NeoVimConfig) — Lua-based with `vim.pack` (Neovim 0.12+). Run `NvimSetup.sh` to install it.
