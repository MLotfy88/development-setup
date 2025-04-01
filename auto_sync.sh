#!/bin/bash
PROJECT_DIR="/root/workspace/project"
SYNC_INTERVAL=60 # seconds

echo "--- Starting Auto Sync Script ---"
echo "Project directory: $PROJECT_DIR"
echo "Sync interval: $SYNC_INTERVAL seconds"

while true; do
  if [ -d "$PROJECT_DIR" ]; then
    echo "$(date): Syncing project code in $PROJECT_DIR..."
    cd "$PROJECT_DIR" || continue # Go to next iteration if cd fails
    # Attempt to pull changes, log success or failure/up-to-date status
    if git pull origin main; then
      echo "$(date): Git pull successful."
    else
      echo "$(date): Git pull failed or repository is already up-to-date."
    fi
    # Go back to a known directory (optional, but good practice)
    cd /root/workspace || continue
  else
    echo "$(date): Project directory $PROJECT_DIR not found. Skipping sync."
  fi
  echo "$(date): Waiting for $SYNC_INTERVAL seconds..."
  sleep "$SYNC_INTERVAL"
done
