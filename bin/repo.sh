#!/bin/bash

# --- Simple Git Helper ---
# Usage: repo "your commit message"

function repo() {
    if [ -z "$1" ]; then
        echo "Usage: repo \"your commit message\""
        return 1
    fi

    echo "Staging all changes..."
    git add .
    
    echo "Committing with message: $1"
    git commit -m "$1"
    
    echo "Pushing to GitHub..."
    git push origin main
}
