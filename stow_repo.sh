#!/usr/bin/env bash

set -euo pipefail

REPO_URL="https://github.com/ElhamSadiqi/hypr-theme-engine"
DOT2_DIR="$HOME/.dot2"
PACKAGE_NAME="hypr-theme-engine"
PACKAGE_DIR="$DOT2_DIR/$PACKAGE_NAME"
TMP_DIR="$(mktemp -d)"

log() {
    printf "\n[STOW] %s\n" "$1"
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

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

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

ensure_deps() {
    log "Verificando dependências"

    local missing=()

    for cmd in git stow rsync; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log "Instalando dependências: ${missing[*]}"
        sudo pacman -S --needed --noconfirm "${missing[@]}"
    fi

    ok "Dependências prontas"
}

backup_path() {
    local target="$1"

    if [[ -e "$target" || -L "$target" ]]; then
        local backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
        mv "$target" "$backup"
        warn "Backup criado: $backup"
    fi
}

clone_repo() {
    log "Clonando repo base"

    git clone --depth 1 "$REPO_URL" "$TMP_DIR/repo"

    ok "Repo clonado"
}

prepare_package() {
    log "Preparando pacote Stow em $PACKAGE_DIR"

    backup_path "$PACKAGE_DIR"
    mkdir -p "$PACKAGE_DIR/.config"

    local repo="$TMP_DIR/repo"

    if [[ -d "$repo/config" ]]; then
        rsync -a "$repo/config/" "$PACKAGE_DIR/.config/"
        ok "config/ copiado para $PACKAGE_DIR/.config"
    else
        warn "Pasta config/ não encontrada no repo"
    fi

    if [[ -d "$repo/scripts" ]]; then
        mkdir -p "$PACKAGE_DIR/.local/bin/hypr-theme-engine"
        rsync -a "$repo/scripts/" "$PACKAGE_DIR/.local/bin/hypr-theme-engine/"
        chmod -R +x "$PACKAGE_DIR/.local/bin/hypr-theme-engine" 2>/dev/null || true
        ok "scripts/ copiado para ~/.local/bin/hypr-theme-engine"
    else
        warn "Pasta scripts/ não encontrada no repo"
    fi

    if [[ -d "$repo/themes" ]]; then
        mkdir -p "$PACKAGE_DIR/.config/hypr-theme-engine/themes"
        rsync -a "$repo/themes/" "$PACKAGE_DIR/.config/hypr-theme-engine/themes/"
        ok "themes/ copiado para ~/.config/hypr-theme-engine/themes"
    else
        warn "Pasta themes/ não encontrada no repo"
    fi

    if [[ -d "$repo/assets" ]]; then
        mkdir -p "$PACKAGE_DIR/.config/hypr-theme-engine/assets"
        rsync -a "$repo/assets/" "$PACKAGE_DIR/.config/hypr-theme-engine/assets/"
        ok "assets/ copiado para ~/.config/hypr-theme-engine/assets"
    else
        warn "Pasta assets/ não encontrada no repo"
    fi

    if [[ -f "$repo/README.md" ]]; then
        cp "$repo/README.md" "$PACKAGE_DIR/README.hypr-theme-engine.md"
    fi

    ok "Pacote Stow preparado"
}

backup_stow_targets() {
    log "Fazendo backup dos destinos que podem conflitar"

    local targets=(
        "$HOME/.config/hypr-theme-engine"
        "$HOME/.local/bin/hypr-theme-engine"
    )

    local config_dirs=()

    if [[ -d "$PACKAGE_DIR/.config" ]]; then
        while IFS= read -r dir; do
            config_dirs+=("$HOME/.config/$(basename "$dir")")
        done < <(find "$PACKAGE_DIR/.config" -mindepth 1 -maxdepth 1 -type d | sort)
    fi

    targets+=("${config_dirs[@]}")

    for target in "${targets[@]}"; do
        if [[ -e "$target" || -L "$target" ]]; then
            case "$target" in
                "$PACKAGE_DIR"/*)
                    continue
                    ;;
            esac

            backup_path "$target"
        fi
    done

    ok "Backups concluídos"
}

apply_stow() {
    log "Aplicando GNU Stow"

    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/bin"

    cd "$DOT2_DIR"

    stow -v -t "$HOME" "$PACKAGE_NAME"

    ok "Stow aplicado"
}

main() {
    require_arch
    require_not_root
    ensure_deps
    clone_repo
    prepare_package
    backup_stow_targets
    apply_stow

    ok "hypr-theme-engine instalado via Stow em ~/.dot2"
}

main "$@"