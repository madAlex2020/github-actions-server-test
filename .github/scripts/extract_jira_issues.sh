#!/bin/sh

# Initialize arrays for each issue type
IP_issues=""
JTD_issues=""
LDST_issues=""

# Function to add issues to respective arrays
add_issue() {
    local issue_type="$1"
    local issue="$2"

    case "$issue_type" in
        "IP")
            IP_issues="$IP_issues $issue"
            ;;
        "JTD")
            JTD_issues="$JTD_issues $issue"
            ;;
        "LDST")
            LDST_issues="$LDST_issues $issue"
            ;;
        *)
            echo "No webhook configured for this issue type: $issue"
            ;;
    esac
}

# Function to trigger Jira Automation Webhook for a list of issues
trigger_jira_automation_bulk() {
    local issues="$1"
    local webhook_url="$2"

    if [ -n "$issues" ]; then
        local issues_json="[\"$issues\"]"
        local payload="{\"issues\": $issues_json}"

        curl --request POST \
             --url "$webhook_url" \
             --header 'Content-Type: application/json' \
             --data "$payload"
    fi
}

# Determine the range of commits to check
TAG_NAME="${GITHUB_REF##*/}"

# Fetch all tags and sort them by date
git fetch --tags
PREVIOUS_TAG=$(git tag --sort=-v:refname | grep -A 1 "$TAG_NAME" | tail -n 1)

COMMIT_RANGE=''

if [ -n "$PREVIOUS_TAG" ] && [ "$PREVIOUS_TAG" != "$TAG_NAME" ]; then
    echo "Examining commits from $PREVIOUS_TAG to $TAG_NAME"
    COMMIT_RANGE="${PREVIOUS_TAG}..${TAG_NAME}"
else
    echo "No previous tag found. Examining all commits."
fi

# Extract Jira issue codes and decide which array to use
git log "$COMMIT_RANGE" --pretty=format:"%s" | grep -oE '[A-Z]+-[0-9]+' | sort | uniq | while read -r issue; do
    case "${issue%%-*}" in
        "IP")
            add_issue "IP" "$issue"
            ;;
        "JTD")
            add_issue "JTD" "$issue"
            ;;
        "LDST")
            add_issue "LDST" "$issue"
            ;;
        *)
            echo "No webhook configured for this issue type: $issue"
            ;;
    esac
done

# Trigger webhooks for each list of issues
trigger_jira_automation_bulk "$IP_issues" "$JIRA_WEBHOOK_IP"
trigger_jira_automation_bulk "$JTD_issues" "$JIRA_WEBHOOK_JTD"
trigger_jira_automation_bulk "$LDST_issues" "$JIRA_WEBHOOK_LDST"
