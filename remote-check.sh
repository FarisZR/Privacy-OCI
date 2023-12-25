#!/bin/bash
# $1=git link, $2=local hash file, $3=remote/file that contains the hash in the repo, $4=output name, $5(optional)=branch
BRANCH=${5:-HEAD}  # Set BRANCH to $5 if provided, else default to HEAD

git ls-remote $1 $BRANCH > $2

local="$2"
remote="$3"
# if the files match, then it means the build is up-to-date, so no need to rebuild.
if cmp -s "$local" "$remote"; then
    echo "$4=false" >> $GITHUB_OUTPUT
else
    echo "$4=true" >> $GITHUB_OUTPUT
fi
