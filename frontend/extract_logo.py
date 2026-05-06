import base64
import re

try:
    with open('assets/logo.svg', 'r', encoding='utf-8') as f:
        svg = f.read()

    start_token = 'data:image/png;base64,'
    start_idx = svg.find(start_token)
    
    if start_idx == -1:
        print("Could not find base64 image in SVG.")
        exit(1)
        
    start_idx += len(start_token)
    end_idx = svg.find('"', start_idx)
    
    b64 = svg[start_idx:end_idx]
    
    # Remove HTML entity newlines and standard newlines
    b64 = b64.replace('&#10;', '').replace('\n', '').replace('\r', '').replace(' ', '')
    
    # Fix padding
    b64 += '=' * (-len(b64) % 4)
    
    image_data = base64.b64decode(b64)
    
    with open('assets/logo.png', 'wb') as f:
        f.write(image_data)
        
    print("Successfully extracted logo.png!")
except Exception as e:
    print(f"Extraction failed: {e}")
    exit(1)
