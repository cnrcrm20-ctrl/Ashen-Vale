"""Release QA: changing app *and world* states must be visible, not just logcat or a HUD."""
from pathlib import Path
import sys

from PIL import Image, ImageChops, ImageStat


def frame_at(path):
    with Image.open(path) as capture:
        assert capture.width > capture.height, f'not landscape: {path.name}'
        return capture.convert('RGB').resize((160, 90))


def title_ready(path):
    # AV_READY means the scene exists; Godot's centered boot icon may still be
    # on the display while the first world shaders compile. Look for the actual
    # gold start/continue button on the *left*, plus a visible world behind it.
    frame = frame_at(path)
    button = frame.crop((12, 53, 47, 58))
    gold = sum(r > 155 and .6*r < g < .94*r and b < .85*g for r, g, b in button.getdata())
    return gold > button.width * button.height * .55 and frame.convert('L').entropy() > 3


def check(folder):
    frames = {}
    for name in ('title', 'court', 'dialogue', 'resumed'):
        frame = frame_at(folder / f'android-{name}.png')
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
    if sys.argv[1] == '--title-ready':
        sys.exit(0 if title_ready(Path(sys.argv[2])) else 1)
    check(Path(sys.argv[1]))
