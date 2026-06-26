---
title: "Chapter 2 Descriptive Statistics Window Map"
aliases:
  - "Historical Window Protocol"
  - "S31 Descriptive Window Architecture"
type: "protocol"
status: "active"
project: "Dissertation Chapter 2"
chapter: 2
country: "United States"
stage: "S31B"
scope: "descriptive diagnostics"
dataset: "chapter2_us_source_of_truth_v1"
dataset_boundary: "read only"
created: 2026-06-24
updated: 2026-06-24
tags:
  - chapter2
  - descriptive-statistics
  - historical-windows
  - periodization
  - united-states
---
# Chapter 2 Descriptive-Statistics Window Map

## Legend

```text
[GLOBAL]      Whole available sample for each variable
[STRUCTURAL]  Broad historical period
[NESTED]      Subperiod contained within a structural period
[TRANSITION]  Short descriptive-only disruption window
[BRIDGE]      Overlapping window crossing a structural boundary
[PROFILE]     Event-centered display window; descriptive only
```

Transition and event-profile windows are never eligible for formal testing or estimation.

---

# 1. Full hierarchical map

```text
global_available_variable_specific_1901_2025 [GLOBAL]
│
├── pre_1974_variable_start_1973 [STRUCTURAL]
│   │
│   ├── pre_fordist_variable_start_1946 [NESTED]
│   │   │
│   │   └── pre_fordist_consolidation_1940_1946 [NESTED]
│   │
│   └── fordist_core_1947_1973 [NESTED]
│
└── post_1974_1974_2025 [STRUCTURAL UMBRELLA]
    │
    ├── post_fordist_pre_gfc_1974_2008 [STRUCTURAL]
    │   │
    │   ├── fordist_aftermath_1974_1978 [TRANSITION]
    │   │
    │   ├── volcker_transition_1979_1982 [TRANSITION]
    │   │
    │   └── mature_post_volcker_pre_gfc_1983_2008 [NESTED]
    │
    └── post_gfc_2009_2025 [STRUCTURAL]
        │
        ├── post_gfc_pre_covid_2009_2019 [NESTED]
        │
        ├── covid_transition_2020_2021 [TRANSITION]
        │
        └── post_covid_configuration_2022_2025 [NESTED]
```

---

# 2. Cross-boundary analytical bridge

The Fordist bridge is not strictly nested inside either the pre-1974 or post-1974 period because it crosses the 1974 boundary.

```text
extended_fordist_bridge_1940_1978 [BRIDGE]
│
├── pre_fordist_consolidation_1940_1946 [NESTED]
├── fordist_core_1947_1973 [NESTED]
└── fordist_aftermath_1974_1978 [TRANSITION]
```

Its historical function is:

```text
formation
→ consolidation
→ immediate aftermath
```

It is an overlapping analytical window, not an additional independent regime.

---

# 3. GFC boundary and transition map

The structural divide is:

```text
post_fordist_pre_gfc_1974_2008
└── ends in 2008

post_gfc_2009_2025
└── begins in 2009
```

The GFC transition crosses that structural boundary:

```text
gfc_transition_2008_2009 [TRANSITION]
│
├── 2008 = terminal year of post_fordist_pre_gfc
└── 2009 = initial year of post_gfc
```

This overlap is intentional.

The wider event-centered display is:

```text
gfc_event_profile_2007_2010 [PROFILE]
│
├── 2007 = pre-crisis reference
├── 2008 = crisis onset / terminal pre-GFC year
├── 2009 = recession / initial post-GFC year
└── 2010 = first subsequent observation
```

Neither `gfc_transition_2008_2009` nor `gfc_event_profile_2007_2010` may be used for testing or estimation.

---

# 4. Volcker shock map

The Volcker shock is nested within the post-Fordist pre-GFC period:

```text
post_fordist_pre_gfc_1974_2008
│
├── fordist_aftermath_1974_1978
├── volcker_transition_1979_1982
└── mature_post_volcker_pre_gfc_1983_2008
```

The wider event-centered display is:

```text
volcker_event_profile_1978_1983 [PROFILE]
│
├── 1978 = pre-transition reference
├── 1979 = monetary-policy shift
├── 1980 = first recessionary phase
├── 1981 = intensified monetary restraint
├── 1982 = deep recessionary adjustment
└── 1983 = first subsequent observation
```

