# Fixed Asset Taxonomy and Notation

## Version: v1.0 (2026-03-13)

---

## 1. Asset Type Classification

The dataset follows a hierarchical asset taxonomy aligned with BEA Fixed Assets
Accounts (Standard Tables). Intellectual property products (IPP) are tracked but
excluded from the **productive capital** aggregate.

### 1.1 Private Non-Residential Fixed Assets

| Code   | Label                          | BEA Category              | Productive? |
|--------|--------------------------------|---------------------------|-------------|
| `ME`   | Machinery and Equipment        | Equipment                 | YES         |
| `NRC`  | Non-Residential Construction   | Structures (nonresid.)    | YES         |
| `IPP`  | Intellectual Property Products | Software, R&D, Originals  | NO (tracked)|

### 1.2 Private Residential Fixed Assets

| Code   | Label                          | BEA Category              | Productive? |
|--------|--------------------------------|---------------------------|-------------|
| `RC`   | Residential Construction       | Residential structures    | NO (tracked)|

### 1.3 Aggregates

| Code    | Definition        | Components      | Notes                             |
|---------|-------------------|-----------------|-----------------------------------|
| `NR`    | Non-Residential   | `ME + NRC`      | **Primary productive capital**    |
| `Total` | Total Private     | `ME + NRC + RC` | Total tangible fixed capital      |
| `NR_IPP`| NR + IPP          | `ME + NRC + IPP`| Total nonresidential (all types)  |

---

## 2. Sectoral Classification

| Code      | Label                          | BEA Legal Form                    |
|-----------|--------------------------------|-----------------------------------|
| `Corp`    | Corporate Business             | All entities filing IRS Form 1120 |
| `CorpNF`  | Corporate Nonfinancial         | Corporate excluding finance/ins.  |
| `CorpF`   | Corporate Financial            | Finance, insurance, RE corps      |
| `Noncorp` | Noncorporate Business          | Partnerships, sole proprietors    |
| `Priv`    | Total Private                  | Corporate + Noncorporate          |

**Primary sector of interest**: `CorpNF` (corporate nonfinancial).

---

## 3. Government Fixed Assets

Government fixed assets are tracked separately using BEA Fixed Assets Section 7
(Standard Tables) or NIPA Table 7.1.

| Code       | Label                          | Components                       |
|------------|--------------------------------|----------------------------------|
| `Gov`      | Total Government               | Federal + State & Local          |
| `Gov_Def`  | Federal: National Defense      | ME + NRC + IPP (defense)         |
| `Gov_NDef` | Federal: Nondefense            | ME + NRC + IPP (nondefense)      |
| `Gov_SL`   | State and Local                | ME + NRC + IPP (state & local)   |

Within each government sub-sector, the same asset-type breakdown applies:
- Equipment (ME)
- Structures (NRC)
- Intellectual Property Products (IPP)

Only **broad aggregates** are extracted (no refined sub-categories within
defense/nondefense).

---

## 4. Stock Measures

| Suffix  | Measure                        | BEA Concept                      |
|---------|--------------------------------|----------------------------------|
| `_net`  | Net Stock (current cost)       | After depreciation               |
| `_gross`| Gross Stock                    | Before depreciation (PIM-based)  |
| `_hist` | Historical-Cost Stock          | At original acquisition prices   |

**Primary measures**: `_net` (BEA published) and `_gross` (derived via PIM).

---

## 5. Flow Measures

| Prefix  | Measure                        | BEA Table Source                 |
|---------|--------------------------------|----------------------------------|
| `I_`    | Investment (historical cost)   | Fixed Assets Table x.7           |
| `DEP_`  | Depreciation (current cost)    | Fixed Assets Table x.4           |
| `CFC_`  | Capital Consumption (= DEP)    | NIPA terminology                 |

---

## 6. Price Indices

| Code     | Description                              | Stock-Flow Role            |
|----------|------------------------------------------|----------------------------|
| `pIG`    | Implicit price deflator, investment      | Deflates investment flows  |
| `pKN`    | Implicit price deflator, net stock       | Deflates net K stock       |
| `pKG`    | Implicit price deflator, gross stock     | Deflates gross K stock     |
| `pGDP`   | GDP implicit price deflator              | Deflates GDP/GVA           |
| `pY`     | GVA deflator (corporate sector)          | Deflates sector output     |

**Stock-flow consistency rule** (Shaikh 2016): The same deflator should be used
for both output (Y) and capital (K) to avoid spurious real capital-output ratios.
When BEA uses chain-type quantity indexes, the implied deflator for stocks differs
from the deflator for flows, which can break this consistency.

---

## 7. Naming Convention for Variables

Full variable names follow the pattern:

```
{measure}_{asset}_{sector}
```

Examples:
- `K_net_NR_CorpNF` — Net stock, non-residential, corporate nonfinancial
- `I_ME_CorpNF` — Investment in equipment, corporate nonfinancial
- `DEP_NRC_CorpNF` — Depreciation of structures, corporate nonfinancial
- `K_gross_NR_Gov_Def` — Gross stock, non-residential, government defense

In the output CSV, sector suffixes may be omitted when the context is
unambiguous (e.g., the primary dataset focuses on `CorpNF`).

---

## 8. Toggle Flags

| Flag               | Default | Description                                    |
|--------------------|---------|------------------------------------------------|
| `SHAIKH_GPIM`      | `FALSE` | Apply Shaikh's generalized PIM adjustment      |
| `WWII_ADJ`         | `FALSE` | Apply WWII-era investment/capital corrections   |

When `SHAIKH_GPIM = TRUE`, the gross capital stock uses adjusted depreciation
rates that separate physical wear-and-tear from quality/efficiency changes in
new vintages. This follows Shaikh (2016, Appendix 6.8).

When `WWII_ADJ = TRUE`, investment and capital data for 1941-1945 are corrected
for the reclassification of military production and price control distortions.

---

## 9. Data Sources

| Source   | Coverage  | Access                                            |
|----------|-----------|---------------------------------------------------|
| BEA NIPA | 1929-2024 | API (`DataSetName=NIPA`) or interactive tables     |
| BEA FA   | 1925-2024 | API (`DataSetName=FixedAssets`) or interactive     |
| FRED     | varies    | Direct CSV download (no key required)              |
| ALFRED   | varies    | Vintage/archival FRED data                         |

**BEA API registration**: Free at `https://apps.bea.gov/API/signup/index.cfm`

---

## 10. Base Year

All price indices are stored with **2017 = 100** (current BEA convention).
A utility function `rebase(series, from_year, to_year)` enables conversion
to any base year (e.g., 2005 for backward compatibility with Shaikh replication).
