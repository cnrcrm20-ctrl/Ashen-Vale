#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD; GODOT="${GODOT:-$HOME/.cache/ashen-tools/4.4.1/godot}"
export GODOT_SILENCE_ROOT_WARNING=1
OUT="$ROOT/build/android"; export SHOT_DIR="$ROOT/build/shots"; mkdir -p "$OUT" "$SHOT_DIR"
python3 tools/story.py --check
mkdir -p "$HOME/.config/godot"; cat > "$HOME/.config/godot/editor_settings-4.4.tres" <<SETTINGS
[gd_resource type="EditorSettings" format=3]
[resource]
export/android/android_sdk_path = "${ANDROID_HOME:?Android SDK required}"
export/android/java_sdk_path = "${JAVA_HOME:?JDK required}"
SETTINGS
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a "$GODOT" --audio-driver Dummy --rendering-method gl_compatibility --path game --editor --import >build/import.log 2>&1 || { tail -120 build/import.log; exit 1; }
# The editor queries Vulkan adapters on startup even with the GL renderer. The host
# has llvmpipe GL, not a Vulkan surface. Suppress only those two driver-probe pairs.
python3 - <<'CHECK'
from pathlib import Path
import re
s=Path('build/import.log').read_text()
s=re.sub(r'^ERROR: (?:Required extension VK_KHR_surface not found\.|Condition "err != OK" is true\. Returning: err)\n\s+at: [^\n]+drivers/vulkan/[^\n]+\n','',s,flags=re.M)
if re.search(r'^ERROR:|SCRIPT ERROR:|Parse Error:|Compile Error:',s,re.M):raise SystemExit(s[-12000:])
CHECK
timeout 90 "$GODOT" --headless --path game --script res://tests/voices_test.gd 2>&1 | tee build/voices.log
if grep -E 'SCRIPT ERROR:|SHADER ERROR:|Program linking failed|^ERROR:' build/voices.log; then exit 1; fi
grep -q 'VOICE_NIGHT_SMOKE PASS' build/voices.log
timeout 90 "$GODOT" --headless --path game --script res://tests/forest_test.gd 2>&1 | tee build/forest.log
if grep -E 'SCRIPT ERROR:|SHADER ERROR:|Program linking failed|^ERROR:' build/forest.log; then exit 1; fi
grep -q 'FOREST_SMOKE PASS' build/forest.log
timeout 150 "$GODOT" --headless --path game --script res://tests/chapter_test.gd 2>&1 | tee build/smoke.log
if grep -E 'SCRIPT ERROR:|SHADER ERROR:|Program linking failed|^ERROR:' build/smoke.log; then exit 1; fi
grep -q 'CHAPTER_SMOKE PASS' build/smoke.log
if command -v xvfb-run >/dev/null; then
  # llvmpipe renders full 720p shadow maps and skinned close-ups on CPU.
  # Keep all eleven production frames and the fatal error/visibility gates.
  LIBGL_ALWAYS_SOFTWARE=1 timeout -k 15 18m xvfb-run -a "$GODOT" --path game --audio-driver Dummy --rendering-method gl_compatibility --resolution 1280x720 --fixed-fps 24 --script res://tests/visual.gd 2>&1 | tee build/visual.log
  grep -qx 'VISUAL_SMOKE PASS' build/visual.log
  test "$(grep -c '^FRAME ' build/visual.log)" = 11
  if grep -E 'SCRIPT ERROR:|SHADER ERROR:|Program linking failed|^ERROR:' build/visual.log; then exit 1; fi
fi
"$GODOT" --headless --path game --export-release Android "$OUT/episode1-unsigned.apk" >build/export.log 2>&1 || { tail -80 build/export.log; exit 1; }
BT=$(find "$ANDROID_HOME/build-tools" -maxdepth 1 -mindepth 1 -type d | sort -V | tail -1)
"$BT/zipalign" -f -P 16 4 "$OUT/episode1-unsigned.apk" "$OUT/Ashen-Vale-Episode-1.apk"; rm "$OUT/episode1-unsigned.apk"
"$BT/zipalign" -c -P 16 4 "$OUT/Ashen-Vale-Episode-1.apk"
"$BT/aapt" dump badging "$OUT/Ashen-Vale-Episode-1.apk" | grep -Ev "^application-label-|^application-icon-" >build/badging.log
if grep -q "android.permission.INTERNET" build/badging.log; then exit 1; fi
grep -q "native-code:.*arm64-v8a.*x86_64" build/badging.log
grep -q ^launchable-activity build/badging.log
cat build/badging.log; grep -Fq "package: name='com.ashenvale.episodeone.preview' versionCode='10002' versionName='1.1-dev'" build/badging.log
unzip -tq "$OUT/Ashen-Vale-Episode-1.apk" >/dev/null
sha256sum "$OUT/Ashen-Vale-Episode-1.apk"
