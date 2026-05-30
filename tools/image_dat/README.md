# Image DAT tools

This folder contains small helper scripts for converting images to RGB444
`.dat` files that can initialize a ROM with `$readmemh`, and for reconstructing
an image preview from such a `.dat` file.

## Requirements

Install Pillow for the Python environment used to run the scripts:

```bash
python3 -m pip install pillow
```

On Windows, use the same command from Git Bash, PowerShell or the Python
environment used for the project.

## Convert image to DAT

```bash
python3 tools/image_dat/img2dat.py path/to/image.png
```

The script creates `path/to/image.dat` next to the input file. Each output line
after the header is one RGB444 pixel in row-major order:

```text
// image rom content of: image.png
// WIDTH = 120
// HEIGHT = 180
F8A
F8A
...
```

The 8-bit RGB source channels are reduced to their 4 most significant bits.
If the input image has an alpha channel or palette transparency, pixels with
alpha below 128 are written as `000`. In the current cursor renderer, `000` is
used as the transparent color key.

## Preview DAT as image

```bash
python3 tools/image_dat/dat2img.py path/to/image.dat
```

The script opens a reconstructed preview image. To save the preview instead:

```bash
python3 tools/image_dat/dat2img.py path/to/image.dat --save path/to/preview.png
```

## RTL addressing note

Pixels are stored linearly, row by row. If image height or width is not a power
of two, do not build the ROM address by simple bit concatenation. Use linear
addressing:

```systemverilog
image_y = vcount_in - ypos;
image_x = hcount_in - xpos;
pixel_addr_nxt = image_y * IMAGE_WIDTH + image_x;
```

This is the addressing style needed for arbitrary image dimensions.
