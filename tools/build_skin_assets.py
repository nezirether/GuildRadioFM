"""Compile PNG artwork and a JSON manifest into a staged TGA/Lua addon overlay."""
import argparse
import json
import math
from pathlib import Path
import re

from PIL import Image

SKINS = {'trogdor', 'alliance', 'horde', 'undercity', 'org', 'stormwind',
         'thunderbluff', 'darnassus', 'ironforge', 'bloodmoon', 'sleek', 'classic', 'retail'}
ROLES = {'background', 'header', 'crest', 'decor', 'outer', 'panel', 'tab', 'button',
         'transport', 'progressTrack', 'progressFill', 'volumeTrack', 'volumeFill',
         'volumeThumb', 'badge', 'queueRow', 'mini'}
STATES = {'normal', 'hover', 'pressed', 'selected', 'disabled'}
MODES = {'stretch', 'contain', 'tile', 'three', 'nine'}


def lua(value):
    if isinstance(value, str):
        return '"' + value.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'
    if isinstance(value, (int, float)) and math.isfinite(value):
        return str(value)
    if isinstance(value, list):
        return '{' + ', '.join(lua(item) for item in value) + '}'
    if isinstance(value, dict):
        return '{' + ', '.join('[' + lua(key) + ']=' + lua(item) for key, item in value.items()) + '}'
    raise ValueError(f'Unsupported manifest value {value!r}')


def compile_assets(manifest, source, output):
    source = source.resolve()
    images = {}
    registrations = {}

    def image_file(skin, filename):
        if not isinstance(filename, str) or not re.fullmatch(r'[a-z0-9_]+\.png', filename):
            raise ValueError('Asset filename must be a lowercase PNG basename')
        path = source / skin / filename
        with Image.open(path) as image:
            image.load()
            width, height = image.size
            if image.format != 'PNG' or max(width, height) > 4096 or min(width, height) < 1:
                raise ValueError(f'Invalid PNG dimensions {path}')
            if width & (width - 1) or height & (height - 1):
                raise ValueError(f'Texture dimensions must be powers of two {path}')
            images[(skin, filename)] = image.convert('RGBA')
        target = filename[:-4] + '.tga'
        return f'Interface\\AddOns\\GuildRadioFM\\Media\\Skins\\{skin}\\{target}', width, height

    def descriptor(skin, data):
        if not isinstance(data, dict):
            raise ValueError('Surface descriptor must be an object')
        path, width, height = image_file(skin, data['file'])
        result = {'path': path, 'width': width, 'height': height, 'mode': data.get('mode', 'stretch')}
        if result['mode'] not in MODES:
            raise ValueError('Unknown scaling mode')
        uv = data.get('uv', [0, 1, 0, 1])
        if len(uv) != 4 or not all(isinstance(x, (int, float)) and math.isfinite(x) and 0 <= x <= 1 for x in uv):
            raise ValueError('UV must have four finite normalized coordinates')
        if uv[0] >= uv[1] or uv[2] >= uv[3]:
            raise ValueError('UV rectangle is empty')
        result['uv'] = uv
        for field in ('insets', 'safe'):
            values = data.get(field, [0, 0, 0, 0])
            if len(values) != 4 or not all(isinstance(x, (int, float)) and math.isfinite(x) and x >= 0 for x in values):
                raise ValueError(f'Invalid {field}')
            if values[0] + values[1] >= (uv[1] - uv[0]) * width or values[2] + values[3] >= (uv[3] - uv[2]) * height:
                raise ValueError(f'{field} exceeds the UV region')
            result[field] = values
        result['states'] = {}
        for name, state in data.get('states', {}).items():
            if name not in STATES or 'states' in state:
                raise ValueError('Invalid or nested surface state')
            result['states'][name] = descriptor(skin, state)
        return result

    if not isinstance(manifest, dict) or not set(manifest).issubset(SKINS):
        raise ValueError('Manifest must map supported skin keys to asset sets')
    for skin, assets in manifest.items():
        if not isinstance(assets, dict):
            raise ValueError('Skin asset set must be an object')
        surfaces = assets.get('surfaces', {})
        if not set(surfaces).issubset(ROLES):
            raise ValueError('Unknown surface role')
        registered = {'surfaces': {role: descriptor(skin, item) for role, item in surfaces.items()}}
        if 'emblem' in assets:
            filename = assets['emblem']['file']
            path, width, height = image_file(skin, filename)
            image = images[(skin, filename)]
            if (width, height) != (512, 512):
                raise ValueError('Production emblem must be 512 by 512 RGBA')
            alpha = image.getchannel('A')
            bounds = alpha.getbbox()
            if bounds is None or alpha.getextrema()[0] != 0:
                raise ValueError('Emblem needs painted content and a transparent background')
            if any(alpha.getpixel(point) != 0 for point in
                   ((0, 0), (511, 0), (0, 511), (511, 511))):
                raise ValueError('Emblem canvas corners must be fully transparent')
            registered['emblem'] = {'path': path, 'width': width, 'height': height,
                                    'mode': 'contain', 'bounds': list(bounds)}
        if 'icons' in assets:
            data = assets['icons']
            path, width, height = image_file(skin, data['file'])
            if (width, height) != (512, 256):
                raise ValueError('Icon atlas must be 512 by 256')
            icons = {'path': path, 'width': width, 'height': height, 'columns': 8, 'cell': 64, 'states': {}}
            for state, filename in data.get('states', {}).items():
                if state not in STATES:
                    raise ValueError('Unknown icon state')
                state_path, w, h = image_file(skin, filename)
                if (w, h) != (width, height):
                    raise ValueError('Icon state atlas dimensions differ')
                icons['states'][state] = state_path
            registered['icons'] = icons
        registrations[skin] = registered

    # Validate every input before writing the staging overlay.
    if output.exists() and any(output.iterdir()):
        raise ValueError('Choose an empty staging output directory')
    output.mkdir(parents=True, exist_ok=True)
    for (skin, filename), image in images.items():
        target = output / 'Media' / 'Skins' / skin / (filename[:-4] + '.tga')
        target.parent.mkdir(parents=True, exist_ok=True)
        image.save(target, format='TGA', compression=None)
        with Image.open(target) as check:
            assert check.size == image.size and check.mode == 'RGBA'
    lines = ['-- Generated from reviewed PNG sources by build_skin_assets.py.']
    for skin, assets in registrations.items():
        lines.append('assert(GuildRadioFM.RegisterSkinAssets(' + lua(skin) + ', ' + lua(assets) + '))')
    (output / 'SkinAssets.lua').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    return len(images), len(registrations)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('manifest', type=Path)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    manifest = json.loads(args.manifest.read_text(encoding='utf-8'))
    count, skins = compile_assets(manifest, args.source, args.output)
    print(f'Compiled {count} PNG assets for {skins} skins into {args.output}')


if __name__ == '__main__':
    main()
