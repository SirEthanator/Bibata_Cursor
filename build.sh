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

# Install Linux Cursors
read -p "Install Linux cursors? (Y/n) " install
install=$(echo "$install" | tr '[:upper:]' '[:lower:]')

if [[ "$install" == 'y' || -z "$install" ]]; then
  read -p "Backup existing cursors? This will overwrite any existing backups. (y/N)" backup
  backup=$(echo "$backup" | tr '[:upper:]' '[:lower:]')
  echo "Installing..."
  cd themes

  if [[ "$backup" == 'y' ]]; then
    rm -rf "$HOME"/.icons/bak
    mkdir "$HOME"/.icons/bak
  fi

  for key in "${!names[@]}"; do
    if [[ -e "$HOME"/.icons/"$key" ]]; then
      if [[ "$backup" == 'y' ]]; then
        mv "$HOME"/.icons/"$key" "$HOME"/.icons/bak || exit 1
      else
        rm -rf "$HOME"/.icons/"$key"
      fi
    fi
    cp -r "$key" "$HOME"/.icons
  done
  echo 'Done!'
fi
