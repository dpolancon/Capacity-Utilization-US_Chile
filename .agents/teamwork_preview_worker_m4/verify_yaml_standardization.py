import os
import glob
import yaml
import pandas as pd

root = r"c:\ReposGitHub\Capacity-Utilization-US_Chile"
csv_path = r"c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_explorer_m1_3\proposed_yaml_mapping_normalized.csv"

mandatory_keys = ["type", "status", "depends_on", "stage_scope", "country", "last_updated"]

# Find all markdown files in repo excluding hidden/agent dirs
target_md_files = []
for r, d, files in os.walk(root):
    if ".agents" in r or ".git" in r or ".claude" in r or ".vscode" in r:
        continue
    for f in files:
        if f.endswith(".md"):
            rel_p = os.path.relpath(os.path.join(r, f), root).replace("\\", "/")
            target_md_files.append(rel_p)

print(f"Total markdown files found in scope: {len(target_md_files)}")

df_csv = pd.read_csv(csv_path)
csv_mapping = {}
for idx, row in df_csv.iterrows():
    p = str(row["Path"]).replace("\\", "/")
    csv_mapping[p] = row

verified_count = 0
excluded_count = 0
failed_files = []

for rel_p in target_md_files:
    if "Ch2_Outline_DEFINITIVE.md" in rel_p or "data_provenance_manifest.md" in rel_p:
        excluded_count += 1
        print(f"Exclusion verified: {rel_p}")
        continue
    
    full_path = os.path.join(root, rel_p.replace("/", "\\"))
    with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()
    
    if not content.startswith("---"):
        failed_files.append((rel_p, "Does not start with ---"))
        continue
    
    parts = content.split("---", 2)
    if len(parts) < 3:
        failed_files.append((rel_p, "Fewer than 2 --- delimiters found"))
        continue
    
    yaml_header_str = parts[1]
    try:
        data = yaml.safe_load(yaml_header_str)
    except Exception as e:
        failed_files.append((rel_p, f"YAML parse error: {e}"))
        continue
    
    if not isinstance(data, dict):
        failed_files.append((rel_p, "Parsed YAML is not a dictionary"))
        continue
    
    missing = [k for k in mandatory_keys if k not in data or data[k] is None]
    if missing:
        failed_files.append((rel_p, f"Missing or null mandatory keys: {missing}"))
        continue
    
    # Check that values match expected mapping values
    expected = csv_mapping.get(rel_p)
    if expected is not None:
        if str(data["type"]) != str(expected["Type"]):
            failed_files.append((rel_p, f"type mismatch: {data['type']} vs {expected['Type']}"))
            continue
        if str(data["status"]) != str(expected["Status"]):
            failed_files.append((rel_p, f"status mismatch: {data['status']} vs {expected['Status']}"))
            continue
        if str(data["stage_scope"]) != str(expected["StageScope"]):
            failed_files.append((rel_p, f"stage_scope mismatch: {data['stage_scope']} vs {expected['StageScope']}"))
            continue
        if str(data["country"]) != str(expected["Country"]):
            failed_files.append((rel_p, f"country mismatch: {data['country']} vs {expected['Country']}"))
            continue
        if str(data["last_updated"]) != str(expected["LastUpdated"]):
            failed_files.append((rel_p, f"last_updated mismatch: {data['last_updated']} vs {expected['LastUpdated']}"))
            continue

    verified_count += 1

print("\n--- VERIFICATION SUMMARY ---")
print(f"Total Markdown Files: {len(target_md_files)}")
print(f"Verified Compliant: {verified_count}")
print(f"Excluded Files: {excluded_count}")
print(f"Failed Verification: {len(failed_files)}")

if failed_files:
    print("\nFAILED FILES:")
    for ff in failed_files:
        print(f" - {ff[0]}: {ff[1]}")
else:
    print("\nALL TARGET MARKDOWN FILES PASS 100% OF VERIFICATION CHECKS!")
