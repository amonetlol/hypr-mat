#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RICE_DIR="$ROOT_DIR/Rice"

THEMES_DIR="$HOME/.themes"
ICONS_DIR="$HOME/.icons"

log() {
    printf "\n[RICE] %s\n" "$1"
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

extract_xz() {
    local file="$1"
    local target="$2"

    if [[ ! -f "$file" ]]; then
        warn "Arquivo não encontrado: $(basename "$file")"
        return
    fi

    log "Extraindo $(basename "$file") para $target"

    tar -xJf "$file" -C "$target"

    ok "$(basename "$file") extraído"
}

main() {
    if [[ ! -d "$RICE_DIR" ]]; then
        die "Pasta Rice não encontrada em $ROOT_DIR"
    fi

    mkdir -p "$THEMES_DIR"
    mkdir -p "$ICONS_DIR"

    log "Extraindo temas GTK para ~/.themes"

    extract_xz "$RICE_DIR/MacTahoe-Dark-nord.tar.xz" "$THEMES_DIR"
    extract_xz "$RICE_DIR/MacTahoe-Dark.tar.xz" "$THEMES_DIR"

    log "Extraindo ícones e cursores para ~/.icons"

    extract_xz "$RICE_DIR/MacTahoe-blue.tar.xz" "$ICONS_DIR"
    extract_xz "$RICE_DIR/MacTahoe-grey.tar.xz" "$ICONS_DIR"
    extract_xz "$RICE_DIR/MacTahoe-nord.tar.xz" "$ICONS_DIR"
    extract_xz "$RICE_DIR/01-MacTahoe.tar.xz" "$ICONS_DIR"
    extract_xz "$RICE_DIR/01-Qogir-cursors.tar.xz" "$ICONS_DIR"

    ok "Rice finalizado"
}

main "$@"