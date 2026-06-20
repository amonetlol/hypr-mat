# hypr-mat

Baseado em:
https://github.com/latency-tech/hyprland-dotfiles

# Clone the repo
git clone https://github.com/latency-tech/hyprland-dotfiles.git ~/dotfiles

# Symlink configs into ~/.config
cd ~/dotfiles
for dir in clipman fastfetch fish foot hypr matugen matuwall rofi swaync waybar wlogout yazi; do
  ln -sf "$PWD/$dir" "$HOME/.config/$dir"
done

# Install fonts (example for Arch)
yay -S ttf-jetbrains-mono-nerd

# Generate colors from a wallpaper
matugen image ~/Pictures/Wallpaper/your-wallpaper.jpg

# Or pick a wallpaper with auto color generation
matuwall

# Reload Hyprland
hyprctl reload
