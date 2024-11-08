gh auth login
#!/bin/bash
# Configuration
GH_USER="allyelvis"                  # GitHub username
MAIN_REPO="allyelvis-manager"         # Main repository name
WORKFLOW_DIR=".github/workflows"
WORKFLOW_FILE="manage_repos.yml"
# Step 1: Check if the main repository exists, if not create it
echo "Checking if main repository '$GH_USER/$MAIN_REPO' exists..."
if gh repo view "$GH_USER/$MAIN_REPO" > /dev/null 2>&1; then   echo "Repository '$GH_USER/$MAIN_REPO' already exists."; else   echo "Creating repository '$GH_USER/$MAIN_REPO'...";   gh repo create "$GH_USER/$MAIN_REPO" --public --description "Main repository to manage, control, maintain, and analyze all $GH_USER repositories."; 
  git clone "https://github.com/$GH_USER/$MAIN_REPO.git";   cd "$MAIN_REPO";   echo "# $MAIN_REPO" > README.md;   echo "Repository to manage, control, maintain, and analyze all $GH_USER repositories." >> README.md;   git add README.md;   git commit -m "Initial commit with README";   git push -u origin main;   cd ..;   echo "Repository '$GH_USER/$MAIN_REPO' created and initialized."; fi
# Step 2: Create the GitHub Actions workflow file
echo "Creating GitHub Actions workflow file..."
# Ensure the .github/workflows directory exists
mkdir -p "$MAIN_REPO/$WORKFLOW_DIR"
# Define the GitHub Actions workflow content
cat <<EOL > "$MAIN_REPO/$WORKFLOW_DIR/$WORKFLOW_FILE"
name: Manage and Analyze Repositories

on:
  schedule:
    - cron: '0 2 * * 1'  # Runs every Monday at 2:00 AM UTC
  workflow_dispatch:  # Allows manual triggering

jobs:
  analyze_repositories:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout Main Repository
      uses: actions/checkout@v3

    - name: Set Up GitHub CLI
      uses: einaregilsson/gh-cli@v1
      with:
        version: latest

    - name: Install jq
      run: sudo apt-get install -y jq

    - name: Generate Repository Report
      env:
        GH_USER: $GH_USER
        REPORT_FILE: repo_report.txt
      run: |
        echo "Repository Report for \$GH_USER" > \$REPORT_FILE
        echo "Generated on \$(date)" >> \$REPORT_FILE
        echo "------------------------------------------" >> \$REPORT_FILE

        echo "Fetching all repositories for \$GH_USER..."
        repos=\$(gh repo list \$GH_USER --json name,visibility,updatedAt,url --jq '.[]')

        analyze_repo() {
          local repo_name=\$1
          echo "Analyzing repository: \$repo_name"

          echo "Repository: \$repo_name" >> \$REPORT_FILE
          echo "URL: \$(echo "\$repo" | jq -r '.url')" >> \$REPORT_FILE
          echo "Visibility: \$(echo "\$repo" | jq -r '.visibility')" >> \$REPORT_FILE
          echo "Last Updated: \$(echo "\$repo" | jq -r '.updatedAt')" >> \$REPORT_FILE

          issues=\$(gh issue list --repo "\$GH_USER/\$repo_name" --state open --json title --jq 'length')
          echo "Open Issues: \$issues" >> \$REPORT_FILE

          prs=\$(gh pr list --repo "\$GH_USER/\$repo_name" --state open --json title --jq 'length')
          echo "Open Pull Requests: \$prs" >> \$REPORT_FILE

          echo "Checking dependencies with Dependabot..." >> \$REPORT_FILE
          dependabot_alerts=\$(gh api -H "Accept: application/vnd.github+json" /repos/\$GH_USER/\$repo_name/dependabot/alerts | jq '.[].dependency.package.name' 2>/dev/null || echo "No dependencies or Dependabot not enabled")
          echo "Dependabot Alerts: \$dependabot_alerts" >> \$REPORT_FILE

          echo "Running CodeQL analysis..." >> \$REPORT_FILE
          gh workflow run CodeQL --repo "\$GH_USER/\$repo_name" || echo "CodeQL workflow not configured for \$repo_name" >> \$REPORT_FILE
          echo "------------------------------------------" >> \$REPORT_FILE
        }

        for repo in \$(echo "\$repos" | jq -c '.'); do
          repo_name=\$(echo "\$repo" | jq -r '.name')
          analyze_repo "\$repo_name"
        done

    - name: Commit and Push Report
      run: |
        git config --global user.name "github-actions[bot]"
        git config --global user.email "github-actions[bot]@users.noreply.github.com"
        
        git add \$REPORT_FILE
        git commit -m "Update repository report on \$(date)"
        git push origin main
