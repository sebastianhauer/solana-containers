#!/bin/bash

set -euo pipefail

# Check for required output file argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 OUTPUT_FILE"
    echo "Generate build matrix and write to specified output file"
    exit 1
fi

output_file="$1"

echo "Checking for ARM64 runner availability..."

# Check for ARM64 runner availability
response=$(curl --location \
  --header "Accept: application/vnd.github+json" \
  --header "Authorization: Bearer $GH_TOKEN" \
  --header "X-GitHub-Api-Version: 2022-11-28" \
  --silent \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runners")

# Print full response for debugging (excluding sensitive data)
echo "API Response:"
echo "$response" | jq 'del(.runners[].token)' || echo "Failed to parse response as JSON"

has_arm64=$(echo "$response" | jq -e '.runners[] | select(.status=="online") | .labels[] | select(.name=="self-hosted-linux-arm64")' > /dev/null && echo "true" || echo "false")
echo "ARM64 runner available: $has_arm64"

# Load configurations
platforms=$(jq '.' .github/configs/platforms.json)
distros=$(jq '.' .github/configs/distros.json)

# Enable ARM64 if runner is available
if [ "$has_arm64" = "true" ]; then
  platforms=$(echo "$platforms" | jq '(.[] | select(.name == "arm64")).enabled = true')
fi

echo "Platform configurations:"
echo "$platforms" | jq '.'

echo "Distro configurations:"
echo "$distros" | jq '.'

# Generate matrix by combining platforms and distros
matrix=$(jq -n \
  --argjson platforms "$platforms" \
  --argjson distros "$distros" \
  '{
    "config": [
      $platforms[] |
      select(.enabled == true) as $p |
      $distros[] as $d |
      $d.variants[] as $v |
      {
        "platform": $p.platform,
        "runs-on": $p["runs-on"],
        "distro": {
          "name": $d.name,
          "release": $d.release,
          "variant": $v
        }
      }
    ]
  }')

echo "Generated matrix:"
echo "$matrix" | jq '.'

# Generate the matrix output
matrix_output=$(echo "$matrix" | jq -c '.')

echo "Writing matrix to $output_file"

# Write to the specified output file
echo "matrix=${matrix_output}"
echo "matrix=${matrix_output}" >> "$output_file"