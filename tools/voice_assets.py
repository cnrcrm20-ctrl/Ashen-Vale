"""Validate the speaker/transcript embedded in the actual recordings, with no codec dependency."""
from pathlib import Path
from struct import unpack_from


def comments(packet):
    def number(offset):
        return unpack_from('<I', packet, offset)[0]
    pos = 4 + number(0)  # vendor
    count = number(pos)
    pos += 4
    tags = {}
    for _ in range(count):
        size = number(pos)
        pos += 4
        key, value = packet[pos:pos+size].decode().split('=', 1)
        tags[key.lower()] = value
        pos += size
    return tags


def take_tags(path: Path):
    data = path.read_bytes()
    if data.startswith(b'fLaC'):
        pos = 4
        while pos + 4 <= len(data):
            block = data[pos]
            size = int.from_bytes(data[pos+1:pos+4], 'big')
            pos += 4
            if block & 127 == 4:  # VORBIS_COMMENT
                return comments(data[pos:pos+size])
            pos += size
            if block & 128:
                break
    elif data.startswith(b'OggS'):
        pos, parts = 0, bytearray()
        while pos + 27 <= len(data) and data[pos:pos+4] == b'OggS':
            count = data[pos+26]
            laces = data[pos+27:pos+27+count]
            pos += 27 + count
            for size in laces:
                parts.extend(data[pos:pos+size])
                pos += size
                if size < 255:
                    if parts.startswith(b'\x01vorbis'):
                        assert parts[11] == 1 and unpack_from('<I', parts, 12)[0] == 24000, path
                    if parts.startswith(b'\x03vorbis'):
                        return comments(bytes(parts[7:]))
                    parts.clear()
    raise ValueError(f'missing recording metadata: {path}')


def check_take(path, speaker, words):
    tags = take_tags(path)
    if (tags.get('artist'), tags.get('title'), tags.get('language')) != (speaker, words, 'tur'):
        raise ValueError(f'recording/subtitle mismatch: {path}; record a new take, do not relabel this one')
