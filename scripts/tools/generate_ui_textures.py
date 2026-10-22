import zlib
import struct
import os

def create_png(width, height, get_pixel_fn, filename):
    raw_bytes = bytearray()
    for y in range(height):
        raw_bytes.append(0) # filter type 0 (None)
        for x in range(width):
            r, g, b, a = get_pixel_fn(x, y, width, height)
            raw_bytes.extend([int(r), int(g), int(b), int(a)])
    
    compressed = zlib.compress(raw_bytes, 9)
    
    png = bytearray(b'\x89PNG\r\n\x1a\n')
    # IHDR
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data)
    png.extend(struct.pack('>I', 13) + b'IHDR' + ihdr_data + struct.pack('>I', ihdr_crc))
    # IDAT
    idat_crc = zlib.crc32(b'IDAT' + compressed)
    png.extend(struct.pack('>I', len(compressed)) + b'IDAT' + compressed + struct.pack('>I', idat_crc))
    # IEND
    iend_crc = zlib.crc32(b'IEND')
    png.extend(struct.pack('>I', 0) + b'IEND' + struct.pack('>I', iend_crc))
    
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, 'wb') as f:
        f.write(png)
    print(f"Created {filename} ({width}x{height})")

# 1. 9-slice panel normal: #081213 bg, #2c3640 border, crystal chip corners
def pixel_panel_normal(x, y, w, h):
    # Border
    is_corner = (x == 0 and y == 0) or (x == w-1 and y == 0) or (x == 0 and y == h-1) or (x == w-1 and y == h-1)
    is_chip = (x == 1 and y == 0) or (x == 0 and y == 1) or (x == w-2 and y == 0) or (x == w-1 and y == 1) or \
              (x == 1 and y == h-1) or (x == 0 and y == h-2) or (x == w-2 and y == h-1) or (x == w-1 and y == h-2)
    is_edge = (x == 0 or x == w-1 or y == 0 or y == h-1)
    
    if is_corner:
        return (0x00, 0x00, 0x00, 0) # transparent chip corner
    elif is_chip:
        return (0x7c, 0x5c, 0xff, 255) # purple gem accent chip
    elif is_edge:
        return (0x2c, 0x36, 0x40, 255) # border outline
    else:
        return (0x08, 0x12, 0x13, 245) # near-black teal-green panel bg

# 2. 9-slice panel focus: gold #ae7e54 border, crystal corners
def pixel_panel_focus(x, y, w, h):
    is_corner = (x == 0 and y == 0) or (x == w-1 and y == 0) or (x == 0 and y == h-1) or (x == w-1 and y == h-1)
    is_chip = (x == 1 and y == 0) or (x == 0 and y == 1) or (x == w-2 and y == 0) or (x == w-1 and y == 1) or \
              (x == 1 and y == h-1) or (x == 0 and y == h-2) or (x == w-2 and y == h-1) or (x == w-1 and y == h-2)
    is_edge = (x == 0 or x == w-1 or y == 0 or y == h-1)
    
    if is_corner:
        return (0x00, 0x00, 0x00, 0)
    elif is_chip:
        return (0xcb, 0xef, 0xc0, 255) # mint highlight chip
    elif is_edge:
        return (0xae, 0x7e, 0x54, 255) # gold border
    else:
        return (0x0c, 0x18, 0x1a, 250)

# 3. Button normal: 12x12
def pixel_btn_normal(x, y, w, h):
    is_corner = (x == 0 and y == 0) or (x == w-1 and y == 0) or (x == 0 and y == h-1) or (x == w-1 and y == h-1)
    is_edge = (x == 0 or x == w-1 or y == 0 or y == h-1)
    if is_corner:
        return (0, 0, 0, 0)
    elif is_edge:
        return (0x2c, 0x36, 0x40, 255)
    else:
        return (0x0e, 0x1f, 0x20, 255)

