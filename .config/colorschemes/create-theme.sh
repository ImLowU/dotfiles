#!/usr/bin/env bash

# ==========================================================
# Script para generar un nuevo set de colores con matugen
# y organizarlo dentro de ~/.config/colorschemes/<tema>/
# con la estructura que espera apply-theme.sh
# ==========================================================

set -Eeuo pipefail
IFS=$'\n\t'

GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

info(){ echo -e "${CYAN}➜ $1${NC}"; }
ok(){ echo -e "${GREEN}✔ $1${NC}"; }
warn(){ echo -e "${YELLOW}⚠ $1${NC}"; }
err(){ echo -e "${RED}✖ $1${NC}"; }

COLORSCHEMES_DIR="$HOME/.config/colorschemes"
APPLY_SCRIPT="$HOME/.config/colorschemes/apply-theme.sh" # ajustá la ruta si vive en otro lado
HYPR_TEMPLATE="$COLORSCHEMES_DIR/._template/hypr/colors.lua" # "look and feel" fijo, solo cambia el require()

# ----------------------------------------------------------
# Mapa: ruta de salida de matugen (según tu config.toml) -> ruta relativa dentro del tema
# Si cambiás algún output_path en tu config de matugen, actualizá acá también.
# ----------------------------------------------------------
declare -A MATUGEN_MAP=(
    ["$HOME/.config/kitty/colors/matugen.conf"]="kitty/colors.conf"
    ["$HOME/.config/waybar/colors/matugen.css"]="waybar/colors.css"
    ["$HOME/.cache/wal/colors.json"]="pywalfox/colors.json"
    ["$HOME/.local/share/rofi/colors/matugen.rasi"]="rofi/colors.rasi"
    ["$HOME/.config/wlogout/colors/matugen.css"]="wlogout/colors.css"
    ["$HOME/.config/swaync/tokens/variables.css"]="swaync/colors.css"
    ["$HOME/.config/rmpc/themes/theme.ron"]="rmpc/theme.ron"
    
)
# Hyprland queda fuera de este mapa: matugen.lua trae los valores crudos de
# color, pero hypr/colors.lua es el archivo de "look and feel" que hace
# require("colors.custom.<tema>") a esos valores. Se arman los dos por
# separado más abajo.

# Cosas que matugen NO genera pero que apply-theme.sh sí espera.
# Si pasás --base <tema>, se copian desde ahí tal cual.
STATIC_ITEMS=(
    "gtk-theme"
    "gtk-icons"
    "gtk-4.0"
    "nvim/lua/chadrc.lua"
    "vscodium-theme"
)

uso() {
    cat <<EOF
Uso: $0 <nombre-tema> <wallpaper> [opciones]

Opciones:
  --base <tema-existente>   Copia desde ese tema las partes que matugen no genera
                             (gtk-theme, gtk-4.0, nvim, vscodium-theme, discord).
                             Default: el tema actualmente activo (.current-theme)
  --mode <dark|light>       Modo de esquema para matugen (default: dark)
  --type <scheme-type>      Tipo de esquema de matugen (ej: scheme-tonal-spot)
  --hypr-template <ruta>    Plantilla de hypr/colors.lua (default: $HYPR_TEMPLATE)
  --no-apply                No llamar a apply-theme.sh al finalizar
  -h, --help                Muestra esta ayuda
EOF
    exit 1
}

[[ $# -lt 2 ]] && uso

THEME="$1"; shift
WALLPAPER="$1"; shift

BASE_THEME=""
MODE="dark"
SCHEME_TYPE=""
DO_APPLY=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        --base) BASE_THEME="$2"; shift 2 ;;
        --mode) MODE="$2"; shift 2 ;;
        --type) SCHEME_TYPE="$2"; shift 2 ;;
        --hypr-template) HYPR_TEMPLATE="$2"; shift 2 ;;
        --no-apply) DO_APPLY=0; shift ;;
        -h|--help) uso ;;
        *) err "Opción desconocida: $1"; uso ;;
    esac
done

THEME_DIR="$COLORSCHEMES_DIR/$THEME"

[[ -z "$THEME" ]] && { err "Falta el nombre del tema."; uso; }
[[ ! -f "$WALLPAPER" ]] && { err "No existe el wallpaper: $WALLPAPER"; exit 1; }
command -v matugen >/dev/null 2>&1 || { err "matugen no está instalado o no está en el PATH."; exit 1; }

if [[ -d "$THEME_DIR" ]]; then
    warn "El tema '$THEME' ya existe en $THEME_DIR, se van a sobreescribir los archivos generados."
fi

mkdir -p "$THEME_DIR"

# ----------------------------------------------------------
# 1. Copiar tema base (partes estáticas que matugen no toca)
# ----------------------------------------------------------
if [[ -z "$BASE_THEME" && -f "$COLORSCHEMES_DIR/.current-theme" ]]; then
    BASE_THEME=$(<"$COLORSCHEMES_DIR/.current-theme")
    info "No se pasó --base, se usa el tema activo como base: $BASE_THEME"
