#!/usr/bin/env bash
# Build a signed (Developer ID) Perch.dmg for GitHub Releases.
# Optional notarization: NOTARY_PROFILE=souffleuse ./scripts/make-dmg.sh
set -euo pipefail
cd "$(dirname "$0")/.."

SIGN_ID="${SIGN_ID:-Developer ID Application: Gabriel Turpin (AKMNXGVVGX)}"
TEAM="${TEAM:-AKMNXGVVGX}"
VERSION="${VERSION:-1.0.1}"
BUILD="${BUILD:-2}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
ROOT="$(pwd)"
DERIVED="${ROOT}/DerivedData/release"
DIST="${ROOT}/dist"
STAGE="${DIST}/dmg"
APP="${DERIVED}/Build/Products/Release/Perch.app"
DMG="${DIST}/Perch-${VERSION}.dmg"

command -v xcodegen >/dev/null
xcodegen generate

rm -rf "${DERIVED}" "${DIST}"
mkdir -p "${STAGE}"

xcodebuild \
  -project Perch.xcodeproj \
  -scheme Perch \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "${DERIVED}" \
  ARCHS='arm64 x86_64' \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="${SIGN_ID}" \
  DEVELOPMENT_TEAM="${TEAM}" \
  MARKETING_VERSION="${VERSION}" \
  CURRENT_PROJECT_VERSION="${BUILD}" \
  OTHER_CODE_SIGN_FLAGS='--timestamp --options runtime' \
  build

test -d "${APP}"

# Contents/Helpers, not Contents/MacOS: a case-insensitive volume would collide with Perch.
swift build -c release --product perch --arch arm64 --arch x86_64
mkdir -p "${APP}/Contents/Helpers"
cp "$(swift build -c release --product perch --arch arm64 --arch x86_64 --show-bin-path)/perch" \
  "${APP}/Contents/Helpers/perch"
codesign --force --options runtime --timestamp --sign "${SIGN_ID}" "${APP}/Contents/Helpers/perch"

codesign --force --deep --options runtime --timestamp --sign "${SIGN_ID}" "${APP}"
codesign --verify --deep --strict "${APP}"

ditto "${APP}" "${STAGE}/Perch.app"
ln -s /Applications "${STAGE}/Applications"

rm -f "${DMG}"
hdiutil create \
  -volname "Perch" \
  -srcfolder "${STAGE}" \
  -ov -format UDZO \
  "${DMG}"

codesign --force --timestamp --sign "${SIGN_ID}" "${DMG}"

if [[ -n "${NOTARY_PROFILE}" ]]; then
  xcrun notarytool submit "${DMG}" --keychain-profile "${NOTARY_PROFILE}" --wait
  xcrun stapler staple "${DMG}"
  spctl --assess --type open --context context:primary-signature -vv "${DMG}" || true
fi

echo "DMG ${DMG}"
ls -lh "${DMG}"
