#!/bin/bash

# Setup git user
git config --global user.email "builds@travis-ci.com"
git config --global user.name "Travis CI"

# Figure out the tag name
#export CLOVER_PKG_NAME=$(echo -n $HOME/src/edk2/Clover/CloverPackage/sym/Clover_*.pkg)
#export CLOVER_PKG_NAME=$(basename ${CLOVER_PKG_NAME})
#export CLOVER_PKG_NAME=$(echo -n ${CLOVER_PKG_NAME/.pkg/})
#export GIT_TAG=$(echo -n ${CLOVER_PKG_NAME/Clover_/})

# Get the commit message for the tag/revision
#export CLOVER_REVISION=$(cd $HOME/src/edk2/Clover && svn info | grep 'Revision: ' | tr -d 'Revision: ')
#export GIT_TAG_MSG=$(svn log svn://svn.code.sf.net/p/cloverefiboot/code --revision $CLOVER_REVISION --xml)
#export GIT_TAG_MSG=$(echo $GIT_TAG_MSG | xmllint --xpath "string(//msg)" -)

# Verify that we have a valid tag
if [[ -z "${GIT_TAG// }" || "${GIT_TAG// }" != v* ]]; then
	echo "Invalid tag '$GIT_TAG', aborting deployment.."
	exit 1
fi

# Update tags
git fetch --tags

# Compare current tag against the built tag
CURRENT_TAG=$(git tag -l $GIT_TAG)
if [[ "$CURRENT_TAG" == "$GIT_TAG" ]]; then
    echo "Tag already exists, skipping deployment.."
	exit 1
else
	echo "Pushing tag: $GIT_TAG"
    git tag $GIT_TAG -a -m "${GIT_TAG_MSG}"
    git push -q https://$GITHUB_OAUTH_TOKEN@github.com/Dids/clover-builder --tags
fi
