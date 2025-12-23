#!/bin/bash

# Test script to validate GitHub API call logic for fetching latest release
# This script mirrors the logic used in the GitHub Actions workflow

set -e

echo "=== Testing GitHub API call logic ==="
echo ""

# Function to make API call with retry logic (same as workflow)
fetch_release_with_retry() {
  local max_attempts=3
  local attempt=1
  local delay=5

  while [ $attempt -le $max_attempts ]; do
    echo "Attempt $attempt of $max_attempts..."

    # Check if GitHub token is available
    if [ -n "$GITHUB_TOKEN" ]; then
      echo "Using authenticated GitHub API request"
    else
      echo "Using unauthenticated GitHub API request"
    fi

    # Make API call with better error handling
    if [ -n "$GITHUB_TOKEN" ]; then
      API_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        https://api.github.com/repos/edde746/plezy/releases/latest)
    else
      API_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/repos/edde746/plezy/releases/latest)
    fi

    HTTP_STATUS=$(echo "$API_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    API_BODY=$(echo "$API_RESPONSE" | sed -e 's/HTTPSTATUS:.*//g')

    echo "HTTP Status: $HTTP_STATUS"
    echo "API Response length: ${#API_BODY}"

    if [ "$HTTP_STATUS" = "200" ]; then
      # Check if response is valid JSON
      if echo "$API_BODY" | jq . >/dev/null 2>&1; then
        # Extract tag_name with better error checking
        LATEST_VERSION=$(echo "$API_BODY" | jq -r '.tag_name // empty')

        if [ "$LATEST_VERSION" != "null" ] && [ -n "$LATEST_VERSION" ]; then
          echo "Successfully extracted version: $LATEST_VERSION"
          return 0
        else
          echo "tag_name field was null or empty"
        fi
      else
        echo "Invalid JSON response from GitHub API"
      fi
    elif [ "$HTTP_STATUS" = "403" ]; then
      echo "Rate limited by GitHub API (HTTP 403)"
      # Check for rate limit specific message
      if echo "$API_BODY" | jq -e '.message' >/dev/null 2>&1; then
        ERROR_MESSAGE=$(echo "$API_BODY" | jq -r '.message')
        echo "GitHub API error: $ERROR_MESSAGE"
      fi
    elif [ "$HTTP_STATUS" = "404" ]; then
      echo "Repository or releases not found (HTTP 404)"
      echo "Response: $API_BODY"
      return 1
    else
      echo "GitHub API request failed with status: $HTTP_STATUS"
      echo "Response body: $API_BODY"
    fi

    if [ $attempt -lt $max_attempts ]; then
      echo "Waiting $delay seconds before retry..."
      sleep $delay
      delay=$((delay * 2))  # Exponential backoff
    fi

    attempt=$((attempt + 1))
  done

  return 1
}

# Check GitHub API status first
echo "Checking GitHub API status..."
API_STATUS=$(curl -s -w "HTTPSTATUS:%{http_code}" https://api.github.com/status)
STATUS_CODE=$(echo "$API_STATUS" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

if [ "$STATUS_CODE" != "200" ]; then
  echo "Warning: GitHub API status check failed (HTTP $STATUS_CODE)"
else
  echo "GitHub API is accessible"
fi

echo ""
echo "Fetching latest release from GitHub API..."

# Try to fetch the release
if ! fetch_release_with_retry; then
  echo ""
  echo "❌ Failed to get latest version after all retry attempts"
  echo "LATEST_VERSION='$LATEST_VERSION'"
  echo ""
  echo "This could indicate:"
  echo "- No releases found in the repository"
  echo "- All releases are drafts or pre-releases"
  echo "- GitHub API rate limiting"
  echo "- Network connectivity issues"
  echo "- Repository access issues"
  echo ""
  echo "Please check:"
  echo "1. Repository exists: https://github.com/edde746/plezy"
  echo "2. Repository has published releases (not drafts)"
  echo "3. GitHub API rate limits: https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting"
  exit 1
fi

echo ""
echo "✅ Final version: $LATEST_VERSION"
echo ""

# Test the complete workflow logic
echo "=== Testing version comparison logic ==="

# Get current version from cask file
if [ -f "Casks/plezy.rb" ]; then
  CURRENT_VERSION=$(grep 'version "' Casks/plezy.rb | sed 's/.*version "\(.*\)".*/\1/')
  echo "Current version: $CURRENT_VERSION"
  echo "Latest version: $LATEST_VERSION"

  if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "✅ Versions match - no update needed"
  else
    echo "🔄 Update available: $CURRENT_VERSION -> $LATEST_VERSION"
  fi
else
  echo "❌ Cask file not found at Casks/plezy.rb"
  exit 1
fi

echo ""
echo "=== Test completed successfully ==="
