#!/bin/bash
# A script for preparing binaries of Bibata Cursors, created by Abdulkaiz Khatri, modified by SirEthanator.

version="v2.0.6"

ROOT="$(
  cd -- "$(dirname "$0")" || exit 1 >/dev/null 2>&1
  pwd -P
)"

error() {
  printf "\033[0;31mERROR: \033[0m%s\n" "$1"
  if [[ "$#" -gt 1 ]]; then
    shift
    for msg in "${@}"; do
      echo "$msg"
    done
  fi
  exit 1
}

warn() {
  printf "\033[0;33mWARN: \033[0m%s\n" "$1"
}

get_config_path() {
  local key="${1}"
  local cfg_path="configs"

  if [[ $key == *"Right"* ]]; then
    cfg_path="${cfg_path}/right"
  else
    cfg_path="${cfg_path}/normal"
  fi

  echo "${ROOT}/${cfg_path}"
}

with_version() {
  local comment="${1}"
  echo "$comment ($version)."
}

declare -A allNames
allNames["Bibata-Modern-Everforest"]=$(with_version "Everforest and rounded edge Bibata")
allNames["Bibata-Modern-Everforest-Light"]=$(with_version "Light Everforest and rounded edge Bibata")
allNames["Bibata-Modern-CatMocha"]=$(with_version "Catppuccin Mocha and rounded edge Bibata")
allNames["Bibata-Modern-CatLatte"]=$(with_version "Catppuccin Latte and rounded edge Bibata")
allNames["Bibata-Modern-Rose-Pine"]=$(with_version "Rose Pine and rounded edge Bibata")
allNames["Bibata-Modern-Rose-Pine-Dawn"]=$(with_version "Rose Pine Dawn and rounded edge Bibata")
allNames["Bibata-Modern-Material"]=$(with_version "Material Dark and rounded edge Bibata")
allNames["Bibata-Modern-Material-Light"]=$(with_version "Material Light and rounded edge Bibata")

is_valid_name() {
  local name="$1"
  for key in "${!allNames[@]}"; do
    if [[ "$name" == "$key" ]]; then
      return 0
    fi
  done

  return 1
}

declare -a names

skip_windows=false
skip_hyprcursors=false
skip_xcursors=false

skip_bitmaps=false
skip_archives=false

while [[ "$#" -gt 0 ]]; do
  case "$1" in
  --skip-windows)
    skip_windows=true
    ;;
  --skip-hyprcursors)
    skip_hyprcursors=true
    ;;
  --skip-xcursors)
    skip_xcursors=true
    ;;
  --skip-bitmaps)
    skip_bitmaps=true
    ;;
  --skip-archives)
    skip_archives=true
    ;;
  *)
    if is_valid_name "$1"; then
      names+=("$1")
    else
      error "Invalid option: ${1}"
    fi
    ;;
  esac
  shift
done

