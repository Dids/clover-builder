#!/bin/bash

# Setup git user
git config --global user.email "builds@travis-ci.com"
git config --global user.name "Travis CI"

# Figure out the tag name
export CLOVER_PKG_NAME=$(echo -n ${TRAVIS_BUILD_DIR}/Clover_*.pkg)
export CLOVER_PKG_NAME=$(basename ${CLOVER_PKG_NAME})
export CLOVER_PKG_NAME=$(echo -n ${CLOVER_PKG_NAME/.pkg/})
export GIT_TAG=$(echo -n ${CLOVER_PKG_NAME/Clover_/})

# Get the commit message for the tag/revision
export CLOVER_REVISION=$(cd $HOME/src/edk2/Clover && svn info | grep 'Revision: ' | tr -d 'Revision: ')
export CLOVER_COMMIT_XML=$(svn log svn://svn.code.sf.net/p/cloverefiboot/code --revision $CLOVER_REVISION --xml)
export CLOVER_COMMIT_MSG=$(echo $CLOVER_COMMIT_XML | xmllint --xpath "string(//msg)" -)
export CLOVER_COMMIT_AUTHOR=$(echo $CLOVER_COMMIT_XML | xmllint --xpath "string(//author)" -)
export CLOVER_COMMIT_DATE=$(echo $CLOVER_COMMIT_XML | xmllint --xpath "string(//date)" -)
export GIT_TAG_MSG="${CLOVER_COMMIT_MSG}\n- ${CLOVER_COMMIT_AUTHOR}"

# Verify that we have a valid tag
if [[ -z "${GIT_TAG// }" || "${GIT_TAG// }" != v* ]]; then
	echo "Invalid tag '$GIT_TAG', skipping deployment.."
	exit 0
fi

# Update tags
git fetch --tags

# Compare current tag against the built tag
CURRENT_TAG=$(git tag -l $GIT_TAG)
if [[ "$CURRENT_TAG" == "$GIT_TAG" ]]; then
    echo "Tag '$GIT_TAG' already exists, skipping deployment.."
	exit 0
else
	echo "Pushing tag '$GIT_TAG'"
    git tag $GIT_TAG -a -m "${GIT_TAG_MSG}"
    git push -q https://$GITHUB_OAUTH_TOKEN@github.com/Dids/clover-builder --tags
    export CLOVER_DEPLOY=true
fi
