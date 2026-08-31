import os
import json
import subprocess

def run_query(query):
    result = subprocess.run(['sf.cmd', 'data', 'query', '--query', query, '--json', '-o', 'sandbox_pyatz'], capture_output=True, text=True, encoding='utf-8')
    return json.loads(result.stdout).get('result', {}).get('records', [])

os.makedirs('Plantillas_Sandbox', exist_ok=True)

folders = run_query("SELECT Id, Name, DeveloperName FROM Folder WHERE Type = 'Email' AND Name LIKE 'Pyatz%'")
for f in folders:
    folder_name = f['Name'].replace('/', '_').replace('\\', '_')
    folder_path = os.path.join('Plantillas_Sandbox', folder_name)
    os.makedirs(folder_path, exist_ok=True)
    
    templates = run_query(f"SELECT Name, DeveloperName, HtmlValue, Body FROM EmailTemplate WHERE FolderId = '{f['Id']}'")
    for t in templates:
        template_name = t['Name'].replace('/', '_').replace('\\', '_').replace(':', '_').replace('"', '')
        file_path = os.path.join(folder_path, f"{template_name}.html")
        content = t.get('HtmlValue') or t.get('Body') or ''
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(content)

print("Todas las plantillas han sido descargadas en la carpeta 'Plantillas_Sandbox'.")
