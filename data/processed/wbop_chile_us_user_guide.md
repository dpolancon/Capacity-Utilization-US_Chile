# WBOP Chile–United States processed panel

## Scope

This processed file contains all available WBOP series for Chile and the United States only.
Source workbook: `C:\ReposGitHub\Capacity-Utilization-US_Chile\data\raw\other\NievasPiketty2025WBOPFinalSeries.xlsx`.
Used sheets: `A1`, `B1a`, `B1b`, `B1c`, `B2a`, `B2b`, `B2c`, `B3a`, `B3b`, `B3c`, `C1a`, `C1b`, `C1c`, `C1d`, `C1e`, `C1f`, `D1a`, `D1b`, `D1c`, `E1a`, `E1b`, `E1c`, `F1`, `G1a`, `G1b`, `G1c`.

## Detected structure

Entity representation was detected from the wide data-sheet headers.
United States raw label: `US`.
Chile raw label: `CL`.
Time variable: annual year in the first column.
Overall source year coverage: 1800-2025.

## Output shape

The processed CSV is wide.
Rows are unique `entity`-`year` pairs.
Columns after `standardized_entity`, `raw_entity_label`, and `year` preserve the original variable names exactly as they appear in the workbook’s title cells.
Wide format is the conservative choice here because the source workbook itself stores one measure per sheet rather than a single long panel table.

## Integrity checks

Checks performed:
- duplicate year rows inside each numeric sheet
- duplicate entity-year-variable rows after normalization
- duplicate entity-year rows in the final Chile–US panel
- missingness by entity and variable after the 1900 filter
- constant-series screening for the visual bundle
- entity-label review against the auxiliary WBOP coverage sheet

Duplicate handling decision: no aggregation or collapse rule was applied because no duplicate conflicts required resolution.

## Missing-data notes

Missingness summary for Chile and the United States after 1900:

