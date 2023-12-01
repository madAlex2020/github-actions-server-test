#!/bin/bash

# Initialize arrays for each issue type
IP_issues=()
JTD_issues=()
LDST_issues=()

# Function to add issues to respective arrays
add_issue() {
    local issue_type="$1"
    local issue="$2"

    case "$issue_type" in
        "IP")
            IP_issues+=("$issue")
            ;;
        "JTD")
            JTD_issues+=("$issue")
            ;;
        "LDST")
            LDST_issues+=("$issue")
            ;;
        *)
            echo "No webhook configured for this issue type: $issue"
            ;;
    esac
}

# Function to trigger Jira Automation Webhook
trigger_jira_automation() {
    local issues=("$@")
    local webhook_url="${!#}"

    if [[ ${#issues[@]} -gt 0 ]]; then
        local issues_json=$(printf '"%s",' "${issues[@]}")
        issues_json="[${issues_json%,}]"

        local payload="{\"issues\": $issues_json}"

        curl --request POST \
             --url "$webhook_url" \
             --header 'Content-Type: application/json' \
             --data "$payload"
    fi
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

# Trigger webhooks for each list of issues
[[ ${#IP_issues[@]} -gt 0 ]] && trigger_jira_automation "${IP_issues[@]}" "$JIRA_WEBHOOK_IP"
[[ ${#JTD_issues[@]} -gt 0 ]] && trigger_jira_automation "${JTD_issues[@]}" "$JIRA_WEBHOOK_JTD"
[[ ${#LDST_issues[@]} -gt 0 ]] && trigger_jira_automation "${LDST_issues[@]}" "$JIRA_WEBHOOK_LDST"

