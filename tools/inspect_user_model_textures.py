"""Make a contact sheet of the user-supplied texture maps."""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
for role in ['japanese', 'volunteer']:
    paths = sorted(p for p in (root / 'AssetLibrary/characters/user_models_20261015' / role).iterdir()
                   if p.suffix.lower() in ['.png', '.jpg', '.tga', '.dds'])
    sheet = Image.new('RGB', (1000, ((len(paths) + 3) // 4) * 280), '#353a3d')
    draw = ImageDraw.Draw(sheet)
    for i, path in enumerate(paths):
        with Image.open(path) as source:
            image = source.convert('RGB')
            image.thumbnail((244, 242))
            x, y = i % 4 * 250, i // 4 * 280
            sheet.paste(image, (x + (250 - image.width) // 2, y))
            draw.text((x + 5, y + 247), path.stem[-9:] + path.suffix, fill='white')
            draw.text((x + 5, y + 262), str(source.size), fill='white')
    sheet.save(root / 'docs/user-models-20261015' / role / 'texture-sheet.jpg')