EOL

# Step 3: Commit and push the workflow file to GitHub
echo "Committing and pushing workflow file..."
cd "$MAIN_REPO"
git add "$WORKFLOW_DIR/$WORKFLOW_FILE"
git commit -m "Add GitHub Actions workflow for repository management"
git push origin main
cd ..
echo "Setup complete! The '$MAIN_REPO' repository now includes a GitHub Actions workflow to manage and analyze all $GH_USER repositories."
git config --global user.name "AllyElvis"
git config --global user.email "allyelvis6569@gmail.com"
git push
ls -la
cd allyevis-manager
cd allyelvis-manager
git push
cd
#!/bin/bash
# Define GitHub username and token (Ensure your token has repo scope)
GITHUB_USER="allyelvis"
GITHUB_TOKEN="Codos: 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"  # Replace with your GitHub token
GITHUB_API="https://api.github.com"
RELEASE_NOTES="Release notes for the new version."
# Get the list of repositories for the user
repos=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/users/$GITHUB_USER/repos?per_page=100" | jq -r '.[].name')
# Function to create a release for a repository
create_release() {   local repo_name=$1;   echo "Creating release for $repo_name..."; 
  latest_commit_hash=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/repos/$GITHUB_USER/$repo_name/commits/main" | jq -r '.sha'); 
  existing_tag=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/repos/$GITHUB_USER/$repo_name/tags" | jq -r ".[] | select(.commit.sha == \"$latest_commit_hash\") | .name");    if [[ -z "$existing_tag" ]]; then
    new_version="v$(date +%Y%m%d%H%M%S)"  # You can adjust this to your preferred versioning strategy

    release_payload=$(cat <<EOF
{
  "tag_name": "$new_version",
  "target_commitish": "main",
  "name": "$new_version",
  "body": "$RELEASE_NOTES",
  "draft": false,
  "prerelease": false
}
EOF

);     release_response=$(curl -s -X POST -u $GITHUB_USER:$GITHUB_TOKEN -H "Content-Type: application/json" \
      -d "$release_payload" "https://api.github.com/repos/$GITHUB_USER/$repo_name/releases");      release_url=$(echo $release_response | jq -r '.html_url');      if [[ "$release_url" != "null" ]]; then       echo "Release created successfully for $repo_name: $release_url";     else       echo "Failed to create release for $repo_name.";     fi;   else     echo "Release already exists for latest commit in $repo_name. Skipping.";   fi; }
