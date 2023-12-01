#!/bin/bash

# Function to trigger Jira Automation Webhook
trigger_jira_automation() {
    local issue="$1"
    local webhook_url="$2"

    local payload="{\"issues\": [\"$issue\"]}"

    # Make a POST request to the Jira Automation Webhook
    curl --request POST \
         --url "$webhook_url" \
         --header 'Content-Type: application/json' \
         --data "$payload"
}

# Determine the range of commits to check
TAG_NAME=${GITHUB_REF##*/}

# Fetch all tags and sort them by date
git fetch --tags
PREVIOUS_TAG=$(git tag --sort=-v:refname | grep -A 1 "$TAG_NAME" | tail -n 1)

COMMIT_RANGE=''
if [[ -n "$PREVIOUS_TAG" ]] && [[ "$PREVIOUS_TAG" != "$TAG_NAME" ]]; then
    echo "Examining commits from $PREVIOUS_TAG to $TAG_NAME"
    COMMIT_RANGE="${PREVIOUS_TAG}..${TAG_NAME}"
else
    echo "No previous tag found. Examining all commits."
fi

# Extract Jira issue codes and decide which webhook to use
git log "$COMMIT_RANGE" --pretty=format:"%s" | grep -oE '[A-Z]+-[0-9]+' | sort | uniq | while read -r issue; do
    case "${issue%%-*}" in
        "IP")
            trigger_jira_automation "$issue" "${JIRA_WEBHOOK_IP}"
            ;;
        "JTD")
            trigger_jira_automation "$issue" "${JIRA_WEBHOOK_JTD}"
            ;;
        "LDST")
            trigger_jira_automation "$issue" "${JIRA_WEBHOOK_LDST}"
            ;;
        *)
            echo "No webhook configured for this issue type: $issue"
            ;;
    esac
done
