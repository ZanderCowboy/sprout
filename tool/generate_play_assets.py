#!/usr/bin/env python3
"""
Generate Play Store listing assets from existing Sprout branding.

Creates:
- icon-512.png (512x512) - resized from sprout-icon-selected-1024.png
- feature-graphic-1024x500.png - feature graphic with app name + icon on left,
  phone screenshots on right (falls back to icon + text if screenshots missing)

Note: Feature graphic generation works best after capturing phone screenshots:
  ./tool/capture_play_screenshots.sh phone
Then regenerate with this script to include the screenshots in the feature graphic.
"""

import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# Paths
workspace = Path(__file__).parent.parent
source_icon = workspace / "docs/branding/sprout-icon-selected-1024.png"
output_dir = workspace / "store/play"

def create_icon_512():
    """Resize 1024x1024 icon to 512x512."""
    print(f"Creating icon-512.png from {source_icon.name}...")
    
    if not source_icon.exists():
        print(f"ERROR: Source icon not found at {source_icon}", file=sys.stderr)
        return False
    
    img = Image.open(source_icon)
    
    # Resize to 512x512 with high-quality downsampling
    img_512 = img.resize((512, 512), Image.Resampling.LANCZOS)
    
    output_path = output_dir / "icon-512.png"
    img_512.save(output_path, "PNG", optimize=True)
    print(f"✓ Created {output_path}")
    return True

def create_rounded_rect_mask(size, radius):
    """Create a rounded rectangle mask for device mockup."""
    mask = Image.new('L', size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), size], radius=radius, fill=255)
    return mask