The formal transition window is:

```text
volcker_transition_1979_1982 [TRANSITION]
```

It is descriptive only.

---

# 5. COVID transition map

COVID is nested within the post-GFC period:

```text
post_gfc_2009_2025
│
├── post_gfc_pre_covid_2009_2019
├── covid_transition_2020_2021
└── post_covid_configuration_2022_2025
```

The wider event-centered display is:

```text
covid_event_profile_2019_2022 [PROFILE]
│
├── 2019 = pre-pandemic reference
├── 2020 = pandemic shock
├── 2021 = disrupted recovery
└── 2022 = first post-transition observation
```

The formal transition window is:

```text
covid_transition_2020_2021 [TRANSITION]
```

It is descriptive only.

---

# 6. Window registry

|Window ID|Years|Type|Parent|Testing/estimation|
|---|--:|---|---|---|
|`global_available`|Variable-specific–2025|Global|—|Potentially eligible|
|`pre_1974`|Variable-specific–1973|Structural|Global|Potentially eligible|
|`pre_fordist`|Variable-specific–1946|Nested|`pre_1974`|Support-dependent|
|`pre_fordist_consolidation`|1940–1946|Nested|`pre_fordist`|Too short for core testing|
|`fordist_core`|1947–1973|Nested|`pre_1974`|Potentially eligible|
|`extended_fordist_bridge`|1940–1978|Bridge|Cross-boundary|Analytical use; eligibility separately assessed|
|`post_1974`|1974–2025|Structural umbrella|Global|Potentially eligible|
|`post_fordist_pre_gfc`|1974–2008|Structural|`post_1974`|Potentially eligible|
|`fordist_aftermath`|1974–1978|Transition|`post_fordist_pre_gfc`|No|
|`volcker_transition`|1979–1982|Transition|`post_fordist_pre_gfc`|No|
|`mature_post_volcker_pre_gfc`|1983–2008|Nested|`post_fordist_pre_gfc`|Potentially eligible|
|`gfc_transition`|2008–2009|Transition|Cross-boundary|No|
|`post_gfc`|2009–2025|Structural|`post_1974`|Potentially eligible|
|`post_gfc_pre_covid`|2009–2019|Nested|`post_gfc`|Limited by sample length|
|`covid_transition`|2020–2021|Transition|`post_gfc`|No|
|`post_covid_configuration`|2022–2025|Nested|`post_gfc`|Descriptive only at present|

---

# 7. Core descriptive-statistics windows

The main descriptive tables should include:

```text
global_available
pre_1974
post_1974
pre_fordist
fordist_core_1947_1973
extended_fordist_bridge_1940_1978
post_fordist_pre_gfc_1974_2008
mature_post_volcker_pre_gfc_1983_2008
post_gfc_2009_2025
post_gfc_pre_covid_2009_2019
post_covid_configuration_2022_2025
```

---

# 8. Transition-only descriptive windows

These must be placed in a separate transition table:

```text
fordist_aftermath_1974_1978
volcker_transition_1979_1982
gfc_transition_2008_2009
covid_transition_2020_2021
```

Required governance:

```text
descriptive_eligible = yes
testing_eligible = no
estimation_eligible = no
```

---

# 9. Event-profile windows

These are used for year-by-year displays rather than ordinary regime statistics:

```text
volcker_event_profile_1978_1983
gfc_event_profile_2007_2010
covid_event_profile_2019_2022
```

For each event profile, report:

```text
year
observed_value
absolute_annual_change
percentage_annual_change_when_valid
position_relative_to_event
```

Do not calculate or interpret these event profiles as independent statistical regimes.

---

# 10. Governing historical sequence

```text
pre-Fordist development
→ pre-Fordist consolidation, 1940–1946
→ Fordist core, 1947–1973
→ Fordist aftermath, 1974–1978
→ Volcker transition, 1979–1982
→ mature post-Volcker post-Fordism, 1983–2008
→ GFC transition, 2008–2009
→ post-GFC pre-COVID configuration, 2009–2019
→ COVID transition, 2020–2021
→ post-COVID configuration, 2022–2025
```

The transition windows overlap or interrupt longer structural periods, but they never replace the structural partition of the sample.