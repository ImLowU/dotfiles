#!/usr/bin/env bash

# ==========================================================
# Selector de temas mediante Rofi.
#
# Muestra todos los temas disponibles dentro del directorio
# de colores y ejecuta el script encargado de aplicarlos.
# ==========================================================

# Detiene la ejecución ante cualquier error.
set -Eeuo pipefail

# Evita problemas con nombres de archivos que contienen espacios.
IFS=$'\n\t'

# ------------------------------------------------------------------
# Configuración
# ------------------------------------------------------------------

# Directorio donde se almacenan los temas.
THEME_DIR="$HOME/.config/colorschemes"

# Script encargado de aplicar el tema seleccionado.
APPLY_SCRIPT="$THEME_DIR/apply-theme.sh"

# Tema de Rofi utilizado para el menú.
ROFI_THEME="$THEME_DIR/rofi-theme.rasi"

# ------------------------------------------------------------------
# Validaciones
# ------------------------------------------------------------------

# Verifica que el directorio de temas exista.
if [[ ! -d "$THEME_DIR" ]]; then
    echo "Error: No existe el directorio de temas:"
    echo "  $THEME_DIR"
    exit 1
fi

# Verifica que el script de aplicación exista y sea ejecutable.
if [[ ! -x "$APPLY_SCRIPT" ]]; then
    echo "Error: No se encontró el script de aplicación o no tiene permisos de ejecución:"
    echo "  $APPLY_SCRIPT"
    exit 1
fi

# Verifica que Rofi esté instalado.
if ! command -v rofi >/dev/null 2>&1; then
    echo "Error: Rofi no está instalado."
    exit 1
fi

# ------------------------------------------------------------------
# Obtiene la lista de temas disponibles
# ------------------------------------------------------------------

mapfile -t THEMES < <(
    find "$THEME_DIR" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        ! -name ".*" \
        -printf "%f\n" \
        | sort
)

# Si no existen temas, termina la ejecución.
if [[ ${#THEMES[@]} -eq 0 ]]; then
    echo "No se encontraron temas disponibles."
    exit 1
fi

# ------------------------------------------------------------------
# Muestra el menú de selección
# ------------------------------------------------------------------

SELECTED_THEME=$(
    printf '%s\n' "${THEMES[@]}" |
    rofi \
        -dmenu \
        -p "Seleccionar tema" \
        -theme "$ROFI_THEME"
)

# ------------------------------------------------------------------
# Aplica el tema seleccionado
# ------------------------------------------------------------------

if [[ -n "$SELECTED_THEME" ]]; then
    exec "$APPLY_SCRIPT" "$SELECTED_THEME"
fi