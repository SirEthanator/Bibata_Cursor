#!/bin/bash
# A script for preparing binaries of Bibata Cursors, created by Abdulkaiz Khatri.

version="v2.0.6"

error() (
  set -o pipefail
  "$@" 2> >(sed $'s,.*,\e[31m&\e[m,' >&2)
)

get_config_path() {
  local key="${1}"
  local cfg_path="configs"

  if [[ $key == *"Right"* ]]; then
    cfg_path="${cfg_path}/right"
  else
    cfg_path="${cfg_path}/normal"
  fi

  echo $cfg_path
}

with_version() {
  local comment="${1}"
  echo "$comment ($version)."
}

if ! type -p ctgen >/dev/null; then
  error ctgen
  exit 127 # exit program with "command not found" error code
fi

declare -A names
names["Bibata-Modern-Everforest"]=$(with_version "Everforest and rounded edge Bibata")
names["Bibata-Modern-Everforest-Light"]=$(with_version "Light Everforest and rounded edge Bibata")
names["Bibata-Modern-CatMocha"]=$(with_version "Catppuccin Mocha and rounded edge Bibata")
names["Bibata-Modern-CatLatte"]=$(with_version "Catppuccin Latte and rounded edge Bibata")
names["Bibata-Modern-Rose-Pine"]=$(with_version "Rose Pine and rounded edge Bibata")
names["Bibata-Modern-Rose-Pine-Dawn"]=$(with_version "Rose Pine Dawn and rounded edge Bibata")
names["Bibata-Modern-Material"]=$(with_version "Material Dark and rounded edge Bibata")
names["Bibata-Modern-Material-Light"]=$(with_version "Material Light and rounded edge Bibata")

if [[ "$#" -gt 0 ]]; then
  declare -A tmp
  for key in "$@"; do [[ -v names[$key] ]] && tmp[$key]="${names[$key]}"; done

  unset names
  declare -A names
  for key in "${!tmp[@]}"; do
    names[$key]="${tmp[$key]}"
  done

  unset tmp
fi

# Cleanup old builds
rm -rf themes bin

# Building Bibata XCursor binaries
for key in "${!names[@]}"; do
  comment="${names[$key]}"
  cfg_path=$(get_config_path "$key")

  ctgen "$cfg_path/x.build.toml" -p x11 -d "bitmaps/$key" -n "$key" -c "$comment XCursors" &
  PID=$!
  wait $PID
done

# Building Bibata Windows binaries
for key in "${!names[@]}"; do
  comment="${names[$key]}"
  cfg_path=$(get_config_path "$key")

  ctgen "$cfg_path/win_rg.build.toml" -d "bitmaps/$key" -n "$key-Regular" -c "$comment Windows Cursors" &
  ctgen "$cfg_path/win_lg.build.toml" -d "bitmaps/$key" -n "$key-Large" -c "$comment Windows Cursors" &
  ctgen "$cfg_path/win_xl.build.toml" -d "bitmaps/$key" -n "$key-Extra-Large" -c "$comment Windows Cursors" &
  PID=$!
  wait $PID
done

# Generate Hyprcursors and compress binaries
mkdir -p bin
cd themes || exit

for key in "${!names[@]}"; do
  mkdir tmp
  hyprcursor-util -x "$key" -o tmp
  hyprcursor-util -c tmp/extracted* -o tmp
  mv 'tmp/theme_Extracted Theme'/* "$key"
  rm -rf tmp
  tar -cJvf "../bin/${key}.tar.xz" "${key}" &
  PID=$!
  wait $PID
done

# Compressing Bibata.tar.xz
cp ../LICENSE .
tar -cJvf "../bin/Bibata.tar.xz" --exclude="*-Windows" . &
PID=$!
wait $PID

# Compressing Bibata-*-Windows
for key in "${!names[@]}"; do
  zip -rv "../bin/${key}-Windows.zip" "${key}-Small-Windows" "${key}-Regular-Windows" "${key}-Large-Windows" "${key}-Extra-Large-Windows" &
  PID=$!
  wait $PID
done

cd ..

# Copying License File for 'bitmaps'
cp LICENSE bitmaps/
zip -rv bin/bitmaps.zip bitmaps

