#!/bin/bash

ROOT="$(
  cd -- "$(dirname "$0")" || exit 1 >/dev/null 2>&1
  pwd -P
)"

declare -a files

if [[ "$#" -lt 1 ]]; then
  echo "No schemes provided. Adding all schemes..."
  files=("$ROOT"/schemes/*)
else
  for scheme in "$@"; do
    path="${ROOT}/schemes/${scheme}.json"
    if [[ -e "$path" ]]; then
      files+=("$path")
    else
      echo "Warning: Scheme not found: ${scheme}. Skipping..."
    fi
  done
fi

if [[ "${#files}" -lt 1 ]]; then
  echo "Error: Nothing to do. Please provide at least one valid scheme."
  exit 1
fi

jq -s 'reduce .[] as $item ({}; . * $item)' "${files[@]}" >render.json
