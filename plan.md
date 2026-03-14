# Plan: Build Extended BEA Fixed Assets Dataset (1925–2024)

## Objective

Build a **new, reproducible, well-documented** dataset of US Gross Domestic Product and capital stock series from BEA sources, extended from 1925 to 2024 (or 2023 if 2024 not yet released), following Shaikh's conceptual framework but constructed from scratch using current BEA releases. The focus is on the **corporate nonfinancial sector**, with capital measured in **gross** and **net** terms, excluding intellectual property products (IPP) from productive capital.

---

## Phase 0: Data Access Infrastructure (Python)

**New file: `codes/30_bea_data_build.py`**

> **Why Python?** R packages (CRAN) are blocked in this environment. Python with `pandas`, `openpyxl`, and `requests` provides full BEA API and CSV download capability.

### 0.1 BEA API Key Setup
- Register for a free BEA API key at `https://apps.bea.gov/API/signup/index.cfm`
- Store key in `.env` file (git-ignored) or pass as environment variable `BEA_API_KEY`
- If API key unavailable: fall back to direct CSV downloads from BEA interactive tables

### 0.2 Download Functions
- `fetch_nipa_table(table_name, frequency='A')` → pandas DataFrame
- `fetch_fixed_assets_table(table_name)` → pandas DataFrame
- `fetch_fred_series(series_id)` → pandas Series
- All downloads cached locally in `data/raw/bea_downloads/` with date-stamped filenames

---

## Phase 1: GDP / Gross Value Added Series (1929–2024)

### 1.1 Primary GDP Series (1929–2024)

**BEA NIPA tables needed:**

| Table | API Name | Content | Years |
|-------|----------|---------|-------|
| 1.1.5 | `T10105` | GDP nominal levels | 1929–2024 |
| 1.1.6 | `T10106` | Real GDP (chained 2017$) | 1929–2024 |
| 1.7.5 | `T10705` | Gross Value Added by sector (nominal) | 1929–2024 |
| 1.14  | `T10140` | Gross Value Added: Corporate sector (nominal) | 1929–2024 |

**FRED fallback series:**
- `GDP`: Nominal GDP
- `GDPC1`: Real GDP (chained 2017$)
- `A455RC1A027NBEA`: GVA Corporate Business (nominal)
- `A455RX1A020NBEA`: GVA Corporate Business (real, chained 2012$)

### 1.2 Pre-1929 Extension (1925–1928)

BEA official NIPA starts at 1929. For 1925–1928:
- **Option A**: Use Kendrick (1961) historical GDP estimates, splice to BEA at 1929 using growth-rate linking
- **Option B**: Use FRED `GNPA` (GNP) which goes back to 1929; for 1925–1928 use Kuznets/Kendrick historical series from NBER Macrohistory database
- **Option C**: Accept 1929 as the start year for GDP (capital stock tables already start at 1925)

> **Recommendation**: Start GDP at 1929 (BEA official). Start K at 1925 (BEA Fixed Assets official start). The 4-year head start for K is actually useful for ARDL/VECM estimation (provides pre-sample observations for K lags).

### 1.3 Corporate Sector Value Added

**Primary interest**: GVA of domestic corporate nonfinancial sector

- NIPA Table 1.14 provides corporate GVA back to 1929
- For nonfinancial corporate specifically: NIPA Table 1.14 line items distinguish financial vs nonfinancial
- Corporate value added = compensation of employees + gross operating surplus + taxes on production
- **Gross** measure (including CFC) is the primary target; net = gross - CFC is secondary

### 1.4 Net Value Added (Secondary)

For cross-validation with Shaikh's net measures:
- NVA = GVA - CFC (consumption of fixed capital)
- CFC available from NIPA Table 1.7.5 or Fixed Assets depreciation tables
- This is secondary — build it but don't prioritize

---

## Phase 2: Capital Stock Series (1925–2024)

### 2.1 BEA Fixed Assets Tables Needed

The BEA Fixed Assets tables are organized in sections. We need **Section 6** (by industry group and legal form of organization) to isolate the corporate nonfinancial sector:

| Table | API Code | Content | Years |
|-------|----------|---------|-------|
| **6.1** | `FAAt601` | Current-cost **net** stock by legal form & industry | 1925–2024 |
| **6.2** | `FAAt602` | Chain-type quantity indexes for net stock | 1925–2024 |
| **6.3** | `FAAt603` | Historical-cost net stock | 1925–2024 |
| **6.4** | `FAAt604` | Current-cost **depreciation** (CFC) | 1925–2024 |
| **6.5** | `FAAt605` | Chain-type quantity indexes for depreciation | 1925–2024 |
| **6.7** | `FAAt607` | Historical-cost **investment** in fixed assets | 1925–2024 |
| **6.8** | `FAAt608` | Chain-type quantity indexes for investment | 1925–2024 |
| **6.9** | `FAAt609` | Current-cost **average age** at yearend | 1925–2024 |

