---
type: note
status: active
layer: analytical_toolkit
note_class: R-note
design_role: measurement_guardrail
scope: chapter2_implementation

object_governed:
  - s_t
  - K_ME
  - K_NRC
  - phi_t

core_rule: stock_flow_consistency

related_to:
  - M10_Empirical_Identification_Framework
  - N_Capital_Composition_and_Productive_Capacity
  - R_StockFlowConsistency
  - R_No_Nominal_Share_Allocation

tags:
  - chapter2
  - measurement
  - stock_flow_consistency
  - capital_stock
  - machinery_equipment
  - non_residential_construction
  - price_wedge
  - deflators
---

# ME/NRC price wedge guardrail

## Core rule

This note operationalizes the stock-flow consistency rule for the construction of the machinery share of the capital stock, $s_t$, in the Chapter 2 machinery-composition block.

It is subordinate to the analytical definition of $s_t$ and does **not** introduce an independent composition variable.

The analytical framework requires:

$$
s_t
=
\frac{K_t^{ME}}
{K_t^{ME}+K_t^{NRC}}
$$

where:

- $ME$ = machinery and equipment
- $NRC$ = non-residential construction

The gross fixed capital formation share enters only in the implementation layer, because it allocates real investment flows before those flows are accumulated into capital stocks.

It does not enter the productive-capacity equation directly.

---

## Analytical placement

The productive-capacity decomposition is:

$$
Y_t^p
=
\theta_t^{ME}K_t^{ME}
+
\theta^{NRC}K_t^{NRC}
$$

The aggregate observable transformation is:

$$
\theta_t^{tot}
=
s_t\theta_t^{ME}
+
(1-s_t)\theta^{NRC}
$$

with:

$$
s_t
=
\frac{K_t^{ME}}
{K_t^{ME}+K_t^{NRC}}
$$

Therefore, $s_t$ is the analytical object.

The flow share $\varphi_t$ is implementation-facing. It may be used to construct the real ME and NRC investment flows that generate the capital stocks, but it does not replace $s_t$ in the analytical framework.

---

## Flow-side construction

Let aggregate real gross fixed capital formation be:

$$
I_t^A
=
I_t^{ME,r}
+
I_t^{NRC,r}
$$

The real ME investment share is:

$$
\varphi_t^r
=
\frac{I_t^{ME,r}}
{I_t^{ME,r}+I_t^{NRC,r}}
$$

Then:

$$
I_t^{ME,r}
=
\varphi_t^r I_t^A
$$

$$
I_t^{NRC,r}
=
(1-\varphi_t^r)I_t^A
$$

These flows are accumulated into stocks:

$$
K_t^{ME}
=
(1-\delta_{ME})K_{t-1}^{ME}
+
I_t^{ME,r}
$$

$$
K_t^{NRC}
=
(1-\delta_{NRC})K_{t-1}^{NRC}
+
I_t^{NRC,r}
$$

Only after this stock construction is the analytical share defined:

$$
s_t
=
\frac{K_t^{ME}}
{K_t^{ME}+K_t^{NRC}}
$$

The implementation sequence is:

$$
\varphi_t^r
\rightarrow
I_t^{ME,r}, I_t^{NRC,r}
\rightarrow
K_t^{ME}, K_t^{NRC}
\rightarrow
s_t
\rightarrow
\theta_t^{tot}
$$

Thus, $\varphi_t^r$ precedes $s_t$ dynamically, but it does not replace $s_t$ analytically.

---

## Stock-flow consistency

With asset-specific depreciation, the stock-flow system is:

$$
K_t^{ME}
=
(1-\delta_{ME})K_{t-1}^{ME}
+
I_t^{ME,r}
$$

$$
K_t^{NRC}
=
(1-\delta_{NRC})K_{t-1}^{NRC}
+
I_t^{NRC,r}
$$

and:

$$
K_t
=
K_t^{ME}
+
K_t^{NRC}
$$

so that:

$$
s_t
=
\frac{K_t^{ME}}{K_t}
$$

