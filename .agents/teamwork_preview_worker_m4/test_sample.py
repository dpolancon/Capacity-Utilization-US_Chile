import os
import pandas as pd
import yaml

csv_path = r"c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_explorer_m1_3\proposed_yaml_mapping_normalized.csv"
df = pd.read_csv(csv_path)

root = r"c:\ReposGitHub\Capacity-Utilization-US_Chile"
mandatory_keys = ["type", "status", "depends_on", "stage_scope", "country", "last_updated"]

sample_paths = [
    "AGENTS.md",
    "PROJECT.md",
    "chapter2_vault/00_constitutive_core/01_Governing_Memo.md",
    "chapter2_vault/00_constitutive_core/02C_Hypotheses.md",
    "output/_legacy/writing/drafts/sec_2_1_introduction.md"
]

for p in sample_paths:
    row = df[df["Path"].str.replace("\\", "/") == p].iloc[0]
    full_path = os.path.join(root, p.replace("/", "\\"))
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
    
    new_content = header_str + "\n\n" + body_content.lstrip("\r\n")
    
    print(f"=== SAMPLE: {p} ===")
    print(new_content[:400])
    print("...\n")
