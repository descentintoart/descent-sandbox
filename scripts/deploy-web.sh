#!/usr/bin/env bash
# Builds the React page and uploads it to the site bucket.
set -euo pipefail
export AWS_PROFILE="${AWS_PROFILE:-art}"
cd "$(dirname "$0")/.."
BUCKET=$(terraform -chdir=infra output -raw bucket_name)
DIST=$(terraform -chdir=infra output -raw distribution_id)
(cd apps/ulid/web && npm run build)
aws s3 sync apps/ulid/web/dist "s3://$BUCKET/ulid/" --delete
aws cloudfront create-invalidation --distribution-id "$DIST" --paths "/ulid/*" > /dev/null
echo "Deployed. Live in a minute or two."
