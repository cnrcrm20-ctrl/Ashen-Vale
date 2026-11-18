#!/usr/bin/env bash
# Install exactly the file supplied; a release test must never re-sign it.
set -euo pipefail
APK=$(realpath "${1:?path to signed APK}"); export APK; ROOT=$(pwd); D=$ROOT/build/device; export D
mkdir -p "$D" "$ROOT/build/shots"; exec > >(tee "$D/test.log") 2>&1
BT=$(find "$ANDROID_HOME/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -1)
"$BT/apksigner" verify --verbose --print-certs "$APK" >"$D/signature.log"; cat "$D/signature.log"; sha256sum "$APK"
SDKMANAGER=$(command -v sdkmanager || find "$ANDROID_HOME/cmdline-tools" -name sdkmanager | head -1); AVDMANAGER=$(dirname "$SDKMANAGER")/avdmanager
"$SDKMANAGER" 'emulator' 'system-images;android-31;google_apis;x86_64' >"$D/sdk.log" 2>&1 || { tail -30 "$D/sdk.log";exit 1; }
AVD=ashen_api31; printf 'no\n' | "$AVDMANAGER" create avd --force -n "$AVD" -k 'system-images;android-31;google_apis;x86_64' --device pixel_2
if [[ -e /dev/kvm ]]; then sudo chmod a+rw /dev/kvm; fi
export ANDROID_SERIAL=emulator-5554; E="$ANDROID_HOME/emulator/emulator"; AVDLOG="$D/emulator.log"
"$E" @"$AVD" -port 5554 -memory 2048 -cores 2 -no-window -no-snapshot -no-audio -no-boot-anim -gpu swiftshader_indirect -camera-back none -camera-front none >"$AVDLOG" 2>&1 & EMUPID=$!
finish(){ adb logcat -d -s 'godot:I' 'Godot:I' 'AndroidRuntime:E' >"$D/game.log" 2>&1 || :; tail -50 "$D/game.log" || :; tail -10 "$AVDLOG" || :; adb emu kill >/dev/null 2>&1 || :; kill "$EMUPID" 2>/dev/null || :; }; trap finish EXIT
if ! timeout 220 bash -c 'adb wait-for-device && until adb shell getprop sys.boot_completed 2>/dev/null | grep -q 1; do sleep 2; done'; then tail -60 "$AVDLOG";exit 1;fi
adb shell wm size 720x1280; adb shell wm density 240; adb shell input keyevent 82; adb shell settings put system accelerometer_rotation 0
adb install "$APK"; PK=com.ashenvale.episodeone; ACT=$(adb shell cmd package resolve-activity --brief "$PK" | tail -1 | tr -d '\r'); [[ $ACT == $PK/* ]]
wait_mark(){ local m=$1; for n in {1..55}; do if adb logcat -d -s 'godot:I' 'Godot:I' | grep -F "$m" >/dev/null; then return 0; fi; sleep 1; done; echo "Missing Android state $m";return 1; }
shot(){ adb exec-out screencap -p >"$ROOT/build/shots/android-$1.png"; }
launch(){ adb logcat -c;adb shell am start -W -n "$ACT"; wait_mark 'AV_READY title';sleep 1; }
launch;shot title
read -r W H < <(python3 -c 'import struct;print(*struct.unpack(">II",open("build/shots/android-title.png","rb").read()[16:24]))'); [[ $W -gt $H ]]
tap(){ adb shell input tap "$((W*$1/100))" "$((H*$2/100))"; }
tap 14 70;wait_mark 'AV_MENU settings';adb shell input keyevent 4; sleep 1; tap 17 61;wait_mark 'AV_BEAT 0';wait_mark 'AV_WALK';sleep 1;shot court
tap 90 89;wait_mark 'AV_LINE 0:0';sleep 1;shot dialogue
for n in 1 2 3; do tap 86 90;sleep .5;done; wait_mark 'AV_BEAT 1'
# A real touch drag, not a debug teleport. Android save/resume is exercised by process death.
adb shell input swipe "$((W*11/100))" "$((H*81/100))" "$((W*14/100))" "$((H*58/100))" 1500;wait_mark 'AV_MOVED'
adb shell input keyevent 3;sleep 1;adb shell am force-stop "$PK";launch;tap 17 61;wait_mark 'AV_BEAT 1'; wait_mark 'AV_WALK';adb shell pidof "$PK";shot resumed
echo 'ANDROID_SMOKE PASS · signed install / title / settings / walk / touch dialogue / movement / process death / resume'
