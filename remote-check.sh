#!/bin/bash
# $1=git link, $2=local hash file, $3=remote/file that contains the hash in the repo, $4=output name, $5(optional)=branch, $6(optional)=mode (commit|release)
BRANCH=${5:-HEAD}  # Set BRANCH to $5 if provided, else default to HEAD
MODE=${6:-commit}

local="$2"
remote="$3"

set -euo pipefail

if [ "$MODE" = "release" ]; then
    # Expecting a GitHub repo URL; extract the owner/repo slug.
    repo_slug=$(echo "$1" | sed -E 's#(git@|https://)([^/:]+)[:/]([^/]+/[^/.]+)(\.git)?#\3#')
    if [ -z "$repo_slug" ]; then
        echo "Could not parse repo slug from $1" >&2
        exit 1
    fi

    release_json=$(curl -fsSL "https://api.github.com/repos/$repo_slug/releases/latest")
    tag=$(echo "$release_json" | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name"\s*:\s*"([^"]+)".*/\1/')
    rel_id=$(echo "$release_json" | grep -m1 '"id"' | sed -E 's/.*"id"\s*:\s*([0-9]+).*/\1/')

    if [ -z "$tag" ] || [ -z "$rel_id" ]; then
        echo "Failed to read release information for $repo_slug" >&2
        exit 1
    fi

    printf "%s %s\n" "$tag" "$rel_id" > "$local"
else
    git ls-remote "$1" "$BRANCH" > "$local"
fi

# if the files match, then it means the build is up-to-date, so no need to rebuild.
if cmp -s "$local" "$remote"; then
    echo "$4=false" >> $GITHUB_OUTPUT
else
    echo "$4=true" >> $GITHUB_OUTPUT
fi
