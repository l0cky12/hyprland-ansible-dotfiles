# Arch Hyprland Ansible Dotfiles Setup

This Ansible project installs an Arch Linux Hyprland desktop package set, supports AUR packages with `yay`, clones the dotfiles repo at `https://github.com/fhlkfds/dotfiles`, and symlinks dotfiles into the target user's home directory using GNU Stow.

## What This Does

- Verifies the system is Arch Linux
- Reads packages from `pacpkg.txt`
- Ignores comments and blank lines in `pacpkg.txt`
- Installs official Arch packages using `pacman`
- Detects packages unavailable in official repos and treats them as AUR candidates
- Installs `yay` before installing AUR packages if needed
- Installs SDDM for a graphical Hyprland login manager
- Installs GNU Stow
- Clones or updates the dotfiles repo
- Checks for existing file conflicts before running Stow
- Backs up conflicting files to `~/.dotfiles-backup-YYYYMMDDTHHMMSS`
- Runs Stow as the target user, not root

## Project Structure

```text
hyprland-ansible-dotfiles/
├── site.yml
├── group_vars/
│   └── all.yml
├── pacpkg.txt
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
aur_helper: "yay"
extra_aur_packages: []
enable_login_manager: true
login_manager: "sddm"
login_manager_packages:
  - sddm
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

## Add AUR Packages

Preferred method:

```yaml
extra_aur_packages:
  - visual-studio-code-bin
  - google-chrome
```

You can also place AUR packages in `pacpkg.txt`. The playbook checks each package with `pacman -Si`. If the package is not in the official repos, it becomes an AUR candidate.

The order is:

1. Install official pacman packages
2. Check if `yay` exists
3. If missing, install `base-devel` and `git`
4. Clone yay from AUR
5. Build and install yay
6. Install AUR packages with yay
7. Clone dotfiles
8. Run Stow

## Run

From the project directory:

```bash
ansible-playbook -K site.yml
```

`-K` asks for your sudo password.

## File Conflict Behavior

Before running Stow, the playbook checks whether target files already exist in the user's home directory.

Example conflict:

```text
~/.config/hypr/hyprland.conf
```

If this file exists and is not already a symlink, it is moved to:

```text
~/.dotfiles-backup-YYYYMMDDTHHMMSS/.config/hypr/hyprland.conf
```

Then Stow creates the symlink from the dotfiles repo.

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
- This playbook enables SDDM and creates `/usr/share/wayland-sessions/hyprland.desktop` so Hyprland appears in the session selector.
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
