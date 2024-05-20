import os
from PIL import Image

def convert_to_webp(image_path, webp_path):
    with Image.open(image_path) as img:
        img.save(webp_path, 'webp')

def convert_to_avif(image_path, avif_path):
    with Image.open(image_path) as img:
        img.save(avif_path, 'avif')

def convert_images(base_dir):
    for root, _, files in os.walk(base_dir):
        for file in files:
            if file.lower().endswith(('.png', '.jpg', '.jpeg')):
                image_path = os.path.join(root, file)
                webp_path = os.path.splitext(image_path)[0] + '.webp'
                avif_path = os.path.splitext(image_path)[0] + '.avif'

                print(f'Converting {image_path} to {webp_path} and {avif_path}')
                convert_to_webp(image_path, webp_path)
                convert_to_avif(image_path, avif_path)

if __name__ == "__main__":
    base_dir = '.'
    convert_images(base_dir)
