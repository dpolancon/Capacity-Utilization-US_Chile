import hashlib
from pathlib import Path

repo_dir = Path(r"C:\ReposGitHub\Capacity-Utilization-US_Chile\chapter2_paper\Chapter2_3.0")
active_sec5 = repo_dir / "section5.tex"
base_file = repo_dir / "_editing_ai_detrace" / "phase2_exp01_section5" / "01_BASELINE_SECTION5.tex"

with open(base_file, 'r', encoding='utf-8') as f:
    base_lines = f.readlines()

with open(active_sec5, 'r', encoding='utf-8') as f:
    active_lines = f.readlines()

print(f"Base lines count: {len(base_lines)}")
print(f"Active lines count: {len(active_lines)}")
assert len(base_lines) == len(active_lines) == 40

line_to_desc = {
    4: "CH2-S05-P001",
    6: "CH2-S05-P002",
    9: "CH2-S05-P003",
    21: "CH2-S05-P004",
    24: "CH2-S05-P005",
    26: "CH2-S05-P006",
    29: "CH2-S05-P007",
    31: "CH2-S05-P008",
    33: "CH2-S05-P009",
    35: "CH2-S05-P010",
    37: "HEADING_P012 (\\paragraph{Synthesis: Dead Labour Across the Global Divide.})",
    38: "CH2-S05-P011",
    40: "CH2-S05-P012",
}

authorized_diff_lines = {4, 6, 21, 26, 31, 35, 37, 40}

differing_lines = []
for idx, (b, a) in enumerate(zip(base_lines, active_lines)):
    line_num = idx + 1
    if b != a:
        desc = line_to_desc.get(line_num, f"Line {line_num}")
        differing_lines.append((line_num, desc))
        print(f"Diff at line {line_num} [{desc}]:")
        print(f"  BASE  : {b[:75]}...")
        print(f"  ACTIVE: {a[:75]}...")

diff_set = set(ln for ln, _ in differing_lines)
assert diff_set == authorized_diff_lines, f"Mismatch in diff set: {diff_set} vs expected {authorized_diff_lines}"
print("\n[VERIFIED] Differences occur ONLY in authorized lines: 4, 6, 21, 26, 31, 35, 37, 40.")

# Verify byte-for-byte identity of protected paragraphs
protected_paragraphs = {
    9: "CH2-S05-P003",
    24: "CH2-S05-P005",
    29: "CH2-S05-P007",
    33: "CH2-S05-P009",
    38: "CH2-S05-P011",
}

for ln, pid in protected_paragraphs.items():
    assert base_lines[ln-1] == active_lines[ln-1], f"Mismatch in protected paragraph {pid} at line {ln}!"
    print(f"[VERIFIED] {pid} (line {ln}): 100% byte-for-byte identical")

# Verify Figure environment (lines 11-19, 1-indexed)
for ln in range(11, 20):
    assert base_lines[ln-1] == active_lines[ln-1], f"Mismatch in Figure environment at line {ln}!"
print("[VERIFIED] Figure 5 environment (lines 11-19): 100% byte-for-byte identical")

# Verify all other lines (headings, blank lines)
for ln in range(1, 41):
    if ln not in authorized_diff_lines:
        assert base_lines[ln-1] == active_lines[ln-1], f"Unauthorized difference at line {ln}!"
print("[VERIFIED] All other lines (lines 1-3, 5, 7-8, 10, 20, 22-23, 25, 27-28, 30, 32, 34, 36, 39): 100% byte-for-byte identical")
