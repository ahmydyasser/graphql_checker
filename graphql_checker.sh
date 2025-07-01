#!/bin/zsh

# Colors
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# Defaults
TODAY=$(date +%F)
input_file=""
output_file="graphql_results_$TODAY.txt"
path_file=""
declare -a graphql_paths_default=(
"/graphql"
"/graphiql"
"/v1/graphql"
"/v2/graphql"
"/v3/graphql"
"/v1/graphiql"
"/v2/graphiql"
"/v3/graphiql"
"/playground"
"/v1/playground"
"/v2/playground"
"/v3/playground"
"/api/v1/playground"
"/api/v2/playground"
"/api/v3/playground"
"/console"
"/api/graphql"
"/api/graphiql"
"/explorer"
"/api/v1/graphql"
"/api/v2/graphql"
"/api/v3/graphql"
"/api/v1/graphiql"
"/api/v2/graphiql"
"/api/v3/graphiql"
)

# Introspection query
INTROSPECTION_QUERY='?query={__schema%20{%0atypes%20{%0aname%0akind%0adescription%0afields%20{%0aname%0a}%0a}%0a}%0a}'

# Usage/help
usage() {
  echo "Usage: $0 -i <input_file> [-o <output_file>] [-p <graphql_paths_file>]"
  exit 1
}

# Parse flags
while getopts ":i:o:p:" opt; do
  case $opt in
    i) input_file="$OPTARG" ;;
    o) output_file="$OPTARG" ;;
    p) path_file="$OPTARG" ;;
    *) usage ;;
  esac
done

# Validate input
if [[ -z "$input_file" ]]; then
  echo "❌ Input file (-i) is required"
  usage
fi

# Load GraphQL paths
if [[ -n "$path_file" ]]; then
  mapfile -t graphql_paths < "$path_file"
else
  graphql_paths=("${graphql_paths_default[@]}")
fi

# Begin scanning
for host in $(cat "$input_file"); do
  for path in "${graphql_paths[@]}"; do
    full_url="${host}${path}"
    echo "[*] Testing $full_url"

    response=$(curl --connect-timeout 10 --max-time 20 -s -X POST "$full_url" \
      -d '{"query":"{__typename}"}' \
      -H "Content-Type: application/json" \
      -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:139.0) Gecko/20100101 Firefox/139.0")

    if echo "$response" | grep -q "\"data\""; then
      echo -e "${GREEN}[+] Found GraphQL in ($full_url) via POST${RESET}"
      echo "[+] $full_url (POST)" >> "$output_file"

      echo -e "${YELLOW}[~] Trying GET introspection on $full_url${RESET}"
      get_response=$(curl --connect-timeout 10 --max-time 20 -s -X GET "$full_url$INTROSPECTION_QUERY" \
        -H "User-Agent: Mozilla/5.0")

      if echo "$get_response" | grep -q "\"__schema\""; then
        echo -e "${GREEN}[+] Found GraphQL introspection at $full_url via GET${RESET}"
        echo "[*] Introspection: ENABLED" >> "$output_file"
        ./send.sh "Found graphql in $full_url \n introspection is enabled [True]"
      else
        echo -e "${RED}[-] Intro CLOSED in ($full_url)${RESET}"
        echo "[*] Introspection: DISABLED" >> "$output_file"
        ./send.sh "Found graphql in $full_url \n introspection is Disabled [❌]"
      fi

      echo "---" >> "$output_file"
    fi
  done
done

