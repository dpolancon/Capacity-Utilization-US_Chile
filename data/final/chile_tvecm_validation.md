# Chile TVECM Panel — Validation Report

Generated: 2026-04-06 21:04
Pipeline: `codes/stage_a/chile/chile_data_construction.py`
Source panel: `output/panel/chile_panel_extended.csv`

## Panel dimensions
- Rows: 105 (years 1920-2024)
- Columns: 28
- Estimation sample: 1940-1978 (N=39)

## Series coverage (in-sample: 1940-1978)

| Variable | First yr | Last yr | Valid | NaN | Mean | Std | Min | Max |
|----------|----------|---------|-------|-----|------|-----|-----|-----|
| y | 1920 | 2024 | 39 | 0 | 16.0452 | 0.3930 | 15.4036 | 16.5960 |
| k_NR | 1920 | 2024 | 39 | 0 | 17.6450 | 0.3635 | 17.1319 | 18.2028 |
| k_ME | 1920 | 2024 | 39 | 0 | 16.8210 | 0.4923 | 16.1207 | 17.4910 |
| m | 1920 | 2024 | 39 | 0 | 13.8436 | 0.5132 | 13.0686 | 14.7349 |
| nrs | 1920 | 2024 | 39 | 0 | 14.7979 | 0.5470 | 13.4948 | 15.7663 |
| omega | 1920 | 2024 | 39 | 0 | 0.5558 | 0.0758 | 0.3945 | 0.6903 |
| omega_kME | 1920 | 2024 | 39 | 0 | 9.3391 | 1.2338 | 6.8731 | 12.0122 |
| phi | 1920 | 2024 | 39 | 0 | 0.4431 | 0.0613 | 0.3362 | 0.5144 |
| tot | 1920 | 2010 | 39 | 0 | 4.6361 | 0.2505 | 4.2321 | 5.1586 |
| pcu | 1920 | 2010 | 39 | 0 | 0.3042 | 0.2354 | -0.0949 | 0.7764 |
| rer | 1920 | 2010 | 39 | 0 | 4.0969 | 0.2675 | 3.1127 | 4.4372 |
| ner | 1920 | 2010 | 39 | 0 | -6.4271 | 4.0117 | -10.4886 | 3.4549 |

## Critical flags
- NRS > 0 for all years in context window. No log issues.
- omega range check: PASS [0.3945, 0.6903]
- Capital stocks: **gross** (Kg_ME, Kg_NRC from K-Stock-Harmonization). Verified.
- Price base: 2003 CLP throughout (deflators indexed 2003=100)

## NRS construction detail
- GOS = π × Y_real (profit share × real GDP)
- I_total = I_real (gross fixed capital formation)
- NRS = GOS − I_total

