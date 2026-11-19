"""Compile the authoring sheet, recorded takes and novel into the offline game."""
import json
import re
import sys
from pathlib import Path

from voice_assets import check_take

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'game/data'
VOICES = ROOT / 'game/audio/voices/tr'


def voice_bank():
    """Vorbis comments travel with the actual take. Reject a stale subtitle or miscast file."""
    rows = json.loads((ROOT / 'story/kalkstein-voices.json').read_text())
    assert {p.stem for p in VOICES.glob('*.ogg')} == set(rows), 'voice assets and script differ'
    masters = ROOT / 'story/voice-masters'
    assert {p.stem for p in masters.glob('*.flac')} == set(rows), 'voice masters and script differ'
    for key, (speaker, words) in rows.items():
        assert re.fullmatch(r'[a-z0-9_]+', key), key
        check_take(VOICES / (key + '.ogg'), speaker, words)
        check_take(masters / (key + '.flac'), speaker, words)
    return rows


def compile_chapter():
    voices = voice_bank()
    used = set()
    zones, beats = [], []
    for line in (ROOT / 'story/episode1.av').read_text().splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        op, val = line[0], line[1:]
        if op == '@':
            name, sub = val.split('|')
            zones.append(dict(name=name, subtitle=sub))
        elif op == ':':
            loc, model, kind, title = val.split('|')
            beat = dict(id=len(beats), zone=len(zones)-1, at=list(map(float, loc.split(','))),
                        model=model, kind=kind, title=title, lines=[], clues=[])
            beats.append(beat)
        elif op == '?':
            k, q, *options = val.split('|')
            beat['ask'] = dict(correct=int(k), q=q, options=[o.split('~') for o in options])
        elif op == '+':
            beat['clues'].append(val.split('|'))
        elif op == '>':  # unvoiced walk-and-talk; same subtitle channel, no borrowed voice
            role, words = val.split('|', 1)
            beat.setdefault('entry', []).append([role, words])
        elif op in '!$':  # ! walk-and-talk on entry; $ voiced conversation at the set
            beat.setdefault('entry' if op == '!' else 'lines', []).append([*voices[val], val])
            used.add(val)
        else:
            beat['lines'].append(line.split('|', 1))
    assert used == set(voices), 'unreferenced recording'
    for b in beats:
        assert b['lines'] or b['kind'] in {'night_fork','night_pass','night_chase','night_out','forest_cross'}
        if b['kind'] == 'search':
            assert len(b['clues']) == 3
        if 'ask' in b:
            a = b['ask']
            assert all(len(o) == 2 for o in a['options']) and -1 <= a['correct'] < len(a['options'])
    return dict(zones=zones, beats=beats)


def compile_book():
    prose, appendix = (ROOT / 'episode-1.md').read_text().split('\n---\n', 1)
    chapters = []
    for chunk in prose.split('### ')[1:]:
        title, text = chunk.split('\n', 1)
        chapters.append(dict(title=title.strip(), text=text.strip().replace('*', '')))
    spells = []
    for line in appendix.splitlines():
        if re.match(r'^\| \d{2} \|', line):
            num, school, name, kind, desc = [c.strip().strip('*') for c in line.strip('|').split('|')]
            spells.append([int(num), school, name, kind, desc])
    assert len(spells) == 34 and sum(s[3] == 'Karanlık' for s in spells) == len({s[1] for s in spells}) == 8
    return dict(chapters=chapters, spells=spells)


if __name__ == '__main__':
    chapter, book = compile_chapter(), compile_book()
    assert len(chapter['zones']) == len(book['chapters']) == 7
    for name, obj in [('chapter', chapter), ('archive', book)]:
        path = DATA / (name + '.json')
        out = json.dumps(obj, ensure_ascii=False, indent=1) + '\n'
        if '--check' in sys.argv:
            assert path.read_text() == out, f'{path} is out of date'
        else:
            path.write_text(out)
    print(f"{len(chapter['zones'])} districts · {len(chapter['beats'])} beats · {len(voice_bank())} matching voice takes · 34 spells")
