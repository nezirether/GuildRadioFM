"""Exercise conversion with synthetic fixtures kept outside shipped artwork."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

from PIL import Image
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('skin_builder', ROOT / 'tools/build_skin_assets.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class SkinPipelineTests(unittest.TestCase):
    def test_signature_texture_paths_and_dimensions(self):
        lua = LuaRuntime()
        lua.execute('GuildRadioFM = {}')
        for name in ('Skins.lua', 'SkinRenderer.lua', 'SkinAssets.lua', 'SignatureArt.lua'):
            lua.execute((ROOT / name).read_text(encoding='utf-8'))
        assets = lua.globals().GuildRadioFM.SkinRenderer.assets
        prefix = 'Interface\\AddOns\\GuildRadioFM\\'
        self.assertEqual(len(list(assets.keys())), 13)
        for key, skin in assets.items():
            if key != 'trogdor':
                self.assertIsNone(skin.surfaces.outer)
                self.assertIsNone(skin.surfaces.tab)
                self.assertIsNone(skin.surfaces.transport)
            for _, surface in skin.surfaces.items():
                local = ROOT / surface.path.removeprefix(prefix).replace('\\', '/')
                with Image.open(local) as image:
                    image.load()
                    self.assertEqual(image.size, (surface.width, surface.height))

    def test_supplied_native_logo(self):
        with tempfile.TemporaryDirectory() as folder:
            output = Path(folder) / 'output'
            builder.compile_assets({'trogdor': {'emblem': {'file': 'emblem.png', 'native': True}}},
                                   ROOT / 'assets', output)
            with Image.open(ROOT / 'assets/trogdor/emblem.png') as original:
                with Image.open(output / 'Media/Skins/trogdor/emblem.tga') as exported:
                    self.assertEqual(original.size, (256, 256))
                    self.assertEqual(original.tobytes(), exported.tobytes())
            with self.assertRaises(ValueError):
                builder.compile_assets({'trogdor': {'emblem': {'file': 'emblem.png'}}},
                                       ROOT / 'assets', Path(folder) / 'unmarked-output')

    def test_emblem_alpha_and_bounds(self):
        with tempfile.TemporaryDirectory() as folder:
            base = Path(folder)
            source = base / 'assets/trogdor'
            source.mkdir(parents=True)
            image = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
            image.paste((120, 60, 30, 255), (100, 20, 400, 480))
            image.save(source / 'emblem.png')
            manifest = {'trogdor': {'emblem': {'file': 'emblem.png'}}}
            output = base / 'output'
            builder.compile_assets(manifest, base / 'assets', output)
            lua = LuaRuntime()
            lua.execute('GuildRadioFM = {}')
            lua.execute((ROOT / 'Skins.lua').read_text(encoding='utf-8'))
            lua.execute((ROOT / 'SkinRenderer.lua').read_text(encoding='utf-8'))
            lua.execute((output / 'SkinAssets.lua').read_text(encoding='utf-8'))
            emblem = lua.globals().GuildRadioFM.SkinRenderer.assets.trogdor.emblem
            self.assertEqual(list(emblem.bounds.values()), [100, 20, 400, 480])
            Image.new('RGBA', (512, 512), (0, 0, 0, 255)).save(source / 'emblem.png')
            with self.assertRaises(ValueError):
                builder.compile_assets(manifest, base / 'assets', base / 'opaque-output')
            self.assertFalse((base / 'opaque-output').exists())

    def test_conversion_and_registration(self):
        with tempfile.TemporaryDirectory() as folder:
            base = Path(folder)
            source = base / 'assets/trogdor'
            source.mkdir(parents=True)
            Image.new('RGBA', (256, 128), (70, 30, 10, 128)).save(source / 'panel.png')
            Image.new('RGBA', (512, 256), (255, 200, 10, 255)).save(source / 'icons.png')
            manifest = {'trogdor': {'surfaces': {'panel': {'file': 'panel.png', 'mode': 'nine',
                         'insets': [16, 16, 8, 8]}}, 'icons': {'file': 'icons.png'}}}
            output = base / 'output'
            self.assertEqual(builder.compile_assets(manifest, base / 'assets', output), (2, 1))
            with Image.open(output / 'Media/Skins/trogdor/panel.tga') as image:
                self.assertEqual(image.getpixel((0, 0)), (70, 30, 10, 128))
            lua = LuaRuntime()
            lua.execute('GuildRadioFM = {}')
            lua.execute((ROOT / 'Skins.lua').read_text())
            lua.execute((ROOT / 'SkinRenderer.lua').read_text())
            lua.execute((output / 'SkinAssets.lua').read_text())
            self.assertEqual(lua.globals().GuildRadioFM.SkinRenderer.assets.trogdor.icons.cell, 64)
            with self.assertRaises(ValueError):
                builder.compile_assets(manifest, base / 'assets', output)

    def test_invalid_inputs_do_not_publish(self):
        with tempfile.TemporaryDirectory() as folder:
            base = Path(folder)
            source = base / 'assets/trogdor'
            source.mkdir(parents=True)
            Image.new('RGBA', (128, 128)).save(source / 'panel.png')
            Image.new('RGBA', (100, 128)).save(source / 'wrong.png')
            for descriptor in ({'file': '../escape.png'}, {'file': 'wrong.png'},
                               {'file': 'panel.png', 'uv': [0.9, 0.1, 0, 1]},
                               {'file': 'panel.png', 'insets': [80, 80, 0, 0]}):
                with self.assertRaises(ValueError):
                    builder.compile_assets({'trogdor': {'surfaces': {'panel': descriptor}}},
                                           base / 'assets', base / 'output')
                self.assertFalse((base / 'output').exists())


if __name__ == '__main__':
    unittest.main()
