#!/usr/bin/env python3
"""
Custom Icon Generator for SSH Remote
Generates 1024x1024 master icon and Android Adaptive Icon layers (background & foreground)
Theme: Royal Blue & Pure White with Cyan Accents
"""

import os
from PIL import Image, ImageDraw, ImageFilter

def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))

def create_vertical_gradient(width, height, color_top, color_bottom):
    base = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    for y in range(height):
        factor = y / float(height - 1)
        r = int(color_top[0] + (color_bottom[0] - color_top[0]) * factor)
        g = int(color_top[1] + (color_bottom[1] - color_top[1]) * factor)
        b = int(color_top[2] + (color_bottom[2] - color_top[2]) * factor)
        row = Image.new('RGBA', (width, 1), (r, g, b, 255))
        base.paste(row, (0, y))
    return base

def draw_terminal_symbol(draw, cx, cy, size, fg_color, bg_card, accent_color):
    """Draws a crisp modern terminal card with prompt `>_` and connection signal"""
    w = size * 0.95
    h = size * 0.72
    left = cx - w / 2
    top = cy - h / 2
    right = cx + w / 2
    bottom = cy + h / 2
    radius = int(size * 0.14)

    # 1. Dark Terminal Window Inside White Container
    draw.rounded_rectangle([left, top, right, bottom], radius=radius, fill=bg_card)
    
    # 2. Window Header Bar
    header_h = h * 0.22
    draw.rounded_rectangle([left, top, right, top + header_h + 10], radius=radius, fill=(20, 32, 50, 255))
    draw.rectangle([left, top + header_h - 10, right, top + header_h], fill=(20, 32, 50, 255))

    # 3. Header Window Dots (Traffic light dots)
    dot_r = header_h * 0.22
    dot_y = top + header_h * 0.5
    dot_colors = [(239, 68, 68), (245, 158, 11), (16, 185, 129)]
    start_x = left + w * 0.12
    for i, col in enumerate(dot_colors):
        x = start_x + i * (dot_r * 2.8)
        draw.ellipse([x - dot_r, dot_y - dot_r, x + dot_r, dot_y + dot_r], fill=col)

    # 4. SSH Remote Signal indicator in header (right side)
    sig_x = right - w * 0.14
    draw.ellipse([sig_x - dot_r, dot_y - dot_r, sig_x + dot_r, dot_y + dot_r], fill=accent_color)
    draw.arc([sig_x - dot_r * 2.2, dot_y - dot_r * 2.2, sig_x + dot_r * 2.2, dot_y + dot_r * 2.2], start=210, end=330, fill=accent_color, width=int(size * 0.02))

    # 5. Terminal Body Prompt `>`
    prompt_top = top + header_h + h * 0.18
    prompt_bot = bottom - h * 0.22
    prompt_mid = (prompt_top + prompt_bot) / 2
    prompt_left = left + w * 0.14
    prompt_w = w * 0.22
    stroke_w = int(size * 0.055)

    draw.line([(prompt_left, prompt_top), (prompt_left + prompt_w, prompt_mid)], fill=accent_color, width=stroke_w)
    draw.line([(prompt_left + prompt_w, prompt_mid), (prompt_left, prompt_bot)], fill=accent_color, width=stroke_w)

    # 6. Terminal Cursor `_`
    cur_left = prompt_left + prompt_w + w * 0.10
    cur_right = cur_left + w * 0.26
    cur_y = prompt_bot
    draw.line([(cur_left, cur_y), (cur_right, cur_y)], fill=(255, 255, 255, 240), width=stroke_w)

def generate_icons():
    target_size = 1024
    supersample = 2
    size = target_size * supersample
    cx = size // 2
    cy = size // 2

    # Blue Theme Palette
    c_top = hex_to_rgb("#0D47A1")       # Deep Sapphire Blue
    c_bot = hex_to_rgb("#1976D2")       # Vivid Royal Blue
    accent_rgb = hex_to_rgb("#00E5FF")  # Electric Cyan
    dark_term = hex_to_rgb("#0B132B")   # Obsidian Slate

    # --- 1. Master Icon ---
    master = create_vertical_gradient(size, size, c_top, c_bot)
    
    # Outer decorative glow ring
    m_draw = ImageDraw.Draw(master)
    outer_r = int(size * 0.44)
    m_draw.ellipse([cx - outer_r, cy - outer_r, cx + outer_r, cy + outer_r], outline=(255, 255, 255, 40), width=int(size * 0.015))

    # Squircle Container (White Card)
    card_w = int(size * 0.72)
    card_r = int(card_w * 0.26)
    
    # Drop shadow
    shadow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.rounded_rectangle([cx - card_w//2, cy - card_w//2 + 35, cx + card_w//2, cy + card_w//2 + 35], radius=card_r, fill=(0, 0, 0, 100))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=30 * supersample))
    master = Image.alpha_composite(master, shadow)
    
    m_draw = ImageDraw.Draw(master)
    # White Card background
    m_draw.rounded_rectangle([cx - card_w//2, cy - card_w//2, cx + card_w//2, cy + card_w//2], radius=card_r, fill=(255, 255, 255, 255))
    
    # Draw Terminal inside white card
    draw_terminal_symbol(m_draw, cx, cy, card_w * 0.85, (255, 255, 255), dark_term, accent_rgb)

    os.makedirs("assets/icon", exist_ok=True)
    master_1024 = master.resize((target_size, target_size), Image.Resampling.LANCZOS)
    master_1024.save("assets/icon/app_icon.png", "PNG", optimize=True)
    print("Saved assets/icon/app_icon.png")

    # --- 2. Adaptive Icon Background ---
    bg = create_vertical_gradient(target_size, target_size, c_top, c_bot)
    bg.save("assets/icon/app_icon_background.png", "PNG", optimize=True)
    print("Saved assets/icon/app_icon_background.png")

    # --- 3. Adaptive Icon Foreground ---
    fg = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    fg_draw = ImageDraw.Draw(fg)
    
    # Safe area squircle (safe zone 60%)
    safe_w = int(size * 0.54)
    safe_r = int(safe_w * 0.26)
    fg_draw.rounded_rectangle([cx - safe_w//2, cy - safe_w//2, cx + safe_w//2, cy + safe_w//2], radius=safe_r, fill=(255, 255, 255, 255))
    draw_terminal_symbol(fg_draw, cx, cy, safe_w * 0.85, (255, 255, 255), dark_term, accent_rgb)
    
    fg_1024 = fg.resize((target_size, target_size), Image.Resampling.LANCZOS)
    fg_1024.save("assets/icon/app_icon_foreground.png", "PNG", optimize=True)
    print("Saved assets/icon/app_icon_foreground.png")

if __name__ == "__main__":
    generate_icons()
