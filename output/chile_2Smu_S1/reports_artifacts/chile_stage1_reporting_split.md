# Suggested Reporting Split for Chile Stage 1
## Non-binding guidance for front-end write-up, appendix, and non-presented diagnostics

## 1. Purpose of this note

This document proposes a practical split for reporting the Stage 1 external-disequilibrium block. It is not a binding instruction set. Its function is to help decide later how much of Stage 1 should appear in the front-end paper narrative, how much should be moved to the appendix, and what can remain in the background results package.

The guiding principle is simple:

- the **front-end paper** should present only what is needed to understand the identification logic and trust the preferred Stage 1 object,
- the **appendix** should document econometric admissibility and cross-window comparison,
- the **non-presented diagnostics** should preserve the broader audit trail without overloading the reader.

---

## 2. Suggested front-end paper write-up

The front-end write-up should be compact and purpose-driven. It should not read like a full econometric appendix.

### 2.1 What should appear in the main paper

The following items are strong candidates for direct inclusion.

#### A. A short statement of the Stage 1 purpose

State that Stage 1 estimates an external-disequilibrium block in which real imports are linked in the long run to machinery capital and non-reinvested surplus. Clarify that the resulting ECT is not utilization, but an external-pressure object.

A compact formulation is enough:

\[
\log M_t = \zeta_0 + \zeta_1 \log KME_t + \zeta_2 \log NRS_t + ECT_t
\]

with a sentence clarifying the sign convention:

- \(ECT < 0\): imports below structural requirements
- \(ECT > 0\): imports above structural requirements

#### B. One preferred-spec comparison table

Include a single compact table with the preferred specification across the three windows:

- FULL
- PRE1974
- POST1974

The table should report:

- normalized cointegrating coefficients on `log_KME` and `log_NRS_proxy`
- import-equation adjustment coefficient \(\alpha_{\log M}\)
- optionally `ect_sd` and `ect_range`

This gives the reader both the long-run relation and the adjustment contrast.

#### C. One paragraph justifying the preferred Stage 1 specification

The paper should state that the preferred object is:

- `S1_B`
- lag 1
- rank 1
- PRE1974 as the anchor window

The justification should be brief:
- it is the theoretically preferred variable set,
- it produces an admissible long-run import-requirement relation,
- it avoids relying on the pooled full-sample average as the main structural anchor.

#### D. One short comparison paragraph about PRE1974 versus POST1974

This is arguably the most important front-end result from Stage 1.

The paper should say clearly that:

- PRE1974 displays slower and wider import-side correction,
- POST1974 displays faster and tighter correction,
- the full sample averages these two dynamics.

This gives Stage 2 a clean transition: the ECT is not just statistically admissible, but historically structured.

#### E. A single sentence on the unit-root battery

The front-end paper does not need a full discussion of ADF/PP/KPSS. A short sentence is enough:

> A compact unit-root battery indicates that the preferred variables behave approximately as \(I(1)\), supporting a rank-1 VECM specification.

That keeps the guardrail visible without dragging the reader into test-by-test detail.

---

## 3. Suggested appendix placement

The appendix should carry the econometric scaffolding that supports the preferred Stage 1 object but would slow down the main paper.

### 3.1 Items well suited to the appendix

#### A. Full preferred-spec VECM output

Include the full `summary(fit)` output, or a clean table derived from it, for:

- FULL, `S1_B`, lag 1, rank 1
- PRE1974, `S1_B`, lag 1, rank 1
- POST1974, `S1_B`, lag 1, rank 1

This should include:
- the cointegrating vector,
- the alpha loadings,
- the short-run lagged coefficients in each equation.

The appendix is the right place for the full equation-by-equation representation.

#### B. Lag comparison within the preferred specification

If useful, the appendix can show `lag 1` versus `lag 2` for `S1_B`, mainly to document why lag 1 was preferred.

This should be presented as a robustness comparison, not as a second unresolved model-selection contest.

#### C. Johansen rank tables

Rank-test tables belong in the appendix. They matter for admissibility, but they usually interrupt the narrative if placed in the main text.

This includes:
- trace tests,
- eigen tests,
- critical values,
- rank selection discussion.

#### D. Unit-root battery tables

The detailed ADF / PP / KPSS outputs for:
- FULL,
- PRE1974,
- POST1974

should live in the appendix or supplementary results file, not in the front-end paper.

#### E. Static diagnostics

The following are appendix candidates:
- VIF
- White test
- LM/BG test
- Jarque–Bera

These matter as audit material, but not as headline text.

### 3.2 Appendix narrative style

The appendix should not merely dump output. It should be organized around a few questions:

- Why is the preferred Stage 1 object admissible?
- Why is PRE1974 the anchor?
- Why is POST1974 treated as a comparison regime?
- Why is the full sample not the primary structural window?

That keeps the appendix analytical rather than archival.

---

## 4. Suggested non-presented diagnostics

Some material is useful to preserve, but not necessary to present unless a referee, advisor, or later drafting decision calls for it.

### 4.1 Good candidates for non-presented storage

#### A. All non-preferred specs

These include:
- `S1_A`
- `S1_C`
- `S1_D`
- non-preferred lag variants unless explicitly used in a robustness note

They should be kept in the results package and the master RDS, but not foregrounded.

#### B. All non-preferred window/spec combinations

If they are not part of the preferred or comparison set, they can remain in the background.

#### C. Full CSV/TEX exports for every test and every spec

Useful for:
- replication,
- advisor audit,
- later appendix expansion,
- referee response.

Not necessary for ordinary narrative presentation.

#### D. Intermediate RDS objects

The fitted `tsDyn` objects should definitely be preserved, but they are not presentation material.

#### E. Plot variants not chosen for the paper

Alternative ECT figures, redundant diagnostic plots, and exploratory visuals can remain in storage until later.

---

## 5. Suggested reporting architecture

A workable split would be:

### Front-end paper
- one paragraph stating the Stage 1 purpose and the ECT sign convention
- one preferred comparison table
- one short paragraph on why PRE1974 is the anchor
- one short paragraph contrasting PRE1974 and POST1974 adjustment
- one sentence noting that the unit-root battery supports a rank-1 VECM

### Appendix
- full preferred-spec VECM summaries
- Johansen rank tables
- detailed unit-root battery
- static diagnostics
- lag-comparison note within `S1_B`

### Non-presented diagnostics / results pack
- all remaining specs and windows
- all CSV/TEX outputs
- all RDS objects
- all exploratory figures and non-selected tables

---

## 6. Suggested emphasis in later writing

If this Stage 1 block is eventually written into the dissertation or a paper, the emphasis should probably not be on “we tried many specifications.” The emphasis should be on:

- the external-disequilibrium relation being theoretically grounded,
- the preferred specification being econometrically admissible,
- the historical contrast in adjustment regimes,
- and the way Stage 1 provides the ECT object needed for Stage 2.

That is the most coherent narrative spine.

---

## 7. Compact recommendation

A minimal, effective reporting strategy would be:

- **Main text:** only the preferred Stage 1 object and its historical comparison
- **Appendix:** all admissibility and robustness material for the preferred object
- **Background pack:** everything else

That division keeps Stage 1 analytically visible without letting it take over the entire empirical chapter.

