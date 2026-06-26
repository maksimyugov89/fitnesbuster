"""
Step 1: Rasterize pixel-SVG → PNG for visual analysis.
Reads M x,y L ... Z paths + fill:rgb + fill-opacity and draws each pixel.
"""
import re
import numpy as np
from PIL import Image
import sys

PATTERN = re.compile(
    r'<path\s+d="\s*M\s+([\d.]+),([\d.]+)[^"]*?Z"\s+style="fill:rgb\((\d+),(\d+),(\d+)\);\s*fill-opacity:([\d.]+)'
)

def rasterize(svg_path: str, out_path: str, width: int = 1024, height: int = 1536):
    print(f"Rasterizing {svg_path} ...")
    img = np.zeros((height, width, 4), dtype=np.float32)

    chunk_size = 1024 * 1024  # 1MB chunks
    buffer = ""
    processed = 0

    with open(svg_path, 'r', encoding='utf-8') as f:
        while True:
            chunk = f.read(chunk_size)
            if not chunk:
                break
            buffer += chunk
            # Process all complete path elements in buffer
            # Keep last 200 chars in case path spans chunk boundary
            work = buffer[:-200] if len(buffer) > 200 else buffer

            for m in PATTERN.finditer(work):
                x = int(float(m.group(1)))
                y = int(float(m.group(2)))
                r = int(m.group(3))
                g = int(m.group(4))
                b = int(m.group(5))
                alpha = float(m.group(6))

                if 0 <= x < width and 0 <= y < height:
                    # Alpha-composite onto existing
                    a_new = alpha
                    a_old = img[y, x, 3]
                    if a_new > 0:
                        a_out = a_new + a_old * (1 - a_new)
                        if a_out > 0:
                            img[y, x, 0] = (r * a_new + img[y, x, 0] * a_old * (1 - a_new)) / a_out
                            img[y, x, 1] = (g * a_new + img[y, x, 1] * a_old * (1 - a_new)) / a_out
                            img[y, x, 2] = (b * a_new + img[y, x, 2] * a_old * (1 - a_new)) / a_out
                            img[y, x, 3] = a_out

                processed += 1
                if processed % 50000 == 0:
                    print(f"  Processed {processed:,} paths...", end='\r')

            buffer = buffer[len(work):]

    print(f"\n  Total paths: {processed:,}")

    # Convert float → uint8
    out = np.zeros((height, width, 4), dtype=np.uint8)
    out[:, :, :3] = np.clip(img[:, :, :3], 0, 255).astype(np.uint8)
    out[:, :, 3] = np.clip(img[:, :, 3] * 255, 0, 255).astype(np.uint8)

    pil_img = Image.fromarray(out, 'RGBA')
    pil_img.save(out_path)
    print(f"  Saved: {out_path}")
    return processed

base = r'c:\Users\Despa\fitnesbuster\assets\anatomy'
rasterize(f'{base}\\front.svg', f'{base}\\front_preview.png')
rasterize(f'{base}\\back.svg',  f'{base}\\back_preview.png')
print("\nDone.")