fi

if [[ -n "$BASE_THEME" ]]; then
    BASE_DIR="$COLORSCHEMES_DIR/$BASE_THEME"
    if [[ ! -d "$BASE_DIR" ]]; then
        warn "El tema base '$BASE_THEME' no existe, se omite."
    else
        info "Copiando archivos estáticos desde el tema base: $BASE_THEME"
        for item in "${STATIC_ITEMS[@]}"; do
            src="$BASE_DIR/$item"
            dst="$THEME_DIR/$item"
            if [[ -e "$src" ]]; then
                mkdir -p "$(dirname "$dst")"
                cp -r "$src" "$dst"
            fi
        done
        ok "Archivos estáticos copiados."
    fi
fi

# ----------------------------------------------------------
# 2. Generar colores con matugen a partir del wallpaper
# ----------------------------------------------------------
info "Generando paleta con matugen (modo: $MODE)"

MATUGEN_ARGS=(image "$WALLPAPER" --mode "$MODE")
[[ -n "$SCHEME_TYPE" ]] && MATUGEN_ARGS+=(--type "$SCHEME_TYPE")

if ! matugen "${MATUGEN_ARGS[@]}"; then
    err "matugen falló al generar la paleta."
    exit 1
fi
ok "Paleta generada."

# ----------------------------------------------------------
# 3. Copiar los outputs de matugen a la estructura del tema
# ----------------------------------------------------------
info "Organizando archivos generados en $THEME_DIR"

for src in "${!MATUGEN_MAP[@]}"; do
    rel_dst="${MATUGEN_MAP[$src]}"
    dst="$THEME_DIR/$rel_dst"

    if [[ -f "$src" ]]; then
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        ok "  $rel_dst"
    else
        warn "  No se encontró: $src (revisá tu config de matugen)"
    fi
done

# ----------------------------------------------------------
# 3.1 Hyprland: separar valores de color y "look and feel"
# ----------------------------------------------------------
HYPR_RAW="$HOME/.config/hypr/colors/matugen.lua"

if [[ -f "$HYPR_RAW" ]]; then
    mkdir -p "$THEME_DIR/hypr/colors"
    cp "$HYPR_RAW" "$HOME/.config/hypr/colors/custom/$THEME.lua"
    ok "  hypr/colors/custom/$THEME.lua (valores de color)"
else
    warn "  No se encontró: $HYPR_RAW (revisá tu config de matugen)"
fi

if [[ -f "$HYPR_TEMPLATE" ]]; then
    cp "$HYPR_TEMPLATE" "$THEME_DIR/hypr/colors.lua"
    sed -i "1s|.*|local colors = require(\"colors.custom.$THEME\")|" "$THEME_DIR/hypr/colors.lua"
    ok "  hypr/colors.lua (require -> colors.custom.$THEME)"
else
    warn "  No se encontró la plantilla: $HYPR_TEMPLATE"
    warn "  Guardá tu 'look and feel' de Hyprland ahí (con cualquier require en la primera línea) y volvé a correr el script."
fi

# ----------------------------------------------------------
# 3.2 Discord/Vesktop
# ----------------------------------------------------------
DISCORD_SRC="$HOME/.config/vesktop/themes/matugen.css"
DISCORD_DIR="$THEME_DIR/discord"

if [[ -f "$DISCORD_SRC" ]]; then
    mkdir -p "$DISCORD_DIR"

    cp "$DISCORD_SRC" "$HOME/.config/vesktop/themes/custom/$THEME.theme.css"

    cat > "$DISCORD_DIR/current.theme.css" <<EOF
@import "custom/$THEME.theme.css";
EOF

    ok "  vesktop/themes/discord/custom/$THEME.theme.css"
    ok "  $THEME/discord/current.theme.css"
else
    warn "  No se encontró: $DISCORD_SRC"
fi

# ----------------------------------------------------------
# 4. Guardar el wallpaper dentro del tema
# ----------------------------------------------------------
mkdir -p "$THEME_DIR/wallpapers"
cp "$WALLPAPER" "$THEME_DIR/wallpapers/"
ok "Wallpaper copiado a $THEME_DIR/wallpapers/"

ok "Tema '$THEME' creado en $THEME_DIR"

# ----------------------------------------------------------
# 5. Aplicar el tema (reutiliza apply-theme.sh)
# ----------------------------------------------------------
if [[ "$DO_APPLY" -eq 1 ]]; then
    if [[ -x "$APPLY_SCRIPT" ]]; then
        info "Aplicando el tema recién creado..."
        "$APPLY_SCRIPT" "$THEME"
        echo "ejecutar SCRIPTS"
    else
        warn "No se encontró o no es ejecutable: $APPLY_SCRIPT"
        warn "Podés aplicarlo manualmente con: apply-theme.sh $THEME"
    fi
fi
