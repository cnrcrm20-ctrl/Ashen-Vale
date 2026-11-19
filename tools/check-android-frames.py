"""Release QA: changing app *and world* states must be visible, not just logcat or a HUD."""
from pathlib import Path
import sys

from PIL import Image, ImageChops, ImageStat


def check(folder):
    frames = {}
    for name in ('title', 'court', 'dialogue', 'resumed'):
        with Image.open(folder / f'android-{name}.png') as capture:
            assert capture.width > capture.height, f'not landscape: {name}'
            frame = capture.convert('RGB').resize((160, 90))
        contrast = sum(ImageStat.Stat(frame).stddev) / 3
        entropy = frame.convert('L').entropy()
        # Exclude the objective, touch controls, and dialogue/title text. A
        # visible UI on top of a failed 3D renderer must not authorize release.
        world = frame.crop((82, 22, 140, 58)).convert('L')
        deviation = ImageStat.Stat(world).stddev[0]
        lo, hi = world.getextrema()
        print(name, 'contrast', round(contrast, 1), 'entropy', round(entropy, 2),
              'world sigma', round(deviation, 1), 'world range', hi-lo, flush=True)
        assert contrast > 14 and entropy > 3, f'blank Android frame: {name}'
        assert deviation > 3.5 and hi - lo > 18, f'blank Android world under the interface: {name}'
        frames[name] = frame
    for one, two in [('title', 'court'), ('court', 'dialogue')]:
        delta = sum(ImageStat.Stat(ImageChops.difference(frames[one], frames[two])).mean) / 3
        print(one, two, 'mean color change', round(delta, 1))
        assert delta > 7, f'frozen Android frame: {one}, {two}'
    print('ANDROID_FRAMES PASS')


if __name__ == '__main__':
    check(Path(sys.argv[1]))
