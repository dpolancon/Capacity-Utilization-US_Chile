import os
import re

baseline_path = "_editing_ai_detrace/submission_parallel/4_2/01_BASELINE_SECTION4.tex"
candidate_path = "_editing_ai_detrace/submission_parallel/4_2/02_CANDIDATE_4_2.tex"

with open(baseline_path, "r", encoding="utf-8") as f:
    b_lines = f.readlines()

with open(candidate_path, "r", encoding="utf-8") as f:
    c_lines = f.readlines()

print(f"Baseline lines: {len(b_lines)}")
print(f"Candidate lines: {len(c_lines)}")

# 1. Whole-file invariance outside Section 4.2
# Section 4.2 spans lines 685 to 813 in baseline (0-indexed 684 to 812)
b_before = "".join(b_lines[:684])
c_before = "".join(c_lines[:684])
assert b_before == c_before, "FAIL: lines before Section 4.2 differ!"
print("PASS: All lines before Section 4.2 (1-684) are byte-for-byte identical.")

# Find matching point after Section 4.2
# Line 814 in baseline is blank, line 815 is \begin{figure}[h!]
# Let's check from line 813 onwards in baseline
b_after = "".join(b_lines[813:])
# In candidate, let's find the figure line
fig_line_idx = None
for idx, line in enumerate(c_lines):
    if "\\begin{figure}[h!]" in line and idx > 750:
        fig_line_idx = idx
        break

assert fig_line_idx is not None, "Could not find figure line in candidate"
c_after = "".join(c_lines[fig_line_idx - 1:]) # including blank line
assert b_after == c_after, "FAIL: lines after Section 4.2 differ!"
print(f"PASS: All lines after Section 4.2 (from line 814 baseline to end) are byte-for-byte identical.")

# 2. Check KEEP paragraphs in Section 4.2
# CH2-S04.02.01-P006: line 709 in baseline
p006_b = b_lines[708]
assert p006_b in "".join(c_lines), "FAIL: CH2-S04.02.01-P006 modified in candidate!"
print("PASS: CH2-S04.02.01-P006 (KEEP) is byte-for-byte identical.")

# CH2-S04.02.01-P007: line 711 in baseline
p007_b = b_lines[710]
assert p007_b in "".join(c_lines), "FAIL: CH2-S04.02.01-P007 modified in candidate!"
print("PASS: CH2-S04.02.01-P007 (KEEP) is byte-for-byte identical.")

# CH2-S04.02.02-P005: lines 792-798 in baseline (0-indexed 791-798)
p005_cl_b = "".join(b_lines[791:798])
assert p005_cl_b in "".join(c_lines), "FAIL: CH2-S04.02.02-P005 modified in candidate!"
print("PASS: CH2-S04.02.02-P005 (KEEP) is byte-for-byte identical.")

# Check all figures/tables inside Section 4.2
# Table tab_us_stylized_facts_summary: line 699 in baseline
assert b_lines[698] in "".join(c_lines)
# Figures 713-768 in baseline
fig_block_us_b = "".join(b_lines[712:768])
assert fig_block_us_b in "".join(c_lines)
# Table tab_cl_stylized_facts_summary: line 775 in baseline
assert b_lines[774] in "".join(c_lines)
print("PASS: All embedded tables and figure blocks in Section 4.2 are byte-for-byte identical.")

from build_candidate import targets

def extract_citations(text):
    return re.findall(r'\\cite[a-z]*\{([^}]+)\}', text)

def extract_numbers(text):
    # strip citations and latex commands first
    t = re.sub(r'\\[a-zA-Z]+(\{[^}]*\})?', ' ', text)
    # find numbers, percentages, years, decimals
    return re.findall(r'\b\d+(?:\.\d+)?%?\b', text)

def extract_math(text):
    return re.findall(r'\$[^$]+\$', text)

def extract_refs(text):
    return re.findall(r'\\ref\{([^}]+)\}', text)

def clean_prose(text):
    # Strip latex commands, comments, math delimiters
    t = re.sub(r'%.*?\n', ' ', text)
    t = re.sub(r'\\[a-zA-Z]+\*?(?:\[[^\]]*\])?(?:\{([^}]*)\})?', r' \1 ', t)
    t = re.sub(r'[\$\{\}\\_]', ' ', t)
    t = re.sub(r'\s+', ' ', t).strip()
    return t

print("\n" + "="*80)
print(f"{'ID':<20} | {'Orig W (raw)':<12} | {'Cand W (raw)':<12} | {'Δ W':<8} | {'Δ %':<8} | Citations | Numbers | Math | Refs")
print("="*80)

total_orig_clean = 0
total_cand_clean = 0
total_orig_raw = 0
total_cand_raw = 0

audit_results = {}

for pid, (orig, cand) in targets.items():
    orig_clean = clean_prose(orig)
    cand_clean = clean_prose(cand)
    orig_cw = len(orig_clean.split())
    cand_cw = len(cand_clean.split())
    orig_rw = len(orig.split())
    cand_rw = len(cand.split())
    
    total_orig_clean += orig_cw
    total_cand_clean += cand_cw
    total_orig_raw += orig_rw
    total_cand_raw += cand_rw
    
    delta_w = cand_cw - orig_cw
    delta_pct = (delta_w / orig_cw) * 100 if orig_cw else 0
    
    # Check citations
    c_orig = extract_citations(orig)
    c_cand = extract_citations(cand)
    c_pass = sorted(c_orig) == sorted(c_cand)
    
    # Check math
    m_orig = extract_math(orig)
    m_cand = extract_math(cand)
    m_pass = sorted(m_orig) == sorted(m_cand)
    
    # Check refs
    r_orig = extract_refs(orig)
    r_cand = extract_refs(cand)
    r_pass = sorted(r_orig) == sorted(r_cand)
    
    # Check numbers
    n_orig = extract_numbers(orig)
    n_cand = extract_numbers(cand)
    n_pass = sorted(n_orig) == sorted(n_cand)
    
    print(f"{pid:<20} | {orig_cw} ({orig_rw}){'':<4} | {cand_cw} ({cand_rw}){'':<4} | {delta_w:<8} | {delta_pct:>6.1f}% | {str(c_pass):<9} | {str(n_pass):<7} | {str(m_pass):<4} | {str(r_pass)}")
    
    audit_results[pid] = {
        "orig_cw": orig_cw, "cand_cw": cand_cw, "delta_cw": delta_w, "pct_cw": delta_pct,
        "orig_rw": orig_rw, "cand_rw": cand_rw, "delta_rw": cand_rw - orig_rw,
        "c_pass": c_pass, "c_orig": c_orig, "c_cand": c_cand,
        "n_pass": n_pass, "n_orig": n_orig, "n_cand": n_cand,
        "m_pass": m_pass, "m_orig": m_orig, "m_cand": m_cand,
        "r_pass": r_pass, "r_orig": r_orig, "r_cand": r_cand,
        "orig_text": orig, "cand_text": cand
    }

print("="*80)
total_delta_clean = total_cand_clean - total_orig_clean
total_pct_clean = (total_delta_clean / total_orig_clean) * 100
total_delta_raw = total_cand_raw - total_orig_raw
total_pct_raw = (total_delta_raw / total_orig_raw) * 100
print(f"TOTAL CLEAN WORDS: {total_orig_clean} -> {total_cand_clean} ({total_delta_clean}, {total_pct_clean:.1f}%)")
print(f"TOTAL RAW TOKENS:  {total_orig_raw} -> {total_cand_raw} ({total_delta_raw}, {total_pct_raw:.1f}%)")
