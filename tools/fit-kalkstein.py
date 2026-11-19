"""Fit the Kalkstein children and Edda on their existing metre-scale outfit skeletons.

Run rig-expression.py first. This asset-prep step needs Pillow; the game and
export do not. Vertex remapping keeps the neck seam and updates speech deltas.
The sewn overdress replaces the bodice rather than drawing over an adult mesh.
"""

import json
import math
import struct
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / 'game/art/company'
PROFILE = 'kalkstein-fitting-v1'


def smooth(lo, hi, x):
    u = max(0.0, min(1.0, (x - lo) / (hi - lo)))
    return u * u * (3.0 - 2.0 * u)


def cloth(path, kitchen=False):
    # A tile of handwoven, madder-brown linen with a repaired pocket. No image service.
    size = 512
    im = Image.new('RGB', (size, size))
    pixels = im.load()
    for y in range(size):
        for x in range(size):
            v = ((x * 871 + y * 449 + x * y * 61) % 37) * 0.115 + 3 * ((x // 2 + y // 2) % 2) - 4
            v += 2.8 * math.cos(x * math.tau / size * 7) + 2.0 * math.sin(
                (x + y * 3) * math.tau / size
            )
            color = (
                (133, 94, 66)
                if not (455 < y < 464 or 478 < y < 484 or 36 < y < 42)
                else (160, 127, 84)
            )
            if kitchen:
                # Undyed bib, narrow ties at the waist, flour caught in the warp.
                half = 46 if y < 208 else 91
                if 31 < y < 486 and abs(x - 256) < half:
                    color = (181, 168, 138)
                    v += math.sin(x * 0.21 + y * 0.18) * math.cos(y * 0.13) * 3
                elif 204 < y < 220:
                    color = (152, 140, 120)
                else:
                    color = (84, 99, 97)
            pixels[x, y] = tuple(round(c + v) for c in color)
    d = ImageDraw.Draw(im)
    d.polygon([(277, 299), (332, 301), (329, 359), (277, 348)], fill=(123, 86, 64))
    for a in range(281, 329, 6):
        d.line((a, 304, a + 2, 304), fill=(164, 129, 94))
        d.line((a, 342 + (a - 281) // 5, a + 2, 343 + (a - 281) // 5), fill=(157, 120, 90))
    for y in range(307, 343, 6):
        d.line((280, y, 280, y + 2), fill=(157, 120, 90))
        d.line((327, y + 2, 327, y + 4), fill=(157, 120, 90))
    for y in (56, 76, 96):
        d.ellipse((252, y, 258, y + 6), fill=(77, 57, 47), outline=(171, 135, 93))
    im.save(path, optimize=True)


class Rig:
    def __init__(self, role):
        self.path = ROOT / (role + '.gltf')
        self.doc = json.loads(self.path.read_text())
        self.bin = bytearray(self.path.with_suffix('.bin').read_bytes())

    def data(self, index):
        a = self.doc['accessors'][index]
        view = self.doc['bufferViews'][a['bufferView']]
        dims = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}
        typ = {5121: 'B', 5123: 'H', 5125: 'I', 5126: 'f'}[a['componentType']]
        form = struct.Struct('<' + typ * dims[a['type']])
        stride = view.get('byteStride', form.size)
        start = view.get('byteOffset', 0) + a.get('byteOffset', 0)
        return form, range(start, start + stride * a['count'], stride)

    def read(self, index):
        form, offsets = self.data(index)
        return [form.unpack_from(self.bin, o) for o in offsets]

    def update(self, index, rows):
        a = self.doc['accessors'][index]
        form, offsets = self.data(index)
        assert len(rows) == len(offsets)
        for o, p in zip(offsets, rows):
            form.pack_into(self.bin, o, *p)
        if 'min' in a:
            a.update(min=list(map(min, zip(*rows))), max=list(map(max, zip(*rows))))

    def add(self, rows, typ, shape, *, bounds=False, indices=False):
        d = self.doc
        self.bin.extend(bytes(-len(self.bin) % 4))
        start = len(self.bin)
        f = struct.Struct('<' + {5121: 'B', 5123: 'H', 5126: 'f'}[typ] * len(rows[0]))
        self.bin.extend(b''.join(f.pack(*r) for r in rows))
        a = {
            'bufferView': len(d['bufferViews']),
            'componentType': typ,
            'count': len(rows),
            'type': shape,
        }
        if bounds:
            a.update(min=list(map(min, zip(*rows))), max=list(map(max, zip(*rows))))
        d['bufferViews'].append(
            {
                'buffer': 0,
                'byteOffset': start,
                'byteLength': len(self.bin) - start,
                'target': 34963 if indices else 34962,
            }
        )
        i = len(d['accessors'])
        d['accessors'].append(a)
        return i

    def save(self):
        self.doc['buffers'][0]['byteLength'] = len(self.bin)
        self.path.with_suffix('.bin').write_bytes(self.bin)
        self.path.write_text(json.dumps(self.doc, separators=(',', ':')) + '\n')


def fit_head(rig, group, younger):
    def remap(p):
        x, y, z = p
        # Widen cheeks/skull and shorten the jaw below the eyeline. Hair, eyes
        # and brows receive the same continuous map; the garment seam stays put.
        eye = 1.657 if younger else 1.702
        weight = smooth(eye - 0.153, eye - 0.087, y)
        dose = 1.0 if younger else 0.60
        f = weight * dose
        fullness = 0.14 + 0.055 * math.exp(-(((y - eye + 0.04) / 0.04) ** 2))
        return (
            x * (1.0 + fullness * f),
            y + (y - eye) * (0.12 if y > eye else -0.115) * f,
            z
            + (z + 0.04) * 0.075 * f
            - 0.009 * math.exp(-(((y - eye + 0.039) / 0.035) ** 2) - (x / 0.027) ** 2) * f,
        )

    att = group['attributes']
    src = rig.read(att['POSITION'])
    dst = [remap(p) for p in src]
    rig.update(att['POSITION'], dst)
    for t in group.get('targets', []):
        values = []
        for p, q, delta in zip(src, dst, rig.read(t['POSITION'])):
            deformed = remap(tuple(a + b for a, b in zip(p, delta)))
            values.append(tuple(a - b for a, b in zip(deformed, q)))
        rig.update(t['POSITION'], values)


def make_shift(rig, mesh, leg, kitchen=False):
    d = rig.doc
    # Follow skin weights from the clothes underneath (not a static prop moving
    # with just the pelvis); the lower hem can part with the thighs during gait.
    samples = []
    for source in [mesh, leg]:
        s = source['primitives'][0]['attributes']
        samples.extend(
            zip(rig.read(s['POSITION']), rig.read(s['JOINTS_0']), rig.read(s['WEIGHTS_0']))
        )
    cut = [
        (0.820, 0.211, 0.149, -0.023),
        (0.833, 0.213, 0.149, -0.023),
        (0.893, 0.204, 0.147, -0.024),
        (1.01, 0.190, 0.142, -0.023),
        (1.135, 0.158, 0.121, -0.021),
        (1.25, 0.151, 0.130, -0.023),
        (1.348, 0.166, 0.133, -0.025),
        (1.414, 0.181, 0.115, -0.035),
        (1.471, 0.177, 0.087, -0.043),
        (1.498, 0.123, 0.072, -0.049),
        (1.509, 0.069, 0.060, -0.048),
        (1.518, 0.067, 0.059, -0.048),
    ]
    if kitchen:
        cut = [
            (0.736, 0.252, 0.176, -0.028),
            (0.755, 0.249, 0.178, -0.028),
            (0.86, 0.238, 0.171, -0.024),
            (1.02, 0.205, 0.154, -0.023),
            (1.10, 0.148, 0.121, -0.021),
            (1.24, 0.157, 0.139, -0.021),
            (1.35, 0.185, 0.154, -0.023),
            (1.42, 0.202, 0.130, -0.031),
            (1.467, 0.185, 0.096, -0.040),
            (1.499, 0.120, 0.076, -0.048),
            (1.520, 0.069, 0.062, -0.048),
        ]
    pts, uv, normal, js, ws, triangles = [], [], [], [], [], []
    steps = 48
    for k, (h, rx, rz, cz) in enumerate(cut):
        for j in range(steps + 1):
            u = j / steps
            a = (u - 0.5) * math.tau
            flute = (0.0045 * math.cos(9 * a + 0.8 * h) + 0.003 * math.cos(13 * a - h * 3)) * (
                1.0 - smooth(1.22, 1.48, h)
            )
            x = (rx + flute) * math.sin(a)
            z = cz + (rz + flute) * math.cos(a)
            y = h + 0.008 * math.sin(a * 4 + 0.5) * (1.0 - smooth(0.84, 1.12, h))
            pts.append((x, y, z))
            uv.append((u, (cut[-1][0] - h) / (cut[-1][0] - cut[0][0])))
            next_k = min(k + 1, len(cut) - 1)
            prev_k = max(0, k - 1)
            slope = (cut[next_k][1] - cut[prev_k][1]) / (cut[next_k][0] - cut[prev_k][0])
            slope_z = (cut[next_k][2] - cut[prev_k][2]) / (cut[next_k][0] - cut[prev_k][0])
            n = (
                math.sin(a) / rx,
                -(slope * math.sin(a) ** 2 / rx + slope_z * math.cos(a) ** 2 / rz),
                math.cos(a) / rz,
            )
            length = math.sqrt(sum(t * t for t in n))
            normal.append(tuple(t / length for t in n))
            _, joints, weights = min(
                samples,
                key=lambda row: (
                    (row[0][0] - x) ** 2 + 1.9 * (row[0][1] - y) ** 2 + (row[0][2] - z) ** 2
                ),
            )
            js.append(joints)
            ws.append(weights)
            if k and j:
                top = k * (steps + 1) + j
                bottom = top - (steps + 1)
                triangles.extend(
                    [(bottom - 1,), (bottom,), (top - 1,), (bottom,), (top,), (top - 1,)]
                )
    filename = 'skins/hall-linen.png' if kitchen else 'skins/kalkstein-linen.png'
    cloth(ROOT / filename, kitchen)
    tex = len(d['textures'])
    d['textures'].append({'source': len(d['images'])})
    d['images'].append({'uri': filename})
    mat = len(d['materials'])
    d['materials'].append(
        {
            'name': 'Hall_Linen' if kitchen else 'Kalkstein_Linen',
            'doubleSided': True,
            'pbrMetallicRoughness': {
                'baseColorTexture': {'index': tex},
                'roughnessFactor': 0.97,
                'metallicFactor': 0,
            },
        }
    )
    attrs = {
        k: rig.add(rows, t, form, bounds=(k == 'POSITION'))
        for k, rows, t, form in [
            ('POSITION', pts, 5126, 'VEC3'),
            ('NORMAL', normal, 5126, 'VEC3'),
            ('TEXCOORD_0', uv, 5126, 'VEC2'),
            ('JOINTS_0', js, 5121, 'VEC4'),
            ('WEIGHTS_0', ws, 5126, 'VEC4'),
        ]
    }
    mesh['primitives'] = [
        {
            'attributes': attrs,
            'indices': rig.add(triangles, 5123, 'SCALAR', indices=True),
            'material': mat,
        }
    ]
    mesh['name'] = 'Serving_Apron' if kitchen else 'Kalkstein_Shift'


def fit(role):
    rig = Rig(role)
    d = rig.doc
    if d['asset'].get('extras', {}).get('fit') == PROFILE:
        return
    meshes = {n['name']: d['meshes'][n['mesh']] for n in d['nodes'] if 'mesh' in n}
    if role == 'edda':
        make_shift(rig, meshes['Female_Wizard_Body'], meshes['Female_Wizard_Legs'], True)
    for name, mesh in meshes.items():
        if role == 'edda':
            break  # Adult head and speech shapes remain intact.
        if name in ('Eyebrows', 'Eyes', 'Superhero_Female', 'SuperHero_Male') or name.startswith(
            'Hair_'
        ):
            for group in mesh['primitives']:
                fit_head(rig, group, role == 'lyra')
    if role == 'lyra':
        make_shift(rig, meshes['Female_Peasant_Body'], meshes['Female_Peasant_Legs'])
    d['asset'].setdefault('extras', {})['fit'] = PROFILE
    rig.save()


def mark_uv():
    # Reserve a UV2 patch on the *right, bare forearm* only. Front-facing skin
    # triangles are split into their own surface, with the SAME weights, normals,
    # albedo and base UV as before. Ink can now follow the animation without a
    # decal hanging in mid-air or appearing on the other arm's mirrored UVs.
    rig = Rig('lyander')
    d = rig.doc
    if any(m['name'] == 'Kalkstein_Forearm' for m in d['materials']):
        return
    arm = next(n for n in d['nodes'] if n.get('name') == 'Male_Peasant_Arms')
    mesh = d['meshes'][arm['mesh']]
    skin = d['skins'][arm['skin']]
    bone = next(i for i, j in enumerate(skin['joints']) if d['nodes'][j]['name'] == 'lowerarm_r')
    inv = rig.read(skin['inverseBindMatrices'])[bone]
    group = next(
        p for p in mesh['primitives'] if d['materials'][p['material']]['name'] == 'MI_Regular_Male'
    )
    xyz = [
        tuple(sum(inv[k + 4 * t] * v for t, v in enumerate((*p, 1.0))) for k in range(3))
        for p in rig.read(group['attributes']['POSITION'])
    ]
    uv = [
        (max(0.001, min(0.999, 0.5 + x / 0.070)), max(0.001, min(0.999, 0.5 + (y - 0.153) / 0.114)))
        for x, y, z in xyz
    ]
    idx = rig.read(group['indices'])
    patch = []
    rest = []
    for i in range(0, len(idx), 3):
        tri = idx[i : i + 3]
        x, y, z = (sum(xyz[t[0]][k] for t in tri) / 3.0 for k in range(3))
        (patch if abs(x) < 0.064 and 0.071 < y < 0.233 and z > 0.0 else rest).extend(tri)
    assert patch and rest
    group['indices'] = rig.add(rest, 5123, 'SCALAR', indices=True)
    surface = dict(group)
    surface['attributes'] = dict(group['attributes'])
    surface['attributes']['TEXCOORD_1'] = rig.add(uv, 5126, 'VEC2')
    surface['indices'] = rig.add(patch, 5123, 'SCALAR', indices=True)
    surface['material'] = len(d['materials'])
    d['materials'].append(dict(d['materials'][group['material']], name='Kalkstein_Forearm'))
    mesh['primitives'].append(surface)
    rig.save()


if __name__ == '__main__':
    for who in ('lyander', 'lyra', 'edda'):
        fit(who)
    mark_uv()
