#!/usr/bin/env bash

set -e

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
DEFAULT_MSG="$TIMESTAMP, quick save"

# Prompt for custom input; hitting Enter uses the default
read -r -p "Commit message (press Enter for default): " custom_msg

if [ -z "$custom_msg" ]; then
    COMMIT_MSG="$DEFAULT_MSG"
else
    # Appends the timestamp to the end of your custom message
    COMMIT_MSG="$custom_msg ($TIMESTAMP)"
fi

git add -A
git commit -m "$COMMIT_MSG"
git push