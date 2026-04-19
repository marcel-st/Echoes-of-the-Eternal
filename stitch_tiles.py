import os
from PIL import Image
import math

# --- CONFIGURATION ---
TILE_SIZE = 16  # Kenney Tiny sets are 16x16
SOURCE_FOLDER = "assets/raw_tiles"  # Put your chosen PNGs here
OUTPUT_ATLAS = "assets/kenney_custom_atlas.png"
OUTPUT_MAPPING = "assets/mapping.txt"
COLUMNS = 10  # How many tiles wide the grid should be
# ---------------------

def create_atlas():
    # Get all PNG files from the source folder
    files = [f for f in os.listdir(SOURCE_FOLDER) if f.endswith('.png')]
    files.sort() # Ensure consistent ordering

    if not files:
        print(f"No PNG files found in {SOURCE_FOLDER}!")
        return

    # Calculate atlas dimensions
    num_tiles = len(files)
    rows = math.ceil(num_tiles / COLUMNS)
    atlas_width = COLUMNS * TILE_SIZE
    atlas_height = rows * TILE_SIZE

    # Create the blank atlas image (RGBA for transparency)
    atlas = Image.new("RGBA", (atlas_width, atlas_height), (0, 0, 0, 0))
    
    mapping = []

    for index, filename in enumerate(files):
        # Calculate grid position
        col = index % COLUMNS
        row = index // COLUMNS
        
        # Open tile and paste into atlas
        tile_path = os.path.join(SOURCE_FOLDER, filename)
        with Image.open(tile_path) as img:
            # Ensure tile is the right size
            if img.size != (TILE_SIZE, TILE_SIZE):
                img = img.resize((TILE_SIZE, TILE_SIZE), Image.NEAREST)
            
            atlas.paste(img, (col * TILE_SIZE, row * TILE_SIZE))
        
        # Record the mapping
        mapping.append(f"{filename} -> Grid Coord: ({col}, {row})")

    # Save results
    atlas.save(OUTPUT_ATLAS)
    with open(OUTPUT_MAPPING, "w") as f:
        f.write("\n".join(mapping))

    print(f"Successfully created {OUTPUT_ATLAS}")
    print(f"Mapping saved to {OUTPUT_MAPPING}")

if __name__ == "__main__":
    create_atlas()