The role of gross fixed capital formation is therefore to generate the stocks, not to enter the productive-capacity equation as an independent theoretical variable.

In short:

$$
\text{real flows}
\rightarrow
\text{real stocks}
\rightarrow
s_t
\rightarrow
\theta_t^{tot}
$$

---

## Price distortion in current-price investment shares

Let current-price investment values be:

$$
V_t^{ME}
=
P_t^{ME,I}I_t^{ME,r}
$$

$$
V_t^{NRC}
=
P_t^{NRC,I}I_t^{NRC,r}
$$

where $P_t^{ME,I}$ and $P_t^{NRC,I}$ are investment deflators for ME and NRC.

The current-price ME investment share is:

$$
\varphi_t^V
=
\frac{V_t^{ME}}
{V_t^{ME}+V_t^{NRC}}
$$

The real ME investment share is:

$$
\varphi_t^r
=
\frac{I_t^{ME,r}}
{I_t^{ME,r}+I_t^{NRC,r}}
$$

Define the relative ME/NRC investment price:

$$
\rho_t^I
=
\frac{P_t^{ME,I}}
{P_t^{NRC,I}}
$$

Then:

$$
\varphi_t^V
=
\frac{\rho_t^I\varphi_t^r}
{\rho_t^I\varphi_t^r+(1-\varphi_t^r)}
$$

In odds form:

$$
\frac{\varphi_t^V}
{1-\varphi_t^V}
=
\rho_t^I
\frac{\varphi_t^r}
{1-\varphi_t^r}
$$

Therefore:

$$
\log\left(
\frac{\varphi_t^V}
{1-\varphi_t^V}
\right)
-
\log\left(
\frac{\varphi_t^r}
{1-\varphi_t^r}
\right)
=
\log \rho_t^I
$$

Current-price ME/NRC investment composition is therefore real composition distorted by the relative price of ME against NRC.

If:

$$
P_t^{ME,I} > P_t^{NRC,I}
$$

then current-price shares overstate real ME accumulation.

If:

$$
P_t^{ME,I} < P_t^{NRC,I}
$$

then current-price shares understate real ME accumulation.

---

## Inadmissible allocation rule

Do not allocate aggregate real GFCF using current-price ME/NRC shares.

The inadmissible construction is:

$$
\widetilde I_t^{ME,r}
=
\varphi_t^V I_t^{A,r}
$$

because if:

$$
I_t^{A,r}
=
\frac{V_t^{ME}+V_t^{NRC}}
{P_t^A}
$$

then:

$$
\widetilde I_t^{ME,r}
=
\frac{V_t^{ME}}
{P_t^A}
=
\frac{P_t^{ME,I}}
{P_t^A}
I_t^{ME,r}
$$

This injects relative capital-goods price movements into measured real accumulation.

The correct procedure is:

$$
I_t^{ME,r}
=
\frac{V_t^{ME}}
{P_t^{ME,I}}
$$

$$
I_t^{NRC,r}
=
\frac{V_t^{NRC}}
{P_t^{NRC,I}}
$$

Asset-specific deflation comes first. Aggregation comes second.

---

## Stock-price distortion

The same wedge logic applies to capital stocks only if the capital-stock source provides asset-specific stock deflator indices, or provides matched current-cost and real stock measures from which such indices can be recovered.

Let:

$$
W_t^{ME}
=
P_t^{ME,K}K_t^{ME,r}
$$

$$
W_t^{NRC}
=
P_t^{NRC,K}K_t^{NRC,r}
$$

where:

- $W_t^{ME}$ and $W_t^{NRC}$ are current-cost or replacement-cost stock values
- $K_t^{ME,r}$ and $K_t^{NRC,r}$ are real stock measures
- $P_t^{ME,K}$ and $P_t^{NRC,K}$ are capital-stock deflator indices

The current-cost ME stock share is:

$$
s_t^V
=
\frac{W_t^{ME}}
{W_t^{ME}+W_t^{NRC}}
$$

The real ME stock share is:

