# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a multi-distro dotfiles repository managing shell configs, window manager configs, and development environments for Arch, Ubuntu, Debian, Fedora, and openSUSE. Configs are deployed via **direct file copying** (not symlinks or GNU stow), managed by bash scripts.

Arch Linux is the primary/most-complete distro. `arch-wsl/` holds the terminal-only configs for Arch under WSL; `dotfiles_lib.sh` selects it instead of `arch/` when running under WSL. Ubuntu has a server and desktop i3 variant. Debian, Fedora, and openSUSE have minimal placeholder configs.

## Dotfile Management Workflow

**Deploy configs from repo → home directory:**
```bash
bash installDotfiles.sh [--dry-run]
```

**Sync configs from home directory → repo (after editing live):**
```bash
bash updateDotFiles.sh [--dry-run]
```

Both scripts source `dotfiles_lib.sh` for distro detection and file discovery. Discovery excludes oh-my-zsh internals (plugins, lib, templates, tools) and standard oh-my-zsh themes (only `sykes_custom_theme.zsh-theme` is kept). `.config/hypr/components/monitors.conf` is skipped during sync (machine-specific).

`installDotfiles.sh` backs up any existing home directory file/directory to a `.bak` copy before overwriting. `--dry-run` on either script prints what would happen without making changes.

`directoriesTracked.txt` and `filesTracked.txt` are documentation outputs written by `updateDotFiles.sh`; they are not read by `installDotfiles.sh` (which does its own discovery).

## Repository Structure

```
DotFiles/
├── arch/               # Arch Linux (most complete)
│   ├── .config/
│   │   ├── hypr/       # Hyprland WM (modular: monitors, keybinds, env, rules)
│   │   ├── waybar/     # Status bar
│   │   └── alacritty/  # Terminal
│   ├── .scripts/       # Custom executables (tmux-sessionizer, wofi menus, etc.)
│   ├── .themes/        # GTK themes
│   ├── .icons/
│   └── .udev/          # Udev rules
├── arch-wsl/           # Arch on WSL (terminal configs + hackerman colors)
├── omarchy/            # Omarchy overrides + sykes_omarchy zsh theme
├── ubuntu/             # Ubuntu (desktop i3 + server variants)
│   ├── .config/
│   │   ├── i3/
│   │   └── polybar/
│   └── .zshrc.server   # Server-specific shell config
├── debian/
├── fedora/
├── opensuse/
├── dotfiles_lib.sh     # Distro detection + file discovery (sourced by install/update)
├── installDotfiles.sh  # Deploys repo → home (with --dry-run and .bak backup)
├── updateDotFiles.sh   # Syncs home → repo (with --dry-run)
├── linuxSetup.sh       # Distro-agnostic tool installation
├── archDesktopInstall.sh
├── NvimSetup.sh        # Neovim bootstrap across distros
├── linuxRemoteSetup.sh # Remote SSH dev box (QEMU guest), any supported distro
└── setupGoCryptfsArch.sh
```

## Neovim Configuration

