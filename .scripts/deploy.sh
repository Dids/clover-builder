#!/bin/bash

set -x

git config --global user.email "builds@travis-ci.com"
git config --global user.name "Travis CI"

export CLOVER_PKG_NAME=$(echo -n $HOME/src/edk2/Clover/CloverPackage/sym/Clover_*.pkg)
export CLOVER_PKG_NAME=$(basename ${CLOVER_PKG_NAME})
export CLOVER_PKG_NAME=$(echo -n ${CLOVER_PKG_NAME/.pkg/})
export GIT_TAG=$(echo -n ${CLOVER_PKG_NAME/Clover_/})

if [[ `git tag -l $GIT_TAG` === $GIT_TAG ]]; then
    echo "Tag already exists, skipping deployment.."
else
    git tag $GIT_TAG -a -m ''
    git push -q https://$GITHUB_OAUTH_TOKEN@github.com/Dids/clover-builder --tags
fi
