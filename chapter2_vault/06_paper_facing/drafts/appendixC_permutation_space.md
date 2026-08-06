---
type: paper_facing
status: draft
depends_on:
  - chapter2_vault/06_paper_facing/results/99_legacy/S05_Appendix.md
  - chapter2_vault/03_econometrics/Interaction_Term_Integration_Order_Gate.md
stage_scope: paper-facing
country: US_CL
last_updated: 2026-08-05
updated_by: CH2_PAPER_FACING_SOURCE_SCOPING
layer: appendix
role: specification-space-map
stage: post-estimation
tags:
  - chapter2/appendix
  - chapter2/robustness
  - chapter2/model-selection
scope: chapter2
priority: core
---

# Appendix C: The Specification Space and Model Selection

The main text reports one preferred specification per case. This appendix reports the space those specifications were selected from, which alternatives were estimated, and why each is not carried forward. Presenting a single preferred model without its search space would leave the reader unable to judge how much the result depends on choices made along the way.

## C.1 The combinatorial grid

Specification A varies three binary dimensions — wage-share denominator (gross versus net value added), interaction form (standard versus effective, the latter scaled by the financialization retention index $(1-\iota_{t-1})$), and the presence of Bai-Perron step level-shifts — across three wage-share measures, giving the estimation matrix reported in §4.2. Specification B adds a fourth dimension by disaggregating capital into structures $k^{\text{NRC}}$ and the mechanization gap $\kappa_t$, and by admitting a relative-price interaction alongside the distributive one.

Every cell of these grids was estimated. None was dropped for producing an inconvenient result.

## C.2 Why alternatives are not carried forward

Specifications fall out of the preferred set for reasons of different weight, and the distinction matters for interpretation.

Some are excluded on **admissibility**: a regressor fails the integration-order gate as actually constructed, including its lag structure, or a generated interaction inherits $I(2)$ behaviour from its components. Theoretical motivation does not rescue these. The theory describes a decision mechanism; the stochastic evidence determines whether a given observable proxy for that mechanism can enter a long-run regression at all.

Some are excluded on **measurement**: the gross-value-added wage shares are admissible but uninformative, because consumption of fixed capital rises mechanically with capital intensity and so contaminates the distributive signal precisely along the dimension the interaction is meant to identify. Their failure is itself a result, not a nuisance, and §4.2 reads it as one.

Some are excluded on **redundancy**: the step-dummy variants sustain cointegration but add nothing once the distributive-financial interaction is specified, which is the basis for carrying forward the no-break specification.

None of the estimated specifications was excluded because it failed to cointegrate.

\PLACEHOLDER{The full consolidated grid --- the $2^3$ Specification A and $2^4$ Specification B permutations under initial-state centering, with each cell's disposition and the economic reason for it --- is already written at \texttt{chapter2\_vault/06\_paper\_facing/results/99\_legacy/S05\_Appendix.md} (status: locked). It needs transposing into this appendix with its internal governance vocabulary translated into plain econometric language: the vault's four-way ledger of dispositions is an internal audit device and must not surface in paper-facing text.}

\PLACEHOLDER{The integration-order verdict table --- each candidate regressor mapped to its theoretical basis, its $I(d)$ evidence on both levels and first differences from at least two complementary tests, and its final disposition --- belongs here. Source material is in the archived \texttt{reports/US\_Integration\_Order\_Appendix/99\_archive/}.}

## C.3 Counterfactual restrictions

Two restrictions test whether the estimated transformation elasticity is doing work the data support rather than work the specification imposes.

The first restricts $\theta = 1$, the Harrodian knife-edge, and asks what the capacity series and the implied utilization path look like under that restriction. This is the case in which accumulation converts one-for-one into productive capacity, and it is the implicit assumption of any filtering approach that fits output to capital without separately identifying the transformation relation.

The second removes the step dummies entirely and re-estimates, to establish how much of the reported structure survives without any exogenous break structure.

\PLACEHOLDER{Both counterfactuals are specified but not yet reported. Each requires a re-estimation pass and a comparison table against the preferred specification.}