Neovim config is managed from a separate repository: **[SykesTheLord/NeoVimConfig](https://github.com/SykesTheLord/NeoVimConfig)**. It is not stored in this dotfiles repo. `NvimSetup.sh` clones that repo and runs its `install.sh` to deploy the config.

The config is Lua-based with **vim.pack** (Neovim 0.12 built-in). Key facts:
- Leader key: `-`, local leader: `_`
- LSP uses `vim.lsp.config`/`vim.lsp.enable` (requires Neovim 0.12+)
- Format on save via conform.nvim; lint on save via nvim-lint
- DAP debugging for Python, C#, Java, C/C++

## Setup Scripts

- **`linuxSetup.sh`** — Detects distro and installs common tools: Docker, PowerShell, Node.js, Neovim, LSP servers, etc.
- **`archDesktopInstall.sh`** — Installs Hyprland desktop environment, Qt apps, udev rules, VMware
- **`archWslSetup.sh`** — Arch on WSL in two stages (root: keyring/locale/user/`wsl.conf`; user: packages, yay + AUR, oh-my-zsh, `arch-wsl/` deploy, mise, .NET global tools, NeoVimConfig, default JDK, Mason packages, docker, Windows Terminal scheme). Dev toolchains for C/C++, C#/.NET, Java, Python and Bash are grouped in `PACMAN_PACKAGES`. Keep the WSL package lists to tools that make sense for development under WSL, with no GUI, media, personal or hardware tools. fastfetch, vim, downgrade, Go, Rust, nmap, tcpdump and whois are included on purpose. Both stages enable multilib and add BlackArch (`enable_multilib`, `configure_blackarch`; both idempotent, `--skip-blackarch` opts out). The BlackArch keyring is pinned by `BLACKARCH_KEYRING_VERSION` and `BLACKARCH_KEYRING_SHA256`. Only bump them after verifying the new tarball's `.sig` against the BlackArch Master key `CBA3C7D4798912702DCF568E67D8BDF42AD93F4E`. Don't switch to `strap.sh`: its verification is disabled. `MASON_PACKAGES` mirrors NeoVimConfig's `mason.lua` for those languages and is installed by a headless nvim Lua waiter, because NeoVimConfig's bootstrap and `:MasonInstall` don't wait for async installs already in progress. The WSL path must not depend on Omarchy tooling (no `omarchy/` files, Omarchy repo packages, or `omarchy-*` commands). Hackerman colors are hardcoded in `arch-wsl/.oh-my-zsh/custom/themes/sykes_hackerman.zsh-theme`, `arch-wsl/.config/btop/themes/hackerman.theme`, and `HACKERMAN_WT_SCHEME` in the script; keep them in sync. It reaches Neovim through `hackerman.nvim` + `aether.nvim` packages in `~/.local/share/nvim/site`, because the NeoVimConfig repo has no Omarchy theme support.
- **`linuxRemoteSetup.sh`** — Headless remote SSH dev box running as a QEMU guest, in two stages, across Arch, Debian, Ubuntu, Fedora, the CentOS/RHEL/Rocky/AlmaLinux family, and openSUSE (`is_arch`/`is_fedora`/`is_centos`/`is_opensuse`/`is_debian`/`is_ubuntu` from `dotfiles_lib.sh` pick `PKG_MANAGER`: pacman/dnf/zypper/apt). Root stage: package-manager init, locale, sudo, user, GitHub key enrollment, then disables SSH password/root login once a key is confirmed installed (`--skip-harden` opts out). User stage: packages, oh-my-zsh, dotfiles deploy, mise, .NET global tools, NeoVimConfig, default JDK, Mason packages, docker, `qemu-guest-agent`, unattended-update timer. `decide_github_user`/`confirm`/`prompt_var`/`import_github_keys`/`harden_sshd` are unchanged from the Arch-only predecessor (archRemoteSetup.sh, retired) and distro-agnostic already, except `harden_sshd` now reloads `$SSHD_UNIT` (`sshd` everywhere except Debian/Ubuntu's `ssh`).
  - **Non-root sudo invocation:** the bottom dispatch is `EUID -eq 0 -> root_stage`, `elif -n "$NEW_USER" -> re-exec via sudo`, `else -> user_stage`. `--user` is the stage-1 signal: if given while not already root, the script does `exec sudo bash "$0" "${ORIGINAL_ARGS[@]}"` (args saved into `ORIGINAL_ARGS` before the parsing loop's `shift`s consume `"$@"`, since re-exec needs the untouched originals) rather than requiring an actual root login — needed for cloud images that only hand you a sudo-capable user (`ubuntu`/`ec2-user`) with root SSH disabled. Dies with a clear message if `sudo` isn't installed. `root_stage`'s existing `id "$NEW_USER"` branch already made self-targeting safe before this change (an already-existing account just gets its sudo-group membership ensured; `passwd -l` only runs in the create-new-user branch), so passing your own username here configures your current account in place instead of creating a separate one, without locking you out.
  - **Arch-only, no equivalent elsewhere (per explicit decision — do not try to fake one):** BlackArch (`enable_multilib`/`configure_blackarch`/`blackarch_install_args`, gated by `is_arch` at every call site) and the AUR/`yay` tools `herdr-bin` and `downgrade`. `install_yay`/`install_aur_packages` log a one-line skip notice on other distros instead of guessing a substitute.
  - **lazygit/lazydocker:** not in `APT_PACKAGES`/`DNF_PACKAGES`/`ZYPPER_PACKAGES` either (Arch gets both natively via `PACMAN_PACKAGES`), but unlike herdr/downgrade they publish prebuilt Linux binaries on their GitHub releases — confirmed live against `api.github.com/repos/jesseduffield/{lazygit,lazydocker}/releases/latest`, asset name `<bin>_<version>_Linux_<x86_64|arm64>.tar.gz`, the same scheme both projects' own install docs use. `install_github_release_binary` (generic: repo + binary name) resolves the latest tag via the GitHub API, downloads and extracts that one binary, and installs it to `/usr/local/bin`; `install_lazygit_lazydocker` calls it for both and no-ops on Arch. Resilient like the package installs: a missing network/API rate limit/unexpected archive layout warns and skips rather than aborting setup. No version pinning — always fetches whatever's currently latest.
  - **Package lists:** four arrays (`PACMAN_PACKAGES` unchanged from the original; `APT_PACKAGES`/`DNF_PACKAGES`/`ZYPPER_PACKAGES` best-effort name mappings) installed via `pkg_install`/the per-manager case blocks in `install_packages`. **Do not rely on a package manager's "skip unknown/missing" flag** (`apt-get install --ignore-missing`, `dnf --setopt=strict=0 --skip-broken`, `zypper --ignore-unknown`) — `apt-get`'s turned out not to cover unresolvable names or "no candidate" packages at all (only download failures for names that already resolved), which is exactly what broke `tldr`/`mise`/`terraform`/`dotnet-sdk-8.0` live on a fresh Ubuntu release and, under `set -euo pipefail`, killed the whole script. Every array now goes through `pkg_available`/`filter_available_packages` first — a real per-package existence check (`apt-cache policy` + `grep -v 'Candidate: (none)'`, `dnf -q list --available` with `@group` refs passed through unfiltered, `zypper install --dry-run`) run before any install call, regardless of whether that manager's own flag can be trusted. `tree-sitter-cli` and `uv`/`ruff` are installed via npm/pipx on non-Arch instead of guessing native package names; `mise` isn't packaged on any non-Arch distro at all, so `install_mise` uses its official `https://mise.run` installer (no root, installs to `~/.local/bin/mise`) and `install_mise_tools` now checks `command -v mise` first rather than assuming it's there. `symlink_renamed_tools` symlinks Debian/Ubuntu's `fdfind`/`batcat` to `fd`/`bat` in `~/.local/bin` so configs expecting the plain names work everywhere.
  - **Vendor repos for packages missing from every base repo:** Docker (Fedora/CentOS only — neither ships `docker-ce`), Terraform, and the .NET SDK/runtime all need a vendor repo added before their package names resolve on Debian/Ubuntu and/or Fedora/CentOS. `setup_docker_repo` (dnf only, pre-existing), `setup_hashicorp_repo` (apt: keys `apt.releases.hashicorp.com/gpg`, writes `/etc/apt/sources.list.d/hashicorp.list` with `VERSION_CODENAME` from `/etc/os-release`; dnf: `dnf config-manager --add-repo` against `rpm.releases.hashicorp.com/{fedora,RHEL}/hashicorp.repo`), and `setup_dotnet_repo` (apt: `dpkg -i` a fetched `packages.microsoft.com/config/$ID/$VERSION_ID/packages-microsoft-prod.deb`; dnf: `rpm -Uvh` the `.rpm` equivalent, `is_centos` mapped to Microsoft's `rhel` path with the major version only) — all three confirmed live (gpg key, repo files, and the Microsoft endpoint genuinely 404s for an unknown distro id rather than serving a generic fallback, so the apt/dnf branches warn and move on if a given id/version combo isn't published). Each checks for its own marker file first (`/etc/apt/sources.list.d/*.list`, `/etc/yum.repos.d/*.repo`) so reruns don't re-add it. openSUSE has no such repo from either vendor; `terraform`/`dotnet-sdk-*`/`aspnetcore-runtime-*` stay in `ZYPPER_PACKAGES` as best-effort guesses, covered by the same `filter_available_packages` skip-with-warning as everything else there.
  - **Java default version:** Arch keeps `archlinux-java` (unchanged). Elsewhere, `configure_java`'s generic path searches `/usr/lib/jvm`/`/usr/lib64/jvm` (openSUSE uses lib64) for the newest matching JDK and symlinks `/usr/lib/jvm/default` to it — same path on every distro on purpose, since `.zshrc`'s `JAVA_HOME` hardcodes it — plus `update-alternatives`/`alternatives` (whichever exists) for `java` on PATH.
  - **Locale:** `configure_locale` branches per `PKG_MANAGER` — dnf installs `glibc-langpack-en` and writes `/etc/locale.conf`; apt uses `/etc/locale.gen` + `locale-gen` + `update-locale`; pacman/zypper use `/etc/locale.gen` + `locale-gen` + `/etc/locale.conf` (same as the original Arch logic).
  - **Auto-update timer:** `install_auto_updates` (`--skip-auto-update` opts out) writes `/usr/local/bin/linux-auto-update.sh` (renamed from `arch-auto-update.sh`) plus `linux-auto-update.service`/`.timer` (`OnCalendar=Mon,Wed,Sat 03:00:00`, `Persistent=true`, `[Service] User=root`). The generated script detects its own package manager at runtime via `command -v pacman/apt-get/dnf/zypper` (not baked in from `$PKG_MANAGER`, so it stays correct if ever copied elsewhere) and upgrades everything that way, AUR via `yay`/`runuser -l` on Arch only. The kernel-reboot check generalizes the old Arch-only `/boot/vmlinuz-linux` lookup into a search (`/boot/vmlinuz-linux`, then `/boot/vmlinuz`, then the newest `/boot/vmlinuz-*` by version sort) before the same `file -b`/`uname -r` comparison and the same nobody-logged-in / no-Claude-Code-running reboot gate.
- **`NvimSetup.sh`** — Installs Neovim + dependencies, then clones `SykesTheLord/NeoVimConfig` and runs its `install.sh`
- **`ubuntuServerInstalli3.sh`** — Ubuntu server i3 window manager setup

## Shell & Terminal

- Shell: **zsh** with oh-my-zsh, custom theme `sykes_custom_theme`
- Tmux: Dracula theme, TPM plugins (resurrect + continuum for persistent sessions, battery, CPU)
- Each distro has its own `.zshrc`; Ubuntu has an additional `.zshrc.server`

## Hyprland (Arch)

Config split into modules under `arch/.config/hypr/`:
- `hyprland.conf` — main entry, sources other modules
- Separate files for monitors, keybinds, environment variables, window rules
- Custom systemd user services for battery monitoring and wallpaper
- Udev rules in `arch/.udev/rules.d/` for hardware integration
- OpenRGB config for RGB lighting
