#!/usr/bin/env bash
# Líneas lógicas (sin blancos ni comentarios) por archivo versionado bajo <ruta>.
# Usa scc o tokei si están; si no, un conteo aproximado con grep.
# Uso: medir.sh [ruta] [--top N]
set -euo pipefail
ruta="${1:-.}"
top=15
[[ "${2:-}" == "--top" ]] && top="${3:-15}"

excluir='(^|/)(node_modules|dist|build|vendor|\.next|coverage|__generated__|generated|migrations)/|\.lock$|-lock\.json$|\.min\.|\.snap$|\.svg$|\.(png|jpg|jpeg|gif|ico|pdf|woff2?)$'

if command -v scc >/dev/null 2>&1; then
  scc --no-cocomo --exclude-dir node_modules,dist,build,vendor,.next,coverage "$ruta"
  exit 0
fi
if command -v tokei >/dev/null 2>&1; then
  tokei --exclude node_modules --exclude dist --exclude build --exclude vendor "$ruta"
  exit 0
fi

cd "$ruta"
archivos=$(git ls-files 2>/dev/null || find . -type f)
total=0
tabla=""
while IFS= read -r f; do
  [[ -z "$f" || ! -f "$f" ]] && continue
  [[ "$f" =~ $excluir ]] && continue
  # Aproximado: quita blancos y líneas que solo son comentario (//, #, *, /*, --, <!--).
  n=$(grep -cvE '^\s*($|//|#|\*|/\*|\*/|--|<!--)' "$f" 2>/dev/null || true)
  total=$((total + n))
  tabla+="$n $f"$'\n'
done <<<"$archivos"

echo "total lineas logicas (aprox): $total"
echo "archivos: $(printf '%s' "$tabla" | grep -c . || true)"
echo "top $top:"
printf '%s' "$tabla" | sort -rn | head -n "$top"
