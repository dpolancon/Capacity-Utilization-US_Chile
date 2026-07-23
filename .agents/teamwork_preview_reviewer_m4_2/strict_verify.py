import os
import yaml

root_dir = r"c:\ReposGitHub\Capacity-Utilization-US_Chile"
mandatory_fields = ["type", "status", "depends_on", "stage_scope", "country", "last_updated"]

md_files = []
for dirpath, dirnames, filenames in os.walk(root_dir):
    dirnames[:] = [d for d in dirnames if not d.startswith('.')]
    if ".agents" in dirpath:
        continue
    for f in filenames:
        if f.endswith('.md'):
            rel_path = os.path.relpath(os.path.join(dirpath, f), root_dir).replace('\\', '/')
            md_files.append(rel_path)

print(f"Auditing all {len(md_files)} markdown files...")

pass_count = 0
fail_list = []

for rel_path in md_files:
    full_path = os.path.join(root_dir, rel_path.replace('/', '\\'))
    try:
        with open(full_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        if not content.startswith('---'):
            fail_list.append((rel_path, "Does not start with '---'"))
            continue
        
        parts = content.split('---', 2)
        if len(parts) < 3:
            fail_list.append((rel_path, "Fewer than 2 '---' delimiters"))
            continue
        
        data = yaml.safe_load(parts[1])
        if not isinstance(data, dict):
            fail_list.append((rel_path, "YAML content is not a dict"))
            continue
        
        missing_or_null = []
        for field in mandatory_fields:
            if field not in data:
                missing_or_null.append(f"missing {field}")
            elif data[field] is None or str(data[field]).strip() == "":
                missing_or_null.append(f"null/empty {field}")
        
        if missing_or_null:
            fail_list.append((rel_path, ", ".join(missing_or_null)))
        else:
            pass_count += 1
            
    except Exception as e:
        fail_list.append((rel_path, f"Exception: {str(e)}"))

print(f"Total Scanned: {len(md_files)}")
print(f"Total Passed: {pass_count}")
print(f"Total Failed: {len(fail_list)}")

if fail_list:
    print("\nFAILS:")
    for path, reason in fail_list:
        print(f"  {path}: {reason}")
else:
    print("\nPERFECT PASS: 100% of all 478 markdown files across the repo have all 6 mandatory YAML fields populated with valid non-null values!")
