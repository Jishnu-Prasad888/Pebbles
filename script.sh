#!/bin/sh
# Embeds pic.png (or pic.jpg) into theme.css as the Pebbles background.
# Usage: put pic.png next to theme.css, then run:   sh embed-pic.sh
# Re-run it any time you change the picture. Needs python3 (preinstalled on Pop!_OS).
cd "$(dirname "$0")" || exit 1
python3 - <<'PY'
import base64, io, os, sys, re
src = next((f for f in ("pic.png", "pic.jpg", "pic.jpeg", "pic.webp") if os.path.exists(f)), None)
if not src:
    sys.exit("No pic.png found next to theme.css")
data = open(src, "rb").read()
mime = {"png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg", "webp": "image/webp"}[src.rsplit(".", 1)[1]]
try:   # shrink big pictures so theme.css stays light (optional, needs Pillow)
    from PIL import Image
    im = Image.open(io.BytesIO(data)).convert("RGB")
    im.thumbnail((1920, 1200))
    buf = io.BytesIO(); im.save(buf, "JPEG", quality=82, optimize=True)
    data, mime = buf.getvalue(), "image/jpeg"
    print("Resized to", im.size)
except ImportError:
    if len(data) > 1_500_000:
        print("Note: picture is %.1f MB. For a snappier Obsidian, shrink it to ~1920px wide first." % (len(data)/1e6))
b64 = base64.b64encode(data).decode()
css = open("theme.css", encoding="utf-8").read()
new, n = re.subn(r"/\*PEBBLES-IMAGE-START\*/.*?/\*PEBBLES-IMAGE-END\*/",
                 lambda m: '/*PEBBLES-IMAGE-START*/--pebbles-image: url("data:%s;base64,%s");/*PEBBLES-IMAGE-END*/' % (mime, b64),
                 css, count=1, flags=re.S)
if n != 1:
    sys.exit("Marker not found in theme.css")
open("theme.css", "w", encoding="utf-8").write(new)
print("Done. Reload Obsidian (Ctrl+R).")
PY