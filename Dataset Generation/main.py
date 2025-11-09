import os
import random
from PIL import Image, ImageDraw, ImageFont

# --- 1. CONFIGURATION ---

# Define the directory where custom TTF/OTF fonts are located.
FONT_DIRECTORY = "fonts"

# Define the path to the file containing the words.
WORDS_FILE = "words.txt"

# Define image dimensions (now expecting multiple lines)
IMAGE_WIDTH = 1024
IMAGE_HEIGHT = 256
FONT_SIZE = 48

# Define the output directory.
OUTPUT_DIR = "TrainingDataTextBlocks"

# --- TEXT BLOCK CONFIGURATION ---
# Set the maximum number of words to consider for a single image block.
MAX_WORDS_PER_BLOCK = 24
# Set the maximum number of lines allowed in a single image.
MAX_LINES_PER_IMAGE = 5
# Set how often to process a block of words.
# 1: Process every block.
# 50: Process every fiftieth block (49 skips between processed blocks).
BLOCK_SKIP_INTERVAL = 50

# Define text drawing parameters
TEXT_COLOR = 'black'
BACKGROUND_COLOR = 'white'
# Spacing between lines (in pixels)
LINE_SPACING = 5
# Margin from the left edge of the image
LEFT_MARGIN = 10


# --- 2. HELPER FUNCTIONS ---

def load_words(file_path):
    """Reads words from a file, stripping whitespace and empty lines."""
    if not os.path.exists(file_path):
        print(f"Error: Words file not found at {file_path}")
        return []
    
    with open(file_path, 'r') as f:
        words = [line.strip() for line in f if line.strip()]
    return words

def sanitize_filename(text, max_length=50):
    """Creates a safe, short filename from a string of text."""
    safe_text = "".join(c for c in text if c.isalnum() or c in (' ', '_', '-')).strip()
    return safe_text.replace(' ', '_')[:max_length]

def wrap_text(words, font, max_width, max_lines, line_spacing):
    """
    Groups a list of words into lines based on maximum width and line count.

    Returns:
        tuple: (list of line strings, estimated total height of the wrapped text, words used)
    """
    lines = []
    current_line = []
    current_x = LEFT_MARGIN
    words_used = 0

    # Use a temporary draw object to measure text
    temp_img = Image.new('RGB', (1, 1))
    temp_draw = ImageDraw.Draw(temp_img)

    # Estimate height of a single line for total height calculation
    try:
        # Get height using textbbox
        bbox = temp_draw.textbbox((0, 0), "H", font=font)
        line_height_base = bbox[3] - bbox[1]
    except Exception:
        line_height_base = FONT_SIZE * 1.2
        
    line_height = line_height_base + line_spacing

    for word in words:
        # Measure the width of the word plus a space (to estimate spacing between words)
        word_with_space = word + " "
        
        bbox = temp_draw.textbbox((0, 0), word_with_space, font=font)
        word_width = bbox[2] - bbox[0]
        
        # Check if adding the word exceeds the image width
        if current_x + word_width > max_width:
            # Check if we have hit the max line limit
            if len(lines) >= max_lines:
                break # Stop adding words
                
            # Finish current line and start a new one
            lines.append(" ".join(current_line))
            current_line = [word]
            current_x = LEFT_MARGIN + word_width
            words_used += 1
        else:
            # Add word to the current line
            current_line.append(word)
            current_x += word_width
            words_used += 1

    # Add the last remaining line if it's not empty
    if current_line and len(lines) < max_lines:
        lines.append(" ".join(current_line))
        
    # Calculate total height
    # Subtract one LINE_SPACING because the last line doesn't need space below it for the next line
    total_height = len(lines) * line_height - (LINE_SPACING if lines else 0)
    
    return lines, total_height, words_used


# --- 3. DYNAMIC FONT LOADING ---

def load_fonts_from_directory(directory):
    """
    Scans the specified directory for .ttf and .otf font files and returns
    a dictionary mapping the cleaned filename (without extension) to the full path.
    """
    font_map = {}
    if not os.path.isdir(directory):
        print(f"Warning: Font directory '{directory}' not found. Only system fonts (if specified) will be used.")
        return font_map
        
    for filename in os.listdir(directory):
        if filename.lower().endswith(('.ttf', '.otf')):
            font_path = os.path.join(directory, filename)
            # Use the font name without extension as the key
            font_name_key = os.path.splitext(filename)[0]
            font_map[font_name_key] = font_path
            
    return font_map

# Load dynamic fonts
DYNAMIC_FONTS = load_fonts_from_directory(FONT_DIRECTORY)

# Pre-populate the master list with dynamic fonts and any desired system defaults
FONTS_TO_GENERATE = DYNAMIC_FONTS.copy()

