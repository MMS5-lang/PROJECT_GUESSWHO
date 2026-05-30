#!/usr/bin/env python3
"""Convert an image file to a simple 12-bit RGB .dat ROM init file.

The output format is compatible with $readmemh:

    // image rom content of: image.png
    // WIDTH = 120
    // HEIGHT = 180
    RGB
    RGB
    ...

Each pixel is written in row-major order as one hexadecimal 12-bit RGB value.
The 8-bit source channels are reduced to their 4 most significant bits.
"""

from pathlib import Path
import argparse

from PIL import Image


def pixel_to_rgb444(pixel: tuple[int, int, int, int]) -> str:
    """Return one RGB444 pixel as three uppercase hexadecimal digits."""
    r, g, b, a = pixel
    if a < 128:
        return "000"

    return f"{r >> 4:X}{g >> 4:X}{b >> 4:X}"


def convert_image(image_path: Path) -> Path:
    output_path = image_path.with_suffix(".dat")

    with Image.open(image_path) as image:
        rgba_image = image.convert("RGBA")
        width, height = rgba_image.size

        with output_path.open("w", encoding="ascii", newline="\n") as output_file:
            output_file.write(f"// image rom content of: {image_path}\n")
            output_file.write(f"// WIDTH = {width}\n")
            output_file.write(f"// HEIGHT = {height}\n")

            for y in range(height):
                for x in range(width):
                    output_file.write(pixel_to_rgb444(rgba_image.getpixel((x, y))) + "\n")

    return output_path


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert an image, for example PNG, to a RGB444 .dat ROM file."
    )
    parser.add_argument("image_file", type=Path, help="Input image file")
    args = parser.parse_args()

    if not args.image_file.is_file():
        raise SystemExit(f"ERROR: file not found: {args.image_file}")

    output_path = convert_image(args.image_file)
    print(f"Wrote {output_path}")


if __name__ == "__main__":
    main()
