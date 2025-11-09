# ML Training Fontface Dataset Generation

## About

Dataset generation to generate large quantity of fontface data for ML training

## Usage

### Populate `fonts` folder

Download and add into the `fonts` folder your desired font files in `.ttf` format.

### Dependencies

```bash
# Install image manipulation dependencies
pip install pillow
```

### Run the script

```
python3 ./main.py
```

This will output the training data in `CreateML`-compatible format, ready for training.



## Configuration

In the code exists magic constants for adjusting words per image, skip intervals to restrain output data count, as well as image dimensions for size control.
