#!/bin/bash
# Start JLinkRemoteServer if not already running

if command -v JLinkRemoteServerExe >/dev/null 2>&1; then
    if pgrep -f JLinkRemoteServer >/dev/null 2>&1; then
        echo "JLinkRemoteServer is already running"
    else
        echo "Starting JLinkRemoteServer..."
        (cd /tmp && nohup JLinkRemoteServerExe -select USB </dev/null >/dev/null 2>&1 &)
        sleep 2
        echo "JLinkRemoteServer started"
    fi
else
    echo "JLinkRemoteServer not found in PATH, skipping..."
fi
