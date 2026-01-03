ROOT="$( cd -- "$(dirname "$0")" || exit 1 > /dev/null 2>&1 ; pwd -P )"
rm -rf "${ROOT:?}"/{bin,bitmaps,themes}
