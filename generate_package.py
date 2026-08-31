import os
import json
import subprocess

def run_query(query):
    result = subprocess.run(['sf.cmd', 'data', 'query', '--query', query, '--json', '-o', 'sandbox_pyatz'], capture_output=True, text=True, encoding='utf-8')
    try:
        return json.loads(result.stdout).get('result', {}).get('records', [])
    except Exception as e:
        print("Error en query:", query, result.stdout, result.stderr)
        return []

folders = run_query("SELECT DeveloperName FROM Folder WHERE Type = 'Email'")

members_folder = []
members_template = []
for f in folders:
    folder_dev_name = f['DeveloperName']
    if 'Pyatz' in folder_dev_name or 'Enhorabuena' in folder_dev_name:
        members_folder.append(f"<members>{folder_dev_name}</members>")
        
        templates = run_query(f"SELECT DeveloperName FROM EmailTemplate WHERE Folder.DeveloperName = '{folder_dev_name}'")
        for t in templates:
            members_template.append(f"<members>{folder_dev_name}/{t['DeveloperName']}</members>")

xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        {chr(10).join(members_folder)}
        <name>EmailFolder</name>
    </types>
    <types>
        {chr(10).join(members_template)}
        <name>EmailTemplate</name>
    </types>
    <version>60.0</version>
</Package>"""

with open('package_templates.xml', 'w', encoding='utf-8') as file:
    file.write(xml)
print("package_templates.xml generado con éxito.")
