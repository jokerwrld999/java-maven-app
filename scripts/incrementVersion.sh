#!/bin/bash

current_version=$(grep -oPm1 "(?<=<version>)[^<]+" pom.xml)

# Split the version into major, minor, and patch components
major=$(echo "$current_version" | awk -F. '{print $1}')
minor=$(echo "$current_version" | awk -F. '{print $2}')
patch=$(echo "$current_version" | awk -F. '{print $3}')

# Increment the patch version
patch=$((patch + 1))

# Create the new version
new_version="$major.$minor.$patch"

# Update the pom.xml file with the new version
sed -i "s/<version>$current_version<\/version>/<version>$new_version<\/version>/" pom.xml