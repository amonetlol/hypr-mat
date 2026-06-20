#!/usr/bin/env bash

set -euo pipefail

HYPR_DIR="$HOME/.config/hypr"
HYPR_CONF="$HYPR_DIR/hyprland.conf"

FOOT_DIR="$HOME/.config/foot"
FOOT_CONF="$FOOT_DIR/foot.ini"

log() {
    printf "\n[HYPRLAND DEFAULT] %s\n" "$1"
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
    if ! command -v sudo >/dev/null 2>&1; then
        die "sudo não encontrado."
    fi

    sudo -v
}

backup_file() {
    local file="$1"

    if [[ -f "$file" || -L "$file" ]]; then
        local backup="${file}.bak.$(date +%Y%m%d-%H%M%S)"
        cp -a "$file" "$backup"
        warn "Backup criado: $backup"
    fi
}

write_hyprland_conf() {
    log "Gerando hyprland.conf personalizado"

    mkdir -p "$HYPR_DIR"

    backup_file "$HYPR_CONF"

    cat > "$HYPR_CONF" <<'EOF'
# ============================================================
# HYPRLAND CONFIG
# Base: latency-tech/hyprland-dotfiles
# Ajustes: Arch Linux + ABNT2 + apps definidos
# ============================================================

# ------------------------------------------------------------
# Variáveis de ambiente
# ------------------------------------------------------------
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland

# GTK
env = GDK_BACKEND,wayland
env = GDK_SCALE,1

# Qt
env = QT_QPA_PLATFORM,wayland
env = QT_AUTO_SCREEN_SCALE_FACTOR,1
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = QT_QPA_PLATFORMTHEME,qt5ct

# Apps
env = MOZ_ENABLE_WAYLAND,1
env = ELECTRON_OZONE_PLATFORM_HINT,wayland

# Cursor
env = XCURSOR_THEME,Qogir-cursors
env = XCURSOR_SIZE,24
env = HYPRCURSOR_THEME,Qogir-cursors
env = HYPRCURSOR_SIZE,24

# ------------------------------------------------------------
# Imports
# ------------------------------------------------------------
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
exec-once = waybar
exec-once = hyprctl setcursor Qogir-cursors 24

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
# Teclado e mouse
# ------------------------------------------------------------
input {
    kb_layout = br
    kb_variant = abnt2
    kb_model =
    kb_options =
    kb_rules =

    follow_mouse = 1
    sensitivity = 0
}

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

    ok "hyprland.conf personalizado criado em $HYPR_CONF"
}

write_foot_conf() {
    log "Gerando foot.ini personalizado"

    mkdir -p "$FOOT_DIR"

    backup_file "$FOOT_CONF"

    cat > "$FOOT_CONF" <<'EOF'
# Foot — Catppuccin Mocha (HyprPunk / dot-catppuccin)

font=JetBrainsMono Nerd Font:size=11
pad=8x8

[colors-dark]
foreground=74c7ec
background=1e1e2e

regular0=45475a
regular1=f38ba8
regular2=a6e3a1
regular3=f9e2af
regular4=89b4fa
regular5=cba6f7
regular6=94e2d5
regular7=bac2de

bright0=585b70
bright1=f38ba8
bright2=a6e3a1
bright3=f9e2af
bright4=89b4fa
bright5=cba6f7
bright6=94e2d5
bright7=a6adc8
EOF

    ok "foot.ini personalizado criado em $FOOT_CONF"
}

reload_hyprland() {
    if [[ "${XDG_CURRENT_DESKTOP:-}" == "Hyprland" ]] && command -v hyprctl >/dev/null 2>&1; then
        log "Recarregando Hyprland"
        hyprctl reload || warn "Hyprland não pôde ser recarregado agora"
    else
        warn "Hyprland não está ativo nesta sessão. Reload ignorado."
    fi
}

main() {
    require_arch
    require_not_root
    ensure_sudo

    write_hyprland_conf
    write_foot_conf
    reload_hyprland

    ok "Hyprland default finalizado"
}

main "$@"