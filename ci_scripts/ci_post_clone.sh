#!/bin/sh

# Xcode Cloud post-clone hook.
# Sets CURRENT_PROJECT_VERSION (used by Xcode to populate CFBundleVersion
# of every target when GENERATE_INFOPLIST_FILE = YES) to the unique
# Xcode Cloud build number so each App Store Connect upload is unique.

set -eu

if [ -z "${CI_BUILD_NUMBER:-}" ]; then
    echo "CI_BUILD_NUMBER is not set; leaving CURRENT_PROJECT_VERSION unchanged."
    exit 0
fi

PROJECT_FILE="$CI_PRIMARY_REPOSITORY_PATH/Body Forge.xcodeproj/project.pbxproj"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "Expected project file not found at: $PROJECT_FILE"
    exit 1
fi

echo "Setting CURRENT_PROJECT_VERSION to $CI_BUILD_NUMBER in $PROJECT_FILE"

/usr/bin/sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = $CI_BUILD_NUMBER;/g" "$PROJECT_FILE"

echo "Done. CURRENT_PROJECT_VERSION occurrences after update:"
/usr/bin/grep -c "CURRENT_PROJECT_VERSION = $CI_BUILD_NUMBER;" "$PROJECT_FILE" || true