def create_feature_graphic():
    """Create 1024x500 feature graphic with app name + icon on left, phone screenshots on right."""
    print("Creating feature-graphic-1024x500.png...")
    
    if not source_icon.exists():
        print(f"ERROR: Source icon not found at {source_icon}", file=sys.stderr)
        return False
    
    # Create base image with dark green background (Sprout brand colors)
    width, height = 1024, 500
    img = Image.new('RGB', (width, height), color='#1B5E20')  # Dark green
    draw = ImageDraw.Draw(img)
    
    # LEFT SIDE: "Sprout" text + icon below
    left_margin = 60
    
    # Try to use a nice font, fall back to default if not available
    try:
        font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 90)
    except:
        try:
            font_large = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", 90)
        except:
            font_large = ImageFont.load_default()
    
    # Draw "Sprout" text at top-left area
    text_y = 80
    draw.text((left_margin, text_y), "Sprout", fill='#FFFFFF', font=font_large)
    
    # Load and resize logo below text
    logo = Image.open(source_icon)
    icon_size = 200
    logo_resized = logo.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    
    # Position icon below text
    icon_x = left_margin
    icon_y = text_y + 120
    
    # Paste icon
    if logo_resized.mode == 'RGBA':
        img.paste(logo_resized, (icon_x, icon_y), logo_resized)
    else:
        img.paste(logo_resized, (icon_x, icon_y))
    
    # RIGHT SIDE: Phone screenshots (if available)
    screenshots_dir = workspace / "store/play/screenshots/phone"
    overview_path = screenshots_dir / "play-overview.png"
    second_screenshot = screenshots_dir / "play-goals.png"
    
    # Fall back to accounts if goals missing
    if not second_screenshot.exists():
        second_screenshot = screenshots_dir / "play-accounts.png"
    
    # Check if we have screenshots to display
    has_screenshots = overview_path.exists() and second_screenshot.exists()
    
    if has_screenshots:
        print("  Using phone screenshots for feature graphic...")
        
        # Load screenshots
        screenshot1 = Image.open(overview_path)
        screenshot2 = Image.open(second_screenshot)
        
        # Calculate scaling to fit nicely in the right side
        # Target: two phone screenshots side by side, with rounded corners like device mockups
        available_width = width - (icon_x + icon_size + 80)  # Space on right side
        screenshot_spacing = 20
        single_screenshot_width = (available_width - screenshot_spacing) // 2
        
        # Scale maintaining aspect ratio
        aspect = screenshot1.height / screenshot1.width
        screenshot_height = int(single_screenshot_width * aspect)
        
        # Limit height to fit in feature graphic with padding
        max_height = height - 80
        if screenshot_height > max_height:
            screenshot_height = max_height
            single_screenshot_width = int(screenshot_height / aspect)
        
        # Resize screenshots
        screen1_resized = screenshot1.resize(
            (single_screenshot_width, screenshot_height), 
            Image.Resampling.LANCZOS
        )
        screen2_resized = screenshot2.resize(
            (single_screenshot_width, screenshot_height), 
            Image.Resampling.LANCZOS
        )
        
        # Convert to RGB if needed (remove alpha)
        if screen1_resized.mode == 'RGBA':
            screen1_rgb = Image.new('RGB', screen1_resized.size, '#1B5E20')
            screen1_rgb.paste(screen1_resized, mask=screen1_resized.split()[3] if len(screen1_resized.split()) > 3 else None)
            screen1_resized = screen1_rgb
        
        if screen2_resized.mode == 'RGBA':
            screen2_rgb = Image.new('RGB', screen2_resized.size, '#1B5E20')
            screen2_rgb.paste(screen2_resized, mask=screen2_resized.split()[3] if len(screen2_resized.split()) > 3 else None)
            screen2_resized = screen2_rgb
        
        # Create rounded corner masks for device mockup effect
        corner_radius = 24
        mask = create_rounded_rect_mask(screen1_resized.size, corner_radius)
        
        # Create temp images with rounded corners
        screen1_rounded = Image.new('RGB', screen1_resized.size, '#1B5E20')
        screen1_rounded.paste(screen1_resized, (0, 0))
        
        screen2_rounded = Image.new('RGB', screen2_resized.size, '#1B5E20')
        screen2_rounded.paste(screen2_resized, (0, 0))
        
        # Position screenshots on right side, vertically centered
        screenshots_start_x = icon_x + icon_size + 80
        screenshots_y = (height - screenshot_height) // 2
        
        screen1_x = screenshots_start_x
        screen2_x = screen1_x + single_screenshot_width + screenshot_spacing
        
        # Add subtle shadow/border effect
        shadow_offset = 3
        for offset in range(shadow_offset, 0, -1):
            alpha = int(30 * (shadow_offset - offset + 1) / shadow_offset)
            shadow_color = (0, 0, 0)
            for sx, sy in [(screen1_x, screenshots_y), (screen2_x, screenshots_y)]:
                draw.rounded_rectangle(
                    [(sx + offset, sy + offset), 
                     (sx + single_screenshot_width + offset, sy + screenshot_height + offset)],
                    radius=corner_radius,
                    fill=shadow_color
                )
        
        # Paste screenshots with rounded corners
        img.paste(screen1_rounded, (screen1_x, screenshots_y), mask)
        img.paste(screen2_rounded, (screen2_x, screenshots_y), mask)
        
    else:
        print(f"  ℹ Phone screenshots not found at {screenshots_dir}/")
        print("  Generating feature graphic without screenshots (icon + text only)")
        print("  Tip: Run ./tool/capture_play_screenshots.sh phone first, then regenerate")
    
    # Save without alpha channel (Play Store requirement)
    output_path = output_dir / "feature-graphic-1024x500.png"
    img.save(output_path, "PNG", optimize=True)
    print(f"✓ Created {output_path}")
    return True

def main():
    # Ensure output directory exists
    output_dir.mkdir(parents=True, exist_ok=True)
    
    success = True
    success &= create_icon_512()
    success &= create_feature_graphic()
    
    if success:
        print("\n✓ All Play Store assets generated successfully!")
        return 0
    else:
        print("\n✗ Some assets failed to generate", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())