**Also needed for cross-checks:**

| Table | API Code | Content |
|-------|----------|---------|
| **2.1** | `FAAt201` | Current-cost net stock by type (equipment, structures, IPP) |
| **2.4** | `FAAt204` | Current-cost depreciation by type |
| **2.7** | `FAAt207` | Investment by type (equipment, structures, IPP) |

### 2.2 Line Item Extraction Strategy

Within each Section 6 table, the row structure typically includes:

```
Private fixed assets
  Corporate
    Nonfinancial
      Equipment
      Structures
      Intellectual property products
    Financial
  Noncorporate
    ...
```

**Extraction targets** (mapping to repository taxonomy from docs/notation.md):

| Repo Code | BEA Line Description | Notes |
|-----------|---------------------|-------|
| `ME` | Equipment (corporate nonfinancial) | Machinery & equipment |
| `NRC` | Structures (corporate nonfinancial) | Non-residential construction |
| `IPP` | Intellectual property products (corporate nonfinancial) | Excluded from productive K |
| `NR` | ME + NRC | Non-residential aggregate (our productive K) |
| `Total` | ME + NRC + IPP | Total fixed capital (for reference) |

> **Critical**: IPP is identified and tracked but **excluded** from the productive capital measure (`NR = ME + NRC`). This follows Shaikh's concept that only tangible capital (equipment + structures) constitutes productive fixed capital.

### 2.3 Gross vs Net Capital Stock

BEA publishes **net** stock directly (current-cost net stock = Table 6.1). To obtain **gross** stock:

**Method A — Accumulation from investment:**
```
K_gross(t) = K_gross(t-1) + I(t) - Retirements(t)
```
BEA does not publish retirements directly, but:
- Historical-cost investment is in Table 6.7
- Current-cost depreciation is in Table 6.4
- "Other changes in volume" captures retirements, disasters, reclassifications

**Method B — Gross = Net + Accumulated Depreciation:**
```
K_gross(t) = K_net(t) + AccumulatedDepreciation(t)
```
This requires tracking accumulated depreciation, which BEA doesn't publish directly.

**Method C — Use BEA's implied gross stock:**
- The chain-type quantity indexes (Table 6.2) combined with the current-cost net stock (Table 6.1) give us the net stock in real terms
- For gross stock: BEA publishes current-cost gross stock in the **Detailed Fixed Assets Tables** (not Standard tables)

> **Recommendation**:
> 1. Primary: Extract **current-cost net stock** from FAAt601 (directly published)
> 2. Compute **gross stock via PIM** from investment (FAAt607) and depreciation (FAAt604)
> 3. Cross-validate against Shaikh's KGCcorp in the overlap period (1947–2011)

### 2.4 Shaikh's Quality Adjustment / Generalized PIM

Shaikh argues that BEA's geometric depreciation (declining-balance PIM) understates gross capital stock because it conflates physical depreciation with quality/efficiency adjustments. His approach:

1. **Standard PIM**: `K(t) = K(t-1) + I(t) - δ*K(t-1)` where δ is the geometric depreciation rate
2. **Shaikh's critique**: BEA's δ includes both physical wear-and-tear AND quality change → overstates "true" depreciation
3. **GPIM approach**: Separate physical depreciation from quality adjustment; use a lower effective depreciation rate

**Implementation strategy:**
- Build the **standard BEA series first** (baseline, reproducible from published tables)
- Add a **toggle parameter** `SHAIKH_GPIM_ADJUST = TRUE/FALSE` in config
- When toggled ON: apply Shaikh's correction factors to depreciation rates by asset type
- Document the adjustment methodology with references to Shaikh (2016) Appendix 6.8

### 2.5 WWII Adjustment Toggle

Shaikh notes that WWII introduced distortions in investment and capital stock data (1941–1945):
- Military investment was classified as private in some accounts
- Price controls distorted deflators
- Conversion of civilian plants to military production

**Implementation:**
- Add toggle `WWII_ADJUST = TRUE/FALSE`
- When ON: apply Shaikh's WWII correction (interpolation or alternative investment series for 1941–1945)
- When OFF: use raw BEA data as-is
- Document the specific adjustments applied

---

## Phase 3: Price Indices & Deflators (Stock-Flow Consistency)

### 3.1 The Stock-Flow Consistency Principle

Shaikh emphasizes that the deflator used for output (Y) and the deflator used for capital (K) must be **consistent** — ideally the same index — to avoid spurious real capital-output ratios.

**Current Shaikh replication**: Uses `pIGcorpbea` (implicit price deflator for gross investment in corporate capital goods) for both Y and K.

### 3.2 Price Indices to Extract

