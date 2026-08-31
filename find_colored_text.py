import os
import re

for root, dirs, files in os.walk('Plantillas_Sandbox'):
    for file in files:
        if file.endswith('.html'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                for i, line in enumerate(lines):
                    if 'color:' in line.lower() or 'color=' in line.lower():
                        # filter out black, white, gray, #000000, #ffffff
                        if not re.search(r'color:\s*(?:black|white|gray|#000000|#ffffff|#333333|#666666)', line, re.IGNORECASE):
                            print(f"{file} (L{i+1}): {line.strip()[:100]}")