# Example: Add system fonts if they exist (optional, but keeps existing capability)
SYSTEM_FALLBACKS = {
    "Helvetica": "/System/Library/Fonts/Helvetica.ttc",
    "TimesNewRoman_Fallback": "/System/Library/Fonts/Supplemental/Times New Roman.ttf",
    "CourierNew_Fallback": "/System/Library/Fonts/Supplemental/Courier New.ttf",
}

for name, path in SYSTEM_FALLBACKS.items():
    if os.path.exists(path) and name not in FONTS_TO_GENERATE:
        FONTS_TO_GENERATE[name] = path


if not FONTS_TO_GENERATE:
    print("Error: No fonts found in the 'fonts' directory and no system fallbacks were loaded. Exiting script.")
    exit()

print(f"Loaded {len(FONTS_TO_GENERATE)} font files for processing.")

# --- 4. SCRIPT EXECUTION ---

# Load the list of words.
WORDS_TO_GENERATE = load_words(WORDS_FILE)

if not WORDS_TO_GENERATE:
    print("No words loaded. Exiting script.")
    exit()

# Randomize the list of words for better diversity
random.shuffle(WORDS_TO_GENERATE)
print(f"Loaded and randomized {len(WORDS_TO_GENERATE)} words from {WORDS_FILE}.")

# Create the main output directory if it doesn't exist.
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)
    print(f"Created directory: {OUTPUT_DIR}")

# Main loop to generate images.
for font_name, font_path in FONTS_TO_GENERATE.items():
    print(f"\n--- Generating data for font: {font_name} ({BLOCK_SKIP_INTERVAL} skip interval) ---")

    font_dir = os.path.join(OUTPUT_DIR, font_name)
    if not os.path.exists(font_dir):
        os.makedirs(font_dir)

    # Load the font file.
    try:
        font = ImageFont.truetype(font_path, FONT_SIZE)
    except IOError:
        print(f"Error: Could not load font at {font_path}. Skipping.")
        continue
    except Exception as e:
        print(f"An unexpected error occurred loading font {font_name}: {e}. Skipping.")
        continue

    processed_image_count = 0
    current_block_index = 0
    
    i = 0
    while i < len(WORDS_TO_GENERATE):
        
        # --- Block Skipping Logic ---
        if current_block_index % BLOCK_SKIP_INTERVAL != 0:
            # Skip this block. We must advance 'i' by MAX_WORDS_PER_BLOCK
            # to ensure these words aren't accidentally used in the next eligible block.
            i += MAX_WORDS_PER_BLOCK
            current_block_index += 1
            continue
        # --- END Block Skipping Logic ---

        # 1. Get the chunk of words for the potential block
        current_block_words = WORDS_TO_GENERATE[i:i + MAX_WORDS_PER_BLOCK]
        
        if not current_block_words:
            break

        # 2. Wrap the words into lines
        wrapped_lines, total_height, words_used_in_wrap = wrap_text(
            current_block_words,
            font,
            IMAGE_WIDTH - LEFT_MARGIN,
            MAX_LINES_PER_IMAGE,
            LINE_SPACING
        )
        
        if not wrapped_lines or words_used_in_wrap == 0:
            # If wrap_text failed to create any lines or used 0 words
            i += 1
            current_block_index += 1
            continue

        # 3. Create and draw the image
        img = Image.new('RGB', (IMAGE_WIDTH, IMAGE_HEIGHT), color=BACKGROUND_COLOR)
        draw = ImageDraw.Draw(img)
        
        # Calculate the height of a single line for drawing
        try:
            bbox = draw.textbbox((0, 0), "H", font=font)
            line_base_height = bbox[3] - bbox[1]
        except Exception:
            line_base_height = FONT_SIZE * 1.2

        # Center vertically
        y_offset = (IMAGE_HEIGHT - total_height) / 2

        # Draw each line of text
        for line_index, line in enumerate(wrapped_lines):
            # Calculate the drawing position for the top-left of the line
            y_position = y_offset + line_index * (line_base_height + LINE_SPACING)
            
            # Use anchor='ls' (left-start) which often aligns better with PIL's default drawing logic for baseline alignment
            draw.text((LEFT_MARGIN, y_position), line, font=font, fill=TEXT_COLOR, anchor='ls')
            
        
        # 4. Save the image
        
        # Create a filename
        first_line_snippet = sanitize_filename(wrapped_lines[0])
        # Include the word index 'i' and the skip interval count to help track generation
        image_filename = f"skip{BLOCK_SKIP_INTERVAL}_{i:04d}_{first_line_snippet}.png"

        image_path = os.path.join(font_dir, image_filename)
        img.save(image_path)
        
        processed_image_count += 1
        
        # Advance the index 'i' by the number of words actually used in this image
        i += words_used_in_wrap
        current_block_index += 1
        
    print(f"Finished generating {processed_image_count} images for {font_name}.")

print("\n--- All done! Your text block training data is ready in the 'TrainingDataTextBlocks' directory. ---")
