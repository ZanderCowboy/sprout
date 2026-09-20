#!/usr/bin/env python3
"""
Generate Play Store listing assets from existing Sprout branding.

Creates:
- icon-512.png (512x512) - resized from sprout-icon-selected-1024.png
- feature-graphic-1024x500.png - feature graphic with logo and text
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

def create_feature_graphic():
    """Create 1024x500 feature graphic with logo and text."""
    print("Creating feature-graphic-1024x500.png...")
    
    if not source_icon.exists():
        print(f"ERROR: Source icon not found at {source_icon}", file=sys.stderr)
        return False
    
    # Create base image with dark green background (Sprout brand colors)
    width, height = 1024, 500
    img = Image.new('RGB', (width, height), color='#1B5E20')  # Dark green
    draw = ImageDraw.Draw(img)
    
    # Load and resize logo (centered-left placement)
    logo = Image.open(source_icon)
    logo_size = 360  # Slightly smaller than height for padding
    logo_resized = logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
    
    # Paste logo on left side, vertically centered
    logo_x = 80
    logo_y = (height - logo_size) // 2
    
    # Handle transparency if present
    if logo_resized.mode == 'RGBA':
        img.paste(logo_resized, (logo_x, logo_y), logo_resized)
    else:
        img.paste(logo_resized, (logo_x, logo_y))
    
    # Add "Sprout" text on the right
    text_x = logo_x + logo_size + 60
    
    # Try to use a nice font, fall back to default if not available
    try:
        # Try common system fonts
        font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 120)
        font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 42)
    except:
        try:
            font_large = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", 120)
            font_small = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf", 42)
        except:
            # Fall back to default
            font_large = ImageFont.load_default()
            font_small = ImageFont.load_default()
    
    # Draw "Sprout" text
    title_y = height // 2 - 80
    draw.text((text_x, title_y), "Sprout", fill='#FFFFFF', font=font_large)
    
    # Draw tagline below
    tagline = "Lush Growth"
    tagline_y = title_y + 140
    draw.text((text_x, tagline_y), tagline, fill='#A5D6A7', font=font_small)  # Light green
    
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
