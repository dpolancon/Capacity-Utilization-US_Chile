import os
import re
import yaml
import json
import datetime

root_dir = r"c:\ReposGitHub\Capacity-Utilization-US_Chile"
mandatory_fields = ["type", "status", "depends_on", "stage_scope", "country", "last_updated"]

# Collect all md files excluding hidden/agent dirs
md_files = []
dir_breakdown = {}

for dirpath, dirnames, filenames in os.walk(root_dir):
    dirnames[:] = [d for d in dirnames if not d.startswith('.')]
    if ".agents" in dirpath:
        continue
    for f in filenames:
        if f.endswith('.md'):
            rel_path = os.path.relpath(os.path.join(dirpath, f), root_dir).replace('\\', '/')
            md_files.append(rel_path)
            
            top_dir = rel_path.split('/')[0] if '/' in rel_path else 'root'
            dir_breakdown[top_dir] = dir_breakdown.get(top_dir, 0) + 1

print(f"Total markdown files found: {len(md_files)}")
print("Directory breakdown:")
for d, c in sorted(dir_breakdown.items()):
    print(f"  {d}: {c} files")

results = {
    "total": len(md_files),
    "compliant": 0,
    "non_compliant": [],
    "syntax_errors": [],
    "missing_fields": [],
    "null_fields": [],
    "invalid_formats": [],
    "excluded_files_status": {},
    "dir_breakdown": dir_breakdown
}

excluded_files = [
    "chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md",
    "data/metadata/data_provenance_manifest.md"
]

date_regex = re.compile(r'^\d{4}-\d{2}-\d{2}$')

def default_converter(o):
    if isinstance(o, (datetime.date, datetime.datetime)):
        return o.isoformat()
    return str(o)

for rel_path in md_files:
    full_path = os.path.join(root_dir, rel_path.replace('/', '\\'))
    with open(full_path, 'r', encoding='utf-8', errors='ignore') as file:
        content = file.read()
    
    if not content.startswith('---'):
        results["non_compliant"].append((rel_path, "Does not start with '---'"))
        continue
    
    parts = content.split('---', 2)
    if len(parts) < 3:
        results["non_compliant"].append((rel_path, "Unclosed YAML frontmatter (fewer than 2 '---')"))
        continue
    
    yaml_text = parts[1]
    try:
        data = yaml.safe_load(yaml_text)
    except Exception as e:
        results["syntax_errors"].append((rel_path, str(e)))
        continue
    
    if not isinstance(data, dict):
        results["non_compliant"].append((rel_path, "YAML frontmatter is not a dictionary"))
        continue
    
    missing = [field for field in mandatory_fields if field not in data]
    nulls = [field for field in mandatory_fields if field in data and (data[field] is None or str(data[field]).strip() == "")]
    
    invalid = []
    # Check date format
    if "last_updated" in data and data["last_updated"] is not None:
        val = str(data["last_updated"])
        if not date_regex.match(val):
            invalid.append(f"last_updated '{val}' does not match YYYY-MM-DD")
            
    # Check country
    if "country" in data and data["country"] is not None:
        val = str(data["country"])
        valid_countries = ["US", "CL", "US_CL", "none", "all"]
        if val not in valid_countries:
            invalid.append(f"country '{val}' not in recognized set {valid_countries}")

    if rel_path in excluded_files:
        results["excluded_files_status"][rel_path] = {
            "has_yaml": True,
            "missing": missing,
            "nulls": nulls,
            "data": data
        }
    
    if missing:
        results["missing_fields"].append((rel_path, missing))
    elif nulls:
        results["null_fields"].append((rel_path, nulls))
    elif invalid:
        results["invalid_formats"].append((rel_path, invalid))
    else:
        results["compliant"] += 1

print("\n=== INDEPENDENT AUDIT SUMMARY ===")
print(f"Total markdown files scanned: {results['total']}")
print(f"Compliant markdown files: {results['compliant']}")
print(f"Non-compliant (no YAML / format): {len(results['non_compliant'])}")
print(f"YAML syntax errors: {len(results['syntax_errors'])}")
print(f"Missing mandatory fields: {len(results['missing_fields'])}")
print(f"Null mandatory fields: {len(results['null_fields'])}")
print(f"Invalid field formats: {len(results['invalid_formats'])}")

if results["non_compliant"]:
    print("\nNon-compliant files:")
    for f, msg in results["non_compliant"]:
        print(f" - {f}: {msg}")

if results["syntax_errors"]:
    print("\nSyntax error files:")
    for f, err in results["syntax_errors"]:
        print(f" - {f}: {err}")

if results["missing_fields"]:
    print("\nMissing field files:")
    for f, fields in results["missing_fields"]:
        print(f" - {f}: missing {fields}")

if results["null_fields"]:
    print("\nNull field files:")
    for f, fields in results["null_fields"]:
        print(f" - {f}: null {fields}")

if results["invalid_formats"]:
    print("\nInvalid format files:")
    for f, errs in results["invalid_formats"]:
        print(f" - {f}: {errs}")

with open(r"c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_reviewer_m4_2\scan_results.json", "w") as out:
    json.dump(results, out, indent=2, default=default_converter)

print("\nSaved scan_results.json successfully!")
