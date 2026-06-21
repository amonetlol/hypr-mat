#!/usr/bin/env bash

set -euo pipefail

APP_DIR_SYSTEM="/usr/share/applications"
APP_DIR_LOCAL="$HOME/.local/share/applications"

log() {
    printf "\n[ROFI APPS] %s\n" "$1"
}

ok() {
    printf "[OK] %s\n" "$1"
}

warn() {
    printf "[AVISO] %s\n" "$1"
}

mkdir -p "$APP_DIR_LOCAL"

hide_desktop_by_name() {
    local wanted_name="$1"
    local found=0

    while IFS= read -r desktop_file; do
        local filename
        filename="$(basename "$desktop_file")"

        local local_file="$APP_DIR_LOCAL/$filename"

        cp "$desktop_file" "$local_file"

        if grep -q '^NoDisplay=' "$local_file"; then
            sed -i 's/^NoDisplay=.*/NoDisplay=true/' "$local_file"
        else
            printf '\nNoDisplay=true\n' >> "$local_file"
        fi

        ok "Ocultado: $wanted_name -> $filename"
        found=1
    done < <(
        grep -rilE "^Name(\[[^]]+\])?=${wanted_name}$" \
            "$APP_DIR_SYSTEM" "$APP_DIR_LOCAL" 2>/dev/null || true
    )

    if [[ "$found" -eq 0 ]]; then
        warn "Não encontrado: $wanted_name"
    fi
}

hide_desktop_by_filename() {
    local filename="$1"
    local system_file="$APP_DIR_SYSTEM/$filename"
    local local_file="$APP_DIR_LOCAL/$filename"

    if [[ -f "$system_file" ]]; then
        cp "$system_file" "$local_file"
    elif [[ -f "$local_file" ]]; then
        :
    else
        warn "Não encontrado por arquivo: $filename"
        return
    fi

    if grep -q '^NoDisplay=' "$local_file"; then
        sed -i 's/^NoDisplay=.*/NoDisplay=true/' "$local_file"
    else
        printf '\nNoDisplay=true\n' >> "$local_file"
    fi

    ok "Ocultado: $filename"
}

rename_desktop_by_name() {
    local old_name="$1"
    local new_name="$2"
    local found=0

    while IFS= read -r desktop_file; do
        local filename
        filename="$(basename "$desktop_file")"

        local local_file="$APP_DIR_LOCAL/$filename"

        cp "$desktop_file" "$local_file"

        if grep -q '^Name=' "$local_file"; then
            sed -i "s/^Name=.*/Name=${new_name}/" "$local_file"
        else
            printf '\nName=%s\n' "$new_name" >> "$local_file"
        fi

        # Remove nomes localizados em pt_BR/pt, se existirem, para não sobrescrever no Rofi
        sed -i '/^Name\[pt_BR\]=/d' "$local_file"
        sed -i '/^Name\[pt\]=/d' "$local_file"

        ok "Renomeado: $old_name -> $new_name"
        found=1
    done < <(
        grep -rilE "^Name(\[[^]]+\])?=${old_name}$" \
            "$APP_DIR_SYSTEM" "$APP_DIR_LOCAL" 2>/dev/null || true
    )

    if [[ "$found" -eq 0 ]]; then
        warn "Não encontrado para renomear: $old_name"
    fi
}

log "Ocultando atalhos indesejados"

hide_desktop_by_name "btop"
hide_desktop_by_name "foot client"
hide_desktop_by_name "foot server"
hide_desktop_by_name "Hardware Locality lstopo"
hide_desktop_by_name "Navegador de servidores SSH do avahi"
hide_desktop_by_name "Navegador de servidores VNC do avahi"
hide_desktop_by_name "Navegador Zeroconf do avahi"
hide_desktop_by_name "Neovim"
hide_desktop_by_name "Preferências do Thunar"
hide_desktop_by_name "Qt V4L2 vídeo capture utility"
hide_desktop_by_name "Rofi"
hide_desktop_by_name "Rofi Theme Selector"
hide_desktop_by_name "Vim"
hide_desktop_by_name "xgps"
hide_desktop_by_name "xgpsspeed"
hide_desktop_by_name "Utilitário de teste V4L2"
hide_desktop_by_name "Micro"
hide_desktop_by_name "Alacritty"

# Fallbacks por nome de arquivo comum
hide_desktop_by_filename "btop.desktop"
hide_desktop_by_filename "footclient.desktop"
hide_desktop_by_filename "foot-server.desktop"
hide_desktop_by_filename "foot-server.desktop"
hide_desktop_by_filename "avahi-discover.desktop"
hide_desktop_by_filename "bvnc.desktop"
hide_desktop_by_filename "bssh.desktop"
hide_desktop_by_filename "nvim.desktop"
hide_desktop_by_filename "vim.desktop"
hide_desktop_by_filename "rofi.desktop"
hide_desktop_by_filename "rofi-theme-selector.desktop"
hide_desktop_by_filename "micro.desktop"
hide_desktop_by_filename "Alacritty.desktop"
hide_desktop_by_filename "alacritty.desktop"
hide_desktop_by_filename "lstopo.desktop"
hide_desktop_by_filename "qv4l2.desktop"
hide_desktop_by_filename "qvidcap.desktop"
hide_desktop_by_filename "xgps.desktop"
hide_desktop_by_filename "xgpsspeed.desktop"
hide_desktop_by_filename "thunar-settings.desktop"

log "Renomeando Thunar"

rename_desktop_by_name "Gerenciador de Arquivos Thunar" "Thunar"
rename_desktop_by_name "Thunar File Manager" "Thunar"

# Fallback direto para o arquivo mais comum do Thunar
if [[ -f "$APP_DIR_SYSTEM/thunar.desktop" ]]; then
    cp "$APP_DIR_SYSTEM/thunar.desktop" "$APP_DIR_LOCAL/thunar.desktop"

    if grep -q '^Name=' "$APP_DIR_LOCAL/thunar.desktop"; then
        sed -i 's/^Name=.*/Name=Thunar/' "$APP_DIR_LOCAL/thunar.desktop"
    else
        printf '\nName=Thunar\n' >> "$APP_DIR_LOCAL/thunar.desktop"
    fi

    sed -i '/^Name\[pt_BR\]=/d' "$APP_DIR_LOCAL/thunar.desktop"
    sed -i '/^Name\[pt\]=/d' "$APP_DIR_LOCAL/thunar.desktop"

    ok "Thunar ajustado via thunar.desktop"
fi

log "Atualizando cache de atalhos"

update-desktop-database "$APP_DIR_LOCAL" 2>/dev/null || true

ok "Atalhos ajustados. Reinicie o Rofi ou abra novamente o menu."