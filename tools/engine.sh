#!/usr/bin/env bash
# Official editor and matching Godot Android templates. No third-party game plugin.
set -euo pipefail
V=4.4.1
CACHE="${HOME}/.cache/ashen-tools/${V}"
mkdir -p "$CACHE" "$HOME/.local/share/godot/export_templates/$V.stable"
if [[ ! -x "$CACHE/godot" || ! -s "$CACHE/android_release.apk" || ! -s "$CACHE/android_source.zip" ]]; then
  t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
  cd "$t"
  root="https://github.com/godotengine/godot-builds/releases/download/$V-stable"
  cli="Godot_v${V}-stable_linux.x86_64.zip"; templates="Godot_v${V}-stable_export_templates.tpz"
  for f in SHA512-SUMS.txt "$cli" "$templates"; do curl -fLsS --retry 3 "$root/$f" -o "$f"; done
  for f in "$cli" "$templates"; do grep -F "$f" SHA512-SUMS.txt | sha512sum -c -; done
  unzip -q "$cli"; install -m755 "Godot_v${V}-stable_linux.x86_64" "$CACHE/godot"
  for template in android_release.apk android_source.zip; do
    unzip -p "$templates" "templates/$template" > "$CACHE/$template.part"
    mv "$CACHE/$template.part" "$CACHE/$template"
  done
fi
for template in android_release.apk android_source.zip; do
  ln -sf "$CACHE/$template" "$HOME/.local/share/godot/export_templates/$V.stable/$template"
done
printf '%s\n' "$V.stable" > "$HOME/.local/share/godot/export_templates/$V.stable/version.txt"
"$CACHE/godot" --version
