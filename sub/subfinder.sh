#!/bin/bash

# Vars
urls=""
TODAY=$(date +%F)
output_file="./sub/hosts.txt"

# Clear output
> "$output_file"

# Usage help
usage() {
  echo "Usage: $0 -i <urls_file>"
  exit 1
}

# Parse flags
while getopts ":i:" opt; do
  case $opt in
    i) urls="$OPTARG" ;;
    *) usage ;;
  esac
done

# Validate input
if [[ -z "$urls" ]]; then
  echo "❌ Missing input URLs file (-i)"
  usage
fi

# Main loop
while read -r host; do
  [[ -z "$host" ]] && continue  # skip empty lines
  echo "[*] Running subfinder for domain: $host"

  last_output="./sub/${host}_${TODAY}.txt"
  subfinder -d "$host" -silent -o "$last_output"

  echo "$host" >> "$output_file"
  cat "$last_output" >> "$output_file"
done < "$urls"

# Deduplicate and add https:// prefix
sort -u "$output_file" -o "$output_file"
sed -i 's|^|https://|' "$output_file"

