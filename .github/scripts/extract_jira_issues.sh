#!/bin/bash

declare -A issue_lists
issue_lists["IP"]=()
issue_lists["JTD"]=()
issue_lists["LDST"]=()

# Function to trigger Jira Automation Webhook
trigger_jira_automation() {
    local issues=("${!1}")
    local webhook_url="$2"

    if [[ ${#issues[@]} -gt 0 ]]; then
        local issues_json=$(printf '"%s",' "${issues[@]}" | sed 's/,$//')
        issues_json="[$issues_json]"

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

# Extract Jira issue codes and decide which webhook to use
git log "$COMMIT_RANGE" --pretty=format:"%s" | grep -oE '[A-Z]+-[0-9]+' | sort | uniq | while read -r issue; do
    case "${issue%%-*}" in
        "IP")
            issue_lists["IP"]+=("$issue")
            ;;
        "JTD")
            issue_lists["JTD"]+=("$issue")
            ;;
        "LDST")
            issue_lists["LDST"]+=("$issue")
            ;;
        *)
            echo "No webhook configured for this issue type: $issue"
            ;;
    esac
done

# Trigger webhooks for each issue list
for project_key in "${!issue_lists[@]}"; do
    case "$project_key" in
        "IP")
            trigger_jira_automation issue_lists["IP"][@] "${JIRA_WEBHOOK_IP}"
            ;;
        "JTD")
            trigger_jira_automation issue_lists["JTD"][@] "${JIRA_WEBHOOK_JTD}"
            ;;
        "LDST")
            trigger_jira_automation issue_lists["LDST"][@] "${JIRA_WEBHOOK_LDST}"
            ;;
    esac
done
