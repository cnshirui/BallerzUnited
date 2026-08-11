#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 || ! $1 =~ ^[0-9]{8}$ ]]; then
  echo "Usage: $0 YYYYMMDD" >&2
  exit 1
fi

date_prefix=$1
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

file_md5() {
  if command -v md5 >/dev/null 2>&1; then
    md5 -q -- "$1"
  elif command -v md5sum >/dev/null 2>&1; then
    md5sum -- "$1" | awk '{print $1}'
  else
    echo "Error: md5 or md5sum is required" >&2
    return 1
  fi
}

while IFS= read -r -d '' source; do
  filename=${source##*/}

  # Files already beginning with YYYYMMDD_ are left unchanged.
  if [[ $filename =~ ^[0-9]{8}_ ]]; then
    continue
  fi

  extension=${filename##*.}
  digest=$(file_md5 "$source")
  destination="$script_dir/${date_prefix}_${digest: -5}.${extension}"

  if [[ -e $destination ]]; then
    if cmp -s -- "$source" "$destination"; then
      echo "Skipping duplicate: $filename -> ${destination##*/}"
      continue
    fi

    echo "Error: destination already exists: ${destination##*/}" >&2
    exit 1
  fi

  mv -- "$source" "$destination"
  echo "$filename -> ${destination##*/}"
done < <(
  find "$script_dir" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
       -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.heic' \) \
    -print0
)
