#!/bin/bash

TARGET_DIR="/home/lowu/Música"

# --- Parseo de argumentos ---
SEARCH_LYRICS=false

usage() {
    echo "Uso: $0 [-l|--lyrics] <enlace_de_video_o_audio>"
    echo "  -l, --lyrics    Buscar y descargar la letra sincronizada (.lrc)"
    exit 1
}

# Recorremos los argumentos para separar flags del enlace
ARGS=()
while [ $# -gt 0 ]; do
    case "$1" in
        -l|--lyrics)
            SEARCH_LYRICS=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

# Restauramos los argumentos posicionales (sin los flags)
set -- "${ARGS[@]}"

# Validar que se haya pasado un argumento (el enlace)
if [ -z "$1" ]; then
    echo "Error: No se proporcionó ningún enlace de descarga."
    usage
fi

link="$1"

echo "Descargando canción..."

# Descarga y captura de la ruta del archivo
songPath=$(yt-dlp -x -q --no-warnings \
    -P "$TARGET_DIR" \
    -o "%(title)s.%(ext)s" \
    --print after_move:filepath \
    --no-write-description \
    --embed-thumbnail \
    --embed-metadata \
    --audio-format m4a \
    --audio-quality 0 \
    "$link")

# Validar si yt-dlp realmente descargó algo
if [ -z "$songPath" ] || [ ! -f "$songPath" ]; then
    echo "Error: La descarga falló o no se pudo obtener la ruta del archivo."
    exit 1
fi

echo "Extrayendo metadatos..."
songTitle=$(exiftool -Title -s -s -s "$songPath")
songArtist=$(exiftool -Artist -s -s -s "$songPath")

# Si exiftool no encuentra título, usamos el nombre del archivo sin extensión como fallback
if [ -z "$songTitle" ]; then
    songTitle=$(basename "$songPath" | sed 's/\.[^.]*$//')
fi

echo ""
echo "=== Pre-visualización de datos ==="
echo "Ruta:   $songPath"
echo "Título: $songTitle"
echo "Artista:${songArtist:-" Desconocido"}"
echo "=================================="
echo ""

# --- Búsqueda de letra (opcional) ---
if [ "$SEARCH_LYRICS" = true ]; then
    echo "Creando archivo para lyrics..."
    lyricsFile="$TARGET_DIR/${songTitle}.lrc"

    echo "[ti:$songTitle]" > "$lyricsFile"
    if [ -n "$songArtist" ]; then
        echo "[ar:$songArtist]" >> "$lyricsFile"
        searchQuery="$songTitle - $songArtist"
    else
        searchQuery="$songTitle"
    fi

    echo "Buscando letra para: $searchQuery..."
    if syncedlyrics "$searchQuery" -o "$lyricsFile"; then
        echo "✓ Letra sincronizada agregada a: $lyricsFile"
    else
        echo "No se pudo encontrar o descargar la letra para esta canción."
    fi
else
    echo "Búsqueda de letra omitida (usa -l para activarla)."
fi

echo ""
echo "Actualizando portada y metadatos con MusicBrainz Picard..."
picard -e LOAD "$songPath" -e SCAN -e LOOKUP -e SAVE_MODIFIED -e QUIT > /dev/null 2>&1

echo ""
echo "Secuencia Finalizada. Canción procesada con éxito."
echo ""