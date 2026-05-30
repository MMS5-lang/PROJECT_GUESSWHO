#!/usr/bin/env python3
"""Display or save an image reconstructed from a RGB444 .dat ROM init file."""

from pathlib import Path
import argparse
import re

from PIL import Image


WIDTH_RE = re.compile(r"^//\s*WIDTH\s*=\s*(\d+)\s*$")
HEIGHT_RE = re.compile(r"^//\s*HEIGHT\s*=\s*(\d+)\s*$")


def parse_size(lines: list[str]) -> tuple[int, int]:
    width_match = WIDTH_RE.match(lines[1])
    height_match = HEIGHT_RE.match(lines[2])

    if width_match is None or height_match is None:
        raise ValueError("DAT header must contain '// WIDTH = ...' and '// HEIGHT = ...'")

    return int(width_match.group(1)), int(height_match.group(1))


def rgb444_to_rgb888(pixel: str) -> tuple[int, int, int]:
    if len(pixel) < 3:
        raise ValueError(f"Invalid RGB444 pixel: {pixel!r}")

    r = int(pixel[0], 16)
    g = int(pixel[1], 16)
    b = int(pixel[2], 16)

    return r * 17, g * 17, b * 17


def load_dat(dat_path: Path) -> Image.Image:
    lines = dat_path.read_text(encoding="ascii").splitlines()

    if len(lines) < 3:
        raise ValueError("DAT file is too short to contain the expected header")

    width, height = parse_size(lines)
    pixels = [line.strip() for line in lines[3:] if line.strip() and not line.startswith("//")]

    expected_pixels = width * height
    if len(pixels) != expected_pixels:
        raise ValueError(
            f"DAT pixel count mismatch: expected {expected_pixels}, got {len(pixels)}"
        )

    image = Image.new("RGB", (width, height))

    for index, pixel in enumerate(pixels):
        x = index % width
        y = index // width
        image.putpixel((x, y), rgb444_to_rgb888(pixel))

    return image


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Display an image reconstructed from a RGB444 .dat ROM file."
    )
    parser.add_argument("dat_file", type=Path, help="Input .dat file")
    parser.add_argument(
        "--save",
        type=Path,
        default=None,
        help="Optional output image path instead of only opening a preview",
    )
    args = parser.parse_args()

    if not args.dat_file.is_file():
        raise SystemExit(f"ERROR: file not found: {args.dat_file}")

    image = load_dat(args.dat_file)

    if args.save is not None:
        image.save(args.save)
        print(f"Wrote {args.save}")
    else:
        image.show()


if __name__ == "__main__":
    main()
