# Ch2 Workflow Bundle — 2026-04-02
## Capacity-Utilization-US_Chile

Everything needed to start writing Chapter 2 and running the empirical pipeline today.

---

## What's in this bundle

```
chapter2/
├── agents/
│   ├── ch2_modular_index.md      ← Section status tracker (v2, rebuilt 2026-04-02)
│   ├── ch2_section_prompts.md    ← All section firing prompts + LaTeX template (v2)
│   ├── ch2_voice_guide.md        ← WLM v4.0 voice calibration — paste FIRST in every tab
│   ├── fire_ch2_drafts.py        ← (Optional) Concurrent API firing script
│   └── drafts/                   ← Opus session outputs land here
├── draft/
│   └── figures/                  ← Chapter figures
└── outline/
    └── Ch2_Outline_DEFINITIVE.md ← LOCKED outline (§2.1–§2.9, 33 subsections)

docs/ch2/
└── repo_structure_Ch2_v2.md      ← Full repo structure spec (v2)

setup_ch2_structure.sh            ← Run this first to create all directories
```

---

## Step 1 — Setup the repo structure

From repo root:

```bash
bash setup_ch2_structure.sh
```

This creates all `codes/stage_a/`, `data/raw/chile/`, `output/stage_*/` directories
and stub scripts. Safe to re-run.

Then copy this bundle's contents into the repo:

```bash
# Copy writing infrastructure
cp -r chapter2/ <repo_root>/

# Copy docs
cp docs/ch2/repo_structure_Ch2_v2.md <repo_root>/docs/ch2/

git add -A
git commit -m "scaffold: Ch2 writing + empirical pipeline structure (v2)"
git push origin main
```

---

## Step 2 — Chile income data (do this now)

Drop assembled CEPAL data into:

```
data/raw/chile/cepal_gdp_income.csv
data/raw/chile/k_stock_canonical_2003CLP.csv   ← from K-Stock-Harmonization output/
```

Then run:

```bash
python codes/stage_a/chile/10_data_assembly.py
python codes/stage_a/chile/11_construct_panel.py
Rscript codes/stage_a/chile/20_integration_tests.R   # STAGE GATE
```

---

## Step 3 — Writing sprint (open tabs in claude.ai)

For each section, open a new claude.ai session **in this project** and paste:

1. **FIRST:** Full contents of `chapter2/agents/ch2_voice_guide.md`
2. **THEN:** The section prompt from `chapter2/agents/ch2_section_prompts.md`

Save Opus output as `chapter2/agents/drafts/ch2_sec<XX>_draft_v1.md`.

Priority order (from modular index):
1. §2.5.1 — Stage A 4-var system (core methodological contribution)
2. §2.3.2 — Layer 1 accounting foundation
3. §2.3.3 — Layer 2 behavioral identification
4. §2.5.4 — Stage A.2 peripheral capital composition
5. §2.7 — Stage C investment function (all 6 subsections, one prompt)
6. §2.2.1–§2.2.5 — Literature review (5 subsections, one tab each)

---

## Files by purpose

| File | When to use |
|---|---|
| `ch2_voice_guide.md` | Paste BEFORE every section prompt |
| `ch2_section_prompts.md` | Source of section prompts + LaTeX template |
| `ch2_modular_index.md` | Check section status + dependency tracking |
| `Ch2_Outline_DEFINITIVE.md` | Ground truth for all content decisions |
| `fire_ch2_drafts.py` | Optional: concurrent API firing (requires separate API key) |
| `setup_ch2_structure.sh` | One-time repo scaffolding |
| `repo_structure_Ch2_v2.md` | Full directory spec for reference |

---

*Bundle prepared: 2026-04-02 | Session: Ch2 outline lockdown + writing sprint setup*
*Outline authority: Ch2_Outline_DEFINITIVE.md | Voice authority: WLM v4.0*
