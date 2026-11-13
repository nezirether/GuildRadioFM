"""Builds the GuildRadioFM 2.3 art: wordmark logo, square icon, and a 16-icon atlas (all 32-bit TGA).
Run: python tools/make_art.py   (writes into GuildRadioFM/Media/)"""
import math
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
MEDIA = os.path.join(HERE, "..", "GuildRadioFM", "Media") if os.path.isdir(os.path.join(HERE, "..", "GuildRadioFM")) else os.path.join(HERE, "..", "Media")
FONT_BLACK = r"C:\Windows\Fonts\seguibl.ttf"
FONT_BOLD = r"C:\Windows\Fonts\segoeuib.ttf"
VIOLET = (139, 92, 255)
CYAN = (56, 220, 255)


def gradient(size, a=VIOLET, b=CYAN, angle=0.0):
    w, h = size
    g = Image.new("RGBA", size)
    px = g.load()
    ca, sa = math.cos(angle), math.sin(angle)
    span = abs(w * ca) + abs(h * sa) or 1
    for y in range(h):
        for x in range(w):
            t = max(0.0, min(1.0, ((x * ca + y * sa) - min(0, w * ca) - min(0, h * sa)) / span))
            px[x, y] = tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)
    return g


def broadcast_mark(size, stroke):
    """((•)) mark as an alpha mask."""
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    c = size / 2
    r = size * 0.11
    d.ellipse([c - r, c - r, c + r, c + r], fill=255)
    for rad in (size * 0.25, size * 0.40):
        box = [c - rad, c - rad, c + rad, c + rad]
        d.arc(box, 140, 220, fill=255, width=stroke)
        d.arc(box, -40, 40, fill=255, width=stroke)
    return m


def save_tga(img, name):
    img.save(os.path.join(MEDIA, name), compression=None)
    print("wrote", name, img.size)


def logo():
    S = 4
    W, H = 512 * S, 128 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    # mark
    mark = broadcast_mark(108 * S, 9 * S)
    grad = gradient(mark.size, angle=0.6)
    img.paste(grad, (4 * S, 10 * S), mark)
    # wordmark
    f = ImageFont.truetype(FONT_BLACK, 46 * S)
    d = ImageDraw.Draw(img)
    x0 = 122 * S
    text = "GUILDRADIO"
    x = x0
    for ch in text:
        d.text((x, 32 * S), ch, font=f, fill=(244, 245, 248, 255))
        x += d.textlength(ch, font=f) - 1.0 * S
    # FM pill
    pf = ImageFont.truetype(FONT_BLACK, 32 * S)
    pw = d.textlength("FM", font=pf) + 26 * S
    px0, py0 = x + 8 * S, 40 * S
    pill = Image.new("L", (int(pw), 46 * S), 0)
    ImageDraw.Draw(pill).rounded_rectangle([0, 0, pill.size[0] - 1, pill.size[1] - 1], radius=12 * S, fill=255)
    img.paste(gradient(pill.size), (int(px0), py0), pill)
    d.text((px0 + 13 * S, py0 - 1 * S), "FM", font=pf, fill=(12, 12, 18, 255))
    print("logo right edge px:", int((px0 + pw) / S))
    small = img.resize((512, 128), Image.LANCZOS)
    save_tga(small, "GuildRadioFM_Logo.tga")


GOLD_HI = (255, 222, 140)
GOLD_LO = (176, 118, 40)


