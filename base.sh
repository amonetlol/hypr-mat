#!/usr/bin/env bash

set -euo pipefail

log() {
    printf "\n[BASE] %s\n" "$1"
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

install_pacman_packages() {
    local packages=("$@")

    log "Instalando pacotes base via pacman"

    sudo pacman -Syu --needed --noconfirm "${packages[@]}"
}

install_yay_bin() {
    if command -v yay >/dev/null 2>&1; then
        ok "yay já instalado"
        return
    fi

    log "Instalando yay-bin via AUR"

    local tmp_dir
    tmp_dir="$(mktemp -d)"

    git clone https://aur.archlinux.org/yay-bin.git "$tmp_dir/yay-bin"

    cd "$tmp_dir/yay-bin"
    makepkg -si --noconfirm

    cd - >/dev/null
    rm -rf "$tmp_dir"

    ok "yay-bin instalado"
}

download_bash_files() {
    log "Baixando arquivos bash para HOME"

    declare -A files=(
        [".bashrc"]="https://github.com/amonetlol/dot/raw/refs/heads/main/dotfiles/bash/.bashrc"
        [".bash_profile"]="https://github.com/amonetlol/dot/raw/refs/heads/main/dotfiles/bash/.bash_profile"
        [".aliases"]="https://github.com/amonetlol/dot/raw/refs/heads/main/dotfiles/bash/.aliases"
        [".aliases-arch"]="https://github.com/amonetlol/dot/raw/refs/heads/main/dotfiles/bash/.aliases-arch"
        [".functions"]="https://github.com/amonetlol/dot/raw/refs/heads/main/dotfiles/bash/.functions"
    )

    for filename in "${!files[@]}"; do
        local destination="$HOME/$filename"
        local url="${files[$filename]}"

        rm -f "$destination"
        wget -q --show-progress -O "$destination" "$url"

        ok "$filename atualizado em $HOME"
    done
}

setup_vmtools() {
    log "Ativando open-vm-tools"

    sudo systemctl enable vmtoolsd.service

    ok "vmtoolsd ativado"
}

setup_ssh() {
    log "Ativando SSH"

    sudo systemctl enable sshd.service

    ok "SSH ativado"
}

setup_sddm_theme() {
    log "Instalando SDDM e tema personalizado"

    local tmp_script
    tmp_script="$(mktemp)"

    wget -q --show-progress -O "$tmp_script" \
        "https://github.com/amonetlol/scripts/raw/refs/heads/main/sddm_theme.sh"

    chmod +x "$tmp_script"
    bash "$tmp_script"

    rm -f "$tmp_script"

    ok "Tema do SDDM instalado"
}

enable_sddm() {
    log "Habilitando SDDM"

    sudo systemctl enable sddm.service

    if systemctl is-active --quiet sddm.service; then
        ok "SDDM já está ativo"
    else
        sudo systemctl enable sddm.service || warn "Não foi possível iniciar o SDDM agora, mas ele foi habilitado para o próximo boot"
    fi
}

setup_locale_ptbr() {
    log "Configurando locale pt_BR.UTF-8"

    if grep -q '^#pt_BR.UTF-8 UTF-8' /etc/locale.gen; then
        sudo sed -i 's/^#pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/' /etc/locale.gen
    fi

    if ! grep -q '^pt_BR.UTF-8 UTF-8' /etc/locale.gen; then
        echo 'pt_BR.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen >/dev/null
    fi

    sudo locale-gen
    sudo localectl set-locale LANG=pt_BR.UTF-8

    ok "Locale pt_BR.UTF-8 configurado"
}

setup_xdg_user_dirs_ptbr() {
    log "Configurando xdg-user-dirs em PT-BR"

    export LANG=pt_BR.UTF-8
    export LC_ALL=pt_BR.UTF-8

    xdg-user-dirs-update --force

    ok "Diretórios do usuário configurados em PT-BR"
}

main() {
    require_arch
    require_not_root
    ensure_sudo

    install_pacman_packages \
        base-devel \
        git \
        wget \
        curl \
        rsync \
        starship \
        open-vm-tools \
        gtkmm3 \
        fuse2 \
        fuse3 \
        sddm \
        p7zip \
        thunar \
        thunar-volman \
        thunar-archive-plugin \
        thunar-media-tags-plugin \
        gvfs \
        thumbler \
        xdg-user-dirs \
        xdg-user-dirs-gtk \
        xarchiver \
        unzip \
        zip \
        unrar \
        openssh \
        eza
        fd \
        fzf \        
        bat \        
        htop \
        zoxide \
        jq \
        ripgrep \
        bat \
        mousepad
        
    
    setup_locale_ptbr
    setup_xdg_user_dirs_ptbr

    install_yay_bin
    download_bash_files
    setup_vmtools
    setup_ssh
    setup_sddm_theme
    enable_sddm

    ok "Base finalizada"
}

main "$@"