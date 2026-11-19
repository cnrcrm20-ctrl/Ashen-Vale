"""Add two restrained, relative speech shapes to the assembled CC0, metre-scale heads.
Run on the company's unmodified glTF or rerun as a no-op after packaging. No learned model.
"""
from pathlib import Path
from math import exp
from struct import pack, unpack_from
import json

COMPANY = Path(__file__).resolve().parents[1] / 'game/art/company'
NAMES = ['SpeechJaw', 'SpeechRound']


def smooth(lo, hi, x):
    t = min(1., max(0., (x - lo) / (hi - lo)))
    return t * t * (3 - 2 * t)


def adapt(path):
    doc = json.loads(path.read_text())
    binary = path.with_suffix('.bin')
    buf = bytearray(binary.read_bytes())
    female = any(n.get('name') == 'Superhero_Female' for n in doc['nodes'])
    changed = False
    for node in doc['nodes']:
        if node.get('name') not in ('SuperHero_Male', 'Superhero_Female', 'Hair_Beard'):
            continue
        mesh = doc['meshes'][node['mesh']]
        if mesh.get('extras', {}).get('targetNames') == NAMES:
            continue
        for group in mesh['primitives']:
            assert 'targets' not in group
            a = doc['accessors'][group['attributes']['POSITION']]
            view = doc['bufferViews'][a['bufferView']]
            stride = view.get('byteStride', 12)
            start = view.get('byteOffset', 0) + a.get('byteOffset', 0)
            assert a['componentType'] == 5126 and a['type'] == 'VEC3'
            jaw, round_ = [], []
            for i in range(a['count']):
                x, y, z = unpack_from('<fff', buf, start + stride * i)
                # Reference both bodies to the male bind-space lip line; never move eyes,
                # nose or the neck seam. The beard receives the same weights as the chin.
                y += .045 if female else 0.
                front = smooth(.001, .082, z)
                lower = smooth(1.53, 1.567, y) * (1. - smooth(1.608, 1.637, y))
                w = front * lower * (1 - smooth(.038, .084, abs(x)))
                lips = exp(-((y - 1.623)/.018)**2 - (x/.044)**2) * front
                jaw.append((x*.075*w, -.014*w, -.003*w))
                round_.append((-.17*x*lips, -.002*lips, .006*lips))
            group['targets'] = []
            for shape in (jaw, round_):
                buf.extend(bytes(-len(buf) % 4))
                pos = len(buf)
                buf.extend(b''.join(pack('<fff', *d) for d in shape))
                ai = len(doc['accessors'])
                doc['accessors'].append(dict(bufferView=len(doc['bufferViews']), componentType=5126,
                    count=len(shape), type='VEC3', min=list(map(min, zip(*shape))), max=list(map(max, zip(*shape)))))
                doc['bufferViews'].append(dict(buffer=0, byteOffset=pos, byteLength=len(buf)-pos, target=34962))
                group['targets'].append({'POSITION': ai})
        mesh.setdefault('extras', {})['targetNames'] = NAMES
        mesh['weights'] = [0, 0]
        changed = True
    if changed:
        doc['buffers'][0]['byteLength'] = len(buf)
        binary.write_bytes(buf)
        path.write_text(json.dumps(doc, separators=(',', ':')) + '\n')


if __name__ == '__main__':
    for path in sorted(COMPANY.glob('*.gltf')):
        adapt(path)
