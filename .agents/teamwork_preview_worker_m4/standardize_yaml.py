import os
import pandas as pd
import yaml

csv_path = r"c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_explorer_m1_3\proposed_yaml_mapping_normalized.csv"
df = pd.read_csv(csv_path)

root = r"c:\ReposGitHub\Capacity-Utilization-US_Chile"
mandatory_keys = ["type", "status", "depends_on", "stage_scope", "country", "last_updated"]

exclusions = ["Ch2_Outline_DEFINITIVE.md", "data_provenance_manifest.md"]

modified_files = []
skipped_files = []
error_files = []

for idx, row in df.iterrows():
    path_str = str(row["Path"]).replace("\\", "/")
    filename = os.path.basename(path_str)
    
    # Check exclusions
    if any(ex.lower() in filename.lower() for ex in exclusions):
        skipped_files.append((path_str, "Excluded by task instructions"))
        continue
    
    full_path = os.path.join(root, path_str.replace("/", "\\"))
    if not os.path.exists(full_path):
        error_files.append((path_str, "File not found on disk"))
        continue
    
    try:
        with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
        
        extra_yaml = {}
        if content.lstrip().startswith("---"):
            stripped = content.lstrip()
            parts = stripped.split("---", 2)
            if len(parts) >= 3:
                body_content = parts[2]
                try:
                    parsed = yaml.safe_load(parts[1])
                    if isinstance(parsed, dict):
                        extra_yaml = {k: v for k, v in parsed.items() if k not in mandatory_keys and k != "epends_on"}
                except Exception:
                    pass
            else:
                body_content = content
        else:
            body_content = content

        lines = ["---"]
        lines.append(f"type: {row['Type']}")
        lines.append(f"status: {row['Status']}")
        lines.append(f"depends_on: {row['DependsOn']}")
        lines.append(f"stage_scope: {row['StageScope']}")
        lines.append(f"country: {row['Country']}")
        lines.append(f"last_updated: {row['LastUpdated']}")
        
        for k, v in extra_yaml.items():
            dumped = yaml.safe_dump({k: v}, default_flow_style=False).strip()
            lines.append(dumped)
        
        lines.append("---")
        header_str = "\n".join(lines)
        
        cleaned_body = body_content.lstrip("\r\n")
        if cleaned_body.strip():
            new_content = header_str + "\n\n" + cleaned_body
        else:
            new_content = header_str + "\n"
        
        with open(full_path, "w", encoding="utf-8", newline="\n") as f:
            f.write(new_content)
        
        modified_files.append(path_str)
    except Exception as e:
        error_files.append((path_str, str(e)))

print(f"Standardization execution finished.")
print(f"Successfully modified: {len(modified_files)}")
print(f"Skipped (excluded): {len(skipped_files)}")
print(f"Errors: {len(error_files)}")
if error_files:
    print("Error details:", error_files)
