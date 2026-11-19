#!/usr/bin/env bash
# One explicitly approved preview. Called after the exact signed APK passes Android QA.
set -euo pipefail
TAG=bolum-1-v1.1-dev
[[ ${GITHUB_REPOSITORY:?} == cnrcrm20-ctrl/Ashen-Vale && ${GITHUB_REF_NAME:?} == arena/f502d2c5-ashen-vale ]]
[[ $(jq -er .tag "$M") == "$TAG" ]]
SOURCE=$(jq -er .source_commit "$M")
A=$(basename "$APK"); V=$(basename "$MP4")
repo=(--repo "$GITHUB_REPOSITORY")
grep -q '^ANDROID_SMOKE PASS' build/device/test.log
grep -qx 'ANDROID_FRAMES PASS' build/device/frames.log

# Never replace a published asset, a tag on another commit or the stable release.
if git show-ref --verify --quiet "refs/tags/$TAG"; then
  test "$(git rev-parse "$TAG^{commit}")" = "$SOURCE"
fi
if prior=$(gh release view "$TAG" "${repo[@]}" --json isDraft,isPrerelease,targetCommitish); then
  jq -e --arg src "$SOURCE" '.isDraft and .isPrerelease and .targetCommitish==$src' <<< "$prior"
  gh release upload "$TAG" "$APK" "$MP4" --clobber "${repo[@]}"
else
  gh release create "$TAG" "$APK" "$MP4" --target "$SOURCE" --draft --prerelease --latest=false \
    --title 'Ashen Vale · 3. Zeytin — 1.1-dev Android önizlemesi' --notes-file delivery/1.1-dev/notes.tr.md "${repo[@]}"
fi

# Both assets must be intact before anyone sees the release. No extra binaries.
gh release view "$TAG" "${repo[@]}" --json assets | jq -e --arg a "$A" --arg v "$V" '([.assets[].name]|sort)==([$a,$v]|sort)'
mkdir -p "$RUNNER_TEMP/draft" "$RUNNER_TEMP/published"
gh release download "$TAG" "${repo[@]}" --dir "$RUNNER_TEMP/draft"
verify_pair(){
  printf '%s  %s\n' "$(jq -r .sha256 "$M")" "$1/$A" "$(jq -r .video_sha256 "$M")" "$1/$V" | sha256sum -c -
}
verify_pair "$RUNNER_TEMP/draft"
gh release edit "$TAG" --draft=false --prerelease --latest=false "${repo[@]}"
for name in "$A" "$V"; do
  curl -fLsS --retry 4 --retry-all-errors "https://github.com/$GITHUB_REPOSITORY/releases/download/$TAG/$name" -o "$RUNNER_TEMP/published/$name"
done
verify_pair "$RUNNER_TEMP/published"
gh release view "$TAG" "${repo[@]}" --json isDraft,isPrerelease,url | jq -e 'select(.isDraft==false and .isPrerelease==true)|.url'
