import os
import shutil
import csv
import unicodedata
import string

source_dir = r"C:\Users\crist\Downloads\Firmas"
deploy_dir = r"C:\Users\crist\OneDrive\Documentos\Salesforce Technovalue Job\DeploySignatures"
sr_dir = os.path.join(deploy_dir, "staticresources")

if os.path.exists(deploy_dir):
    shutil.rmtree(deploy_dir)
os.makedirs(sr_dir)

def normalize_text(text):
    text = unicodedata.normalize('NFD', text).encode('ascii', 'ignore').decode('utf-8')
    text = text.upper()
    for p in string.punctuation:
        text = text.replace(p, ' ')
    return ' '.join(text.split())

# Load users
users = []
with open(r"C:\Users\crist\OneDrive\Documentos\Salesforce Technovalue Job\PyatProd\users.csv", encoding="utf-16") as f:
    reader = csv.reader(f)
    next(reader) # skip header
    for row in reader:
        if row:
            users.append((row[0], normalize_text(row[0])))

# We also have existing static resources we might want to match exact names if already deployed.
# But for now, let's just create the SR name by replacing spaces with underscores in the normalized full name.
def get_sr_name(full_name):
    # E.g. "CRUZ VEGA CARLOS ERNESTO" -> "CRUZ_VEGA_CARLOS_ERNESTO"
    # Wait, the controller just needs the SR name to contain all words of the user name.
    # The existing ones are named exactly like the user's name with underscores.
    return normalize_text(full_name).replace(' ', '_')

# Match
for file_name in os.listdir(source_dir):
    if not file_name.lower().endswith(".png"): continue
    
    # clean file name for matching
    clean_name = file_name.upper().replace(".PNG", "").replace("F.", "").replace("F ", "").strip()
    words = clean_name.split()
    
    best_match = None
    best_score = 0
    for real_name, norm_name in users:
        score = sum(1 for w in words if w in norm_name)
        if score > best_score:
            best_score = score
            best_match = real_name
            
    if best_match:
        print(f"Matched: '{file_name}' -> '{best_match}'")
        sr_name = get_sr_name(best_match)
        
        # Copy file
        src_path = os.path.join(source_dir, file_name)
        dst_path = os.path.join(sr_dir, f"{sr_name}.resource")
        shutil.copy(src_path, dst_path)
        
        # Create meta.xml
        meta_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<StaticResource xmlns="http://soap.sforce.com/2006/04/metadata">
    <cacheControl>Public</cacheControl>
    <contentType>image/png</contentType>
    <description>Firma {best_match}</description>
</StaticResource>'''
        with open(dst_path + "-meta.xml", "w", encoding="utf-8") as f:
            f.write(meta_content)
    else:
        print(f"WARNING: Could not match {file_name}")

# Create package.xml
package_xml = '''<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>*</members>
        <name>StaticResource</name>
    </types>
    <version>67.0</version>
</Package>'''
with open(os.path.join(deploy_dir, "package.xml"), "w", encoding="utf-8") as f:
    f.write(package_xml)

print("Ready to deploy!")
