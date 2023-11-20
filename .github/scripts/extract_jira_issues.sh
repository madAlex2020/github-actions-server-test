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

# Git tags (assumed to be passed into the script)
TAG_NAME=$1
PREVIOUS_TAG=$(git tag --sort=-creatordate | grep -B 1 ${TAG_NAME} | head -n 1)

if [ -z "$PREVIOUS_TAG" ] || [ "$PREVIOUS_TAG" = "$TAG_NAME" ]; then
    echo "No previous tag found or previous tag is the same as current tag. Exiting."
    exit 1
fi

echo "Listing commits from $PREVIOUS_TAG to $TAG_NAME"

# Extract Jira issue codes and update issues in Jira
git log ${PREVIOUS_TAG}..${TAG_NAME} --pretty=format:"%s" | grep -oE '[A-Z]+-[0-9]+' | sort | uniq | while read issue; do
    echo "Updating Jira issue: $issue"
    update_jira_issue_to_done "$issue"
done
