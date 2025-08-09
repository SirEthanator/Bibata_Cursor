#!/bin/bash

ROOT="$( cd -- "$(dirname "$0")" || exit 1 > /dev/null 2>&1 ; pwd -P )"

if [[ -n "$1" ]]; then
  json="${ROOT}/schemes/${1}.json"
else
  "$ROOT"/gen_render_json.sh
  json="${ROOT}/render.json"
fi

npx cbmp "$json"
"$ROOT"/build.sh "$@"

