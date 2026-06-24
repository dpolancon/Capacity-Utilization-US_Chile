# Corporate-Sector NOS Without Double Accounting

## Accounting Reconciliation and Available-Variable Report

### Verdict

The corporate-minus-NFC method reconstructs a coherent implied financial-corporate account from 1929 through 2025. All six accounting identities pass in every year within the source tables' published rounding: the largest discrepancy is $2 million.

`NFC_NOS` remains the productive-origin baseline because it measures nonfinancial corporate operating surplus before interest distribution. Subtracting `NFC_NET_INT` produces an after-financial-claims measure; it does not measure surplus generation and must not replace `NFC_NOS`.

### Available accounts

The source layer contains 29 complete annual corporate/NFC variables. Fourteen matched corporate-minus-NFC residual accounts are therefore constructible without external data.

### Transfer assumptions

The full-attribution proxy uses the entire positive NFC net-interest and miscellaneous-payment position. The matched-position proxy is positive in 90 years and zero in 7 years because implied finance has a net-payment rather than net-receipt position in those years.

Neither proxy is an observed bilateral NFC-to-finance flow. The full-attribution measure is the stronger theoretical assumption; the matched-position measure is a conservative sensitivity bound.

### Interpretation hierarchy

- `NFC_NOS`: productive-origin surplus baseline.
- S30G after-interest variables: NFC surplus remaining after the bounded claims proxy.
- S30H corporate clean variables: published corporate NOS after removing the assumed NFC financial claim once.
- S30H implied financial variables: accounting residuals, not independently produced surplus.

### Release-candidate disposition

S30H prepares 22 variables and 2134 rows for explicit v1.1 extension review. It does not silently alter the existing S30G v1.1 candidate.

The candidate remains bounded by unresolved counterparty attribution, the inclusion of miscellaneous payments, and the absence of an actual/imputed-interest decomposition.
