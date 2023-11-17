#!/bin/bash

# The tag for which we want to list commits and extract Jira issues
TAG_NAME=$1

# Finding the previous tag
PREVIOUS_TAG=$(git describe --tags --abbrev=0 ${TAG_NAME}^)

if [ -z "$PREVIOUS_TAG" ]; then
    echo "No previous tag found. Exiting."
    exit 1
fi

echo "Listing commits from $PREVIOUS_TAG to $TAG_NAME"

# List commits between the two tags and extract Jira issue codes
git log ${PREVIOUS_TAG}..${TAG_NAME} --pretty=format:"%s" | grep -oE 'JTD-[0-9]+' | sort | uniq

