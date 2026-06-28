# D04 GPIM S12D_B Source Price and Seed Audit

## Purpose
D04 audits the S12D_B source objects, implicit-price recovery, and seed-price treatment that feed S29C real ME/NRC investment construction. It is bounded to source-price diagnosis and does not decide initialization, warmup treatment, or GPIM refreeze.

## Branch and base commit
- Branch: `feature/us-gpim-d04-s12db-source-price-seed-audit`
- HEAD at run: `7d85d5510a131cba584e25db34f331fb16e6aa12`
- Base `origin/main`: `7d85d5510a131cba584e25db34f331fb16e6aa12`

## D01/D02/D03 context
D01 fixed the physical retirement/survival schedule defect. D02 showed the remaining low endpoint is not a survival-engine defect and pointed to weak input paths plus initialization-history sensitivity. D03 showed S29C arithmetic reconstructs exactly from nominal investment and price inputs. D04 therefore audits the upstream S12D_B source-price machinery rather than S29C formula scaling.

## S12D_B file inventory
D04 inventoried 93 local files across S12D/S13/S29C/D03/provider handoff context. See `D04_s12db_file_inventory.csv`.

## Source-object admissibility findings
The direct NFC ME and NRC current-cost nominal investment flows are admissible as nominal investment inputs. The BEA quantity indexes are not admissible as headline deflators. The S12D_B price object is a recursively recovered SFC implicit price, not a directly sourced BEA investment price, and therefore remains conceptually high risk until the price protocol is rebuilt or independently justified.

## Implicit-price recovery findings
Annual recovery reproduces the stored S12D_B and S29C price paths for ME and NRC within tolerance. Maximum absolute recovery difference versus S12D_B is 0.000000000000454747. This resolves arithmetic recovery at the stored-object layer but not conceptual admissibility of the recovered price.

## Seed-price and backcast findings
Seed-price spans are present for both assets. ME seed-to-2024 ratio is 0.000937965; NRC seed-to-2024 ratio is 0.000434117. Seed treatment is classified as a refreeze-blocking risk because early prices are carried from initialization rather than directly recovered.

## S12D_B to S29C bridge findings
The S12D_B to S29C bridge is exact within tolerance for both assets: ME S12D_B to S29C bridge is arithmetically exact within tolerance; D04 defect classification must be upstream of S29C. NRC S12D_B to S29C bridge is arithmetically exact within tolerance; D04 defect classification must be upstream of S29C.

## Shaikh context
Shaikh diagnostic tables are used only as context. D04 does not require equality with Shaikh. The comparison supports the classification that the remaining GPIM gap is plausibly tied to Chapter 2 source-price behavior and unresolved scope/provider-price comparability, not to an S29C arithmetic defect.

## Decision matrix summary
Recommendation: `RECONSTRUCT_PRICE_INDEX_BEFORE_WARMUP`.

## What D04 resolves
- S29C consumes S12D_B objects without bridge differences.
- The nominal source object is analytically admissible for NFC ME/NRC current-cost investment.
- The stored implicit price can be arithmetically recovered from S12D_B nominal and real-flow columns.

## What remains unresolved
- The recovered SFC price object is not a directly sourced investment deflator.
- Seed/backcast treatment is material and not independently validated.
- Provider vintage, source-price concept, and Shaikh boundary differences remain unresolved evidence rather than retirement-engine explanations.

## Recommended next phase
Run a bounded price-index reconstruction and provider-price concept review before any initialization/warmup decision. Do not refreeze GPIM until the price recovery and seed treatment are repaired or explicitly re-authorized.

## Authorization boundary
D04 is audit-only. It does not authorize replacement of the frozen Chapter 2 capital stock, S31/S32 reruns, VECM estimation, investment-function estimation, paper-facing baseline use, downstream econometric consumption, initialization/warmup treatment, or GPIM refreeze.