$$
s_t^r
=
\frac{K_t^{ME,r}}
{K_t^{ME,r}+K_t^{NRC,r}}
$$

Define the relative capital-stock price:

$$
\rho_t^K
=
\frac{P_t^{ME,K}}
{P_t^{NRC,K}}
$$

Then:

$$
s_t^V
=
\frac{\rho_t^K s_t^r}
{\rho_t^K s_t^r+(1-s_t^r)}
$$

and:

$$
\frac{s_t^V}
{1-s_t^V}
=
\rho_t^K
\frac{s_t^r}
{1-s_t^r}
$$

Therefore:

$$
\log\left(
\frac{s_t^V}
{1-s_t^V}
\right)
-
\log\left(
\frac{s_t^r}
{1-s_t^r}
\right)
=
\log \rho_t^K
$$

This diagnostic is admissible only when $P_t^{ME,K}$ and $P_t^{NRC,K}$ are observed or recoverable on a consistent accounting basis.

---

## If-and-only-if admissibility rule

Capital-stock price wedge diagnostics are admissible **if and only if** the capital-stock source provides asset-specific capital-stock deflator indices for ME and NRC, or provides matched current-cost and real stock measures from which such indices can be recovered.

Formally, the diagnostic:

$$
\rho_t^K
=
\frac{P_t^{ME,K}}
{P_t^{NRC,K}}
$$

is admissible only if both $P_t^{ME,K}$ and $P_t^{NRC,K}$ are observed or recoverable.

If capital-stock deflator indices are not available, Chapter 2 must not infer capital-stock price distortion by borrowing investment deflators.

Investment deflators can construct real investment flows.

They cannot automatically stand in for capital-stock deflators.

No stock-deflator indices, no capital-stock price-wedge diagnostic.

---

## Measurement rule

Baseline construction:

$$
I_t^{ME,r}
=
\frac{V_t^{ME}}
{P_t^{ME,I}}
$$

$$
I_t^{NRC,r}
=
\frac{V_t^{NRC}}
{P_t^{NRC,I}}
$$

Then:

$$
K_t^{ME}
=
(1-\delta_{ME})K_{t-1}^{ME}
+
I_t^{ME,r}
$$

$$
K_t^{NRC}
=
(1-\delta_{NRC})K_{t-1}^{NRC}
+
I_t^{NRC,r}
$$

Finally:

$$
s_t
=
\frac{K_t^{ME}}
{K_t^{ME}+K_t^{NRC}}
$$

Current-price shares are retained only as expenditure-pressure or price-wedge diagnostics.

They are not baseline real-composition variables.

---

## Interpretation

The Chapter 2 measurement spine is:

$$
\text{real ME and NRC flows}
\rightarrow
\text{real ME and NRC stocks}
\rightarrow
s_t
\rightarrow
\theta_t^{tot}
$$

The price-wedge diagnostic is not part of the core model. It is a measurement guardrail used to detect whether current-price composition differs from real composition because ME and NRC prices move differently.

The diagnostic is allowed for investment flows when investment deflators exist.

The diagnostic is allowed for capital stocks only when stock deflator indices exist.

---

## Parent-note backlink

Add this line to the parent analytical note where $s_t$ is defined:

> Measurement guardrail: the construction of $s_t$ must follow the ME/NRC stock-flow consistency rule. Current-price composition shares are admissible only as diagnostics, and capital-stock price wedges are admissible only when asset-specific stock deflator indices are available. See [[R05_ME_NRC_Price_Wedge_Guardrail]].

---

## Final lock

Chapter 2 constructs the ME/NRC capital-composition share through stock-flow consistency. The analytical object is $s_t$, not $\varphi_t$. The flow share $\varphi_t$ is implementation-facing: it allocates real gross fixed capital formation into ME and NRC flows, which are then accumulated into real capital stocks. Current-price ME/NRC shares are not admissible as baseline real-composition measures. Capital-stock price wedge diagnostics are admissible if and only if stock deflator indices for ME and NRC are available or recoverable from consistent stock accounts.