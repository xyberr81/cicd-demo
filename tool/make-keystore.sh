#!/usr/bin/env bash
# Creates the release signing key once and uploads it to GitHub Actions secrets.
# Keep secrets/upload.jks backed up: every future APK must be signed with it,
# or Android refuses to install the update over the old version.
set -euo pipefail
cd "$(dirname "$0")/.."

ALIAS=upload
PASSWORD=$(openssl rand -base64 24 | tr -d '/+=')
mkdir -p secrets

if [ -e secrets/upload.jks ]; then
  echo "secrets/upload.jks already exists; not overwriting it." >&2
  exit 1
fi

keytool -genkeypair -v -keystore secrets/upload.jks -storetype PKCS12 \
  -alias "$ALIAS" -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$PASSWORD" -keypass "$PASSWORD" \
  -dname "CN=CI/CD Demo"
printf '%s\n' "$PASSWORD" > secrets/password.txt

base64 -w0 secrets/upload.jks | gh secret set ANDROID_KEYSTORE_BASE64
printf '%s' "$PASSWORD" | gh secret set ANDROID_KEYSTORE_PASSWORD
printf '%s' "$PASSWORD" | gh secret set ANDROID_KEY_PASSWORD
printf '%s' "$ALIAS" | gh secret set ANDROID_KEY_ALIAS
echo "Done. Key and password are in secrets/ (gitignored)."
