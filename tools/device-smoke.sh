#!/usr/bin/env bash
# Install exactly the file supplied; a release test must never re-sign it.
set -euo pipefail
export PATH="${ANDROID_HOME:?}/platform-tools:$ANDROID_HOME/emulator:$PATH"
APK=$(realpath "${1:?path to signed APK}"); export APK; ROOT=$(pwd); D=$ROOT/build/device; export D
mkdir -p "$D" "$ROOT/build/shots"; exec > >(tee "$D/test.log") 2>&1
BT=$(find "$ANDROID_HOME/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -1)
"$BT/apksigner" verify --verbose --print-certs "$APK" >"$D/signature.log"; cat "$D/signature.log"; sha256sum "$APK"
SDKMANAGER=$(command -v sdkmanager || find "$ANDROID_HOME/cmdline-tools" -name sdkmanager | head -1); AVDMANAGER=$(dirname "$SDKMANAGER")/avdmanager
# AOSP image, no Play services and no account. Only sdkmanager's status is relevant
# when yes exits on the closed input pipe.
(set +o pipefail; yes | "$SDKMANAGER" --licenses >"$D/licenses.log" 2>&1)
"$SDKMANAGER" 'platform-tools' 'emulator' 'system-images;android-31;default;x86_64'  >"$D/sdk.log" 2>&1 || { tail -30 "$D/sdk.log";exit 1; }
adb version
# New cmdline-tools may create AVDs under XDG_CONFIG_HOME while the emulator
# still searches ~/.android/avd. Point both tools at the same disposable store.
export ANDROID_USER_HOME="${RUNNER_TEMP:-/tmp}/ashen-android-user"
export ANDROID_EMULATOR_HOME="$ANDROID_USER_HOME" ANDROID_AVD_HOME="$ANDROID_USER_HOME/avd"
mkdir -p "$ANDROID_AVD_HOME"
AVD=ashen_api31; printf 'no\n' | "$AVDMANAGER" create avd --force -n "$AVD" --path "$ANDROID_AVD_HOME/$AVD.avd" -k 'system-images;android-31;default;x86_64' --device pixel_2
test -s "$ANDROID_AVD_HOME/$AVD.avd/config.ini"
printf 'avd.ini.encoding=UTF-8\npath=%s\ntarget=android-31\n' "$ANDROID_AVD_HOME/$AVD.avd" > "$ANDROID_AVD_HOME/$AVD.ini"
if [[ -e /dev/kvm ]]; then sudo chmod a+rw /dev/kvm; fi
export ANDROID_SERIAL=emulator-5554; E="$ANDROID_HOME/emulator/emulator"; AVDLOG="$D/emulator.log"
"$E" -list-avds | grep -Fx "$AVD"
adb start-server
"$E" -version | head -8 || true
"$E" -accel-check || true
ls -l /dev/kvm || true
"$E" @"$AVD" -port 5554 -memory 2048 -cores 2 -no-window -no-snapshot -no-audio -no-boot-anim -gpu "${EMULATOR_GPU:-host}" -feature -Vulkan -camera-back none -camera-front none >"$AVDLOG" 2>&1 & EMUPID=$!
finish(){ timeout 5 adb logcat -d -s 'godot:I' 'Godot:I' 'AndroidRuntime:E' >"$D/game.log" 2>&1 || :; tail -50 "$D/game.log" || :; tail -35 "$AVDLOG" || :; timeout 4 adb emu kill >/dev/null 2>&1 || :; kill "$EMUPID" 2>/dev/null || :; }; trap finish EXIT
boot=no
for n in {1..95}; do
  if ! kill -0 "$EMUPID" 2>/dev/null; then echo '::error::Android emulator exited during boot'; tail -80 "$AVDLOG";exit 1;fi
  if [[ $(timeout 3 adb get-state 2>/dev/null || :) == device ]] && [[ $(timeout 3 adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || :) == 1 ]]; then boot=yes;break; fi
  sleep 2
done
[[ $boot == yes ]] || { echo '::error::Android boot timeout';tail -80 "$AVDLOG";exit 1; }
echo '::notice::AOSP API 31 booted'
adb shell settings put secure immersive_mode_confirmations confirmed; adb shell wm dismiss-keyguard; adb shell wm size 720x1280; adb shell wm density 240; adb shell input keyevent 82; adb shell settings put system accelerometer_rotation 0
# Keep historical 1.0.0 testable but never install an unrelated application.
PK=$("$BT/aapt" dump badging "$APK" | sed -n "s/^package: name='\([^']*\)'.*/\1/p")
case "$PK" in com.ashenvale.episodeone|com.ashenvale.episodeone.preview) ;; *) echo 'Unexpected application ID'; exit 1;; esac
timeout 80 adb install "$APK"; ACT=$(adb shell cmd package resolve-activity --brief "$PK" | tail -1 | tr -d '\r'); [[ $ACT == $PK/* ]]
wait_mark(){ local m=$1; echo "Waiting for $m"; for n in {1..55}; do if timeout 5 adb logcat -d -s 'godot:I' 'Godot:I' | grep -F "$m" >/dev/null; then return 0; fi; sleep 1; done; echo "Missing Android state $m";return 1; }
shot(){ adb exec-out screencap -p >"$ROOT/build/shots/android-$1.png"; }
launch(){ adb logcat -c;timeout 35 adb shell am start -W -n "$ACT"; wait_mark 'AV_READY title';sleep 1; }
launch;shot title
read -r W H < <(python3 -c 'import struct;print(*struct.unpack(">II",open("build/shots/android-title.png","rb").read()[16:24]))'); [[ $W -gt $H ]]
tap(){ adb shell input tap "$((W*$1/100))" "$((H*$2/100))"; }
tap 14 70;wait_mark 'AV_MENU settings';adb shell input keyevent 4; sleep 1; tap 17 61;wait_mark 'AV_BEAT 0';wait_mark 'AV_WALK';sleep 1;shot court
# The released 1.0.0 begins beside the bowl. The new cut begins on foot.
# Inspect the installed package, so the signed historical screencheck remains reproducible.
VER=$(adb shell dumpsys package "$PK" | sed -n 's/.*versionName=//p' | head -1 | tr -d '\r')
if [[ "$VER" != 1.0.0 ]]; then
  for n in {1..9}; do
    if adb logcat -d -s 'godot:I' 'Godot:I' | grep -F 'AV_NEAR Lyra' >/dev/null; then break; fi
    adb shell input swipe "$((W*12/100))" "$((H*80/100))" "$((W*9/100))" "$((H*60/100))" 630
  done
  wait_mark 'AV_NEAR Lyra'
fi
tap 90 89;wait_mark 'AV_LINE 0:0';sleep 1;shot dialogue
for n in 1 2 3; do tap 86 93;sleep .5;done; wait_mark 'AV_BEAT 1'
# A real touch drag, not a debug teleport. Android save/resume is exercised by process death.
adb shell input swipe "$((W*11/100))" "$((H*81/100))" "$((W*14/100))" "$((H*58/100))" 1500;wait_mark 'AV_MOVED'
adb logcat -d -s "godot:I" "Godot:I" >"$D/first-launch.log";adb shell input keyevent 3;sleep 1;adb shell am force-stop "$PK";launch;tap 17 61;wait_mark 'AV_BEAT 1'; wait_mark 'AV_WALK';adb shell pidof "$PK";shot resumed
adb logcat -d -s 'godot:I' 'Godot:I' >"$D/resume.log"
python3 tools/check-android-frames.py "$ROOT/build/shots" | tee "$D/frames.log"
if grep -E 'Program linking failed|SHADER ERROR|SCRIPT ERROR:|FATAL EXCEPTION' "$D/first-launch.log" "$D/resume.log";then echo '::error::Android shader or script failure';exit 1;fi
echo 'ANDROID_SMOKE PASS · signed install / title / settings / walk / touch dialogue / movement / process death / resume'
