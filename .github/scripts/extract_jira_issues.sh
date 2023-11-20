#!/bin/bash

# Jira API credentials - these should be set as environment variables
JIRA_API_TOKEN=${JIRA_API_TOKEN}
JIRA_EMAIL=${JIRA_EMAIL}
JIRA_BASE_URL=${JIRA_BASE_URL}

# Function to get the transition ID for moving an issue to DONE
get_transition_id_to_done() {
    local issue_key=$1

    # Fetch transitions for the issue
    transitions=$(curl -s --request GET \
        --url "$JIRA_BASE_URL/rest/api/3/issue/$issue_key/transitions" \
        --user "$JIRA_EMAIL:$JIRA_API_TOKEN" \
        --header 'Content-Type: application/json')

    # Parse the JSON response to find the "DONE" transition ID
    echo $transitions | jq -r '.transitions[] | select(.name == "Done") | .id'
}

# Function to update Jira issue to DONE
update_jira_issue_to_done() {
    local issue_key=$1
    local transition_id

    transition_id=$(get_transition_id_to_done "$issue_key")

    if [ -z "$transition_id" ]; then
        echo "Transition ID to DONE not found for issue $issue_key"
        return 1
    fi

    JSON_PAYLOAD=$(cat <<EOF
    {
      "transition": {
        "id": "$transition_id"
      }
    }
EOF
    )

    curl --request POST \
      --url "$JIRA_BASE_URL/rest/api/3/issue/$issue_key/transitions" \
      --user "$JIRA_EMAIL:$JIRA_API_TOKEN" \
      --header 'Content-Type: application/json' \
      --data "$JSON_PAYLOAD"
}

# Determine the range of commits to check
TAG_NAME=$1
PREVIOUS_TAG=$(git describe --tags --abbrev=0 ${TAG_NAME}^)

if [ -z "$PREVIOUS_TAG" ]; then
    echo "No previous tag found. Examining all commits."
    COMMIT_RANGE=''
else
    echo "Examining commits from $PREVIOUS_TAG to $TAG_NAME"
    COMMIT_RANGE="${PREVIOUS_TAG}..${TAG_NAME}"
fi

# Extract Jira issue codes and update issues in Jira
git log $COMMIT_RANGE --pretty=format:"%s" | grep -oE '[A-Z]+-[0-9]+' | sort | uniq | while read issue; do
    echo "Updating Jira issue: $issue"
    update_jira_issue_to_done "$issue"
done
