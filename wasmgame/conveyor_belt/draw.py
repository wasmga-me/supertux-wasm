# Draws conveyor belt frames (32x32): a steel block with a dark belt and green chevrons.
import sys
from PIL import Image, ImageDraw
out = sys.argv[1]
def block():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 31, 31], fill=(20, 22, 26, 255))
    d.rectangle([1, 1, 30, 5], fill=(70, 74, 80, 255))
    d.line([2, 2, 29, 2], fill=(150, 155, 162, 255))
    d.rectangle([1, 7, 30, 30], fill=(110, 115, 122, 255))
    d.line([1, 7, 30, 7], fill=(185, 190, 196, 255))
    d.line([1, 7, 1, 30], fill=(160, 165, 172, 255))
    d.line([30, 8, 30, 30], fill=(60, 63, 68, 255))
    d.line([2, 30, 30, 30], fill=(60, 63, 68, 255))
    d.rectangle([4, 10, 27, 27], fill=(12, 13, 16, 255))
    return im
def chevrons(im, shift, right):
    d = ImageDraw.Draw(im)
    for base in (-12, 0, 12, 24):
        x = base + shift
        for t in range(5):
            for dx in (0, 1):
                for px, py in ((x + t + dx, 13 + t), (x + t + dx, 22 - t)):
                    if not right:
                        px = 31 - px
                    if 5 <= px <= 26:
                        d.point((px, py), fill=(40, 220, 60, 255))
    return im
block().save(f"{out}/conveyor_stopped.png")
for i in range(6):
    chevrons(block(), i * 2, True).save(f"{out}/conveyor_right{i}.png")
    chevrons(block(), i * 2, False).save(f"{out}/conveyor_left{i}.png")
