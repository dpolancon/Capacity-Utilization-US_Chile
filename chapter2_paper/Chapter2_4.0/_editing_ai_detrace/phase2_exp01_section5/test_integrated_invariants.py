import re
from pathlib import Path
from collections import Counter

base_file = Path(r"C:\ReposGitHub\Capacity-Utilization-US_Chile\chapter2_paper\Chapter2_3.0\_editing_ai_detrace\phase2_exp01_section5\01_BASELINE_SECTION5.tex")
cand_file = Path(r"C:\ReposGitHub\Capacity-Utilization-US_Chile\chapter2_paper\Chapter2_3.0\_editing_ai_detrace\phase2_exp01_section5\02_CANDIDATE_SECTION5.tex")

with open(base_file, 'r', encoding='utf-8') as f:
    base_lines = f.readlines()

with open(cand_file, 'r', encoding='utf-8') as f:
    cand_lines = f.readlines()

# P004 amendments
p004_text = cand_lines[20]
p004_text = p004_text.replace("This higher amplitude directly tracks", "This higher amplitude tracks")
p004_text = p004_text.replace("severe macro-historical trough", "macroeconomic trough")
p004_text = p004_text.replace("radically divergent regime shifts", "divergent regime shifts")

# P006 revisions
p006_text = cand_lines[25]
target_p006_mid = "The Federal Reserve Board data left the physical conversion of accumulation into capacity unexamined. Here, $\\mu_t$ is evaluated as an endogenous residual of $\\theta_t$."
repl_p006_mid = "The Federal Reserve Board utilization series does not identify the physical conversion of accumulation into capacity. Here, $\\mu_t$ is instead recovered as an endogenous residual of $\\theta_t$."
p006_text = p006_text.replace(target_p006_mid, repl_p006_mid)

target_p006_end = "The center's idle capacity records secular stagnation after financialization and its shift toward the predominance of intangible-asset accumulation \\citep{Rikap2021, Rotta2018}."
repl_p006_end = "Persistent idle capacity therefore accompanies the post-Fordist shift toward financialization and the growing weight of intangible-asset accumulation \\citep{Rikap2021, Rotta2018}."
p006_text = p006_text.replace(target_p006_end, repl_p006_end)

repl_heading = "\\paragraph{Synthesis: Dead Labour Across the Global Divide.}\n"
p012_text = "The dead labour embedded in under-utilized productive capacities is crystallized past labour denied the living labour necessary for its valorization. In the center, this idleness accompanies the dismantling of a domestic social settlement in the name of profitability and financialized rent extraction; in the periphery, it reflects an asymmetrical global order that conditions growth on structural subordination. In both cases, accumulated capital remains physically present while the conditions for its reproduction are impaired."
if cand_lines[39].endswith('\n'):
    p012_text += '\n'

integrated_lines = list(base_lines)
integrated_lines[3] = cand_lines[3]
integrated_lines[5] = cand_lines[5]
integrated_lines[20] = p004_text
integrated_lines[25] = p006_text
integrated_lines[30] = cand_lines[30]
integrated_lines[34] = cand_lines[34]
integrated_lines[36] = repl_heading
integrated_lines[39] = p012_text

target_lines = {
    "CH2-S05-P001": 4,
    "CH2-S05-P002": 6,
    "CH2-S05-P004": 21,
    "CH2-S05-P006": 26,
    "CH2-S05-P008": 31,
    "CH2-S05-P010": 35,
    "CH2-S05-P012": 40,
}

def extract_citations(text):
    cites = []
    for m in re.finditer(r'\\cite[pt]?\{([^}]+)\}', text):
        keys = [k.strip() for k in m.group(1).split(',')]
        cites.extend(keys)
    return sorted(cites)

def extract_math(text):
    maths = re.findall(r'\$([^$]+)\$', text)
    return sorted([m.strip() for m in maths])

def extract_numbers(text):
    nums = re.findall(r'(?:\d+\.\d+|\d+)%?', text)
    return sorted(nums)

def extract_years(text):
    years = re.findall(r'\b(19\d\d|20\d\d)\b', text)
    return sorted(years)

def extract_fig_refs(text):
    refs = re.findall(r'\\ref\{([^}]+)\}', text)
    return sorted(refs)

def word_count(text):
    cleaned = re.sub(r'\\[a-zA-Z]+(?:\[[^\]]*\])?(?:\{[^}]*\})?', ' ', text)
    cleaned = re.sub(r'\$[^$]*\$', ' ', cleaned)
    cleaned = re.sub(r'[{}\\%~]', ' ', cleaned)
    words = [w for w in cleaned.split() if w.strip()]
    return len(words)

def raw_word_count(text):
    return len(text.split())

tot_b_clean = 0
tot_i_clean = 0
tot_b_raw = 0
tot_i_raw = 0

print("=== INVARIANT AUDIT OF INTEGRATED TARGET PARAGRAPHS ===")
for pid, ln in target_lines.items():
    b_text = base_lines[ln-1].strip()
    i_text = integrated_lines[ln-1].strip()
    
    b_cite = Counter(extract_citations(b_text))
    i_cite = Counter(extract_citations(i_text))
    
    b_math = Counter(extract_math(b_text))
    i_math = Counter(extract_math(i_text))
    
    b_nums = Counter(extract_numbers(b_text))
    i_nums = Counter(extract_numbers(i_text))
    
    b_years = Counter(extract_years(b_text))
    i_years = Counter(extract_years(i_text))
    
    b_refs = Counter(extract_fig_refs(b_text))
    i_refs = Counter(extract_fig_refs(i_text))
    
    b_wc = word_count(b_text)
    i_wc = word_count(i_text)
    raw_b_wc = raw_word_count(b_text)
    raw_i_wc = raw_word_count(i_text)
    
    tot_b_clean += b_wc
    tot_i_clean += i_wc
    tot_b_raw += raw_b_wc
    tot_i_raw += raw_i_wc
    
    print(f"--- {pid} (Line {ln}) ---")
    print(f"Word counts: cleaned: {b_wc} -> {i_wc} ({i_wc - b_wc:+d}; {(i_wc - b_wc)/b_wc*100:+.1f}%) | raw: {raw_b_wc} -> {raw_i_wc} ({raw_i_wc - raw_b_wc:+d}; {(raw_i_wc - raw_b_wc)/raw_b_wc*100:+.1f}%)")
    print(f"Citations equal: {b_cite == i_cite}")
    print(f"Math equal: {b_math == i_math}")
    print(f"Numbers equal: {b_nums == i_nums}")
    print(f"Years equal: {b_years == i_years}")
    print(f"Refs equal: {b_refs == i_refs}")
    assert b_cite == i_cite, f"Citations mismatch in {pid}"
    assert b_math == i_math, f"Math mismatch in {pid}"
    assert b_nums == i_nums, f"Numbers mismatch in {pid}"
    assert b_years == i_years, f"Years mismatch in {pid}"
    assert b_refs == i_refs, f"Refs mismatch in {pid}"

print(f"\nTotal Cleaned Words across 7 paragraphs: {tot_b_clean} -> {tot_i_clean} ({tot_i_clean - tot_b_clean:+d}; {(tot_i_clean - tot_b_clean)/tot_b_clean*100:+.1f}%)")
print(f"Total Raw Words across 7 paragraphs: {tot_b_raw} -> {tot_i_raw} ({tot_i_raw - tot_b_raw:+d}; {(tot_i_raw - tot_b_raw)/tot_b_raw*100:+.1f}%)")
