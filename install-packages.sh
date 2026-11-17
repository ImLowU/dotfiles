#!/usr/bin/env bash
# Instala los programas de la config (Arch Linux + Hyprland).
# Uso: ./install-packages.sh
set -euo pipefail

# --- Comprobaciones ---------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
    echo "No ejecutes este script como root (yay/makepkg no lo permiten)." >&2
    exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
    echo "Este script es solo para Arch Linux (o derivadas con pacman)." >&2
    exit 1
fi

# --- Paquetes ----------------------------------------------------------------
# Se instalan con yay para que resuelva solo si cada paquete esta en los
# repos oficiales o en el AUR.
PACKAGES=(
    # Escritorio y sesion
    hyprland
    hyprpolkitagent
    waybar
    rofi            # rofi 2.x ya incluye soporte Wayland (antes: rofi-wayland)
    wlogout         # AUR
    swaync

    # Terminal y editor
    kitty
    vscodium-bin    # AUR

    # Musica y audio
    mpd
    rmpc
    cava

    # Apps
    vesktop

    # Theming
    matugen
    gtk3
    gtk4
    kvantum
)

# --- yay ---------------------------------------------------------------------
if ! command -v yay >/dev/null 2>&1; then
    echo ">> yay no esta instalado. Instalando..."
    sudo pacman -S --needed --noconfirm base-devel git
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
    (cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
fi

# --- Instalacion -------------------------------------------------------------
echo ">> Instalando ${#PACKAGES[@]} paquetes..."
yay -S --needed "${PACKAGES[@]}"

# --- Notas finales -----------------------------------------------------------
cat <<'EOF'

Listo. Pasos opcionales:
  - Activar mpd para tu usuario:   systemctl --user enable --now mpd
  - Copiar/enlazar tus dotfiles a ~/.config (hypr, waybar, rofi, kitty, etc.)
EOF
