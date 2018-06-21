#!/usr/bin/env bash

# Setup git user
git config --global user.email "builds@bitrise.io"
git config --global user.name "Bitrise CI"

# Check if this is a real deployment
export CLOVER_DEPLOY=false
if [[ ! -z "${CLOVER_REVISION// }" ]]; then
	export CLOVER_DEPLOY=true
else
	echo "Not a valid release build, skipping deployment.."
	exit 0
fi

# Figure out the tag name
export CLOVER_PKG_NAME=$(echo -n ${BITRISE_DEPLOY_DIR}/Clover_*.pkg)
export CLOVER_PKG_NAME=$(basename ${CLOVER_PKG_NAME})
export CLOVER_PKG_NAME=$(echo -n ${CLOVER_PKG_NAME/.pkg/})
export GIT_TAG=$(echo -n ${CLOVER_PKG_NAME/Clover_/})

# Get the commit message for the tag/revision
export CLOVER_REVISION=$(cd $HOME/src/UDK2018/Clover && svn info | grep 'Revision: ' | tr -d 'Revision: ')
export CLOVER_COMMIT_XML=$(svn log svn://svn.code.sf.net/p/cloverefiboot/code --revision $CLOVER_REVISION --xml)
export CLOVER_COMMIT_MSG=$(echo $CLOVER_COMMIT_XML | xmllint --xpath "string(//msg)" -)
export CLOVER_COMMIT_AUTHOR=$(echo $CLOVER_COMMIT_XML | xmllint --xpath "string(//author)" -)
export CLOVER_COMMIT_DATE=$(echo $CLOVER_COMMIT_XML | xmllint --xpath "string(//date)" -)
export GIT_TAG_MSG=$(printf '%s\n- %s' "$CLOVER_COMMIT_MSG" "$CLOVER_COMMIT_AUTHOR")

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
    git tag $GIT_TAG -a -m "${CLOVER_COMMIT_MSG}" -m "- ${CLOVER_COMMIT_AUTHOR}"
    git push -q https://$GITHUB_OAUTH_TOKEN@github.com/Dids/clover-builder --tags
fi