| Year | Π (GOS) | I (GFCF) | Π−I (NRS) | ln(NRS) |
|------|---------|----------|-----------|---------|
| 1940 | 1,921,162 | 690,555 | 1,230,606 | 14.0230 |
| 1941 | 1,881,162 | 680,814 | 1,200,348 | 13.9981 |
| 1942 | 2,189,680 | 541,528 | 1,648,153 | 14.3152 |
| 1943 | 2,067,268 | 581,387 | 1,485,881 | 14.2115 |
| 1944 | 1,987,848 | 653,819 | 1,334,029 | 14.1037 |
| 1945 | 2,280,333 | 690,555 | 1,589,777 | 14.2791 |
| 1946 | 2,679,179 | 956,411 | 1,722,768 | 14.3594 |
| 1947 | 1,776,895 | 1,051,227 | 725,669 | 13.4948 |
| 1948 | 2,639,435 | 933,507 | 1,705,928 | 14.3496 |
| 1949 | 2,609,757 | 1,067,587 | 1,542,170 | 14.2487 |
| 1950 | 2,914,739 | 985,637 | 1,929,102 | 14.4726 |
| 1951 | 3,301,912 | 1,121,725 | 2,180,187 | 14.5949 |
| 1952 | 2,691,705 | 1,173,632 | 1,518,073 | 14.2330 |
| 1953 | 4,523,782 | 1,185,382 | 3,338,400 | 15.0210 |
| 1954 | 4,441,752 | 1,148,422 | 3,293,330 | 15.0074 |
| 1955 | 4,662,855 | 1,329,725 | 3,333,130 | 15.0194 |
| 1956 | 3,980,960 | 1,266,737 | 2,714,222 | 14.8140 |
| 1957 | 4,167,445 | 1,448,932 | 2,718,513 | 14.8156 |
| 1958 | 5,246,527 | 1,426,028 | 3,820,500 | 15.1559 |
| 1959 | 3,801,648 | 1,229,629 | 2,572,018 | 14.7602 |
| 1960 | 3,785,341 | 1,592,903 | 2,192,438 | 14.6005 |
| 1961 | 3,462,986 | 1,613,381 | 1,849,605 | 14.4305 |
| 1962 | 4,315,125 | 1,811,348 | 2,503,777 | 14.7333 |
| 1963 | 5,000,880 | 2,078,750 | 2,922,131 | 14.8878 |
| 1964 | 3,735,724 | 1,960,294 | 1,775,430 | 14.3896 |
| 1965 | 4,216,412 | 1,841,846 | 2,374,566 | 14.6803 |
| 1966 | 5,782,355 | 1,901,085 | 3,881,271 | 15.1717 |
| 1967 | 5,626,510 | 1,941,725 | 3,684,785 | 15.1197 |
| 1968 | 6,378,932 | 2,125,393 | 4,253,539 | 15.2633 |
| 1969 | 7,174,729 | 2,232,626 | 4,942,103 | 15.4133 |
| 1970 | 7,194,055 | 2,376,724 | 4,817,331 | 15.3877 |
| 1971 | 6,991,090 | 2,321,612 | 4,669,478 | 15.3566 |
| 1972 | 4,886,057 | 1,855,149 | 3,030,908 | 14.9244 |
| 1973 | 6,779,556 | 1,743,388 | 5,036,168 | 15.4322 |
| 1974 | 9,110,955 | 2,076,606 | 7,034,350 | 15.7663 |
| 1975 | 6,647,275 | 1,630,203 | 5,017,072 | 15.4284 |
| 1976 | 6,977,976 | 1,392,540 | 5,585,436 | 15.5357 |
| 1977 | 7,385,201 | 1,663,297 | 5,721,904 | 15.5598 |
| 1978 | 8,941,162 | 1,948,810 | 6,992,352 | 15.7603 |

## Pairwise correlations (in-sample, log-level series)

| | y | k_NR | k_ME | m | nrs | omega | phi | tot |
|---|---|---|---|---|---|---|---|---|
| y | 1.000 | 0.982 | 0.982 | 0.976 | 0.858 | -0.297 | 0.884 | 0.658 |
| k_NR | 0.982 | 1.000 | 0.988 | 0.973 | 0.859 | -0.302 | 0.856 | 0.593 |
| k_ME | 0.982 | 0.988 | 1.000 | 0.980 | 0.842 | -0.277 | 0.925 | 0.643 |
| m | 0.976 | 0.973 | 0.980 | 1.000 | 0.825 | -0.264 | 0.897 | 0.686 |
| nrs | 0.858 | 0.859 | 0.842 | 0.825 | 1.000 | -0.713 | 0.702 | 0.587 |
| omega | -0.297 | -0.302 | -0.277 | -0.264 | -0.713 | 1.000 | -0.165 | -0.284 |
| phi | 0.884 | 0.856 | 0.925 | 0.897 | 0.702 | -0.165 | 1.000 | 0.692 |
| tot | 0.658 | 0.593 | 0.643 | 0.686 | 0.587 | -0.284 | 0.692 | 1.000 |

## Unit root pre-tests (ADF)

### Levels (expect: fail to reject H₀ of unit root)

| Series | ADF stat | p-value | Lags | 1% cv | 5% cv | 10% cv | Reject 5%? |
|--------|----------|---------|------|-------|-------|--------|------------|
| y | -1.084 | 0.721 | 1 | -3.621 | -2.944 | -2.610 | no |
| k_NR | -0.285 | 0.928 | 1 | -3.621 | -2.944 | -2.610 | no |
| k_ME | -0.996 | 0.755 | 1 | -3.621 | -2.944 | -2.610 | no |
| m | -0.452 | 0.901 | 3 | -3.633 | -2.949 | -2.613 | no |
| nrs | -0.583 | 0.875 | 2 | -3.627 | -2.946 | -2.612 | no |
| omega | -3.488 | 0.008 | 0 | -3.616 | -2.941 | -2.609 | YES ⚠ |
| phi | -1.540 | 0.513 | 1 | -3.621 | -2.944 | -2.610 | no |
| tot | -1.891 | 0.336 | 0 | -3.616 | -2.941 | -2.609 | no |

### First differences (expect: reject H₀ → confirms I(1))

