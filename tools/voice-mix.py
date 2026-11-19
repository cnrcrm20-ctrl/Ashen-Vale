"""Package already-generated Arena takes. No TTS engine, downloads or model at build/runtime."""
from array import array
import argparse
import math
import sys
import json
import subprocess
from pathlib import Path

from voice_assets import check_take

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--ffmpeg', default='ffmpeg')
parser.add_argument('--preview', action='store_true', help='also mix a short listening excerpt outside the game')
args = parser.parse_args()
bank = json.loads((ROOT / 'story/kalkstein-voices.json').read_text())
clips = ROOT / 'game/audio/voices/tr'
clips.mkdir(parents=True, exist_ok=True)

def ff(*argv):
    subprocess.run([args.ffmpeg, '-hide_banner', '-v', 'error', '-y', *map(str, argv)], check=True)

envelopes = {}
for key, (speaker, text) in bank.items():
    master = ROOT / 'story/voice-masters' / (key + '.flac')
    check_take(master, speaker, text)
    ff('-i', master, '-map_metadata', '0', '-ac', 1,
       '-af', 'loudnorm=I=-18:LRA=9:TP=-1.5', '-ar', 24000, '-c:a', 'libvorbis', '-q:a', 6,
       clips / (key + '.ogg'))
    # Two audio-driven curves: short-time energy and voicing (not phoneme labels).
    # Match playhead of shipped clip, including silences and skipped lines.
    pcm = array('h', subprocess.check_output([args.ffmpeg, '-v', 'error', '-i', str(clips / (key + '.ogg')),
        '-map', '0:a:0', '-ac', '1', '-ar', '12000', '-f', 's16le', '-']))
    if sys.byteorder != 'little': pcm.byteswap()
    frames = []
    for i in range(0, len(pcm), 480):
        part = pcm[i:i+480]
        rms = math.sqrt(sum(v*v for v in part) / len(part)) / 32768.
        crossings = sum((x < 0) != (y < 0) for x,y in zip(part, part[1:])) / len(part)
        w = max(0., min(1., (rms-.009)*4.8)) ** .72
        frames.append(round(255*w) | (round(255*w * max(0., 1.-crossings*4.6)) << 8))
    envelopes[key] = frames
(ROOT / 'game/data/speech-curves.json').write_text(json.dumps({'fps':25, 'takes':envelopes}, separators=(',',':')) + '\n')
if args.preview:
    # A listening edit of four of the actual in-game takes, not a separate re-voicing.
    sequence = ['lyander_carik', 'lyra_kapi', 'katip_tablet', 'matilda_muhur']
    inputs = [a for key in sequence for a in ('-i', clips / (key + '.ogg'))]
    out = ROOT / 'samples/kalkstein-gecesi.mp3'
    out.parent.mkdir(exist_ok=True)
    ff(*inputs, '-filter_complex',
       '[0:a]apad=pad_dur=0.25[a];[1:a]apad=pad_dur=0.65[b];[2:a]apad=pad_dur=0.35[c];'
       '[a][b][c][3:a]concat=n=4:v=0:a=1,apad=pad_dur=0.55[m]',
       '-map', '[m]', '-metadata', 'title=3. Zeytin — Kalkstein gecesi', '-c:a', 'libmp3lame', '-b:a', '160k', out)
