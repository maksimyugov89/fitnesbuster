"""
Quick analysis of front.svg / back.svg structure
to understand color distribution and path count.
"""
import re
import sys
from collections import Counter

def analyze_svg(filepath):
    print(f"\n=== {filepath} ===")

    # Count paths and collect color info
    path_count = 0
    color_counter = Counter()
    opacity_counter = Counter()
    rect_sizes = Counter()

    coord_pattern = re.compile(r'M\s*([\d.]+),([\d.]+)\s*L\s*([\d.]+),([\d.]+)')
    fill_pattern = re.compile(r'fill:rgb\((\d+),(\d+),(\d+)\)')
    opacity_pattern = re.compile(r'fill-opacity:([\d.]+)')

    x_min, x_max, y_min, y_max = 9999, 0, 9999, 0

    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            paths_in_line = line.count('<path')
            path_count += paths_in_line

            # sample first 50k paths for analysis
            if path_count > 50000:
                continue

            for m in coord_pattern.finditer(line):
                x1, y1, x2, y2 = float(m.group(1)), float(m.group(2)), float(m.group(3)), float(m.group(4))
                w = abs(x2 - x1)
                h = abs(y2 - y1)
                rect_sizes[(round(w), round(h))] += 1
                if x1 < x_min: x_min = x1
                if x2 > x_max: x_max = x2
                if y1 < y_min: y_min = y1
                if y2 > y_max: y_max = y2

            for m in fill_pattern.finditer(line):
                r, g, b = int(m.group(1)), int(m.group(2)), int(m.group(3))
                # bucket colors to 16-step resolution
                rb, gb, bb = (r >> 4) << 4, (g >> 4) << 4, (b >> 4) << 4
                color_counter[(rb, gb, bb)] += 1

            for m in opacity_pattern.finditer(line):
                op = float(m.group(1))
                bucket = round(op * 10) / 10
                opacity_counter[bucket] += 1

    print(f"Total paths: {path_count:,}")
    print(f"Coordinate range: x=[{x_min:.0f},{x_max:.0f}], y=[{y_min:.0f},{y_max:.0f}]")

    print(f"\nTop 20 colors (sampled first 50k paths):")
    for color, cnt in color_counter.most_common(20):
        r, g, b = color
        print(f"  rgb({r:3d},{g:3d},{b:3d}) -> {cnt:6d}x")

    print(f"\nOpacity distribution (sampled first 50k paths):")
    for op, cnt in sorted(opacity_counter.items()):
        if cnt > 100:
            print(f"  opacity={op:.1f} -> {cnt:6d}x")

    print(f"\nRect sizes (sampled):")
    for size, cnt in rect_sizes.most_common(10):
        print(f"  {size[0]}x{size[1]} -> {cnt:6d}x")

    return path_count

analyze_svg(r'c:\Users\Despa\fitnesbuster\assets\anatomy\front.svg')
analyze_svg(r'c:\Users\Despa\fitnesbuster\assets\anatomy\back.svg')