| Series | ADF stat | p-value | Lags | 1% cv | 5% cv | 10% cv | Reject 5%? |
|--------|----------|---------|------|-------|-------|--------|------------|
| Δy | -7.492 | 0.000 | 0 | -3.621 | -2.944 | -2.610 | YES ✓ |
| Δk_NR | -2.296 | 0.173 | 0 | -3.621 | -2.944 | -2.610 | no ⚠ |
| Δk_ME | -2.169 | 0.218 | 0 | -3.621 | -2.944 | -2.610 | no ⚠ |
| Δm | -5.535 | 0.000 | 2 | -3.633 | -2.949 | -2.613 | YES ✓ |
| Δnrs | -7.022 | 0.000 | 1 | -3.627 | -2.946 | -2.612 | YES ✓ |
| Δomega | -6.498 | 0.000 | 1 | -3.627 | -2.946 | -2.612 | YES ✓ |
| Δphi | -2.443 | 0.130 | 0 | -3.621 | -2.944 | -2.610 | no ⚠ |
| Δtot | -5.587 | 0.000 | 1 | -3.627 | -2.946 | -2.612 | YES ✓ |

## Variable → Stage mapping

| Variable | Stage 1 | Stage 2 | Post-est. | Role |
|----------|:-------:|:-------:|:---------:|------|
| y |  | **×** |  | Stage 2 state vector |
| k_NR |  | **×** |  | Stage 2 state vector |
| k_ME | **×** | **×** |  | Stage 1 + Stage 2 state vector (overlap) |
| m | **×** |  |  | Stage 1 state vector |
| nrs | **×** |  |  | Stage 1 state vector |
| omega | **×** | **×** |  | Stage 1 state vector; Stage 2 via interaction |
| omega_kME |  | **×** |  | Stage 2 state vector (interaction ω·k_ME) |
| phi |  |  | **×** | Post-estimation: composition K_ME/K_NR |
| tot | **×** |  |  | Stage 1 exogenous / conditioning |
| pcu | **×** |  |  | Stage 1 exogenous / conditioning |
| rer | **×** |  |  | Stage 1 exogenous / conditioning |
| ner | **×** |  |  | Stage 1 exogenous / conditioning |
| p_Y |  |  |  | Auxiliary deflator |
| p_M |  |  |  | Auxiliary deflator |
| pi |  |  |  | Auxiliary (used in NRS construction) |

### Cross-reference
- **Stage 1 VECM** state vector: `(m, k_ME, nrs, omega)`
- **Stage 1 exogenous**: `(tot, pcu, rer, ner)`
- **Stage 2 TVECM** state vector: `(y, k_NR, k_ME, omega_kME)`
- **Post-estimation**: `(phi)`
- **Overlap (Stage 1 ∩ Stage 2)**: `(k_ME, omega)`
  - `k_ME` is a state variable in both stages — it transmits the capital-deepening channel across the recursive structure.
  - `omega` enters Stage 1 directly and Stage 2 via the interaction `omega_kME = ω × k_ME` — it transmits the distributional channel.

## Data sources
| Variable | Source | Base |
|----------|--------|------|
| Y_real | Pérez & Eyzaguirre (via chile_panel_extended) | 2003 CLP |
| M_real | Pérez & Eyzaguirre (via chile_panel_extended) | 2003 CLP |
| Kg_ME, Kg_NRC | K-Stock-Harmonization (via chile_panel_extended) | 2003 CLP |
| omega, pi | distr_19202024.xlsx (via chile_panel_extended) | ratio |
| P_Y, P_X, P_M | ClioLab W04 splice (via chile_panel_extended) | 2003=100 |
| tot | ClioLab W04 sheet 4.3.2 (TERMINT, index 2003=100) | log |
| I_real | Pérez & Eyzaguirre (via chile_panel_extended) | 2003 CLP |
| pcu | ClioLab W04 sheet 4.3.3 (COP_USA03) | 2003 USD/lb |
| ner | ClioLab W04 sheet 4.2.1 (TCNUSD, pesos actuales/USD) | log |
| rer | ClioLab W04 sheet 4.2.2 (TCREAL, index 2003=100) | log |

## Outstanding items
- All series sourced. ClioLab W04 provides copper, NER, and RER with redenomination handling built in.
- Note: ClioLab coverage ends 2010. Post-2010 extension would require BCCh for exchange rates and World Bank for copper.

---
*Report generated by chile_data_construction.py — 2026-04-06T21:04:50.777100*