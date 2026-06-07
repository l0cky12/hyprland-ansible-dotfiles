# Arch Hyprland Ansible Dotfiles Setup

This Ansible project installs an Arch Linux Hyprland desktop package set, supports AUR packages with `yay`, clones the dotfiles repo at `https://github.com/fhlkfds/dotfiles`, and symlinks dotfiles into the target user's home directory using GNU Stow.

## What This Does

- Verifies the system is Arch Linux
- Reads packages from `pacpkg.txt`
- Installs required bootstrap packages using `pacman`
- Adds a limited sudoers rule so the target user can run `/usr/bin/pacman` without a password for yay
- After yay is installed, runs `yay -S --needed --noconfirm $(cat pacpkg.txt)`
- Optionally runs the same yay install command from `yaypkg.txt`
- Installs `yay` early on Arch Linux using `scripts/install-yay.sh` before any AUR package install
- Installs SDDM for a graphical Hyprland login manager
- Installs GNU Stow
- Clones or updates the dotfiles repo
- Ensures `~/.config` exists before running Stow
- Runs `stow -v -t "$HOME" */` from inside the cloned dotfiles folder as the target user
- Ensures Noctalia starts from Hyprland with `exec-once = qs -c noctalia-shell`

## Project Structure

```text
hyprland-ansible-dotfiles/
├── site.yml
├── group_vars/
│   └── all.yml
├── pacpkg.txt
├── yaypkg.txt
├── scripts/
│   └── install-yay.sh
├── roles/
│   ├── packages/
│   │   └── tasks/
│   │       └── main.yml
│   ├── dotfiles/
│   │   └── tasks/
│   │       └── main.yml
│   └── login_manager/
│       └── tasks/
│           └── main.yml
└── README.md
```

## Requirements

Install Ansible first:

```bash
sudo pacman -S --needed ansible git
```

Install the required Ansible collection:

```bash
ansible-galaxy collection install community.general
```

## Configure Variables

Edit:

```text
group_vars/all.yml
```

Important variables:

```yaml
target_user: "liam"
target_home: "/home/{{ target_user }}"
dotfiles_repo: "https://github.com/fhlkfds/dotfiles.git"
dotfiles_dest: "{{ target_home }}/dotfiles"
pacman_package_file: "pacpkg.txt"
yay_package_file: "yaypkg.txt"
aur_helper: "yay"
extra_aur_packages: []
enable_login_manager: true
login_manager: "sddm"
login_manager_packages:
  - sddm
hyprland_session_packages:
  - hyprland
  - xdg-desktop-portal-hyprland
  - xdg-desktop-portal
  - dbus
  - uwsm
  - qt5-wayland
  - qt6-wayland
stow_packages:
  - fastfetch
  - hypr
  - hyprlock
  - noctalia
  - rofi
  - swaync
  - waybar
  - wofi
  - zsh
```

Change `target_user` if your Linux username is not `liam`.

## Add AUR/Yay Packages

Preferred method: put AUR/yay packages in `yaypkg.txt`, one package per line.

```text
visual-studio-code-bin
google-chrome
brave-bin
```

Blank lines and comments are ignored.

You can still add AUR packages in `group_vars/all.yml` if you prefer variables:

```yaml
extra_aur_packages:
  - visual-studio-code-bin
  - google-chrome
```

Main package installs now happen through yay from `pacpkg.txt` with:

```bash
yay -S --needed --noconfirm $(cat pacpkg.txt)
```

If `yaypkg.txt` contains packages, the playbook also runs the same style command against `yaypkg.txt`.

The order is:

1. Install core playbook requirements
2. Run `scripts/install-yay.sh` as root through Ansible
3. The script checks if `yay` exists
4. If missing, the script installs `base-devel`, `git`, and `go`
5. The script clones yay from AUR as the target user
6. The script builds yay as the target user
7. The script installs the built yay package with pacman
8. Add a limited sudoers rule for passwordless `/usr/bin/pacman`
9. Run `yay -S --needed --noconfirm $(cat pacpkg.txt)` as the target user
10. If `yaypkg.txt` has packages, run `yay -S --needed --noconfirm $(cat yaypkg.txt)` as the target user
11. Clone dotfiles
12. Ensure `~/.config` exists
13. Run `stow -v -t "$HOME" */` from inside the cloned dotfiles folder
14. Ensure Noctalia autostarts with Hyprland

## Run

From the project directory:

```bash
ansible-playbook -K site.yml
```

`-K` asks for your sudo password.

## File Conflict Behavior

The playbook no longer backs up or moves conflicting dotfiles before Stow.

If a target file already exists and blocks Stow, Stow will fail and show the conflict. Remove or move that file manually, then rerun the playbook.

## Recommended First Run

For safest first run, edit `group_vars/all.yml` and start with only:

```yaml
stow_packages:
  - fastfetch
  - rofi
  - waybar
  - wofi
```

Then add these after verifying:

```yaml
  - hypr
  - hyprlock
  - swaync
  - noctalia
```

Add `zsh` last because it can affect your shell startup.

## Warnings

- This playbook does not validate that the Hyprland config works on your GPU.
- This playbook enables SDDM, creates `/usr/local/bin/start-hyprland-sddm`, logs startup failures to `/tmp/start-hyprland.log`, removes the old bad `/usr/local/bin/start-hyprland` wrapper if present, and creates `/usr/share/wayland-sessions/hyprland.desktop` so Hyprland appears in the session selector.
- NVIDIA, AMD, and Intel setups require different driver packages.
- AUR packages are not official Arch packages. Review PKGBUILDs if security matters.
- Do not run Stow as root. This playbook intentionally runs Stow as the target user.
- The upstream dotfiles repo includes a `zsh/.oh-my-zsh` folder, so existing `~/.oh-my-zsh` will be backed up before linking.

## Manual Stow Test

```bash
cd ~/dotfiles
stow --simulate --verbose --target="$HOME" hypr
```

Undo one package:

```bash
cd ~/dotfiles
stow --delete --target="$HOME" hypr
```
