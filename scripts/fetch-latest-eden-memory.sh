#!/usr/bin/env bash
# fetch-latest-eden-memory.sh
#
# Queries the private source repo for the most recent release whose tag matches
# the configured pattern and whose CI checks are green.
#
# Usage:
#   fetch-latest-eden-memory.sh \
#     --owner yakovkhalinsky \
#     --repo eden-memory \
#     --pattern '^v[0-9]{4}\.[0-9]{4}\.[0-9]{4}$' \
#     --require-green \
#     --output GITHUB_OUTPUT

set -euo pipefail

OWNER="yakovkhalinsky"
REPO="eden-memory"
TAG_PATTERN='^v[0-9]{4}\.[0-9]{4}\.[0-9]{4}$'
REQUIRE_GREEN="false"
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner) OWNER="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --pattern) TAG_PATTERN="$2"; shift 2 ;;
    --require-green) REQUIRE_GREEN="true"; shift ;;
    --output) OUTPUT_FILE="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--owner OWNER] [--repo REPO] [--pattern PATTERN] [--require-green] [--output FILE]"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if ! command -v gh >/dev/null 2&1; then
  echo "gh CLI is required" >&2
  exit 1
fi

FULL_REPO="${OWNER}/${REPO}"

echo "Fetching releases from ${FULL_REPO}..."

# Paginate through releases until we find a matching, green one.
PAGE=1
while true; do
  releases="$(gh api "repos/${FULL_REPO}/releases?per_page=100&page=${PAGE}" --jq '.[] | {tag_name, created_at, draft, prerelease, target_commitish} | @base64')"

  if [ -z "$releases" ]; then
    break
  fi

  while IFS= read -r release_b64; do
    [ -z "$release_b64" ] && continue
    release="$(echo "$release_b64" | base64 -d)"
    tag_name="$(echo "$release" | jq -r .tag_name)"
    created_at="$(echo "$release" | jq -r .created_at)"
    draft="$(echo "$release" | jq -r .draft)"
    prerelease="$(echo "$release" | jq -r .prerelease)"
    target_commitish="$(echo "$release" | jq -r .target_commitish)"

    if [ "$draft" = "true" ] || [ "$prerelease" = "true" ]; then
      continue
    fi

    if ! echo "$tag_name" | grep -Eq "$TAG_PATTERN"; then
      continue
    fi

    echo "Candidate release: $tag_name ($created_at) on commit $target_commitish"

    if [ "$REQUIRE_GREEN" = "true" ]; then
      # Resolve tag to commit SHA because target_commitish can be a branch name.
      sha="$(gh api "repos/${FULL_REPO}/git/refs/tags/${tag_name}" --jq '.object.sha')"
      echo "Checking check-runs for commit ${sha}..."

      # GitHub check-runs endpoint returns conclusion for each check suite/run.
      # Group by name and take the latest, then require all to be 'success'.
      non_success="$(gh api "repos/${FULL_REPO}/commits/${sha}/check-runs?per_page=100" \
        --jq '
          .check_runs
          | group_by(.name)
          | map(last)
          | map(select(.status != "completed" or .conclusion != "success"))
          | length
        ')"

      if [ "$non_success" -ne 0 ]; then
        echo "  SKIP: ${non_success} check run(s) not green for ${tag_name}"
        continue
      fi

      status_state="$(gh api "repos/${FULL_REPO}/commits/${sha}/status" --jq '.state')"
      if [ "$status_state" != "success" ]; then
        echo "  SKIP: combined status is ${status_state} for ${tag_name}"
        continue
      fi

      echo "  OK: all checks green"
      target_commitish="$sha"
    fi

    echo "Selected source release: ${tag_name} (${target_commitish})"
    if [ -n "$OUTPUT_FILE" ]; then
      echo "tag=${tag_name}" >> "$OUTPUT_FILE"
      echo "sha=${target_commitish}" >> "$OUTPUT_FILE"
      echo "created_at=${created_at}" >> "$OUTPUT_FILE"
    else
      echo "tag=${tag_name}"
      echo "sha=${target_commitish}"
      echo "created_at=${created_at}"
    fi
    exit 0
  done <<< "$releases"

  PAGE=$((PAGE + 1))
done

echo "ERROR: no green, matching release found in ${FULL_REPO}" >&2
exit 1
