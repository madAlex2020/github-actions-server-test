#!/bin/sh

# Function to trigger Jira Automation Webhook in bulk
trigger_jira_automation_bulk() {
    local webhook_url="$1"
    local payload="$2"
    if [ -n "$payload" ]; then
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

if [ -n "$PREVIOUS_TAG" ] && [ "$PREVIOUS_TAG" != "$TAG_NAME" ]; then
    echo "Examining commits from $PREVIOUS_TAG to $TAG_NAME"
    COMMIT_RANGE="${PREVIOUS_TAG}..${TAG_NAME}"
else
    echo "No previous tag found. Examining all commits."
fi

# Initialize variables to store issues for each board key
IP_issues=""
JTD_issues=""
LDST_issues=""

# Extract Jira issue codes and group them by board key
for issue in $(git log "$COMMIT_RANGE" --pretty=format:"%s" | grep -oE '[A-Z]+-[0-9]+' | sort | uniq); do
    jira_board_key="${issue%%-*}"

    case "$jira_board_key" in
        "IP")
            if [ -n "$IP_issues" ]; then
                IP_issues="$IP_issues, $issue"
            else
                IP_issues="$issue"
            fi
            ;;
        "JTD")
            if [ -n "$JTD_issues" ]; then
                JTD_issues="$JTD_issues, $issue"
            else
                JTD_issues="$issue"
            fi
            ;;
        "LDST")
            if [ -n "$LDST_issues" ]; then
                LDST_issues="$LDST_issues, $issue"
            else
                LDST_issues="$issue"
            fi
            ;;
        *)
            echo "No webhook configured for this board key: $jira_board_key"
            ;;
    esac
done

# Trigger webhooks for each board key and its issues in bulk
[ -n "$IP_issues" ] && trigger_jira_automation_bulk "$JIRA_WEBHOOK_IP" "$IP_issues"
[ -n "$JTD_issues" ] && trigger_jira_automation_bulk "$JIRA_WEBHOOK_JTD" "$JTD_issues"
[ -n "$LDST_issues" ] && trigger_jira_automation_bulk "$JIRA_WEBHOOK_LDST" "$LDST_issues"
