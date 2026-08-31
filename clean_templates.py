import subprocess
import json

def run_query(org, query):
    cmd = ['sf.cmd', 'data', 'query', '--query', query, '--json', '-o', org]
    result = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8')
    return json.loads(result.stdout).get('result', {}).get('records', [])

# 1. Get Sandbox templates
sb_templates = run_query('sandbox_pyatz', "SELECT DeveloperName, Folder.DeveloperName FROM EmailTemplate WHERE Folder.DeveloperName LIKE 'Pyatz%' OR Folder.DeveloperName = 'Enhorabuena' OR Folder.DeveloperName = 'Membrete_Pyatz_PDF'")
sb_dev_names = {t['DeveloperName'] for t in sb_templates}

# 2. Get Production templates
prod_templates = run_query('produccion_pyatz', "SELECT Id, DeveloperName, Folder.DeveloperName FROM EmailTemplate WHERE Folder.DeveloperName LIKE 'Pyatz%' OR Folder.DeveloperName = 'Enhorabuena' OR Folder.DeveloperName = 'Membrete_Pyatz_PDF'")

# 3. Find the bad ones
bad_ids = []
for t in prod_templates:
    if t['DeveloperName'] not in sb_dev_names:
        bad_ids.append(t['Id'])

# 4. Generate Apex
apex_code = f"List<EmailTemplate> bad = [SELECT Id FROM EmailTemplate WHERE Id IN {bad_ids}];\ndelete bad;\nSystem.debug('Deleted ' + bad.size() + ' templates.');"
# Replace Python list string with Apex list string
apex_code = apex_code.replace("[", "('").replace("]", "')").replace(", ", "', '")
apex_code = apex_code.replace("IN ('')", "IN ('00X000000000000')") # Handle empty case

with open('delete_bad_templates.apex', 'w', encoding='utf-8') as f:
    f.write(apex_code)

print(f"Found {len(bad_ids)} bad templates to delete.")
