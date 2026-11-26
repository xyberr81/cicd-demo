#!/usr/bin/env bash
# CI only: writes the release key from Actions secrets to android/.
# Release and patch builds must both be signed with it.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${KEYSTORE_BASE64:-}" ]; then
  echo "::error::Signing secrets are missing. Run tool/make-keystore.sh first."
  exit 1
fi
echo "$KEYSTORE_BASE64" | base64 -d > android/upload.jks
cat > android/key.properties <<PROPS
storeFile=upload.jks
storePassword=$KEYSTORE_PASSWORD
keyAlias=$KEY_ALIAS
keyPassword=$KEY_PASSWORD
PROPS
