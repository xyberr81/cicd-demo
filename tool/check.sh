#!/usr/bin/env bash
# Same checks as the CI "check" job. Run before pushing.
set -euo pipefail
cd "$(dirname "$0")/.."

flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