| source_sheet | original_variable_name                                         | standardized_entity | missingness_share | min_year_available | max_year_available |
| ------------ | -------------------------------------------------------------- | ------------------- | ----------------- | ------------------ | ------------------ |
| A1           | Data series on GDP (current millions dollars MER)              | Chile               | 0.0%              | 1900               | 2025               |
| A1           | Data series on GDP (current millions dollars MER)              | United States       | 0.0%              | 1900               | 2025               |
| B1a          | Data series on net trade balance (goods) (% GDP)               | Chile               | 0.0%              | 1900               | 2025               |
| B1a          | Data series on net trade balance (goods) (% GDP)               | United States       | 0.0%              | 1900               | 2025               |
| B1b          | Data series on exports in goods (% GDP)                        | Chile               | 0.0%              | 1900               | 2025               |
| B1b          | Data series on exports in goods (% GDP)                        | United States       | 0.0%              | 1900               | 2025               |
| B1c          | Data series on imports in goods (% GDP)                        | Chile               | 0.0%              | 1900               | 2025               |
| B1c          | Data series on imports in goods (% GDP)                        | United States       | 0.0%              | 1900               | 2025               |
| B2a          | Data series on net trade balance (primary commodities) (% GDP) | Chile               | 0.0%              | 1900               | 2025               |
| B2a          | Data series on net trade balance (primary commodities) (% GDP) | United States       | 0.0%              | 1900               | 2025               |
| B2b          | Data series on exports in primary commodities (% GDP)          | Chile               | 0.0%              | 1900               | 2025               |
| B2b          | Data series on exports in primary commodities (% GDP)          | United States       | 0.0%              | 1900               | 2025               |
| B2c          | Data series on imports in primary commodities (% GDP)          | Chile               | 0.0%              | 1900               | 2025               |
| B2c          | Data series on imports in primary commodities (% GDP)          | United States       | 0.0%              | 1900               | 2025               |
| B3a          | Data series on net trade balance (manufactured goods) (% GDP)  | Chile               | 0.0%              | 1900               | 2025               |
| B3a          | Data series on net trade balance (manufactured goods) (% GDP)  | United States       | 0.0%              | 1900               | 2025               |
| B3b          | Data series on exports in manufactured goods (% GDP)           | Chile               | 0.0%              | 1900               | 2025               |
| B3b          | Data series on exports in manufactured goods (% GDP)           | United States       | 0.0%              | 1900               | 2025               |
| B3c          | Data series on imports in manufactured goods (% GDP)           | Chile               | 0.0%              | 1900               | 2025               |
| B3c          | Data series on imports in manufactured goods (% GDP)           | United States       | 0.0%              | 1900               | 2025               |
| C1a          | Data series on net trade balance (services) (% GDP)            | Chile               | 0.0%              | 1900               | 2025               |
| C1a          | Data series on net trade balance (services) (% GDP)            | United States       | 0.0%              | 1900               | 2025               |
| C1b          | Data series on exports in services (% GDP)                     | Chile               | 0.0%              | 1900               | 2025               |
| C1b          | Data series on exports in services (% GDP)                     | United States       | 0.0%              | 1900               | 2025               |
| C1c          | Data series on imports in services (% GDP)                     | Chile               | 0.0%              | 1900               | 2025               |
| C1c          | Data series on imports in services (% GDP)                     | United States       | 0.0%              | 1900               | 2025               |
| C1d          | Data series on net trade balance (goods+services) (% GDP)      | Chile               | 0.0%              | 1900               | 2025               |
| C1d          | Data series on net trade balance (goods+services) (% GDP)      | United States       | 0.0%              | 1900               | 2025               |
| C1e          | New series on exports in goods + services (% GDP) (MER $)      | Chile               | 0.0%              | 1900               | 2023               |
| C1e          | New series on exports in goods + services (% GDP) (MER $)      | United States       | 0.0%              | 1900               | 2023               |
| C1f          | New series on imports in goods + services (% GDP) (MER $)      | Chile               | 0.0%              | 1900               | 2023               |
| C1f          | New series on imports in goods + services (% GDP) (MER $)      | United States       | 0.0%              | 1900               | 2023               |
| D1a          | Data series on net income balance (% GDP)                      | Chile               | 0.0%              | 1900               | 2025               |
| D1a          | Data series on net income balance (% GDP)                      | United States       | 0.0%              | 1900               | 2025               |
| D1b          | Data series on foreign income inflows (% GDP)                  | Chile               | 0.0%              | 1900               | 2025               |
| D1b          | Data series on foreign income inflows (% GDP)                  | United States       | 0.0%              | 1900               | 2025               |
| D1c          | Data series on foreign income outflows (% GDP)                 | Chile               | 0.0%              | 1900               | 2025               |
| D1c          | Data series on foreign income outflows (% GDP)                 | United States       | 0.0%              | 1900               | 2025               |
| E1a          | Data series on net transfer balance (% GDP)                    | Chile               | 0.0%              | 1900               | 2025               |
| E1a          | Data series on net transfer balance (% GDP)                    | United States       | 0.0%              | 1900               | 2025               |
| E1b          | Data series on foreign transfer inflows (% GDP)                | Chile               | 0.0%              | 1900               | 2025               |
| E1b          | Data series on foreign transfer inflows (% GDP)                | United States       | 0.0%              | 1900               | 2025               |
| E1c          | Data series on foreign transfer outflows (% GDP)               | Chile               | 0.0%              | 1900               | 2025               |
| E1c          | Data series on foreign transfer outflows (% GDP)               | United States       | 0.0%              | 1900               | 2025               |
| F1           | Data series on net current account (% GDP)                     | Chile               | 0.0%              | 1900               | 2025               |
| F1           | Data series on net current account (% GDP)                     | United States       | 0.0%              | 1900               | 2025               |
| G1a          | Data series on foreign wealth across world regions (% GDP)     | Chile               | 0.0%              | 1900               | 2025               |
| G1a          | Data series on foreign wealth across world regions (% GDP)     | United States       | 0.0%              | 1900               | 2025               |
| G1b          | Data series on gross foreign assets (% GDP)                    | Chile               | 0.0%              | 1900               | 2025               |
| G1b          | Data series on gross foreign assets (% GDP)                    | United States       | 0.0%              | 1900               | 2025               |
| G1c          | Data series on gross foreign liabilities (% GDP)               | Chile               | 0.0%              | 1900               | 2025               |
| G1c          | Data series on gross foreign liabilities (% GDP)               | United States       | 0.0%              | 1900               | 2025               |

