#!/bin/bash

set -x

# Setup git user
git config --global user.email "builds@travis-ci.com"
git config --global user.name "Travis CI"

# Figure out the tag name
export CLOVER_PKG_NAME=$(echo -n $HOME/src/edk2/Clover/CloverPackage/sym/Clover_*.pkg)
export CLOVER_PKG_NAME=$(basename ${CLOVER_PKG_NAME})
export CLOVER_PKG_NAME=$(echo -n ${CLOVER_PKG_NAME/.pkg/})
export GIT_TAG=$(echo -n ${CLOVER_PKG_NAME/Clover_/})

# Update tags
git fetch --tags

# Compare current tag against the built tag
CURRENT_TAG=$(git tag -l $GIT_TAG)
if [[ "$CURRENT_TAG" == "$GIT_TAG" ]]; then
    echo "Tag already exists, skipping deployment.."
else
    git tag $GIT_TAG -a -m ''
    git push -q https://$GITHUB_OAUTH_TOKEN@github.com/Dids/clover-builder --tags
fi
