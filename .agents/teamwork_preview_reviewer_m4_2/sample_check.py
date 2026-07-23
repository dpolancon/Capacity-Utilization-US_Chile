import os
import yaml

root_dir = r"c:\ReposGitHub\Capacity-Utilization-US_Chile"
mandatory_fields = ["type", "status", "depends_on", "stage_scope", "country", "last_updated"]

sample_files = [
    "AGENTS.md",
    "chapter2_vault/00_constitutive_core/01A_Design_vs_Presentation_Firewall.md",
    "chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md"
]

for rel_path in sample_files:
    full_path = os.path.join(root_dir, rel_path.replace('/', '\\'))
    with open(full_path, 'r', encoding='utf-8') as f:
        content = f.read()
    parts = content.split('---', 2)
    data = yaml.safe_load(parts[1])
    print(f"=== {rel_path} ===")
    print("YAML Keys:", list(data.keys()))
    print("Content preview (first 150 chars of body):")
    print(repr(parts[2][:150]))
    print()