if [[ ${#names[@]} -eq 0 ]]; then
  for key in "${!allNames[@]}"; do
    names+=("$key")
  done
fi

if ! which ctgen >/dev/null 2>&1; then
  error 'ctgen not found.' 'Please install it from https://github.com/ful1e5/clickgen'
fi

if [[ $skip_bitmaps = false ]] && ! which cbmp >/dev/null 2>&1; then
  error 'cbmp-rs not found.' 'Please install it from https://github.com/SirEthanator/cbmp-rs'
fi

if [[ $skip_hyprcursors == false ]] && [[ $skip_xcursors == true ]]; then
  error 'Hyprcursor generation requires xcursors to be generated first.' 'To skip XCursors, also skip hyprcursors (run with --skip-hyprcursors).'
fi

# Generate bitmaps
if [[ $skip_bitmaps == false ]]; then
  (
    cd "$ROOT" || error "Failed to cd into ${ROOT}"
    echo 'Generating bitmaps...'
    ./gen_render_json.sh "${names[@]}"
    cbmp --quiet ./render.json
  )
fi

# Cleanup old builds
for key in "${names[@]}"; do
  # If XCursors are skipped, so are hyprcursors
  if [[ $skip_xcursors == false ]]; then
    echo "Cleaning old XCursors and hyprcursors (${key})..."
    rm -rf "${ROOT}/themes/${key}"

    if [[ $skip_archives == false ]]; then
      rm -f "${ROOT}/bin/${key}.tar.xz"
    fi
    echo "Done"
  fi

  if [[ $skip_windows == false ]]; then
    echo "Cleaning old Windows cursors (${key})..."
    rm -rf "${ROOT}/themes/${key}-Windows"

    if [[ $skip_archives == false ]]; then
      rm -f "${ROOT}/bin/${key}-Windows.tar.xz"
    fi
    echo "Done"
  fi
done

# Building Bibata XCursor binaries
if [[ $skip_xcursors == false ]]; then
  for key in "${names[@]}"; do
    comment="${allNames[$key]}"
    cfg_path=$(get_config_path "$key")

    ctgen "$cfg_path/x.build.toml" -p x11 -d "${ROOT}/bitmaps/${key}" -n "$key" -c "$comment XCursors"
  done
fi

# Building Bibata Windows binaries
if [[ $skip_windows == false ]]; then
  for key in "${names[@]}"; do
    comment="${allNames[$key]}"
    cfg_path=$(get_config_path "$key")

    ctgen "$cfg_path/win_rg.build.toml" -d "${ROOT}/bitmaps/$key" -n "$key-Regular" -c "$comment Windows Cursors"
    ctgen "$cfg_path/win_lg.build.toml" -d "${ROOT}/bitmaps/$key" -n "$key-Large" -c "$comment Windows Cursors"
    ctgen "$cfg_path/win_xl.build.toml" -d "${ROOT}/bitmaps/$key" -n "$key-Extra-Large" -c "$comment Windows Cursors"
  done
fi

# Generate Hyprcursors and compress binaries
if [[ ! -d "${ROOT}/bin" ]]; then
  mkdir "${ROOT}/bin"
fi

generate_hyprcursors() {
  tmpdir=$(mktemp -d '/tmp/bibata_hyprcursor_XXXXXX')
  hyprcursor-util -x "${ROOT}/themes/${key}" -o "$tmpdir" || return 1
  hyprcursor-util -c "$tmpdir"/extracted* -o "$tmpdir" || return 1
  mv "$tmpdir"/theme*/* "${ROOT}/themes/${key}" || return 1
  rm -rf "$tmpdir"
}

for key in "${names[@]}"; do
  if [[ $skip_hyprcursors == false ]]; then
    echo "Generating hyprcursors (${key})..."

    if ! generate_hyprcursors > /dev/null 2>&1; then
      warn "Hyprcursor generation failed"
    fi

    echo "Done"
  fi

  if [[ $skip_archives == false ]]; then
    [[ $skip_hyprcursors == false ]] && hyprcursor_str=" and hyprcursors" || hyprcursor_str=""
    echo "Adding XCursors${hyprcursor_str} to archive (${key})..."
    tar -cJf "${ROOT}/bin/${key}.tar.xz" "${ROOT}/themes/${key}" >/dev/null 2>&1
    echo "Done"
  fi
done

# Compressing Bibata-*-Windows
if [[ $skip_windows == false && $skip_archives == false ]]; then
  for key in "${names[@]}"; do
    echo "Zipping Windows cursors (${key})..."
    zip -rv "${ROOT}/bin/${key}-Windows.zip" "${ROOT}/themes/${key}-"{Small-Windows,Regular-Windows,Large-Windows,Extra-Large-Windows} >/dev/null 2>&1
    echo "Done"
  done
fi

cd ..

if [[ $skip_bitmaps == false && $skip_archives == false ]]; then
  # Copying License File for 'bitmaps'
  cp "${ROOT}/LICENSE" "${ROOT}/bitmaps/"

  echo "Zipping bitmaps..."
  zip -rv "${ROOT}/bin/bitmaps.zip" "${ROOT}/bitmaps" >/dev/null 2>&1
  echo "Done"
fi
