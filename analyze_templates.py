import os
import re

merge_field_pattern = re.compile(r'\{!([^}]+)\}')
template_data = {}

for root, dirs, files in os.walk('Plantillas_Sandbox'):
    folder_name = os.path.basename(root)
    if folder_name == 'Plantillas_Sandbox': continue
    
    for file in files:
        if file.endswith('.html'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
                fields = merge_field_pattern.findall(content)
                if fields:
                    if folder_name not in template_data:
                        template_data[folder_name] = {}
                    # Deduplicate and sort fields
                    template_data[folder_name][file] = sorted(list(set(fields)))

for folder, templates in template_data.items():
    print(f"\n--- CARPETA: {folder} ---")
    for t_name, fields in templates.items():
        print(f"  Plantilla: {t_name}")
        for field in fields:
            print(f"    - {field}")
