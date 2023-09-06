#!/bin/bash

# Initialize an associative array to store commit message counts
declare -A message_counts

# Iterate through the commit history starting from HEAD
git log --format="%h %s" --reverse HEAD |
while read -r commit message; do
  # Increment the count for the current commit message
  message_counts["$message"]=$((message_counts["$message"] + 1))

  # Check if this is not the first occurrence of the message
  if [ "${message_counts["$message"]}" -gt 1 ]; then
    # Squash the current commit into the previous one
    git reset --soft HEAD^
    git commit --amend --no-edit
  fi
done