| Series | Source | Description |
|--------|--------|-------------|
| `pIG` | FAAt608 implied | Implicit price deflator for gross investment (corporate nonfinancial) |
| `pKN` | FAAt601/FAAt602 implied | Implicit price deflator for net capital stock |
| `pKG` | Computed | Implicit price deflator for gross capital stock |
| `pY_corp` | NIPA T1.14 implied | Implicit deflator for corporate GVA |
| `pGDP` | NIPA T1.1.4 / FRED `GDPDEF` | GDP implicit price deflator |

**Implicit deflator computation:**
```
p_implicit(t) = Nominal_value(t) / Real_value(t) × 100
```
where Real_value comes from chain-type quantity index × base-year nominal / 100.

### 3.3 Asset-Type Deflators

For separate ME, NRC, IPP deflators:
- Extract from Section 2 tables (by type) or derive from Section 6 if available by type within legal form
- These enable Shaikh's stock-flow consistency check: does deflating K by pIG (investment goods price) vs pKN (net capital stock price) change results?

### 3.4 Rebasing

All indices rebased to **2017 = 100** (current BEA convention) unless matching Shaikh's **2005 = 100** base for backward compatibility with existing replication pipeline.

> **Decision needed**: Use 2017 base (BEA current) or 2005 base (Shaikh compatibility)?
> **Recommendation**: Store in 2017 base (matches BEA releases), provide utility function to rebase to any year.

---

## Phase 4: Dataset Assembly & Output

### 4.1 Output CSV Structure

**Primary output**: `data/processed/bea_extended_dataset_v1.csv`

| Column | Description | Source |
|--------|-------------|--------|
| `year` | 1925–2024 | — |
| `GDP_nom` | Nominal GDP | NIPA 1.1.5 |
| `GDP_real_2017` | Real GDP (chained 2017$) | NIPA 1.1.6 |
| `GVA_corp_nom` | Corporate GVA (nominal) | NIPA 1.14 |
| `GVA_corpNF_nom` | Corporate nonfinancial GVA (nominal) | NIPA 1.14 |
| `CFC_corpNF` | Capital consumption (corporate NF) | FAAt604 |
| `NVA_corpNF_nom` | Net value added = GVA - CFC | Derived |
| `K_net_ME` | Net stock: machinery & equipment (current cost) | FAAt601 |
| `K_net_NRC` | Net stock: structures (current cost) | FAAt601 |
| `K_net_IPP` | Net stock: intellectual property (current cost) | FAAt601 |
| `K_net_NR` | Net stock: ME + NRC (productive capital) | Derived |
| `K_net_Total` | Net stock: ME + NRC + IPP | Derived |
| `K_gross_ME` | Gross stock: machinery & equipment | PIM from FAAt607 |
| `K_gross_NRC` | Gross stock: structures | PIM from FAAt607 |
| `K_gross_NR` | Gross stock: ME + NRC | Derived |
| `K_gross_Total` | Gross stock: ME + NRC + IPP | Derived |
| `I_ME` | Investment in equipment | FAAt607 |
| `I_NRC` | Investment in structures | FAAt607 |
| `I_IPP` | Investment in IPP | FAAt607 |
| `I_NR` | Investment: ME + NRC | Derived |
| `DEP_ME` | Depreciation: equipment | FAAt604 |
| `DEP_NRC` | Depreciation: structures | FAAt604 |
| `DEP_IPP` | Depreciation: IPP | FAAt604 |
| `DEP_NR` | Depreciation: ME + NRC | Derived |
| `pIG_ME` | Price index: equipment investment | FAAt608 implied |
| `pIG_NRC` | Price index: structures investment | FAAt608 implied |
| `pIG_NR` | Price index: NR investment (aggregate) | FAAt608 implied |
| `pKN_NR` | Price index: net capital stock (NR) | FAAt601/602 implied |
| `pGDP` | GDP deflator | NIPA 1.1.4 |
| `avg_age_ME` | Average age: equipment | FAAt609 |
| `avg_age_NRC` | Average age: structures | FAAt609 |
| `shaikh_gpim_adj` | Boolean: Shaikh GPIM adjustment applied | Toggle |
| `wwii_adj` | Boolean: WWII adjustment applied | Toggle |

### 4.2 Metadata & Documentation

**New file: `docs/bea_dataset_codebook.md`** documenting:
- Every variable: definition, BEA table source, line number, computation formula
- Splicing methodology for pre-1929 (if used)
- Shaikh GPIM adjustment methodology (when toggle ON)
- WWII adjustment methodology (when toggle ON)
- BEA vintage date (which annual release the data comes from)
- Reproducibility: exact API calls or download URLs

### 4.3 Validation Checks

