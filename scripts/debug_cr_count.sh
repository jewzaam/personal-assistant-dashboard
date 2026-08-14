#!/usr/bin/env bash
# Debug CR count for a PR URL
# Usage: ./scripts/debug_cr_count.sh https://github.com/owner/repo/pull/123

set -euo pipefail

PR_URL="${1:?Usage: $0 https://github.com/owner/repo/pull/123}"

# Parse owner/repo and number from URL
REPO=$(echo "$PR_URL" | sed -E 's|https://github.com/([^/]+/[^/]+)/pull/[0-9]+.*|\1|')
NUMBER=$(echo "$PR_URL" | sed -E 's|.*/pull/([0-9]+).*|\1|')

echo "Repo:   $REPO"
echo "PR:     #$NUMBER"
echo ""

# Get current user
LOGIN=$(gh api user --jq '.login')
echo "User:   $LOGIN"
echo ""

# Fetch all reviews (paginated)
echo "=== All reviews ==="
gh api --paginate "/repos/$REPO/pulls/$NUMBER/reviews" \
  --jq '.[] | "\(.user.login)\t\(.state)\t\(.submitted_at)\t\(.id)"' \
  | column -t -s $'\t'

echo ""
echo "=== My reviews only ==="
gh api --paginate "/repos/$REPO/pulls/$NUMBER/reviews" \
  --jq ".[] | select(.user.login == \"$LOGIN\") | \"\(.state)\t\(.submitted_at)\t\(.id)\"" \
  | column -t -s $'\t'

echo ""
echo "=== My CHANGES_REQUESTED count ==="
COUNT=$(gh api --paginate "/repos/$REPO/pulls/$NUMBER/reviews" \
  --jq "[.[] | select(.user.login == \"$LOGIN\" and .state == \"CHANGES_REQUESTED\")] | length")
echo "$COUNT"
