# Gnome tweaks and configs

## Gnome terminal
### Profile
- export with: `dconf dump /org/gnome/terminal/legacy/profiles:/ > gnome-terminal-profiles.dconf`
- import with `dconf load /org/gnome/terminal/legacy/profiles:/ < gnome-terminal-profiles.dconf`
- examples from: https://unix.stackexchange.com/questions/448811/how-to-export-a-gnome-terminal-profile
