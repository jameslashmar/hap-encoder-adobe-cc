#!/bin/bash
# macOS installer for the HAP After Effects output module only (no Premiere / AME exporter).
#
#   installer/ae-only/build-mac-pkg.sh <path to HAPAfterEffectsPlugin.bundle> <version>
#
# Optional environment:
#   APP_IDENTITY       "Developer ID Application: ..."  signs the plugin bundle
#   INSTALLER_IDENTITY "Developer ID Installer: ..."    signs the .pkg
#   NOTARY_PROFILE     notarytool keychain profile      notarises + staples the .pkg
# Without them the result is unsigned, for local testing only.
set -euo pipefail

BUNDLE=${1:?bundle path}
VERSION=${2:?version}
NAME=HAPAfterEffectsPlugin.bundle
DEST="Library/Application Support/Adobe/Common/Plug-ins/7.0/MediaCore/HAP"
ID=org.hapcommunity.HapCodecPlugin.aftereffects
OUT="$PWD/HAP-AfterEffects-$VERSION-macOS.pkg"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/root/$DEST"
ditto "$BUNDLE" "$WORK/root/$DEST/$NAME"
xattr -cr "$WORK/root/$DEST/$NAME"

if [ -n "${APP_IDENTITY:-}" ]; then
  codesign --force --timestamp --options runtime --sign "$APP_IDENTITY" "$WORK/root/$DEST/$NAME"
else
  echo "warning: APP_IDENTITY unset - bundle keeps its ad-hoc signature"
  codesign --force --sign - "$WORK/root/$DEST/$NAME"
fi
codesign --verify --strict "$WORK/root/$DEST/$NAME"

# install exactly where AE looks; never "relocate" onto some other copy of the bundle
pkgbuild --analyze --root "$WORK/root" "$WORK/components.plist"
plutil -replace 0.BundleIsRelocatable -bool false "$WORK/components.plist"
pkgbuild --root "$WORK/root" --component-plist "$WORK/components.plist" \
  --identifier "$ID" --version "$VERSION" --install-location / "$WORK/component.pkg"

cat > "$WORK/distribution.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>HAP for After Effects $VERSION</title>
    <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
    <allowed-os-versions><os-version min="11.0"/></allowed-os-versions>
    <license file="license.txt"/>
    <choices-outline><line choice="default"/></choices-outline>
    <choice id="default" title="HAP for After Effects"><pkg-ref id="$ID"/></choice>
    <pkg-ref id="$ID" version="$VERSION">component.pkg</pkg-ref>
</installer-gui-script>
EOF
mkdir -p "$WORK/resources"
cp "$(dirname "$0")/../../license.txt" "$WORK/resources/license.txt"

SIGN=()
[ -n "${INSTALLER_IDENTITY:-}" ] && SIGN=(--sign "$INSTALLER_IDENTITY" --timestamp)
productbuild --distribution "$WORK/distribution.xml" --resources "$WORK/resources" \
  --package-path "$WORK" ${SIGN[@]+"${SIGN[@]}"} "$OUT"   # bash 3.2-safe empty array

if [ -n "${NOTARY_PROFILE:-}" ]; then
  xcrun notarytool submit "$OUT" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$OUT"
fi
pkgutil --check-signature "$OUT" || true
echo "built $OUT"
