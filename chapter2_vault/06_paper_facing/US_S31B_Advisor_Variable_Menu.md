---
title: "S31B Advisor Variable Menu"
aliases:
  - "S31B Advisor Brief Selection"
type: "presentation-selection-menu"
status: "active"
project: "Dissertation Chapter 2"
chapter: 2
country: "United States"
stage: "S31B"
dataset: "chapter2_us_source_of_truth_v1"
dataset_boundary: "read only"
created: 2026-06-24
updated: 2026-06-24
tags:
  - chapter2
  - advisor-facing
  - descriptive-statistics
  - variable-selection
  - presentation-menu
---

# S31B Advisor Variable Menu

## Purpose

Use this checklist to select the evidence for a focused advisor-facing brief. Edit
the checkboxes and the question field, then return this file to Codex.

This menu controls presentation only. It does not modify the frozen S30 release,
create canonical variables, revise classifications, construct estimation samples,
perform econometric tests, or authorize a later stage.

## Editing Rules

1. Keep the stable identifier before the `|` unchanged.
2. Select no more than four `MAIN_VAR` entries.
3. Select no more than four principal `WINDOW` entries.
4. Keep at least one output variable and one capital variable in the main set.
5. A variable cannot be selected as both `MAIN_VAR` and `BACKUP_VAR`.
6. Reference-only variables may appear in backup material but never as headline
   evidence.
7. Unchecked boxes and all user notes must be preserved when this menu is returned.

## Advisor Question

Replace the text after `QUESTION::` with the concrete concern the brief should
answer. Keep the identifier on the same line.

QUESTION:: How did real NFC output, productive capital, accumulation, and the wage share differ across the Fordist core, the post-Fordist pre-GFC period, and the post-GFC period?

Additional notes:

> Add any emphasis, concern, comparison, or wording request here.

---

## 1. Main-Text Variables

Select at most four. These variables define the two principal tables and the three
bounded findings.

- [x] MAIN_VAR::Y_REAL_NFC_GVA_BASELINE | Real NFC output | ROLE::OUTPUT | MEASURE::ANNUAL_PERCENT_GROWTH
- [x] MAIN_VAR::G_TOT_GPIM_2017 | Gross productive capital | ROLE::CAPITAL | MEASURE::ANNUAL_PERCENT_GROWTH
- [x] MAIN_VAR::I_TOT_REAL_2017 | Total real capital accumulation | ROLE::ACCUMULATION | MEASURE::EXISTING_FROZEN_ANNUAL_MEASURE
- [x] MAIN_VAR::NFC_COMPENSATION_SHARE_GVA | NFC compensation share of GVA | ROLE::DISTRIBUTION | MEASURE::PERCENTAGE_POINT_CHANGE

### Main-variable interpretation

| Stable variable ID | Advisor-facing meaning | Presentation rule |
|---|---|---|
| `Y_REAL_NFC_GVA_BASELINE` | Observed real output of nonfinancial corporations | Report level coverage and annual percentage growth |
| `G_TOT_GPIM_2017` | Gross productive-capital stock | Report level coverage and annual percentage growth |
| `I_TOT_REAL_2017` | Real capital accumulation | Use the released annual measure directly |
| `NFC_COMPENSATION_SHARE_GVA` | Labor compensation relative to NFC gross value added | Report annual percentage-point change |

---

## 2. Robustness and Backup Variables

These options do not enter the headline tables unless they are moved explicitly
into the main-variable section and pass the main-variable rules.

### Capital robustness

- [ ] BACKUP_VAR::N_TOT_GPIM_2017 | Net productive capital | ROLE::CAPITAL | TIER::ROBUSTNESS

### Alternative real-output measures

- [ ] BACKUP_VAR::Y_REAL_NFC_GVA_PROXY_GDP_IMPLICIT | Real NFC output using the GDP implicit deflator | ROLE::OUTPUT | TIER::ROBUSTNESS
- [ ] BACKUP_VAR::Y_REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT | Real NFC output using nonfarm business output | ROLE::OUTPUT | TIER::ROBUSTNESS
- [ ] BACKUP_VAR::Y_REAL_NFC_GVA_PROXY_BUSINESS_OUTPUT | Real NFC output using business output | ROLE::OUTPUT | TIER::ROBUSTNESS
- [ ] BACKUP_VAR::Y_REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT_BLS | Real NFC output using the BLS nonfarm business series | ROLE::OUTPUT | TIER::ROBUSTNESS
- [ ] BACKUP_VAR::Y_REAL_NFC_GVA_PROXY_GDPBYIND_VA_FINANCE_INSURANCE | Finance and insurance real value-added proxy | ROLE::OUTPUT | TIER::ROBUSTNESS
- [ ] BACKUP_VAR::Y_REAL_NFC_GVA_PROXY_GDPBYIND_VA_MANUFACTURING | Manufacturing real value-added proxy | ROLE::OUTPUT | TIER::ROBUSTNESS

