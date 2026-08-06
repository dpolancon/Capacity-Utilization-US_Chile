---
type: paper_facing
status: draft
depends_on:
  - chapter2_vault/04_data_measurement/D03_capacity_utilization_level_anchor_pinch_year_protocol.md
  - chapter2_vault/06_paper_facing/drafts/ch2_sec4_1_data_measurement_prelatex.md
stage_scope: paper-facing
country: US_CL
last_updated: 2026-08-05
updated_by: CH2_PAPER_FACING_SOURCE_SCOPING
layer: appendix
role: data-construction
stage: data-measurement
tags:
  - chapter2/appendix
  - chapter2/data-measurement
  - chapter2/gpim
scope: chapter2
priority: core
---

# Appendix B: Data Construction and Measurement Provenance

The main text of §4.1 keeps only what identification requires: the constructed capital stocks, the distinction between depreciation and retirement, the analytical roles of gross and net capital, and the rule that cross-country comparability rests on accounting consistency rather than on harmonized source vintages. Everything needed to reproduce those constructions, but not to follow the argument, is collected here.

## B.1 The generalized perpetual inventory method

\PLACEHOLDER{Full statement of the GPIM construction: survival function and its parameterization, service-life assumptions by asset class, the initialization of the capital stock at the start of each series, and the treatment of the discard rate $z$ on gross capital in operation as distinct from the net depreciation rate $\delta$. Source material sits in the archived maintenance audits at \texttt{reports/maintenance/} --- specifically the gross-survival remediation, input-initialization, price-deflator provenance, and source-price-seed audits.}

## B.2 Price bases and deflator provenance

\PLACEHOLDER{Deflator chain for each series and the base-year conventions. The Chilean capital stock and GDP series share a 2003 CLP base and require no rebasing, which is the reason the Chilean accounting closes without a splice at that seam; this needs stating explicitly with its source. Pre-1940 Chilean relative capital-asset prices are proxied by a US wholesale price index, and the consequences of that proxy for the price channel need to be stated here rather than left in a table footnote.}

## B.3 Source reconciliation and splice diagnostics

\PLACEHOLDER{Series-by-series reconciliation against source vintages, splice points and the diagnostics run at each, and the repository provenance of every input. Source material is in the archived \texttt{reports/US\_Wage\_Share\_Data\_Provenance\_Note/99\_archive/} and the corresponding Chilean lane.}

## B.4 The wage-share measures

Four wage-share measures enter the estimation and the distinctions between them do analytical work, so they are set out here in full rather than by reference.

The baseline measure takes compensation over value added for the non-financial corporate sector. The gross and net variants differ in whether consumption of fixed capital sits in the denominator; because that quantity rises mechanically with capital intensity, the two variants respond differently to exactly the mechanization the interaction term is meant to identify, which is why §4.2 treats the gross-basis failure as evidence rather than as noise.

The two Shaikh-Tonak variants further separate productive from supervisory labour compensation. Tier 1 isolates variable capital on a first pass; Tier 2 applies the supervisory correction in full. The theoretical motivation is that cost-minimizing choice of technique responds to shop-floor labour cost, not to an aggregate that folds managerial overhead into the same ratio.

\PLACEHOLDER{Construction detail for each of the four measures --- the exact NIPA line items, the supervisory split and its source, and the crosswalk between the four --- belongs in this subsection.}

## B.5 The level anchor

Capacity utilization is a ratio whose numerator is observed and whose denominator is estimated. Estimation recovers the transformation relation and therefore the shape of the productive-capacity path, but not its level: any scalar multiple of $\hat{Y}^p_t$ fits equally well. The level is fixed by anchoring utilization to unity in a benchmark year chosen to approximate frontier utilization.

This normalization anchors the series. It does not define the object. The distinction matters because it is precisely what separates this construction from approaches that recover utilization as a residual: here the transformation elasticity is identified first and the level is imposed afterwards, so the anchor year carries no weight in identifying $\theta$.

\PLACEHOLDER{Statement of the pinch-year selection rule, the chosen benchmark year for each case with its justification, and sensitivity of the reconstructed level path to alternative anchor years. Protocol is at \texttt{chapter2\_vault/04\_data\_measurement/D03\_capacity\_utilization\_level\_anchor\_pinch\_year\_protocol.md}.}