## Variable dictionary summary

| source_sheet | original_variable_name                                         | included_in_visual_bundle | included_in_chile_us_panel | percent_missing |
| ------------ | -------------------------------------------------------------- | ------------------------- | -------------------------- | --------------- |
| A1           | Data series on GDP (current millions dollars MER)              | yes                       | yes                        | 0.0             |
| B1a          | Data series on net trade balance (goods) (% GDP)               | yes                       | yes                        | 0.0             |
| B1b          | Data series on exports in goods (% GDP)                        | yes                       | yes                        | 0.0             |
| B1c          | Data series on imports in goods (% GDP)                        | yes                       | yes                        | 0.0             |
| B2a          | Data series on net trade balance (primary commodities) (% GDP) | yes                       | yes                        | 0.0             |
| B2b          | Data series on exports in primary commodities (% GDP)          | yes                       | yes                        | 0.0             |
| B2c          | Data series on imports in primary commodities (% GDP)          | yes                       | yes                        | 0.0             |
| B3a          | Data series on net trade balance (manufactured goods) (% GDP)  | yes                       | yes                        | 0.0             |
| B3b          | Data series on exports in manufactured goods (% GDP)           | yes                       | yes                        | 0.0             |
| B3c          | Data series on imports in manufactured goods (% GDP)           | yes                       | yes                        | 0.0             |
| C1a          | Data series on net trade balance (services) (% GDP)            | yes                       | yes                        | 0.0             |
| C1b          | Data series on exports in services (% GDP)                     | yes                       | yes                        | 0.0             |
| C1c          | Data series on imports in services (% GDP)                     | yes                       | yes                        | 0.0             |
| C1d          | Data series on net trade balance (goods+services) (% GDP)      | yes                       | yes                        | 0.0             |
| C1e          | New series on exports in goods + services (% GDP) (MER $)      | yes                       | yes                        | 0.0             |
| C1f          | New series on imports in goods + services (% GDP) (MER $)      | yes                       | yes                        | 0.0             |
| D1a          | Data series on net income balance (% GDP)                      | yes                       | yes                        | 0.0             |
| D1b          | Data series on foreign income inflows (% GDP)                  | yes                       | yes                        | 0.0             |
| D1c          | Data series on foreign income outflows (% GDP)                 | yes                       | yes                        | 0.0             |
| E1a          | Data series on net transfer balance (% GDP)                    | yes                       | yes                        | 0.0             |
| E1b          | Data series on foreign transfer inflows (% GDP)                | yes                       | yes                        | 0.0             |
| E1c          | Data series on foreign transfer outflows (% GDP)               | yes                       | yes                        | 0.0             |
| F1           | Data series on net current account (% GDP)                     | yes                       | yes                        | 0.0             |
| G1a          | Data series on foreign wealth across world regions (% GDP)     | yes                       | yes                        | 0.0             |
| G1b          | Data series on gross foreign assets (% GDP)                    | yes                       | yes                        | 0.0             |
| G1c          | Data series on gross foreign liabilities (% GDP)               | yes                       | yes                        | 0.0             |

## Caveats for later analytical use

- Country units in the numeric sheets are coded (`US`, `GB`, `CL`) rather than fully spelled out.
- The auxiliary `WBOP` sheet spells out names such as `USA`, `Britain`, and `Chile`; those naming differences were documented rather than forced into the numeric source.
- Region labels vary slightly across some sheets. The Chile–US panel is unaffected because it uses only `US` and `CL`.
- This file is an extraction and inspection product. It does not impose semantic harmonization beyond the explicit standardization of the entity labels in the processed output.
