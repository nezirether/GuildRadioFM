from pathlib import Path
import math
import random
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parent.parent / "Media"
rng = random.Random(16001)

def iron(name, size, header=False):
    w, h = size
    image = Image.new("RGB", size)
    pixels = []
    for y in range(h):
        for x in range(w):
            heat = max(0, 1 - math.hypot((x-w*0.82)/(w*0.55), (h-y)/(h*0.68)))
            noise = rng.randrange(-4, 5) + int(2*math.sin(y*.14 + x*.027))
            base = (39, 25, 22) if header else (27, 22, 19)
            flare = (65, 13, 3) if header else (16, 6, 2)
            pixels.append(tuple(max(0, min(255, b + noise + int(heat*f)))
                                for b, f in zip(base, flare)))
    image.putdata(pixels)
    draw = ImageDraw.Draw(image)
    if header:
        draw.line((0, 2, w, 2), fill=(147, 76, 33), width=2)
        draw.line((0, h-3, w, h-3), fill=(182, 78, 27), width=2)
        for x in (8, w-9):
            draw.ellipse((x-4, 11, x+4, 19), fill=(115, 70, 42), outline=(15, 8, 6))
            draw.point((x-1, 13), fill=(242, 169, 91))
    image.save(root / name, format="TGA")

iron("GuildRadioFM_Forge.tga", (256, 256))
iron("GuildRadioFM_ForgeHeader.tga", (512, 128), header=True)
