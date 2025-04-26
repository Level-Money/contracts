#!/bin/bash

# Configuration
# Add or remove directories to ignore in this array
IGNORED_DIRS=(
    "lib"
    "broadcast"
    "tmp"
    ".git"
    "integration_tests"
    "docs"
    ".gitmodules"
    ".github"
)

IGNORED_FILES=(
    ".gitignore"
    ".gitmodules"
    "script/sync_from_monorepo.sh"
)

# Function to show usage
show_usage() {
    echo "Usage: $0 [-d] /path/to/monorepo [commit_hash]"
    echo "  -d           Dry run (show which files would be changed without making changes)"
    echo "  commit_hash  Optional: Specific commit hash to sync from (defaults to latest on main branch)"
    exit 1
}

# Parse command line options
DRY_RUN=false
while getopts ":d" opt; do
    case ${opt} in
        d )
            DRY_RUN=true
            ;;
        \? )
            show_usage
            ;;
    esac
done
shift $((OPTIND -1))

# Check if the path to the monorepo is provided
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    show_usage
fi

MONOREPO_PATH="$1"
COMMIT_HASH=""

# Check if commit hash is provided as second argument
if [ "$#" -eq 2 ]; then
    COMMIT_HASH="$2"
fi

CONTRACTS_PATH="$MONOREPO_PATH/packages/contracts"

# Check if the monorepo path exists
if [ ! -d "$MONOREPO_PATH" ]; then
    echo "Error: Monorepo path does not exist"
    exit 1
fi

# Check if the contracts directory exists in the monorepo
if [ ! -d "$CONTRACTS_PATH" ]; then
    echo "Error: Contracts directory not found in monorepo"
    exit 1
fi

# Ensure we're in the contracts repo
if [ ! -d ".git" ]; then
    echo "Error: Must be run from the root of the contracts repo"
    exit 1
fi

# Function to get PR details from commit hash
get_pr_details() {
    local commit_hash="$1"
    local monorepo_dir="$2"
    
    # Save current directory
    local current_dir=$(pwd)
    
    # Change to monorepo directory
    cd "$monorepo_dir"
    
    # Get the commit message to extract PR number
    local commit_msg=$(git log -1 --pretty=format:"%s" "$commit_hash")
    
    # Extract PR number using regex
    local pr_number=$(echo "$commit_msg" | grep -oE "Merge pull request #([0-9]+)" | grep -oE "#([0-9]+)" | tr -d '#')
    
    # If we couldn't find PR number in merge commit, try to find it in the commit message
    if [ -z "$pr_number" ]; then
        pr_number=$(echo "$commit_msg" | grep -oE "\(#([0-9]+)\)" | grep -oE "#([0-9]+)" | tr -d '#')
    fi
    
    # Get PR title from commit message (removing the PR number part if present)
    local pr_title=""
    if [ -n "$pr_number" ]; then
        pr_title=$(echo "$commit_msg" | sed -E 's/Merge pull request #[0-9]+ from [^/]+\/[^[:space:]]+//' | sed -E 's/\(#[0-9]+\)//' | xargs)
    else
        # If no PR number found, use the commit message as title
        pr_title="$commit_msg"
    fi
    
    # Return to original directory
    cd "$current_dir"
    
    # Return the results
    echo "$pr_number|$pr_title"
}

# Function to perform sync
perform_sync() {
    local dry_run_flag=""
    if [ "$DRY_RUN" = true ]; then
        dry_run_flag="--dry-run"
        echo "Performing dry run. No changes will be made."
    fi

    # Create a temporary file for rsync exclude patterns
    EXCLUDE_FILE=$(mktemp)

    # Add directories from IGNORED_DIRS to exclude file
    for dir in "${IGNORED_DIRS[@]}"; do
        echo "$dir/" >> "$EXCLUDE_FILE"
    done

    # Add files from IGNORED_FILES to exclude file
    for file in "${IGNORED_FILES[@]}"; do
        echo "$file" >> "$EXCLUDE_FILE"
    done

    # Add .gitignore patterns to exclude file
    if [ -f ".gitignore" ]; then
        cat ".gitignore" >> "$EXCLUDE_FILE"
    fi

    # Use rsync with delete option to copy/update files and remove non-existent ones
    rsync -avi $dry_run_flag --delete --exclude-from="$EXCLUDE_FILE" --itemize-changes "$CONTRACTS_PATH/" ./ | sed -E 's/^(.)(.)(.)(.)(.)(.)(....) (.*)/\1 \8/' | while read line; do
        change=${line:0:1}
        file=${line:2}
        case $change in
            ">") echo "+ $file" ;;  # New file
            "<") echo "- $file" ;;  # Deleted file
            "c") echo "~ $file" ;;  # Changed file
            "h") echo "~ $file" ;;  # Hard link change
            "*") echo "- $file" ;;  # Deleted directory
            ".") ;;  # No change, don't output anything
            *)   echo "$line" ;;  # Any other cases, just print the line as-is
        esac
    done

    # Remove the temporary exclude file
    rm "$EXCLUDE_FILE"

    if [ "$DRY_RUN" = false ]; then
        # Stage all changes (including deletions)
        git add -A

        # Get PR details if commit hash is available
        local pr_details=""
        local pr_number=""
        local pr_title=""
        
        if [ -n "$CURRENT_COMMIT" ]; then
            pr_details=$(get_pr_details "$CURRENT_COMMIT" "$MONOREPO_PATH")
            pr_number=$(echo "$pr_details" | cut -d'|' -f1)
            pr_title=$(echo "$pr_details" | cut -d'|' -f2)
        fi
        
        # Format commit message
        local commit_msg=""
        
        if [ -n "$pr_number" ] && [ -n "$pr_title" ]; then
            # Format with PR number and title
            commit_msg="#$pr_number: $pr_title (${CURRENT_COMMIT:0:7})"
        else
            # Fallback format if PR details not found
            commit_msg="Sync changes from monorepo - commit ${CURRENT_COMMIT:0:7}"
        fi
    
        
        git commit -m "$commit_msg"

        echo "Changes from monorepo have been copied to the new branch: $NEW_BRANCH"
        echo "Review the changes and then merge this branch if everything looks good."
        echo "To push this branch to remote, use: git push origin $NEW_BRANCH"
    fi
}

# Fetch the latest changes from the contracts repo remote
git fetch origin

# Go to the monorepo and ensure we have the right commit
cd "$MONOREPO_PATH"

if [ -n "$COMMIT_HASH" ]; then
    # Check if the commit hash exists
    if ! git cat-file -e "$COMMIT_HASH" 2>/dev/null; then
        echo "Error: Commit hash $COMMIT_HASH does not exist in the monorepo"
        exit 1
    fi
    
    # Checkout the specific commit
    git checkout "$COMMIT_HASH"
    CURRENT_COMMIT="$COMMIT_HASH"
    echo "Using monorepo at specific commit: $CURRENT_COMMIT"
else
    # No commit hash provided, use latest main
    git checkout main
    git pull origin main
    CURRENT_COMMIT=$(git rev-parse HEAD)
    echo "Using latest commit from monorepo main branch: $CURRENT_COMMIT"
fi

# Create branch name using the commit hash
SHORT_HASH="${CURRENT_COMMIT:0:7}"
NEW_BRANCH="sync_from_monorepo_$SHORT_HASH"

# Go back to the contracts repo
cd -

if [ "$DRY_RUN" = false ]; then
    # Create and checkout a new branch in the contracts repo
    git checkout -b "$NEW_BRANCH"
fi

# Perform the sync
perform_sync