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
)

IGNORED_FILES=(
    ".gitignore"
    ".gitmodules"
    "script/sync_from_monorepo.sh"
)

# Function to show usage
show_usage() {
    echo "Usage: $0 [-d] /path/to/monorepo"
    echo "  -d    Dry run (show which files would be changed without making changes)"
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
if [ "$#" -ne 1 ]; then
    show_usage
fi

MONOREPO_PATH="$1"
CONTRACTS_PATH="$MONOREPO_PATH/packages/contracts"
CURRENT_DATE=$(date +"%Y%m%d_%H%M%S")
NEW_BRANCH="sync_from_monorepo_$CURRENT_DATE"

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
        # Update docs
	forge doc

        # Stage all changes (including deletions)
        git add -A

        # Commit the changes
        commit_msg="Sync changes from monorepo - $CURRENT_DATE"
        commit_msg+="\n\nSynchronized with monorepo, including removal of files/directories"
        commit_msg+=" that no longer exist in the monorepo's contracts directory."
        
        git commit -m "$commit_msg"

        echo "Changes from monorepo have been copied to the new branch: $NEW_BRANCH"
        echo "Review the changes and then merge this branch if everything looks good."
        echo "To push this branch to remote, use: git push origin $NEW_BRANCH"
    fi
}

# Fetch the latest changes from the contracts repo remote
git fetch origin

if [ "$DRY_RUN" = false ]; then
    # Create and checkout a new branch in the contracts repo
    git checkout -b "$NEW_BRANCH"
fi

# Go to the monorepo and ensure we're on the main branch with the latest changes
cd "$MONOREPO_PATH"
git checkout main
git pull origin main

# Go back to the contracts repo
cd -

# Perform the sync
perform_sync