### Distribution robustness

- [ ] BACKUP_VAR::NFC_COMPENSATION_SHARE_NVA | NFC compensation share of net value added | ROLE::DISTRIBUTION | TIER::ROBUSTNESS
- [ ] BACKUP_VAR::CORP_COMPENSATION_SHARE_GVA | Corporate compensation share of gross value added | ROLE::DISTRIBUTION | TIER::ROBUSTNESS
- [ ] BACKUP_VAR::CORP_COMPENSATION_SHARE_NVA | Corporate compensation share of net value added | ROLE::DISTRIBUTION | TIER::ROBUSTNESS

### Reference-only profit-share measures

These variables may support a labeled appendix note only. They cannot become
headline variables.

- [ ] BACKUP_VAR::NFC_NET_OPERATING_SURPLUS_SHARE_GVA | NFC net operating surplus share of GVA | ROLE::DISTRIBUTION | TIER::REFERENCE_ONLY
- [ ] BACKUP_VAR::NFC_NET_OPERATING_SURPLUS_SHARE_NVA | NFC net operating surplus share of NVA | ROLE::DISTRIBUTION | TIER::REFERENCE_ONLY
- [ ] BACKUP_VAR::CORP_NET_OPERATING_SURPLUS_SHARE_GVA | Corporate net operating surplus share of GVA | ROLE::DISTRIBUTION | TIER::REFERENCE_ONLY
- [ ] BACKUP_VAR::CORP_NET_OPERATING_SURPLUS_SHARE_NVA | Corporate net operating surplus share of NVA | ROLE::DISTRIBUTION | TIER::REFERENCE_ONLY

---

## 3. Principal Historical Windows

Select at most four principal windows. The default comparison uses three
non-overlapping historical periods.

- [ ] WINDOW::global_available_variable_specific_1901_2025 | Global available sample
- [ ] WINDOW::pre_1974_variable_start_1973 | Pre-1974 available sample
- [ ] WINDOW::pre_fordist_variable_start_1946 | Pre-Fordist available sample
- [ ] WINDOW::pre_fordist_consolidation_1940_1946 | Pre-Fordist consolidation, 1940-1946
- [x] WINDOW::fordist_core_1947_1973 | Fordist core, 1947-1973
- [ ] WINDOW::post_1974_1974_2025 | Post-1974 umbrella, 1974-2025
- [x] WINDOW::post_fordist_pre_gfc_1974_2008 | Post-Fordist pre-GFC, 1974-2008
- [ ] WINDOW::mature_post_volcker_pre_gfc_1983_2008 | Mature post-Volcker pre-GFC, 1983-2008
- [x] WINDOW::post_gfc_2009_2025 | Post-GFC, 2009-2025
- [ ] WINDOW::post_gfc_pre_covid_2009_2019 | Post-GFC pre-COVID, 2009-2019
- [ ] WINDOW::post_covid_configuration_2022_2025 | Post-COVID configuration, 2022-2025
- [ ] WINDOW::extended_fordist_bridge_1940_1978 | Extended Fordist bridge, 1940-1978

### Descriptive transition windows

Transition windows do not count as principal windows. They are descriptive only
and are never eligible for testing, estimation, or regime-level interpretation.

- [ ] TRANSITION::fordist_aftermath_1974_1978 | Fordist aftermath, 1974-1978
- [ ] TRANSITION::volcker_transition_1979_1982 | Volcker transition, 1979-1982
- [ ] TRANSITION::gfc_transition_2008_2009 | GFC transition, 2008-2009
- [ ] TRANSITION::covid_transition_2020_2021 | COVID transition, 2020-2021

### Event profiles

- [ ] EVENT::volcker_event_profile_1978_1983 | Volcker event profile, 1978-1983
- [ ] EVENT::gfc_event_profile_2007_2010 | GFC event profile, 2007-2010
- [ ] EVENT::covid_event_profile_2019_2022 | COVID event profile, 2019-2022

---

## 4. Evidence Modules

The checked modules determine which statistics may appear in the brief.

