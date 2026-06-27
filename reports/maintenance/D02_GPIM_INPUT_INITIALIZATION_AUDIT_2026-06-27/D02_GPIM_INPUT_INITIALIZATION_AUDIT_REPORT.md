# D02 GPIM Input-Path and Initialization-History Audit

**Date:** 2026-06-27
**Branch:** `feature/us-gpim-d02-input-initialization-audit`
**Base commit:** `49f6aebfc7ba3f1ac450788f175a26b681d83e72`
**Status:** Audit-only output; not authorized for econometric consumption.

## Purpose

D02 explains why the D01 corrected gross-survival stock remains low relative to Shaikh diagnostic paths. The audit focuses on input-path differences, initialization-history treatment, and asset-boundary or scope differences.

## D01 result being audited

D01 fixed the survival cliff and produced a 2024 core ME+NRC index of `41.808879` on a 1947=100 basis. The frozen diagnostic endpoint was `35.806099`. D01 resolved the retirement-schedule defect but did not authorize baseline replacement.

## Input-path findings

S29C ME real investment changes from `909126.492` in 1947 to `699141.486` in 2024, a 2024/1947 ratio of `0.769026`.
S29C NRC real investment changes from `1203631.9` in 1947 to `360036.226` in 2024, a 2024/1947 ratio of `0.299125`.
The cross-switch diagnostic is decisive: under the Shaikh constant retirement engine, Chapter 2 input ends at `90.739` while Shaikh asset input ends at `980.532` on the same 1947=100 basis. The input path remains a high-materiality source of the gap independent of the survival schedule.

## Initialization-history findings

Full-history D02 replication ends at `41.808879`, matching D01. The 1925 cold start ends at `64.866722`, the 1931 cold start ends at `121.055947`, and the 1947 cold start ends at `1335.140484` on a 1947=100 basis.
The inherited pre-1947 vintage history is therefore material. Later cold starts raise the 1947-based endpoint because they remove inherited vintage-stock composition from the denominator and early stock path.

## Scope/boundary findings

D02 keeps ME and NRC inside the core. Government transportation and IPP remain parked or conditioning objects. Total NFC fixed assets and Shaikh diagnostic paths remain comparators, not D01/D02 core objects. Boundary differences remain classified, not resolved as an additive numerical contribution.

## Gap attribution matrix summary

D01 resolved the retirement/survival schedule defect. D02 tests and confirms that input-path and initialization-history differences remain material. D02 classifies scope and boundary differences, flags price/deflator differences as a bounded follow-up, and leaves remaining unidentified differences open until those decisions close.

## What D01 resolved

D01 removed the forced mass exit at mean service life and produced a validated gross-survival stock under untruncated Weibull survival.

## What D02 resolves or narrows

D02 narrows the post-D01 gap to input-path, initialization-history, and unresolved boundary/deflator decisions. It confirms that the low D01 endpoint is not a residual survival-cliff problem.

## Remaining unresolved decisions

- Audit S29C nominal-to-real investment and deflator construction against provider and Shaikh asset inputs.
- Decide inherited-vintage and warmup treatment before any refreeze.
- Decide whether parked boundary objects remain outside the core or become conditioning variables only.
- Preserve boundary discipline before any paper-facing baseline replacement.

## Authorization boundary

D02 is audit-only. It does not authorize replacement of the frozen Chapter 2 capital stock, S31/S32 reruns, VECM estimation, investment-function estimation, paper-facing baseline use, or downstream econometric consumption.

## Recommended next phase

Run a bounded D03 S29C investment-price and deflator provenance audit, then a separate initialization/warmup decision pass before any refreeze.
