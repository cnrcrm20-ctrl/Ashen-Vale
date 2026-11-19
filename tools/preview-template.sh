#!/usr/bin/env bash
# Install the pinned official template plus our small capability probe. Do not
# overwrite someone's custom Android project. All generated files are ignored.
set -euo pipefail
cd "$(dirname "$0")/.."
version=4.4.1.stable
template="$HOME/.local/share/godot/export_templates/$version/android_source.zip"
root=game/android; out=$root/build
if [[ -d $root && ! -f $root/.ashen-preview-template ]]; then
  echo 'Existing custom game/android directory: use a clean checkout for release packaging.' >&2; exit 1
fi
mkdir -p "$out"; touch "$root/.ashen-preview-template" "$root/.gdignore" "$out/.gdignore"
printf '%s\n' "$version" > "$root/.build_version"
unzip -oq "$template" -d "$out"; chmod +x "$out/gradlew"
# Hosted shared runner IPs can hit Maven Central's HTTP 429. Google's public
# mirror contains the same Central coordinates; retain the upstream repos for
# Android/Gradle artifacts and cache only tools/dependencies, never the APK.
for cfg in "$out/settings.gradle" "$out/build.gradle"; do
  grep -q '^[[:space:]]*mavenCentral()' "$cfg"
  sed -i '/^[[:space:]]*mavenCentral()/i\        maven { url "https://maven-central.storage-download.googleapis.com/maven2/" }' "$cfg"
done
java_dir="$out/src/com/godot/game"
install -m644 android/preview/PreviewGraphics.java "$java_dir/PreviewGraphics.java"
# Retain the official activity, splash screen and license. Add only the host hook.
python3 - "$java_dir/GodotApp.java" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1]); s = p.read_text(); marker = 'public class GodotApp extends GodotActivity {'
assert s.count(marker) == 1 and 'getCommandLine()' not in s, 'Unexpected template activity'
p.write_text(s.replace(marker, marker + '''
    @Override
    public java.util.List<String> getCommandLine() {
        return PreviewGraphics.commandLine(this, super.getCommandLine());
    }
'''))
PY
install -Dm644 android/preview/AndroidManifest.xml "$out/src/standardRelease/AndroidManifest.xml"
ndk=${ANDROID_NDK_HOME:-}
if [[ ! -d $ndk/toolchains/llvm ]]; then
  ndk=$(find "${ANDROID_HOME:?}/ndk" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -1)
fi
cc_dir=$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin
for abi in arm64-v8a x86_64; do
  target=aarch64-linux-android; [[ $abi != x86_64 ]] || target=x86_64-linux-android
  mkdir -p "$out/libs/release/$abi"
  "$cc_dir/${target}24-clang" -std=c11 -Os -Wall -Wextra -Werror -fPIC -shared -fvisibility=hidden \
    -Wl,-z,max-page-size=16384,-z,relro,-z,now,--no-undefined,-soname,libashen_gpu.so \
    android/preview/gpu_probe.c -lvulkan -o "$out/libs/release/$abi/libashen_gpu.so"
done