def emblem(N):
    """Gold rune ring with a beamed music note: the GuildRadioFM emblem (WoW-style, not a radio-wave mark)."""
    S = 4
    M = N * S
    img = Image.new("RGBA", (M, M), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([2 * S, 2 * S, M - 2 * S, M - 2 * S], fill=(16, 13, 10, 255))
    mask = Image.new("L", (M, M), 0)
    md = ImageDraw.Draw(mask)
    w = max(2, M // 30)
    md.ellipse([w, w, M - w, M - w], outline=255, width=w * 2)
    md.ellipse([M * 0.12, M * 0.12, M * 0.88, M * 0.88], outline=255, width=max(1, w // 2))
    # rune ticks between the rings
    c = M / 2
    for k in range(16):
        a = math.radians(k * 22.5)
        r1, r2 = M * 0.405, M * 0.455
        md.line([(c + math.cos(a) * r1, c + math.sin(a) * r1), (c + math.cos(a) * r2, c + math.sin(a) * r2)], fill=255, width=max(1, w // 2))
    # beamed eighth notes
    hw, hh = M * 0.13, M * 0.095
    for hx, hy in ((M * 0.36, M * 0.66), (M * 0.62, M * 0.6)):
        md.ellipse([hx - hw / 2, hy - hh / 2, hx + hw / 2, hy + hh / 2], fill=255)
    sw = max(2, int(M * 0.03))
    md.rectangle([M * 0.36 + hw / 2 - sw, M * 0.30, M * 0.36 + hw / 2, M * 0.66], fill=255)
    md.rectangle([M * 0.62 + hw / 2 - sw, M * 0.24, M * 0.62 + hw / 2, M * 0.60], fill=255)
    md.polygon([(M * 0.36 + hw / 2 - sw, M * 0.30), (M * 0.62 + hw / 2, M * 0.24), (M * 0.62 + hw / 2, M * 0.32), (M * 0.36 + hw / 2 - sw, M * 0.38)], fill=255)
    img.paste(gradient((M, M), GOLD_HI, GOLD_LO, angle=1.2), (0, 0), mask)
    return img.resize((N, N), Image.LANCZOS)


def square_icon():
    save_tga(emblem(64), "GuildRadioFM_Icon.tga")
    save_tga(emblem(256), "GuildRadioFM_Emblem.tga")


def icons():
    S = 256
    names = ["prev", "play", "stop", "next", "heart", "heartline", "shuffle", "repeat",
             "volume", "mute", "plus", "close", "up", "down", "minus", "live"]
    atlas = Image.new("RGBA", (64 * len(names), 64), (0, 0, 0, 0))
    W = 255
    for i, n in enumerate(names):
        m = Image.new("L", (S, S), 0)
        d = ImageDraw.Draw(m)
        lw = 22
        if n == "play":
            d.polygon([(80, 52), (80, 204), (204, 128)], fill=W)
        elif n == "stop":
            d.rounded_rectangle([70, 70, 186, 186], radius=18, fill=W)
        elif n in ("prev", "next"):
            d.polygon([(70, 60), (70, 196), (170, 128)], fill=W)
            d.rounded_rectangle([172, 60, 196, 196], radius=6, fill=W)
            if n == "prev":
                m = m.transpose(Image.FLIP_LEFT_RIGHT)
        elif n in ("heart", "heartline"):
            hm = Image.new("L", (S, S), 0)
            hd = ImageDraw.Draw(hm)
            hd.ellipse([44, 56, 132, 144], fill=W)
            hd.ellipse([124, 56, 212, 144], fill=W)
            hd.polygon([(50, 118), (206, 118), (128, 210)], fill=W)
            if n == "heartline":
                inner = hm.filter(ImageFilter.MinFilter(41))
                hm = Image.eval(Image.merge("L", [hm]), lambda v: v)
                hm.paste(0, (0, 0), inner)
            m = hm
        elif n == "shuffle":
            d.line([(50, 80), (100, 80), (156, 176), (190, 176)], fill=W, width=lw, joint="curve")
            d.line([(50, 176), (100, 176), (156, 80), (190, 80)], fill=W, width=lw, joint="curve")
            d.polygon([(186, 50), (186, 110), (222, 80)], fill=W)
            d.polygon([(186, 146), (186, 206), (222, 176)], fill=W)
        elif n == "repeat":
            d.rounded_rectangle([52, 78, 204, 178], radius=40, outline=W, width=lw)
            d.rectangle([118, 60, 150, 100], fill=0)
            d.polygon([(120, 50), (120, 108), (160, 79)], fill=W)
        elif n in ("volume", "mute"):
            d.polygon([(48, 100), (88, 100), (134, 58), (134, 198), (88, 156), (48, 156)], fill=W)
            if n == "volume":
                d.arc([110, 84, 172, 172], -50, 50, fill=W, width=lw)
                d.arc([110, 50, 214, 206], -50, 50, fill=W, width=lw)
            else:
                d.line([(160, 96), (212, 160)], fill=W, width=lw)
                d.line([(212, 96), (160, 160)], fill=W, width=lw)
        elif n == "plus":
            d.rounded_rectangle([116, 56, 140, 200], radius=8, fill=W)
            d.rounded_rectangle([56, 116, 200, 140], radius=8, fill=W)
        elif n == "minus":
            d.rounded_rectangle([60, 116, 196, 140], radius=8, fill=W)
        elif n == "close":
            d.line([(76, 76), (180, 180)], fill=W, width=lw)
            d.line([(180, 76), (76, 180)], fill=W, width=lw)
        elif n in ("up", "down"):
            d.line([(64, 160), (128, 96), (192, 160)], fill=W, width=lw, joint="curve")
            if n == "down":
                m = m.transpose(Image.FLIP_TOP_BOTTOM)
        elif n == "live":
            m = broadcast_mark(S, 20)
        tile = Image.new("RGBA", (S, S), (255, 255, 255, 0))
        tile.putalpha(m)
        atlas.paste(tile.resize((64, 64), Image.LANCZOS), (64 * i, 0))
    save_tga(atlas, "GuildRadioFM_Icons.tga")
    print("icons:", ", ".join(f"{i}={n}" for i, n in enumerate(names)))


if __name__ == "__main__":
    square_icon()
    icons()
