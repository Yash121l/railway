import sys, glob
from PIL import Image, ImageDraw
pattern, out, cols = sys.argv[1], sys.argv[2], int(sys.argv[3])
fs = sorted(glob.glob(pattern))
ims = [Image.open(f).convert("RGB") for f in fs]
w = 560 if ims[0].width > ims[0].height else 300
ims = [i.resize((w, int(i.height * w / i.width))) for i in ims]
h = ims[0].height
rows = (len(ims) + cols - 1) // cols
c = Image.new("RGB", (w * cols, h * rows), "black")
d = ImageDraw.Draw(c)
for k, (f, i) in enumerate(zip(fs, ims)):
    x, y = (k % cols) * w, (k // cols) * h
    c.paste(i, (x, y))
    d.text((x + 6, y + 4), f.split("-")[-1].split(".")[0], fill=(255, 80, 80))
c.save(out, quality=85)
