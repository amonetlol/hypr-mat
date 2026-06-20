#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/latency-tech/hyprland-dotfiles"
REPO_DIR="$ROOT_DIR/.repo_base/hyprland-dotfiles"
DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$HOME/.config"

log() {
    printf "\n[HYPRLAND] %s\n" "$1"
}

ok() {
    printf "[OK] %s\n" "$1"
}

warn() {
    printf "[AVISO] %s\n" "$1"
}

die() {
    printf "[ERRO] %s\n" "$1" >&2
    exit 1
}

require_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        die "Este script foi feito para Arch Linux ou derivados baseados em Arch."
    fi
}

require_not_root() {
    if [[ "${EUID}" -eq 0 ]]; then
        die "Não execute como root. Rode com seu usuário normal."
    fi
}

ensure_sudo() {
    sudo -v
}

require_yay() {
    if ! command -v yay >/dev/null 2>&1; then
        die "yay não encontrado. Rode primeiro o base.sh."
    fi
}

install_pacman_packages() {
    log "Instalando pacotes oficiais necessários para o rice"

    sudo pacman -S --needed --noconfirm \
        hyprland \
        hyprlock \
        hypridle \
        waybar \
        rofi-wayland \
        wlogout \
        foot \
        thunar \
        firefox \
        fastfetch \
        cliphist \
        wl-clipboard \
        grim \
        slurp \
        brightnessctl \
        pamixer \
        playerctl \
        network-manager-applet \
        blueman \
        bluez \
        bluez-utils \
        pavucontrol \
        polkit-gnome \
        papirus-icon-theme \
        ttf-jetbrains-mono-nerd \
        noto-fonts \
        noto-fonts-emoji \
        jq \
        imagemagick \
        unzip \
        tar \
        xz \
        rsync

    ok "Pacotes oficiais instalados"
}

install_aur_packages() {
    log "Instalando pacotes AUR necessários para o rice"

    local packages=(
        matugen
        matuwall
        clipman
        swayosd
    )

    yay -S --needed --noconfirm "${packages[@]}"

    if ! yay -S --needed --noconfirm awww; then
        warn "Pacote awww não instalou como 'awww'. Tentando awww-git."
        yay -S --needed --noconfirm awww-git || warn "Não foi possível instalar awww/awww-git automaticamente."
    fi

    ok "Pacotes AUR instalados"
}

clone_or_update_repo() {
    log "Baixando repo base do Hyprland"

    mkdir -p "$(dirname "$REPO_DIR")"

    if [[ -d "$REPO_DIR/.git" ]]; then
        git -C "$REPO_DIR" pull --ff-only
    else
        rm -rf "$REPO_DIR"
        git clone "$REPO_URL" "$REPO_DIR"
    fi

    ok "Repo base disponível em $REPO_DIR"
}

backup_path() {
    local target="$1"

    if [[ -e "$target" || -L "$target" ]]; then
        local backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
        mv "$target" "$backup"
        warn "Backup criado: $backup"
    fi
}

link_configs() {
    log "Movendo configs para ~/.dotfiles e criando links em ~/.config"

    mkdir -p "$CONFIG_DIR"
    mkdir -p "$DOTFILES_DIR"

    local dirs=(
        clipman
        fastfetch
        foot
        hypr
        matugen
        matuwall
        rofi
        waybar
        wlogout
    )

    for dir in "${dirs[@]}"; do
        local src="$REPO_DIR/$dir"
        local dot_dst="$DOTFILES_DIR/$dir"
        local config_dst="$CONFIG_DIR/$dir"

        if [[ ! -d "$src" ]]; then
            warn "$dir não existe no repo base, pulando"
            continue
        fi

        backup_path "$dot_dst"
        cp -a "$src" "$dot_dst"

        backup_path "$config_dst"
        ln -s "$dot_dst" "$config_dst"

        ok "$dir movido para ~/.dotfiles/$dir e linkado em ~/.config/$dir"
    done
}

create_hypr_keyboard_config() {
    log "Criando kb.conf com teclado br abnt2"

    mkdir -p "$CONFIG_DIR/hypr"

    cat > "$CONFIG_DIR/hypr/kb.conf" <<'EOF'
input {
    kb_layout = br
    kb_variant = abnt2
    kb_model =
    kb_options =
    kb_rules =

    follow_mouse = 1
    sensitivity = 0
}
EOF

    ok "kb.conf criado"
}

