#!/bin/bash

# Jira API credentials - these should be set as environment variables
JIRA_WEBHOOK=${JIRA_WEBHOOK}

# Function to trigger Jira Automation Webhook
trigger_jira_automation() {
    local issue_key=$1

    # Make a POST request to the Jira Automation Webhook
    curl --request POST \
         --url "$JIRA_WEBHOOK" \
         --header 'Content-Type: application/json' \
         --data "{\"issueKey\": \"$issue_key\"}"
}

# Determine the range of commits to check
TAG_NAME=${GITHUB_REF##*/}

# Fetch all tags and sort them by date
git fetch --tags
git tag --sort=-v:refname | grep -A 1 $TAG_NAME | tail -n 1
PREVIOUS_TAG=$(git tag --sort=-v:refname | grep -A 1 $TAG_NAME | tail -n 1)

if [ -z "$PREVIOUS_TAG" ] || [ "$PREVIOUS_TAG" = "$TAG_NAME" ]; then
    echo "No previous tag found. Examining all commits."
    COMMIT_RANGE=''
else
    echo "Examining commits from $PREVIOUS_TAG to $TAG_NAME"
    COMMIT_RANGE="${PREVIOUS_TAG}..${TAG_NAME}"
fi


# Extract Jira issue codes and update issues in Jira
git log $COMMIT_RANGE --pretty=format:"%s" | grep -oE '[A-Z]+-[0-9]+' | sort | uniq | while read issue; do
    echo "Updating Jira issue: $issue"
    trigger_jira_automation "$issue"
done

