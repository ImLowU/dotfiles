#!/usr/bin/env bash

# ==========================================================
# Script para aplicar temas al entorno de escritorio.
# ==========================================================

set -Eeuo pipefail
IFS=$'\n\t'

GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

THEME="${1:-}"
THEME_DIR="$HOME/.config/colorschemes/$THEME"
CURRENT_THEME_FILE="$HOME/.config/colorschemes/.current-theme"
WALLPAPER_STATE="$HOME/.config/colorschemes/.wallpaper-state"

info(){ echo -e "${CYAN}➜ $1${NC}"; }
ok(){ echo -e "${GREEN}✔ $1${NC}"; }
warn(){ echo -e "${YELLOW}⚠ $1${NC}"; }

copiar_archivo() {
    local origen="$1"
    local destino="$2"
    if [[ -f "$origen" ]]; then
        mkdir -p "$(dirname "$destino")"
        cp "$origen" "$destino"
    else
        warn "No existe: $origen"
    fi
}

reiniciar_waybar() {
    pkill waybar >/dev/null 2>&1 || true
    ~/.config/waybar/scripts/launch.sh >/dev/null 2>&1 &
    disown
}

if [[ -z "$THEME" ]]; then
    warn "Uso: $0 <tema>"
    exit 1
fi

if [[ ! -d "$THEME_DIR" ]]; then
    warn "El tema '$THEME' no existe."
    notify-send "Error" "Tema no encontrado" -u critical
    exit 1
fi

echo "$THEME" > "$CURRENT_THEME_FILE"

info "Aplicando tema: $THEME"
notify-send "Cambio de tema" "Aplicando: $THEME"


# Hyprland
info "Hyprland"
copiar_archivo "$THEME_DIR/hypr/colors.lua" "$HOME/.config/hypr/colors/colors.lua"

# Waybar
info "Waybar"
copiar_archivo "$THEME_DIR/waybar/colors.css" "$HOME/.config/waybar/colors/colors.css"

# Fondo de pantalla
info "Fondo de pantalla"
WALLPAPER_DIR="$THEME_DIR/wallpapers"
touch "$WALLPAPER_STATE"

SAVED=$(grep "^$THEME:" "$WALLPAPER_STATE" 2>/dev/null | cut -d: -f2- || true)

if [[ -n "$SAVED" && -f "$SAVED" ]]; then
    WALL="$SAVED"
elif [[ -d "$WALLPAPER_DIR" ]]; then
    WALL=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | sort | head -n1 || true)
    if [[ -n "${WALL:-}" ]]; then
        sed -i "/^$THEME:/d" "$WALLPAPER_STATE"
        echo "$THEME:$WALL" >> "$WALLPAPER_STATE"
    fi
fi

if [[ -n "${WALL:-}" && -f "$WALL" ]]; then
    awww img "$WALL" --transition-type wipe --transition-fps 144 --transition-step 255
    ln -sf "$WALL" ~/.config/hypr/hyprlock/wallpaper
fi

# GTK
if [[ -f "$THEME_DIR/gtk-theme" ]]; then
    GTK_THEME=$(<"$THEME_DIR/gtk-theme")
    info "GTK: $GTK_THEME"
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
fi

# GTK4
if [[ -d "$THEME_DIR/gtk-4.0" ]]; then
    mkdir -p ~/.config/gtk-4.0
    ln -sf "$THEME_DIR/gtk-4.0/gtk.css" ~/.config/gtk-4.0/gtk.css
    ln -sf "$THEME_DIR/gtk-4.0/gtk-dark.css" ~/.config/gtk-4.0/gtk-dark.css
    ln -sfn "$THEME_DIR/gtk-4.0/assets" ~/.config/gtk-4.0/assets
fi

# Kitty
if [[ -f "$THEME_DIR/kitty/colors.conf" ]]; then
    copiar_archivo "$THEME_DIR/kitty/colors.conf" "$HOME/.config/kitty/colors/colors.conf"
    pgrep kitty | xargs -r kill -SIGUSR1
fi

# SwayNC
copiar_archivo "$THEME_DIR/swaync/colors.css" "$HOME/.config/swaync/colors/colors.css"
reiniciar_waybar

# Wlogout
copiar_archivo "$THEME_DIR/wlogout/colors.css" "$HOME/.config/wlogout/colors/colors.css"

# Rofi
copiar_archivo "$THEME_DIR/rofi/colors.rasi" "$HOME/.local/share/rofi/colors/colors.rasi"

# NvChad
copiar_archivo "$THEME_DIR/nvim/lua/chadrc.lua" "$HOME/.config/nvim/lua/chadrc.lua"

# VSCodium
if [[ -f "$THEME_DIR/vscodium-theme" ]]; then
    THEME_NAME=$(<"$THEME_DIR/vscodium-theme")
    SETTINGS="$HOME/.config/VSCodium/User/settings.json"
    if command -v jq >/dev/null; then
        tmp=$(mktemp)
        jq --arg theme "$THEME_NAME" '.["workbench.colorTheme"]=$theme' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    fi
fi

# Discord
copiar_archivo "$THEME_DIR/discord/current.theme.css" "$HOME/.config/vesktop/themes/current.theme.css"

notify-send "Tema aplicado" "$THEME"
ok "Proceso finalizado."