- [x] EVIDENCE::COVERAGE | First year, last year, valid observations, and missingness
- [x] EVIDENCE::MEAN_GROWTH | Mean annual percentage growth or percentage-point change
- [x] EVIDENCE::VOLATILITY | Standard deviation of the selected annual measure
- [x] EVIDENCE::ENDPOINTS | Initial value, terminal value, and endpoint change
- [x] EVIDENCE::VALID_N | Valid observation count in every reported cell
- [ ] EVIDENCE::MEDIAN_GROWTH | Median annual growth or percentage-point change
- [ ] EVIDENCE::QUANTILES | Selected distributional quantiles
- [ ] EVIDENCE::SKEWNESS | Skewness
- [ ] EVIDENCE::KURTOSIS | Excess kurtosis
- [ ] EVIDENCE::TRANSITION_DETAIL | Transition-window endpoint and annual-change detail
- [ ] EVIDENCE::EVENT_PROFILE_DETAIL | Year-level event-profile detail
- [ ] EVIDENCE::OUTPUT_CAPITAL_CORRESPONDENCE | Descriptive output-capital growth correspondence

---

## 5. Advisor Deliverable

Select exactly one primary format.

- [x] FORMAT::TWO_PAGE_MEMO | Two-page advisor brief with two tables
- [ ] FORMAT::SLIDE_READY_OUTLINE | Result-bearing slide outline
- [ ] FORMAT::TECHNICAL_REPORT | Expanded technical report

### Required two-page memo structure

- [x] MEMO_SECTION::EMPIRICAL_QUESTION | State the advisor question and define selected variables in plain language
- [x] MEMO_SECTION::COVERAGE_TABLE | One coverage and measurement table
- [x] MEMO_SECTION::GROWTH_COMPARISON_TABLE | One historical growth-comparison table
- [x] MEMO_SECTION::THREE_FINDINGS | Three bounded findings
- [x] MEMO_SECTION::LIMITATIONS | Short description-versus-estimation limitation statement
- [ ] MEMO_SECTION::ROBUSTNESS_APPENDIX | Compact robustness appendix
- [ ] MEMO_SECTION::TECHNICAL_APPENDIX | Technical representation appendix
- [ ] MEMO_SECTION::COMPLETE_TABLES | Complete master descriptive tables

---

## 6. Technical Representation Boundary

The menu operates at the economic-concept level. The following representations
remain hidden from headline presentation unless `TECHNICAL_APPENDIX` is checked:

- [ ] TECH_REP::LOG_LEVELS | Canonical log-level representations
- [ ] TECH_REP::LAGGED_LEVELS | Lagged log-level representations
- [ ] TECH_REP::LAGGED_GROWTH | Lagged growth representations
- [ ] TECH_REP::DUPLICATE_GROWTH_FORMS | Arithmetic and log-difference versions of the same growth concept

Internal mapping rules:

```text
positive level or index
  -> direct annual percentage growth

share or bounded ratio
  -> annual percentage-point change

existing frozen growth or difference
  -> use released observations directly

log with an available level counterpart
  -> derive presentation growth from the level counterpart

log or lagged technical representation
  -> exclude from headline evidence
```

---

## 7. Validation Contract

Codex must validate this menu before generating the advisor brief:

- Every checked variable ID exists in the S31B descriptive variable registry.
- Every checked window ID exists in the S31B descriptive window registry.
- The main set contains no more than four variables.
- The principal window set contains no more than four windows.
- The main set contains at least one `ROLE::OUTPUT` variable.
- The main set contains at least one `ROLE::CAPITAL` variable.
- No variable is selected as both main and backup.
- No log, lag, or reference-only representation becomes headline evidence.
- Exactly one `FORMAT` option is checked.
- The generated brief uses only checked variables, windows, evidence modules, and
  memo sections.
- Unchecked boxes, stable IDs, and user notes remain unchanged when the menu is
  returned.

If a validation condition fails, do not silently broaden or reinterpret the
selection. Return:

```text
ADVISOR_MENU_NARROWING_REQUIRED
```

and identify the exact conflicting or excessive selections.

---

## 8. Advisor-Facing Writing Contract

The brief must:

1. Begin with the empirical question, not the chapter architecture.
2. Name each observed variable before introducing notation or method.
3. Explain economic meaning before technical construction.
4. Present one coverage table and one historical comparison table.
5. State exactly three bounded findings supported by those tables.
6. Distinguish descriptive evidence from estimation and structural inference.
7. Avoid internal workflow language and undefined technical labels.

Required limitation:

> These comparisons describe the frozen S30 observations across selected
> historical windows. They do not construct an estimation sample, infer
> integration order, estimate productive capacity, or identify the structural
> elasticity theta.

