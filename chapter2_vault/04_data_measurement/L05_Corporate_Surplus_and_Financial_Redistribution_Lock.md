---
title: "Corporate Surplus and Financial Redistribution Lock"
aliases:
  - "Corporate Surplus Theory Lock"
  - "Nonproductive Finance Dataset-Role Lock"
type: "theory-lock"
status: "locked"
project: "Dissertation Chapter 2"
chapter: 2
country: "United States"
stage: "S30H"
scope: "corporate surplus and financial redistribution"
created: 2026-06-24
updated: 2026-06-24
tags:
  - chapter2
  - corporate-surplus
  - financial-redistribution
  - theory-lock
  - data-governance
---

# Lock - Corporate Surplus and Financial Redistribution

## Status

**LOCKED**

## Core theoretical assumption

The financial corporate sector is treated as nonproductive in the surplus-value
sense. Financial-sector income is interpreted as a secondary claim on,
redistribution of, or absorption of value generated in primary productive
activity rather than as an independent creation of surplus value.

Within the available U.S. corporate accounts, nonfinancial corporate operating
surplus is the observable baseline proxy for productive-origin corporate
surplus.

## Productive-origin surplus baseline

The preferred productive-origin surplus measure is:

\[
S_t^{origin}=NOS_t^{NFC}.
\]

| Variable | Locked role |
|---|---|
| `NFC_NOS` | `CORPORATE_PRODUCTIVE_ORIGIN_SURPLUS_BASELINE` |

`NFC_NOS` measures nonfinancial corporate operating surplus before its
distribution through interest, transfers, taxes, dividends, and retained
earnings. It must not be replaced by an after-interest measure when the
analytical object is surplus generation.

## Implied financial corporate account

The financial corporate account is reconstructed as the accounting residual
between total corporate and nonfinancial corporate accounts:

\[
X_t^{FIN,implied}=X_t^{CORP}-X_t^{NFC}.
\]

For net operating surplus:

\[
NOS_t^{FIN,implied}=NOS_t^{CORP}-NOS_t^{NFC}.
\]

The S30H reconciliation confirms that these corporate-minus-NFC residuals form
a coherent implied financial corporate account within published rounding.
These are exact accounting residuals, not independently observed bilateral
transfer flows.

## Locked interpretations

### Financial NOS

| Variable | Locked role |
|---|---|
| `FIN_NOS_IMPLIED` | `FINANCIAL_REDISTRIBUTED_PROFIT_TYPE_INCOME_PROXY` |

Under the maintained nonproductive-finance assumption, implied financial NOS
represents the financial profit form embedded in published corporate NOS. It is
not independently produced surplus value.

A permitted diagnostic ratio is:

\[
\rho_t^{FIN}=\frac{NOS_t^{FIN,implied}}{NOS_t^{NFC}}.
\]

This ratio measures financial profit-type income relative to the
productive-origin surplus proxy. It is not an identified bilateral transfer
rate from NFCs to finance.

### Financial compensation

| Variable | Locked role |
|---|---|
| `FIN_COMP_IMPLIED` | `UNPRODUCTIVE_FINANCIAL_LABOR_COST_FINANCED_FROM_PRIMARY_VALUE` |

Implied financial compensation is a use or absorption of surplus-generated
value. It is not financial profit and must not be added to financial NOS as a
second profit component.

### Financial NVA

| Variable | Locked role |
|---|---|
| `FIN_NVA_IMPLIED` | `FINANCIAL_SECTOR_ABSORPTION_OF_PRIMARY_VALUE_PROXY` |

Financial NVA includes financial compensation, taxes, and NOS subject to the
source table's accounting structure. It is broader than financial profit.

A permitted burden ratio is:

\[
a_t^{FIN}=\frac{NVA_t^{FIN,implied}}{NOS_t^{NFC}}.
\]

This ratio measures total financial-sector absorption relative to the
productive-origin surplus proxy.

### Financial GVA

Implied financial GVA includes consumption of fixed capital:

\[
GVA_t^{FIN,implied}=NVA_t^{FIN,implied}+CFC_t^{FIN,implied}.
\]

It must not be described as current redistributed net surplus without
qualification.

## Clean corporate surplus

Under the strict nonproductive-finance assumption:

\[
NOS_t^{CORP,productive\ origin}
=NOS_t^{CORP}-NOS_t^{FIN,implied}
=NOS_t^{NFC}.
\]

The fully cleaned corporate productive-origin surplus measure is therefore
`NFC_NOS`.

## After-interest and partial-clean measures

| Variable | Locked role |
|---|---|
| `NFC_SURPLUS_AFTER_NET_INTEREST_PROXY` | `NFC_SURPLUS_REMAINING_AFTER_BOUNDED_FINANCIAL_CLAIMS` |

This is surplus remaining with NFCs after the bounded net-interest and
miscellaneous-payment position. It is not productive-origin surplus.

| Variable | Locked role |
|---|---|
| `CORP_NOS_NET_NFC_FINANCIAL_CLAIMS_PROXY` | `PARTIAL_CORPORATE_FINANCIAL_CLAIMS_CONSOLIDATION_PROXY` |

This removes one bounded NFC financial-claims channel from published corporate
NOS. It does not remove every financial claim, identify an exact bilateral
flow, or replace `NFC_NOS` as the strict productive-origin baseline.

## Required analytical distinction

| Object | Interpretation |
|---|---|
| `NFC_NOS` | Productive-origin surplus |
| `FIN_NOS_IMPLIED` | Redistributed financial profit-type income proxy |
| `FIN_NVA_IMPLIED` | Financial-sector absorption of primary value proxy |
| `NFC_NOS - NFC_NET_INT` | NFC surplus remaining after bounded financial claims |
| `CORP_NOS - NFC_NET_INT` | Partial corporate financial-claims consolidation proxy |

These objects answer different questions and must not be used interchangeably.

## Empirical qualification

The accounting residuals identify the financial corporate component of
published corporate accounts. They do not establish that every dollar of
financial income came directly from U.S. nonfinancial corporations. Financial
corporations may receive claims from households, government, noncorporate
businesses, the rest of the world, other financial institutions, and
nonfinancial corporations.

The theory assigns ultimate value origin to primary productive activity; the
accounts do not identify every bilateral transfer pathway.

## Prohibited interpretations

Do not claim that:

- All financial receipts are observed NFC-to-finance transfers.
- Every financial residual is a separate quantity of profit.
- Financial compensation is financial profit.
- Financial GVA is equivalent to net surplus.
- Financial residuals can be summed across decompositions.
- The bounded interest proxy is an exact bilateral flow.
- S30G or S30H reproduces the exact Shaikh Appendix 6.7 adjustment.
- Corporate NOS minus NFC interest is fully cleaned productive-origin surplus.
- Finance produces independent surplus value within the maintained model.

## Authorized formulation

> The implied financial corporate accounts are exact accounting residuals.
> Under the maintained nonproductive-finance assumption, financial NOS is
> interpreted as redistributed profit-type income, while financial compensation
> and the remaining components of financial NVA are interpreted as uses or
> absorptions of value generated in primary productive activity. NFC NOS
> remains the observable productive-origin corporate surplus baseline.

## Dataset-role lock

| Object or family | Dataset role |
|---|---|
| `NFC_NOS` | Baseline productive-origin surplus |
| `FIN_NOS_IMPLIED` | Financial redistribution diagnostic |
| `FIN_COMP_IMPLIED` | Unproductive financial labor-cost diagnostic |
| `FIN_NVA_IMPLIED` | Total financial absorption diagnostic |
| S30G after-interest variables | Financial-claims burden and retained-surplus robustness |
| S30H corporate clean variables | Partial consolidation sensitivity proxies |

No variable in the financial residual family may replace `NFC_NOS` as the
productive-origin baseline without a later explicit theory-lock revision.