1. **Internal consistency**: `K_net_NR = K_net_ME + K_net_NRC` (exact)
2. **BEA cross-check**: Compare our derived gross stock against BEA's published detailed tables
3. **Shaikh overlap**: Compare against `Shaikh_canonical_series_v1.csv` for 1947–2011 overlap period
   - `K_net_NR` ≈ `KNCcorpbea` (should be close modulo vintage differences)
   - `K_gross_NR` ≈ `KGCcorp` (after GPIM adjustment)
   - `GVA_corp_nom` ≈ `VAcorp`
4. **Accounting identity**: `K_net(t) = K_net(t-1) + I(t) - DEP(t) + OtherChanges(t)`

---

## Phase 5: Configuration & Integration

### 5.1 New Config Entries

Add to `10_config.R` (or a new `11_config_extended.R`):

```r
CONFIG_EXT <- list(
  # Extended dataset
  data_bea_extended = "data/processed/bea_extended_dataset_v1.csv",

  # Toggles
  SHAIKH_GPIM_ADJUST = FALSE,  # Default: standard BEA depreciation
  WWII_ADJUST = FALSE,          # Default: no WWII correction

  # Asset taxonomy (matching docs/notation.md)
  asset_types = c("ME", "NRC", "IPP"),
  productive_K = c("ME", "NRC"),  # IPP excluded

  # Base year for deflators
  deflator_base_year = 2017,  # BEA current convention

  # Sample window (extended)
  WINDOWS_EXT = list(
    full_bea     = c(1929, 2024),
    full_K       = c(1925, 2024),
    shaikh_orig  = c(1947, 2011),
    extended     = c(1947, 2024)
  )
)
```

### 5.2 Integration with Existing Pipeline

The extended dataset is a **new, parallel data source** — it does NOT replace `Shaikh_canonical_series_v1.csv`. The existing S0/S1/S2 pipeline continues to use Shaikh's original data for faithful replication. The extended dataset enables:
- **Forward extension**: Run ARDL/VECM models on 1947–2024 (13 extra years)
- **Robustness checks**: Compare deflator choices with the extended sample
- **Structural break analysis**: Test whether post-2011 data changes parameter stability

---

## Phase 6: Script Structure

### New files to create:

| File | Purpose |
|------|---------|
| `codes/30_bea_data_build.py` | Main Python script: download, extract, assemble BEA data |
| `codes/31_bea_validation.py` | Validation: internal consistency, Shaikh overlap comparison |
| `codes/32_shaikh_gpim_adjustment.py` | GPIM toggle: Shaikh's quality-adjusted depreciation rates |
| `docs/bea_dataset_codebook.md` | Full variable codebook and methodology documentation |

> **Note**: The `30_`-series numbering is reserved for Chapter 4 reduced-rank VECM in the current handoff doc. Since this is a **data construction** task (not a model), we could use `15_`-series instead (`15_bea_data_build.py`, `16_bea_validation.py`). This keeps the `20`-series for models and `30`-series for Chapter 4.

### Alternative numbering (recommended):

| File | Purpose |
|------|---------|
| `codes/15_bea_data_build.py` | Main data construction |
| `codes/16_bea_validation.py` | Validation checks |
| `codes/17_shaikh_gpim_adjust.py` | GPIM toggle |
| `docs/bea_dataset_codebook.md` | Codebook |

---

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| BEA API key required | Fall back to direct CSV download from BEA interactive tables |
| BEA API rate limits | Cache all downloads locally; re-download only when vintage changes |
| Section 6 tables may not have ME/NRC/IPP breakdown | Fall back to Section 2 (by type, all private) + Section 6 (by legal form, total) and compute corporate share |
| 1925–1928 GDP not available from BEA | Accept 1929 start for GDP; K starts at 1925 from Fixed Assets |
| Shaikh GPIM parameters not fully specified | Use Shaikh (2016) Appendix 6.8 calibration; mark as "approximate" |
| WWII adjustment methodology ambiguous | Implement as linear interpolation 1941–1945; document as provisional |
| Python not standard in this R-centric project | Python scripts are clearly marked as data-build utilities; output is CSV consumed by R |

---

## Execution Sequence

1. **Create directory structure** (`data/raw/bea_downloads/`, output dirs)
2. **Write `15_bea_data_build.py`** with download + extraction + assembly logic
3. **Test BEA API access** (or set up CSV fallback)
4. **Download all required tables** and cache locally
5. **Extract line items** for corporate nonfinancial by asset type
6. **Compute derived series** (gross stock via PIM, aggregates, deflators)
7. **Write `16_bea_validation.py`** — run internal consistency and Shaikh overlap checks
8. **Write codebook** (`docs/bea_dataset_codebook.md`)
9. **Write `17_shaikh_gpim_adjust.py`** — implement GPIM toggle
10. **Update config** with new data paths and toggles
11. **Commit and push**