write_hyprland_conf() {
    log "Gerando hyprland.conf personalizado"

    local conf="$CONFIG_DIR/hypr/hyprland.conf"

    if [[ -f "$conf" && ! -L "$conf" ]]; then
        cp "$conf" "${conf}.bak.$(date +%Y%m%d-%H%M%S)"
    fi

    cat > "$conf" <<'EOF'
# ============================================================
# HYPRLAND CONFIG
# Base: latency-tech/hyprland-dotfiles
# Ajustes: Arch Linux + ABNT2 + apps definidos
# ============================================================

# === Variáveis de Ambiente (Wayland/Hyprland) ===
env = XDG_CURRENT_DESKTOP, Hyprland
env = XDG_SESSION_TYPE, wayland
env = XDG_SESSION_DESKTOP, Hyprland

# GTK
env = GDK_BACKEND, wayland
env = GDK_SCALE, 1

# Qt
env = QT_QPA_PLATFORM, wayland
env = QT_AUTO_SCREEN_SCALE_FACTOR, 1
env = QT_WAYLAND_DISABLE_WINDOWDECORATION, 1
env = QT_QPA_PLATFORMTHEME, qt5ct   # ou qt6ct

# Outras recomendadas
env = MOZ_ENABLE_WAYLAND, 1
env = ELECTRON_OZONE_PLATFORM_HINT, wayland


source = ~/.config/hypr/colors.conf
source = ~/.config/hypr/kb.conf

# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------
$mainMod = SUPER

$terminal = foot
$fileManager = thunar
$browser = firefox

$hub = ""
$rofi = rofi -show drun
$wall = ""
$cb = ""
$power = wlogout

# ------------------------------------------------------------
# Monitor
# ------------------------------------------------------------
monitor = , preferred, auto, 1

# ------------------------------------------------------------
# Autostart
# ------------------------------------------------------------
exec-once = awww-daemon
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
#exec-once = swayosd-server
exec-once = waybar
#exec-once = clipman

# ------------------------------------------------------------
# Aparência
# ------------------------------------------------------------
general {
    gaps_in = 6
    gaps_out = 12
    border_size = 2
    layout = dwindle
}

decoration {
    rounding = 10
    active_opacity = 0.75
    inactive_opacity = 0.70

    blur {
        enabled = true
        size = 5
        passes = 5
        new_optimizations = true
    }

    shadow {
        enabled = true
        range = 15
        render_power = 3
    }
}

dwindle {
    preserve_split = true
}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
}

# ------------------------------------------------------------
# Cursor
# ------------------------------------------------------------
env = XCURSOR_THEME,Qogir-cursors
env = XCURSOR_SIZE,24
env = HYPRCURSOR_THEME,Qogir-cursors
env = HYPRCURSOR_SIZE,24

exec-once = hyprctl setcursor Qogir-cursors 24

# ------------------------------------------------------------
# Window rules
# ------------------------------------------------------------
windowrule = float on, dim_around on, no_blur on, move (cursor_x-(window_w*0.5)) (cursor_y-(window_h*0.5)), match:title ^Clipboard$

# ------------------------------------------------------------
# Workspaces
# ------------------------------------------------------------
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# ------------------------------------------------------------
# Mouse
# ------------------------------------------------------------
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# ------------------------------------------------------------
# Volume e brilho
# ------------------------------------------------------------
bindel = , XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise
bindel = , XF86AudioLowerVolume, exec, swayosd-client --output-volume lower
bindl = , XF86AudioMute, exec, swayosd-client --output-volume mute-toggle

bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# ------------------------------------------------------------
# Apps principais
# ------------------------------------------------------------
bind = $mainMod, Return, exec, $terminal
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, W, exec, $browser
bind = $mainMod, D, exec, $rofi

bind = , F12, exec, pkill waybar || waybar
bind = , F11, exec, $hub
bind = , F10, exec, $wall

bind = ALT, V, exec, $cb

# ------------------------------------------------------------
# Janela
# ------------------------------------------------------------
bind = $mainMod, Q, killactive
bind = $mainMod, X, exec, $power
bind = $mainMod, F, fullscreen
bind = , F5, togglefloating
bind = , F6, layoutmsg, swapnext

# ------------------------------------------------------------
# Screenshot
# ------------------------------------------------------------
bind = $mainMod SHIFT, S, exec, grim -g "$(slurp)" - | wl-copy
EOF

    ok "hyprland.conf personalizado criado"
}

reload_hyprland() {
    if command -v hyprctl >/dev/null 2>&1; then
        log "Recarregando Hyprland"
        hyprctl reload || warn "Hyprland não pôde ser recarregado agora"
    fi
}

main() {
    require_arch
    require_not_root
    ensure_sudo
    require_yay

    install_pacman_packages
    install_aur_packages
    clone_or_update_repo
    link_configs
    create_hypr_keyboard_config
    write_hyprland_conf
    reload_hyprland

    ok "Hyprland finalizado"
}

main "$@"