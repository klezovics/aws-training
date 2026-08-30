#!/usr/bin/env bash
# Round-trip an object through S3: upload -> read -> overwrite -> read -> delete.
# Shows that a PUT to an existing key REPLACES it (no versioning = old value gone).
set -euo pipefail

export AWS_PROFILE="${AWS_PROFILE:-ak-aws-training}"
export AWS_PAGER=""   # stop the CLI piping output through less (the "(END)" prompt)

BUCKET="ak-test-bucket-777"
KEY="ak/test-object"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

put_then_get() {
  local src="$1"
  echo "--- PUT $src -> s3://$BUCKET/$KEY"
  aws s3api put-object --bucket "$BUCKET" --key "$KEY" --body "$src" \
    --query '{ETag:ETag}' --output text

  echo "--- GET s3://$BUCKET/$KEY"
  aws s3api get-object --bucket "$BUCKET" --key "$KEY" /dev/stdout \
    --query '{Size:ContentLength,Modified:LastModified}' --output text
  echo
}

echo "=== bucket: $BUCKET  key: $KEY"
put_then_get "$DIR/file1.txt"
put_then_get "$DIR/file2.txt"

echo "--- DELETE s3://$BUCKET/$KEY"
aws s3api delete-object --bucket "$BUCKET" --key "$KEY"

echo "--- verify it is gone (expect a 404 / NoSuchKey)"
if aws s3api head-object --bucket "$BUCKET" --key "$KEY" 2>/dev/null; then
  echo "STILL THERE - bucket is versioned? check: aws s3api list-object-versions --bucket $BUCKET --prefix $KEY"
else
  echo "gone."
fi