# 4. Button hover: emerald tint + gold outline
def pixel_btn_hover(x, y, w, h):
    is_corner = (x == 0 and y == 0) or (x == w-1 and y == 0) or (x == 0 and y == h-1) or (x == w-1 and y == h-1)
    is_edge = (x == 0 or x == w-1 or y == 0 or y == h-1)
    if is_corner:
        return (0, 0, 0, 0)
    elif is_edge:
        return (0xae, 0x7e, 0x54, 255) # gold
    else:
        return (0x1f, 0x38, 0x2c, 255) # emerald secondary

# 5. Button pressed: purple accent
def pixel_btn_pressed(x, y, w, h):
    is_corner = (x == 0 and y == 0) or (x == w-1 and y == 0) or (x == 0 and y == h-1) or (x == w-1 and y == h-1)
    is_edge = (x == 0 or x == w-1 or y == 0 or y == h-1)
    if is_corner:
        return (0, 0, 0, 0)
    elif is_edge:
        return (0x7c, 0x5c, 0xff, 255) # purple gem
    else:
        return (0x14, 0x10, 0x28, 255)

# 6. Button focus: gold outline + mint corners
def pixel_btn_focus(x, y, w, h):
    is_corner = (x == 0 and y == 0) or (x == w-1 and y == 0) or (x == 0 and y == h-1) or (x == w-1 and y == h-1)
    is_edge = (x == 0 or x == w-1 or y == 0 or y == h-1)
    if is_corner:
        return (0xcb, 0xef, 0xc0, 255) # mint
    elif is_edge:
        return (0xae, 0x7e, 0x54, 255) # gold
    else:
        return (0, 0, 0, 0) # transparent overlay

# 7. Button disabled
def pixel_btn_disabled(x, y, w, h):
    is_corner = (x == 0 and y == 0) or (x == w-1 and y == 0) or (x == 0 and y == h-1) or (x == w-1 and y == h-1)
    is_edge = (x == 0 or x == w-1 or y == 0 or y == h-1)
    if is_corner:
        return (0, 0, 0, 0)
    elif is_edge:
        return (0x1a, 0x20, 0x24, 255)
    else:
        return (0x07, 0x0c, 0x0d, 200)

# 8. Gem Cursor: 12x12 glowing purple diamond gem
def pixel_gem_cursor(x, y, w, h):
    cx, cy = 5.5, 5.5
    dist = abs(x - cx) + abs(y - cy)
    if dist <= 2.0:
        if x <= 5 and y <= 5:
            return (0xcb, 0xef, 0xc0, 255) # mint specular shine
        return (0xab, 0x8c, 0xff, 255) # bright purple facet
    elif dist <= 4.0:
        return (0x7c, 0x5c, 0xff, 255) # primary purple gem
    elif dist <= 5.5:
        return (0x4a, 0x2e, 0xa8, 200) # gem glow boundary
    return (0, 0, 0, 0)

# 9. Slider Grabber: 8x8
def pixel_slider_grabber(x, y, w, h):
    cx, cy = 3.5, 3.5
    dist = abs(x - cx) + abs(y - cy)
    if dist <= 1.5:
        return (0xcb, 0xef, 0xc0, 255) # mint center
    elif dist <= 3.5:
        return (0xae, 0x7e, 0x54, 255) # gold edge
    return (0, 0, 0, 0)

if __name__ == '__main__':
    create_png(16, 16, pixel_panel_normal, 'assets/ui/panel_9slice_normal.png')
    create_png(16, 16, pixel_panel_focus, 'assets/ui/panel_9slice_focus.png')
    create_png(12, 12, pixel_btn_normal, 'assets/ui/button_normal.png')
    create_png(12, 12, pixel_btn_hover, 'assets/ui/button_hover.png')
    create_png(12, 12, pixel_btn_pressed, 'assets/ui/button_pressed.png')
    create_png(12, 12, pixel_btn_focus, 'assets/ui/button_focus.png')
    create_png(12, 12, pixel_btn_disabled, 'assets/ui/button_disabled.png')
    create_png(12, 12, pixel_gem_cursor, 'assets/ui/gem_cursor.png')
    create_png(8, 8, pixel_slider_grabber, 'assets/ui/slider_grabber.png')
    print("All UI textures generated successfully.")
