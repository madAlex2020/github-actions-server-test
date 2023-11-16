import os
import re
import requests
from subprocess import check_output

def get_commit_messages():
    # Get commit messages between the last two tags
    commit_range = check_output(['git', 'describe', '--tags', '--abbrev=0', 'HEAD^']).strip().decode() + '..HEAD'
    commit_messages = check_output(['git', 'log', '--pretty=format:%s', commit_range]).decode()
    return commit_messages

def extract_jira_keys(commit_messages):
    # Regex pattern for JIRA issue keys
    pattern = r'([A-Z]+-\d+)'
    return re.findall(pattern, commit_messages)

def update_jira_issues(issue_keys):
    jira_base_url = os.getenv('JIRA_BASE_URL')
    auth = (os.getenv('JIRA_USER_EMAIL'), os.getenv('JIRA_API_TOKEN'))

    for key in issue_keys:
        url = f'{jira_base_url}/rest/api/2/issue/{key}/transitions'
        data = {
            "transition": {"id": "Transition_ID"}  # Replace with your actual transition ID
        }
        response = requests.post(url, json=data, auth=auth)
        if response.status_code == 204:
            print(f'Issue {key} updated successfully.')
        else:
            print(f'Failed to update issue {key}. Response: {response.text}')

if __name__ == '__main__':
    commit_messages = get_commit_messages()
    issue_keys = extract_jira_keys(commit_messages)
    print(f'Found JIRA Issues: {issue_keys}')
#     update_jira_issues(set(issue_keys))  # Using set to remove duplicates
