#!/usr/bin/env bash
# copiar-config.sh
# Copia rutas específicas de ~/.config y ~/.local hacia ~/dotfiles/,
# preservando symlinks, permisos y la estructura exacta de subcarpetas.
#
# Cada ruta fue validada contra un `find` real de ambos directorios, para
# no arrastrar cachés/basura de apps (discord/, gtk-4.0-backup, VSCodium
# caches, vesktop sessionData, etc.) ni contenido no versionable.

set -euo pipefail

# --- Configuración por defecto -------------------------------------------
ORIGEN_HOME="${1:-$HOME}"
DESTINO_BASE="${2:-$HOME/dotfiles}"

# --- Rutas dentro de ~/.config (relativas a $ORIGEN_HOME/.config) ---------
RUTAS_CONFIG=(
    # cava (carpeta completa: config, shaders, themes)
    "cava/config"
    "cava/shaders"
    "cava/themes"

    # colorschemes (carpeta completa: 12 temas + scripts)
    "colorschemes"

    # colorschemes_backup (carpeta completa, mismos 12 elementos que colorschemes)
    "colorschemes_backup"

    # gtk-3.0 (carpeta completa)
    "gtk-3.0"

    # gtk-4.0 (carpeta completa)
    # OJO: NO confundir con gtk-4.0-backup ni gtk-4.0.backup, que existen en
    # el ~/.config real pero NO se copian (no están en este array).
    "gtk-4.0"

    # hypr (carpeta completa: colors, hyprland.lua, hyprlock, scripts)
    "hypr/colors"
    "hypr/hyprland.lua"
    "hypr/hyprlock"
    "hypr/scripts"

    # hyprpolkitagent (carpeta completa)
    "hyprpolkitagent"

    # kitty (carpeta completa)
    "kitty"

    # Kvantum (carpeta completa)
    "Kvantum"

    # matugen (carpeta completa)
    "matugen"

    # mpd (carpeta completa)
    "mpd"

    # rmpc (carpeta completa)
    "rmpc"

    # rofi (carpeta completa: applets, colors, config.rasi, images, launchers, powermenu, scripts)
    "rofi/applets"
    "rofi/colors"
    "rofi/config.rasi"
    "rofi/images"
    "rofi/launchers"
    "rofi/powermenu"
    "rofi/scripts"

    # swaync (carpeta completa)
    "swaync"

    # vesktop (SOLO themes; sessionData, Crashpad, ExtensionCache, settings
    # quedan afuera a propósito, son cachés/datos de sesión de la app)
    "vesktop/themes"

    # VSCodium (SOLO settings.json; globalStorage, History, snippets,
    # workspaceStorage, chatLanguageModels.json y todas las cachés quedan afuera)
    "VSCodium/User/settings.json"

    # waybar (carpeta completa)
    "waybar"

    # wlogout (carpeta completa)
    "wlogout"
)

# --- Rutas dentro de ~/.local (relativas a $ORIGEN_HOME/.local) -----------
RUTAS_LOCAL=(
    # fuentes personales (carpeta completa: Inter, InterDisplay, Icomoon,
    # GrapeNuts, Iosevka, JetBrains Mono Nerd Font, etc.)
    "fonts"

    # rofi (solo colors, historial de calculadora y themes)
    "rofi/colors"
    "rofi/rofi_calc_history"
    "rofi/themes"

    # share (fuentes y rofi a nivel de usuario)
    "share/fonts"
    "share/rofi"
)

# --- Rutas sueltas directamente en $HOME (relativas a $ORIGEN_HOME) -------
RUTAS_HOME=(
    ".zprofile"
)

# --- Función de copia genérica ---------------------------------------------
# $1 = carpeta origen, $2 = carpeta destino, $3 = nombre del array de rutas
copiar_bloque() {
    local origen="$1"
    local destino="$2"
    local -n rutas_ref="$3"

    if [[ ! -d "$origen" ]]; then
        echo "Error: la carpeta origen '$origen' no existe." >&2
        return 1
    fi

    mkdir -p "$destino"

    echo "== Bloque: $origen -> $destino =="

    pushd "$origen" > /dev/null

    for ruta in "${rutas_ref[@]}"; do
        if [[ -e "$ruta" || -L "$ruta" ]]; then
            echo ">> Copiando: $ruta"
            rsync -avR "$ruta" "$destino"/
        else
            echo "!! Aviso: '$ruta' no existe en el origen, se omite." >&2
        fi
    done

    popd > /dev/null
    echo
}

# --- Función de copia completa (todo el directorio, sin lista de rutas) ---
# Para ~/.icons: es una colección completa de temas de iconos (~150 carpetas),
# no tiene sentido enumerarlas una por una como en los otros bloques.
copiar_completo() {
    local origen="$1"
    local destino="$2"

    if [[ ! -d "$origen" ]]; then
        echo "Error: la carpeta origen '$origen' no existe." >&2
        return 1
    fi

    mkdir -p "$destino"

    echo "== Bloque completo: $origen -> $destino =="
    rsync -av "$origen"/ "$destino"/
    echo
}

# --- Ejecución ---------------------------------------------------------
echo "Origen : $ORIGEN_HOME"
echo "Destino: $DESTINO_BASE"
echo

copiar_bloque "$ORIGEN_HOME/.config" "$DESTINO_BASE/.config" RUTAS_CONFIG
copiar_bloque "$ORIGEN_HOME/.local"  "$DESTINO_BASE/.local"  RUTAS_LOCAL
copiar_completo "$ORIGEN_HOME/.icons" "$DESTINO_BASE/.icons"
copiar_completo "$ORIGEN_HOME/.themes" "$DESTINO_BASE/.themes"
copiar_bloque "$ORIGEN_HOME" "$DESTINO_BASE" RUTAS_HOME

echo "Listo. Copia finalizada en: $DESTINO_BASE"
