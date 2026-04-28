#!/bin/bash
# Triggered by Planner when ticket status is set to CLOSED
# Pushes current branch to GitHub

set -e

BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "Ticket closed. Pushing $BRANCH to GitHub..."

git push origin "$BRANCH"

if [ $? -eq 0 ]; then
  echo "PUSH DONE — $BRANCH pushed to origin"
else
  echo "PUSH FAILED — check git remote and credentials"
  exit 1
fi
