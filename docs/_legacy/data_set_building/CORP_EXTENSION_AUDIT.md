# Corporate Sector Extension — Pre-Coding Audit

**Date**: 2026-03-14
**Auditor**: Claude Code
**Purpose**: Verify data availability and pipeline state before creating 50-series scripts.

---

## 1. BEA Parsed Data (`data/interim/bea_parsed/`)

**Status**: EMPTY — no BEA tables have been fetched yet.

The 40-series pipeline (scripts 40–49) has not been executed. No parsed BEA tables exist.
All corporate tables (FAAt601–FAAt607) and NIPA tables (T10114, T70011) must be fetched fresh.

## 2. NIPA Tables Status

| Table | Description | Status |
|-------|-------------|--------|
| T10114 (Table 1.14) | Corporate GVA | NOT FETCHED |
| T70011 (Table 7.11) | Interest Paid/Received | NOT FETCHED |

Both will be fetched by `codes/50_fetch_bea_corporate.R`.

## 3. IRS Book Value File

**File**: `data/raw/irs_book_value.csv`
**Status**: DOES NOT EXIST

ADJ_3 (IRS Depression-era scrapping correction) will be skipped gracefully.
The toggle `ADJ3_IRS_SCRAPPING` defaults to FALSE.

## 4. GDP Deflator (Py) Status

**File**: `data/processed/gdp_us_1925_2024.csv`
**Status**: DOES NOT EXIST (40-series not run)

**Resolution**: Script 50 will independently fetch FRED series `A191RD3A086NBEA`
(GDP implicit price deflator, annual) and write to `data/interim/gdp_components/gdp_deflator_fred.csv`.

**Alternative source**: `data/raw/ALFRED_GDPDEF_vintage2012.csv` EXISTS.
Contains columns: `year`, `Py_alfred`. However, this file has quarterly observations
(multiple rows per year) and only extends to ~2012. Not suitable as primary source.

## 5. Shaikh Canonical Series

**File**: `data/raw/Shaikh_canonical_series_v1.csv`
**Status**: EXISTS (67 lines, 1946–2011)

### Columns present (32):
year, VAcorp, NOScorp, Pcorpnipa, NMINT, KGCcorp, INVcorp, KTCcorp, Rcorp,
Profshcorp, rcorp, VAcorpnipa, KNCcorpbea, Rcorpnipa, Profshcorpnipa, rcorpnipa,
uK, uFRB, Rcorpn, Profshcorpn, rcorpn, IGCcorpbea, DEPCcorp, pIGcorpbea,
GOSRcorp, ECcorp, WEQ2, VAcorp_check, Pcorp, rcorp_sectoral, exploit_rate, pKN

### 1947 Validation Targets (from canonical CSV):

| Variable | 1947 Value | Notes |
|----------|------------|-------|
| VAcorp | 118.6 | Net value added (adjusted) |
| GVAcorp | 127.5 | = VAcorp + DEPCcorp = 118.6 + 8.9 |
| NOScorp | 24.9 | Net operating surplus (adjusted) |
| ECcorp | 82.1 | Employee compensation |
| DEPCcorp | 8.9 | CFC / depreciation |
| KGCcorp | 170.6 | Gross capital stock (Shaikh-adjusted) |
| KNCcorpbea | 190.1 | BEA net stock (unadjusted) |
| Pcorp | 22.5 | Corporate profits |
| Pcorpnipa | 22.5 | NIPA profits (same in 1947) |
| pIGcorpbea | 23.29 | Investment goods deflator |
| pKN | 11.69 | Net K stock implicit deflator |
| exploit_rate | 0.303 | = NOScorp / ECcorp |
| Profshcorp | 0.210 | Profit share |
| uK | 0.885 | Shaikh capacity utilization |
| IGCcorpbea | 15.7 | Gross investment |

### Key identities verified:
- GVAcorp = VAcorp + DEPCcorp: 118.6 + 8.9 = 127.5 ✓
- exploit_rate = NOScorp / ECcorp: 24.9 / 82.1 = 0.303 ✓

## 6. API Key Availability

**File**: `codes/40_gdp_kstock_config.R`

| Key | Status |
|-----|--------|
| BEA_API_KEY | SET (fallback default in config: `6EA6700D-...`) |
| FRED_API_KEY | SET (fallback default in config: `fc67199e...`) |

Both keys are available via `Sys.getenv()` with hardcoded fallbacks.

## 7. BEA Table Disambiguation

**Research finding**: BEA Fixed Assets table sections:
- Section 4 (FAAt4xx): Nonresidential FA by Industry & Legal Form
- Section 6 (FAAt6xx): Private FA by Industry Group & Legal Form ← CORPORATE IS HERE
- Section 7 (FAAt7xx): Government FA

The 40-series config mislabels `govt_net_cc = "FAAt601"` — FAAt601 is actually
"Private FA by Legal Form" (Section 6). Government should be FAAt7xx.
No conflict exists since data/interim/bea_parsed/ is empty.

**FAAt601–FAAt607 are confirmed correct** for private FA by legal form (Corporate).
Runtime verification of "Corporate" line labels is implemented as safeguard.

## 8. Existing Code to Reuse

| Function | Source File | Purpose |
|----------|-------------|---------|
| `fetch_bea_table_api()` | `codes/41_fetch_bea_fixed_assets.R:35` | BEA API fetch pattern |
| `parse_bea_api_response()` | `codes/97_kstock_helpers.R` | BEA response parser |
| `fetch_fred_series()` | `codes/42_fetch_fred_gdp.R:43` | FRED fetch w/ backoff |
| `gpim_accumulate_real()` | `codes/97_kstock_helpers.R` | GPIM real stock recursion |
| `gpim_build_gross_real()` | `codes/97_kstock_helpers.R` | Gross stock construction |
| `gpim_depreciation_rate()` | `codes/97_kstock_helpers.R` | Theoretically correct z |
| `gpim_whelan_liu_rate()` | `codes/97_kstock_helpers.R` | Approximate z (WL) |
| `validate_gross_sfc()` | `codes/97_kstock_helpers.R` | SFC identity check |
| `safe_write_csv()` | `codes/99_utils.R` | CSV writer w/ dir creation |
| `now_stamp()` | `codes/99_utils.R` | Timestamp helper |
| `ensure_dirs()` | `codes/97_kstock_helpers.R` | Directory creation |
| `log_data_quality()` | `codes/97_kstock_helpers.R` | Data quality logging |

---

## AUDIT CONCLUSION

**Ready to proceed.** All required API keys are available. No data conflicts exist.
The 50-series pipeline can be built as a self-contained corporate sector track.

Key risks:
1. BEA API rate limits or downtime — mitigated by force_refetch toggle
2. NIPA line numbers may differ from expected — mitigated by runtime label printing
3. BEA vintage gap for K-stock — documented, not a bug (intentional replication finding)

---

*Post-validation results will be appended below after scripts 50–54 are run.*
