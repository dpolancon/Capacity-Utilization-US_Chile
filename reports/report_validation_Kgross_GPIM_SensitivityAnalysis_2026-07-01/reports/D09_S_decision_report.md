# D09-S Kgross GPIM Service-Life Sensitivity Decision

## Repository state
- Branch: `main`
- HEAD: `d594ed061e5e89ec3ce2761c304cc304a2b5c725`
- origin/main: `d594ed061e5e89ec3ce2761c304cc304a2b5c725`
- Working tree at start: D09-S generated artifacts only after verified clean opening state

## Scope
D09-S is report-only. It does not overwrite D05-D09-R outputs, alter D06, modify D07, change pKN, or run econometrics.

## Literature result
Nomura 2005 office-building values were recorded with status `EXTRACTED`: S0 approximately 15.4 years, Sv approximately 22.2 years, adjusted Sv-hat approximately 23.0 years. The evidence is methodological, not a U.S. NRC calibration.

## Sensitivity result
- ME cases: 4
- NRC cases: 9
- Capacity cases: 16
- Figures: 26
- PDF compiled: `TRUE`

## Key NRC result
The baseline NRC peak-to-latest change is -44.3 percent; the L50 case is -22 percent. Longer lives reduce the decline but increase warmup fragility, so the verdict is proceed with an NRC robustness flag rather than replace the D06 baseline.

## Key ME result
ME sensitivity remains visually stable across L=10, L=14, L=18, and L=22 cases; no ME blocking flag is raised.

## Identity audit status
- Stock-flow identities: PASS
- Current-cost identities: PASS
- Capacity identities: PASS

## Human review flags summary
    Var1            Var2 Freq
1   HIGH    NON_BLOCKING    0
2    LOW    NON_BLOCKING    1
3 MEDIUM    NON_BLOCKING    1
4   HIGH REVIEW_REQUIRED    1
5    LOW REVIEW_REQUIRED    0
6 MEDIUM REVIEW_REQUIRED    3

## Decision
`AUTHORIZE_D10_TRANSFORMATION_PLANNING_WITH_NRC_ROBUSTNESS_FLAG`
