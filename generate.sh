#!/bin/bash

if ! which cbmp; then
  echo 'Error: cbmp not found'
  echo 'Please install it from https://github.com/SirEthanator/cbmp-rs'
  exit 1
fi

ROOT="$( cd -- "$(dirname "$0")" || exit 1 > /dev/null 2>&1 ; pwd -P )"

if [[ -n "$1" ]]; then
  json="${ROOT}/schemes/${1}.json"
else
  "$ROOT"/gen_render_json.sh
  json="${ROOT}/render.json"
fi

(
  # Render jsons and build.sh use relative paths, so cd is needed.
  cd "$ROOT" || exit 1
  cbmp "$json"
  ./build.sh "$@"
)
