#!/bin/bash

WEBHOOK_URL=${JIRA_WEBHOOK}
issue_keys=()

# Determine the range of commits to check based on tags
TAG_NAME=${GITHUB_REF##*/}

# Fetch all tags and sort them by date
git fetch --tags
PREVIOUS_TAG=$(git tag --sort=-v:refname | grep -A 1 $TAG_NAME | tail -n 1)

if [ -z "$PREVIOUS_TAG" ] || [ "$PREVIOUS_TAG" = "$TAG_NAME" ]; then
    echo "No previous tag found. Examining all commits."
    COMMIT_RANGE=''
else
    echo "Examining commits from $PREVIOUS_TAG to $TAG_NAME"
    COMMIT_RANGE="${PREVIOUS_TAG}..${TAG_NAME}"
fi

# Extract Jira issue codes
git log $COMMIT_RANGE --pretty=format:"%s" | grep -oE '[A-Z]+-[0-9]+' | sort | uniq | while read issue; do
    issue_keys+=("$issue")
done

# Function to trigger Jira Automation Webhook
trigger_jira_automation() {
    # Construct JSON array of issues
    local issues_array=$(printf '%s\n' "${issue_keys[@]}" | jq -R . | jq -cs .)

    # Create JSON payload with "issues" field
    local payload="{\"issues\": $issues_array}"

    # Make a POST request to the Jira Automation Webhook
    curl --request POST \
         --url "$WEBHOOK_URL" \
         --header 'Content-Type: application/json' \
         --data "$payload"
}

# Check if there are any issues to update
if [ ${#issue_keys[@]} -ne 0 ]; then
    echo "Triggering automation for Jira issues"
    trigger_jira_automation
else
    echo "No Jira issues found to update."
fi
