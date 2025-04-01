#!/bin/bash
# Exit on error, print commands and arguments as they are executed.
set -euxo pipefail

echo "--- Starting SSH Service ---"
# Ensure sshd directory exists with correct permissions before starting
mkdir -p /run/sshd
chmod 700 /run/sshd
# Start SSH service
service ssh start || { echo "Failed to start SSH service"; exit 1; }
echo "SSH Service Started."

# Ensure workspace directory exists
echo "--- Ensuring Workspace Directory ---"
WORKSPACE_DIR="/root/workspace"
if [ ! -d "$WORKSPACE_DIR" ]; then
    echo "Creating workspace directory: $WORKSPACE_DIR"
    mkdir -p "$WORKSPACE_DIR"
fi
cd "$WORKSPACE_DIR" || exit 1
echo "Workspace directory ready: $WORKSPACE_DIR"

# Clone or update the project repository
# IMPORTANT: Replace with your actual project repository URL
PROJECT_REPO_URL="https://github.com/MLotfy88/MediSwitch-Final.git"
PROJECT_DIR_NAME="project" # Local directory name for the project

echo "--- Cloning/Updating Project Repository ---"
if [ ! -d "$PROJECT_DIR_NAME" ]; then
    echo "🚀 Cloning project for the first time from $PROJECT_REPO_URL..."
    git clone "$PROJECT_REPO_URL" "$PROJECT_DIR_NAME" || { echo "Failed to clone repository"; exit 1; }
    cd "$PROJECT_DIR_NAME" || exit 1
else
    echo "✅ Project directory '$PROJECT_DIR_NAME' already exists. Updating..."
    cd "$PROJECT_DIR_NAME" || exit 1
    # Attempt to pull changes, ignore error if already up-to-date
    git pull origin main || echo "Git pull failed or repository is up-to-date."
fi
echo "Project code is in $(pwd)"
# Go back to workspace dir
cd "$WORKSPACE_DIR" || exit 1

# Create credentials file with clearer instructions
echo "--- Creating Credentials File ---"
CRED_DIR="/root/public"
CRED_FILE="$CRED_DIR/credentials.txt"
mkdir -p "$CRED_DIR"
# Get the container's primary IP address
CONTAINER_IP=$(hostname -I | awk '{print $1}')
echo "🔐 VPS Credentials & Connection Info 🔐" > "$CRED_FILE"
echo "-----------------------------------------" >> "$CRED_FILE"
echo "Container IP Address: $CONTAINER_IP" >> "$CRED_FILE"
echo "Project Path inside Container: $WORKSPACE_DIR/$PROJECT_DIR_NAME" >> "$CRED_FILE"
echo "" >> "$CRED_FILE"
echo "📌 SSH Connection (From Your Local Machine):" >> "$CRED_FILE"
echo "   Use the following details with your SSH client (like VS Code Remote-SSH, Trae.ai, Terminal):" >> "$CRED_FILE"
echo "   Host: <YOUR_VPS_PUBLIC_IP>" >> "$CRED_FILE"
echo "   Port: 2222 (This is the port mapped on the VPS by 'docker run -p 2222:22')" >> "$CRED_FILE"
echo "   User: root" >> "$CRED_FILE"
echo "   Authentication: Use password (if enabled in sshd_config) or SSH key." >> "$CRED_FILE"
echo "" >> "$CRED_FILE"
echo "📌 ADB Connection (Port 5037 is mapped):" >> "$CRED_FILE"
echo "   Ensure ADB server is running inside the container (this script starts it)." >> "$CRED_FILE"
echo "   Connect your device via USB/WiFi and use 'adb devices' to check." >> "$CRED_FILE"
echo "-----------------------------------------" >> "$CRED_FILE"
echo "Credentials file created at $CRED_FILE"
echo "Download it from your local machine using: scp -P 2222 root@<YOUR_VPS_PUBLIC_IP>:$CRED_FILE ."

# Start ADB server
echo "--- Starting ADB Server ---"
adb start-server || echo "Warning: Failed to start ADB server."
echo "ADB Server started."

echo "--- Environment Setup Complete ---"
echo "Container is running. Project is in $WORKSPACE_DIR/$PROJECT_DIR_NAME"
echo "Connect via SSH using port 2222 on your VPS IP."
echo "Keeping container alive..."

# Keep the container running
tail -f /dev/null