# Loop through all repositories
for repo in $repos; do   create_release "$repo"; done
echo "Release scanning and creation process completed."
#!/bin/bash
# Define GitHub username and token (Ensure your token has repo scope)
GITHUB_USER="allyelvis"
GITHUB_TOKEN="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"  # Replace with your GitHub token
GITHUB_API="https://api.github.com"
# Function to get the latest workflow run (e.g., GitHub Actions)
get_failed_workflows() {   local repo_name=$1;   echo "Fetching failed workflows for $repo_name..."; 
  workflows=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/repos/$GITHUB_USER/$repo_name/actions/runs?status=failed&per_page=5" | jq -r '.workflow_runs[] | {id, name, status, conclusion, created_at}');      if [[ -z "$workflows" ]]; then     echo "No failed workflows found for $repo_name.";   else     echo "Failed workflows found for $repo_name:";     echo "$workflows" | jq .;   fi; }
# Function to get the latest commit and detect failed tests or errors
get_failed_commits() {   local repo_name=$1;   echo "Checking for failed commits in $repo_name..."; 
  commits=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/repos/$GITHUB_USER/$repo_name/commits/main" | jq -r '.commit.message'); 
  failed_commits=$(echo "$commits" | grep -i 'fail\|error\|issue');      if [[ -z "$failed_commits" ]]; then     echo "No failed commits detected in $repo_name.";   else     echo "Failed commits found in $repo_name:";     echo "$failed_commits";   fi; }
# Function to automatically fix issues (e.g., by pulling updates or reverting to a working commit)
auto_fix_issues() {   local repo_name=$1;   echo "Attempting to fix issues in $repo_name..."; 
  git clone https://github.com/$GITHUB_USER/$repo_name.git;   cd $repo_name || exit; 
  git checkout main;   git pull origin main;   git reset --hard HEAD~1  # Undo the last commit, you can customize this logic
  git push origin main;    echo "Fix applied and pushed for $repo_name."; }
# Function to create a release for a repository
create_release() {   local repo_name=$1;   echo "Creating release for $repo_name..."; 
  latest_commit_hash=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/repos/$GITHUB_USER/$repo_name/commits/main" | jq -r '.sha'); 
  existing_tag=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/repos/$GITHUB_USER/$repo_name/tags" | jq -r ".[] | select(.commit.sha == \"$latest_commit_hash\") | .name");    if [[ -z "$existing_tag" ]]; then
    new_version="v$(date +%Y%m%d%H%M%S)"  # You can adjust this to your preferred versioning strategy

    release_payload=$(cat <<EOF
{
  "tag_name": "$new_version",
  "target_commitish": "main",
  "name": "$new_version",
  "body": "Release after fixing errors",
  "draft": false,
  "prerelease": false
}
EOF

);     release_response=$(curl -s -X POST -u $GITHUB_USER:$GITHUB_TOKEN -H "Content-Type: application/json" \
      -d "$release_payload" "https://api.github.com/repos/$GITHUB_USER/$repo_name/releases");      release_url=$(echo $release_response | jq -r '.html_url');      if [[ "$release_url" != "null" ]]; then       echo "Release created successfully for $repo_name: $release_url";     else       echo "Failed to create release for $repo_name.";     fi;   else     echo "Release already exists for latest commit in $repo_name. Skipping.";   fi; }
# Main logic: loop through all repositories and apply fixes and releases if necessary
repos=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/users/$GITHUB_USER/repos?per_page=100" | jq -r '.[].name')
for repo in $repos; do
  get_failed_workflows "$repo";   get_failed_commits "$repo"; 
  auto_fix_issues "$repo";   create_release "$repo"; done
echo "Error fix and release process completed."
ls -la
cd
git add .
cd accounting
cd accountin
git add .
git commit -A
git add -A
git commit -m " general commit"
git add Accounting/*
#!/bin/bash
# Define the repository directory (optional if you're in the repository already)
REPO_DIR="./"  # Default to current directory, adjust if needed
# Navigate to the repository directory (uncomment if using a specific directory)
# cd $REPO_DIR
# Check if there are any changes in the repository
if [[ -n $(git status --porcelain) ]]; then   echo "Changes detected, proceeding with commit..."; 
  COMMIT_MESSAGE="Auto commit: $(date +'%Y-%m-%d %H:%M:%S') - Changes made"; 
  git add .; 
  git commit -m "$COMMIT_MESSAGE";    echo "Changes committed with message: $COMMIT_MESSAGE"; else   echo "No changes detected, nothing to commit."; fi
#!/bin/bash
# Define GitHub repository and token (ensure your token has the necessary scope)
GITHUB_USER="allyelvis"
GITHUB_TOKEN="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"  # Replace with your GitHub token
GITHUB_API="https://api.github.com"
# Function to get failed workflows (e.g., GitHub Actions)
get_failed_workflows() {   local repo_name=$1;   echo "Fetching failed workflows for $repo_name..."; 
  workflows=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/repos/$GITHUB_USER/$repo_name/actions/runs?status=failed&per_page=5" | jq -r '.workflow_runs[] | {id, name, status, conclusion, created_at}');      if [[ -z "$workflows" ]]; then     echo "No failed workflows found for $repo_name.";   else     echo "Failed workflows found for $repo_name:";     echo "$workflows" | jq .;   fi; }
# Function to automatically detect and fix errors in the code
auto_fix_issues() {   local repo_name=$1;   echo "Attempting to fix issues in $repo_name..."; 
  git clone https://github.com/$GITHUB_USER/$repo_name.git;   cd $repo_name || exit; 
  git pull origin main; 
  if [ -f "package.json" ]; then     echo "Installing dependencies...";     npm install;   fi; 
  if command -v eslint &>/dev/null; then     echo "Fixing code style issues...";     eslint --fix .;   fi; 
  if command -v npm &>/dev/null; then     echo "Attempting to build project...";     npm run build;   fi; 
  git add .;   COMMIT_MESSAGE="Auto fix: $(date +'%Y-%m-%d %H:%M:%S') - Fixed dependencies, formatting, and build errors";   git commit -m "$COMMIT_MESSAGE"; 
  git push origin main;    echo "Fixes applied and pushed to the repository."; }
# Function to detect failed commits (e.g., commits with failed tests)
get_failed_commits() {   local repo_name=$1;   echo "Checking for failed commits in $repo_name..."; 
  commits=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/repos/$GITHUB_USER/$repo_name/commits/main" | jq -r '.commit.message'); 
  failed_commits=$(echo "$commits" | grep -i 'fail\|error\|issue');      if [[ -z "$failed_commits" ]]; then     echo "No failed commits detected in $repo_name.";   else     echo "Failed commits found in $repo_name:";     echo "$failed_commits";   fi; }
# Function to create a new release after fixing the issue
create_release() {   local repo_name=$1;   echo "Creating a release for $repo_name..."; 
  latest_commit_hash=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/repos/$GITHUB_USER/$repo_name/commits/main" | jq -r '.sha'); 
  existing_tag=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/repos/$GITHUB_USER/$repo_name/tags" | jq -r ".[] | select(.commit.sha == \"$latest_commit_hash\") | .name");    if [[ -z "$existing_tag" ]]; then
    new_version="v$(date +%Y%m%d%H%M%S)"; 
    release_payload=$(cat <<EOF
{
  "tag_name": "$new_version",
  "target_commitish": "main",
  "name": "$new_version",
  "body": "Release after fixing errors",
  "draft": false,
  "prerelease": false
}
EOF

);     release_response=$(curl -s -X POST -u $GITHUB_USER:$GITHUB_TOKEN -H "Content-Type: application/json" \
      -d "$release_payload" "https://api.github.com/repos/$GITHUB_USER/$repo_name/releases");      release_url=$(echo $release_response | jq -r '.html_url');      if [[ "$release_url" != "null" ]]; then       echo "Release created successfully for $repo_name: $release_url";     else       echo "Failed to create release for $repo_name.";     fi;   else     echo "Release already exists for the latest commit in $repo_name. Skipping.";   fi; }
# Main logic: Loop through all repositories and apply fixes
repos=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/users/$GITHUB_USER/repos?per_page=100" | jq -r '.[].name')
for repo in $repos; do
  get_failed_workflows "$repo";   get_failed_commits "$repo"; 
  auto_fix_issues "$repo";   create_release "$repo"; done
echo "Error fix and release process completed."
ls -la
cd
#!/bin/bash
# Define GitHub repository and token (ensure your token has the necessary scope)
GITHUB_USER="allyelvis"
GITHUB_TOKEN="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"  # Replace with your GitHub token
GITHUB_API="https://api.github.com"
# Function to get failed workflows (e.g., GitHub Actions)
get_failed_workflows() {   local repo_name=$1;   echo "Fetching failed workflows for $repo_name..."; 
  workflows=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/repos/$GITHUB_USER/$repo_name/actions/runs?status=failed&per_page=5" | jq -r '.workflow_runs[] | {id, name, status, conclusion, created_at}');      if [[ -z "$workflows" ]]; then     echo "No failed workflows found for $repo_name.";   else     echo "Failed workflows found for $repo_name:";     echo "$workflows" | jq .;   fi; }
# Function to automatically detect and fix errors in the code
auto_fix_issues() {   local repo_name=$1;   echo "Attempting to fix issues in $repo_name..."; 
  git clone https://github.com/$GITHUB_USER/$repo_name.git;   cd $repo_name || exit; 
  git pull origin main; 
  if [ -f "package.json" ]; then     echo "Installing dependencies...";     npm install;   fi; 
  if command -v eslint &>/dev/null; then     echo "Fixing code style issues...";     eslint --fix .;   fi; 
  if command -v npm &>/dev/null; then     echo "Attempting to build project...";     npm run build;   fi; 
  git add .;   COMMIT_MESSAGE="Auto fix: $(date +'%Y-%m-%d %H:%M:%S') - Fixed dependencies, formatting, and build errors";   git commit -m "$COMMIT_MESSAGE"; 
  git push origin main;    echo "Fixes applied and pushed to the repository."; }
# Function to detect failed commits (e.g., commits with failed tests)
get_failed_commits() {   local repo_name=$1;   echo "Checking for failed commits in $repo_name..."; 
  commits=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/repos/$GITHUB_USER/$repo_name/commits/main" | jq -r '.commit.message'); 
  failed_commits=$(echo "$commits" | grep -i 'fail\|error\|issue');      if [[ -z "$failed_commits" ]]; then     echo "No failed commits detected in $repo_name.";   else     echo "Failed commits found in $repo_name:";     echo "$failed_commits";   fi; }
# Function to create a new release after fixing the issue
create_release() {   local repo_name=$1;   echo "Creating a release for $repo_name..."; 
  latest_commit_hash=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/repos/$GITHUB_USER/$repo_name/commits/main" | jq -r '.sha'); 
  existing_tag=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/repos/$GITHUB_USER/$repo_name/tags" | jq -r ".[] | select(.commit.sha == \"$latest_commit_hash\") | .name");    if [[ -z "$existing_tag" ]]; then
    new_version="v$(date +%Y%m%d%H%M%S)"; 
    release_payload=$(cat <<EOF
{
  "tag_name": "$new_version",
  "target_commitish": "main",
  "name": "$new_version",
  "body": "Release after fixing errors",
  "draft": false,
  "prerelease": false
}
EOF

);     release_response=$(curl -s -X POST -u $GITHUB_USER:$GITHUB_TOKEN -H "Content-Type: application/json" \
      -d "$release_payload" "https://api.github.com/repos/$GITHUB_USER/$repo_name/releases");      release_url=$(echo $release_response | jq -r '.html_url');      if [[ "$release_url" != "null" ]]; then       echo "Release created successfully for $repo_name: $release_url";     else       echo "Failed to create release for $repo_name.";     fi;   else     echo "Release already exists for the latest commit in $repo_name. Skipping.";   fi; }
# Main logic: Loop through all repositories and apply fixes
repos=$(curl -s -u $GITHUB_USER:$GITHUB_TOKEN "$GITHUB_API/users/$GITHUB_USER/repos?per_page=100" | jq -r '.[].name')
for repo in $repos; do
  get_failed_workflows "$repo";   get_failed_commits "$repo"; 
  auto_fix_issues "$repo";   create_release "$repo"; done
echo "Error fix and release process completed."
cd
