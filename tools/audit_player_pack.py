"""Read the unencrypted Godot 4 PCK directory and verify its payload checksums."""
import argparse
import collections
import hashlib
import json
import struct
from pathlib import Path

from package_game import ROOT, digest, write_json


def audit(path, output, reference=None):
    with path.open('rb') as stream:
        magic, version, major, minor, patch, flags, base, directory = struct.unpack('<6I2Q', stream.read(40))
        if magic != 0x43504447 or version != 4 or flags & 1:
            raise ValueError('This audit supports unencrypted Godot PCK v4 only.')
        stream.seek(directory)
        count, = struct.unpack('<I', stream.read(4))
        entries = {}
        for _ in range(count):
            length, = struct.unpack('<I', stream.read(4))
            name = stream.read(length).rstrip(b'\x00').decode('utf-8')
            offset, size, checksum, entry_flags = struct.unpack('<QQ16sI', stream.read(36))
            if entry_flags:
                raise ValueError('Unexpected encrypted or removed entry: ' + name)
            entries[name] = dict(offset=offset + base, bytes=size, md5=checksum.hex())
        for name, entry in entries.items():
            stream.seek(entry['offset'])
            value = hashlib.md5()
            remaining = entry['bytes']
            while remaining:
                block = stream.read(min(remaining, 1024 * 1024))
                if not block:
                    raise ValueError('Truncated payload: ' + name)
                value.update(block)
                remaining -= len(block)
            if value.hexdigest() != entry['md5']:
                raise ValueError('PCK entry checksum mismatch: ' + name)
    types = collections.Counter()
    for name, entry in entries.items():
        types[Path(name).suffix] += entry['bytes']
    record = dict(pack_bytes=path.stat().st_size, sha256=digest(path),
                  files=len(entries), types=dict(types), entries=entries,
                  every_entry_checksum_verified=True)
    if reference:
        previous = json.loads(reference.read_text(encoding='utf-8'))
        retained = {name: entry for name, entry in entries.items() if name.endswith('.ctex')}
        for name, entry in retained.items():
            if name not in previous['entries'] or entry['md5'] != previous['entries'][name]['md5']:
                raise ValueError('A retained texture changed instead of lossless sharing: ' + name)
        record.update(retained_textures_byte_identical=len(retained),
                      bytes_removed=previous['pack_bytes'] - record['pack_bytes'])
    write_json(output, record)
    print(json.dumps({key: value for key, value in record.items() if key != 'entries'}), flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('pack', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--reference', type=Path)
    args = parser.parse_args()
    audit(args.pack, args.output, args.reference)
