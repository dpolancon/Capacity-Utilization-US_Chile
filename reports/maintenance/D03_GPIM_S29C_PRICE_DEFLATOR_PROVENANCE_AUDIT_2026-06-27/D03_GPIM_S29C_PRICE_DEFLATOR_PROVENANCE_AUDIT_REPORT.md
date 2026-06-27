# D03 GPIM S29C Investment-Price and Deflator Provenance Audit

**Date:** 2026-06-27
**Branch:** `feature/us-gpim-d03-s29c-price-deflator-provenance-audit`
**Base commit:** `0765c69896bf759ef0cff443bc724498fd22ffbf`
**Status:** Audit-only output; not authorized for econometric consumption.

## Purpose

D03 audits whether the low S29C real-investment paths used by D01 and D02 arise from nominal investment paths, asset-specific deflators, rebasing, unit scaling, filtering, or source-object mismatch.

## D01 and D02 context

D01 resolved the retirement/survival schedule cliff. D02 showed that the corrected full-history endpoint remains low and that S29C input paths, especially NRC, are material to the gap. D03 audits the S29C nominal-to-real construction behind those paths.

## S29C provenance map

S29C maps ME and NRC real investment to S12D_B nominal investment and S12D_B SFC implicit price columns. The detected formula is `I_NOMINAL_DIRECT_* / (P_*_2017 / 100)`. The target base year is 2017 and no rebasing is recorded as required inside S29C.

## Nominal-path findings

ME nominal investment changes from `9960` in 1947 to `1028975` in 2024, a ratio of `103.310743`.
NRC nominal investment changes from `5233` in 1947 to `629156` in 2024, a ratio of `120.22855`.

## Deflator/price-path findings

ME deflator changes from `1.095557` in 1947 to `147.176933` in 2024, a ratio of `134.339808`.
NRC deflator changes from `0.434767` in 1947 to `174.747971` in 2024, a ratio of `401.934326`.
The deflator path depresses real investment relative to nominal investment because the price indexes rise strongly on a 2017=100 basis.

## Real-investment reconstruction results

ME reconstruction max absolute difference is `4.6566129e-09`; NRC reconstruction max absolute difference is `4.8894435e-09`. Reconstruction passes for both assets, so S29C arithmetic, rebasing, and unit scaling are not the immediate defect.

## S29C-vs-Shaikh context

Under the Shaikh constant diagnostic engine, Chapter 2 input ends at `90.739` while Shaikh asset input ends at `980.532` on a 1947=100 basis. D03 does not require agreement with Shaikh; the comparison shows that S29C provenance explains why the Chapter 2 input path remains low.

## Attribution summary

D03 resolves S29C arithmetic: nominal divided by the S29C price column mechanically reproduces the real investment series. The immediate mechanical reason the real path is low is that the deflator rises faster than nominal investment, especially for NRC. The remaining material channels are implicit-price recovery, possible source-object mismatch, and upstream provider-vintage issues.

## What D03 resolves

D03 rules out S29C-level formula, rebasing, and unit-scaling errors as the cause of the low D01/D02 input path.

## What remains unresolved

- Whether the S12D_B nominal source object is the correct Chapter 2 analytical object.
- Whether the S12D_B implicit price recovery and seed-price treatment are appropriate for paper-facing use.
- Whether provider vintage or revision history changes the nominal or price path.
- Whether boundary differences against Shaikh diagnostic paths should remain contextual only.

## Authorization boundary

D03 is audit-only. It does not authorize replacement of the frozen Chapter 2 capital stock, S31/S32 reruns, VECM estimation, investment-function estimation, paper-facing baseline use, downstream econometric consumption, or initialization/warmup treatment.

## Recommended next phase

Run a bounded D04 S12D_B source-object, implicit-price recovery, and seed-price audit before any initialization/warmup decision or refreeze.
