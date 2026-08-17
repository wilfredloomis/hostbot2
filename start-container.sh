#!/bin/sh
set -eu

mkdir -p /mnt/r2
endpoint="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"

/usr/local/bin/tigrisfs --endpoint "${endpoint}" -f "${R2_BUCKET_NAME}" /mnt/r2 &
fuse_pid=$!

attempt=0
while ! mountpoint -q /mnt/r2; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 30 ]; then
    echo "R2 mount did not become ready" >&2
    kill "$fuse_pid" 2>/dev/null || true
    exit 1
  fi
  sleep 1
done

mkdir -p /mnt/r2/bots
rm -rf /var/www/html/bots
ln -s /mnt/r2/bots /var/www/html/bots

exec apache2-foreground
