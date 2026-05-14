# Chile Stage 1 Report  
## External Disequilibrium VECM Exploration

## 1. Scope and analytical purpose

Stage 1 identifies an external-disequilibrium object for Chile using a rank-1 VECM centered on real imports, machinery capital, and non-reinvested surplus. The purpose is not to estimate capacity utilization, but to recover an error-correction term interpretable as the deviation of actual imports from structural import requirements.

The preferred specification is:

- **Spec:** S1_B  
- **Variables:** `log_M`, `log_KME`, `log_NRS_proxy`  
- **Preferred lag:** 1  
- **Rank:** 1  
- **Anchor window:** PRE1974  

The working long-run relation is:

\[
\log M_t = \zeta_0 + \zeta_1 \log KME_t + \zeta_2 \log NRS_t + ECT_t
\]

with the estimated error-correction term written as:

\[
ECT_t = \log M_t - \zeta_0 - \zeta_1 \log KME_t - \zeta_2 \log NRS_t
\]

Under this sign convention:

- **ECT < 0**: actual imports are below fitted structural import requirements  
- **ECT > 0**: actual imports are above fitted structural import requirements  

This makes the ECT interpretable as an external-pressure or import-compression object.

---

## 2. Preferred Stage 1 comparison

The preferred screen comparison uses **S1_B, lag 1, rank 1** across the three windows.

### Table 1. Preferred long-run vector and adjustment coefficients

| Sample | log_M | log_KME | log_NRS_proxy | alpha_log_M | alpha_log_KME | alpha_log_NRS |
|---|---:|---:|---:|---:|---:|---:|
| FULL | 1.0000 | -1.0112 | -0.1337 | -0.3850 | -0.0049 | 0.0072 |
| PRE1974 | 1.0000 | -0.6323 | -0.4965 | -0.3192 | -0.0112 | 0.1854 |
| POST1974 | 1.0000 | -0.5476 | -0.7750 | -0.7252 | -0.0593 | -0.2960 |

Read in normalized form, the implied long-run import requirement relation is:

- **FULL:**  
  \[
  \log M_t = 1.011\,\log KME_t + 0.134\,\log NRS_t + c + ECT_t
  \]

- **PRE1974:**  
  \[
  \log M_t = 0.632\,\log KME_t + 0.496\,\log NRS_t + c + ECT_t
  \]

- **POST1974:**  
  \[
  \log M_t = 0.548\,\log KME_t + 0.775\,\log NRS_t + c + ECT_t
  \]

### Reading

Three points stand out.

First, the long-run relation is economically admissible in all three windows once normalized on imports: both machinery capital and non-reinvested surplus increase structural import requirements.

Second, the **PRE1974** window is the cleanest anchor because it yields a balanced long-run relation between machinery and NRS, instead of the machinery-heavy pooled relation in the full sample or the NRS-heavy structure in the post-1974 window.

Third, the **adjustment regime changes sharply**. In all windows the imports equation carries the main error-correction burden, but the speed of adjustment is much faster after 1974.

---

## 3. Error-correction comparison

### Table 2. Error-correction and ECT dispersion

| Sample | alpha_log_M | ect_mean | ect_sd | ect_range |
|---|---:|---:|---:|---:|
| FULL | -0.3850 | -4.5575 | 0.2661 | 1.8601 |
| PRE1974 | -0.3192 | -3.6963 | 0.3665 | 2.0690 |
| POST1974 | -0.7252 | -6.7050 | 0.1650 | 0.7340 |

### Reading

This table is the core Stage 1 result.

- **PRE1974**: slower correction, wider disequilibrium band  
- **POST1974**: much faster correction, narrower disequilibrium band  
- **FULL**: intermediate values, effectively averaging two distinct regimes  

This implies that the post-1974 external block tolerates less deviation and corrects more aggressively. The issue is not whether cointegration exists in both periods; it does. The issue is that the **adjustment mechanism** is historically different.

---

## 4. Post-estimation VECM summaries

### 4.1 FULL sample

Preferred model: `S1_B / lag 1 / rank 1`

\[
\beta' X_t = \log M_t - 1.011 \log KME_t - 0.134 \log NRS_t
\]

Imports equation:

\[
\Delta \log M_t = -0.385\,ECT_{t-1} - 1.745 + 0.475\,\Delta \log M_{t-1}
+ 0.354\,\Delta \log KME_{t-1} + 0.064\,\Delta \log NRS_{t-1}
\]

with the ECT term highly significant.

Interpretation:

- the full sample preserves a stable import-requirement relation,
- disequilibrium correction is concentrated in imports,
- the full sample is informative, but should be treated as a pooled average rather than the primary identification window.

### 4.2 PRE1974

Preferred model: `S1_B / lag 1 / rank 1`

\[
\beta' X_t = \log M_t - 0.632 \log KME_t - 0.496 \log NRS_t
\]

Imports equation:

\[
\Delta \log M_t = -0.319\,ECT_{t-1} - 1.158 + 0.478\,\Delta \log M_{t-1}
- 0.322\,\Delta \log KME_{t-1} + 0.002\,\Delta \log NRS_{t-1}
\]

with the ECT term highly significant.

Interpretation:

- the pre-1974 relation is the most balanced and theoretically attractive,
- imports absorb disequilibrium at a moderate speed,
- the correction remains centered in the imports equation rather than diffused across the whole system.

### 4.3 POST1974

Preferred model: `S1_B / lag 1 / rank 1`

\[
\beta' X_t = \log M_t - 0.548 \log KME_t - 0.775 \log NRS_t
\]

Imports equation:

\[
\Delta \log M_t = -0.725\,ECT_{t-1} - 4.894 - 0.051\,\Delta \log M_{t-1}
+ 1.480\,\Delta \log KME_{t-1} + 0.517\,\Delta \log NRS_{t-1}
\]

with the ECT term highly significant.

Interpretation:

- post-1974 imports correct much faster than in pre-1974,
- the long-run import requirement shifts toward a stronger NRS component,
- disequilibrium becomes tighter in dispersion but harsher in correction,
- the external block no longer looks like a softer import-only adjustment regime.

---

## 5. Unit-root guardrail battery

The unit-root battery is used here as a guardrail, not as a hard selection device. The objective is to verify whether the preferred variables behave broadly like \(I(1)\), so that a rank-1 VECM in levels is admissible.

The variables checked are:

- `log_M`
- `log_KME`
- `log_NRS_proxy`

The tests are:

- ADF with drift
- PP with constant
- KPSS with level-stationarity null

### Table 3. Unit-root guardrail summary

| Sample | Variable | Levels reading | First-differences reading | Guardrail verdict |
|---|---|---|---|---|
| FULL | log_M | non-stationary / weak rejection | stationary | compatible with I(1) |
| FULL | log_KME | non-stationary / weak rejection | stationary | compatible with I(1) |
| FULL | log_NRS_proxy | non-stationary / weak rejection | stationary | compatible with I(1) |
| PRE1974 | log_M | non-stationary / weak rejection | stationary | compatible with I(1) |
| PRE1974 | log_KME | broadly non-stationary | mostly stationary in diff | compatible with I(1), mild caution |
| PRE1974 | log_NRS_proxy | non-stationary / weak rejection | stationary | compatible with I(1) |
| POST1974 | log_M | non-stationary / weak rejection | stationary | compatible with I(1) |
| POST1974 | log_KME | non-stationary / weak rejection | stationary | compatible with I(1) |
| POST1974 | log_NRS_proxy | non-stationary / weak rejection | stationary | compatible with I(1) |

### Reading

The battery supports the VECM rather than undermining it.

- In levels, ADF and PP mostly do not reject a unit-root interpretation.
- KPSS typically rejects level stationarity.
- In first differences, ADF and PP become much more negative and KPSS falls sharply.

The overall message is that the preferred variables are **approximately \(I(1)\)** across all three windows. The small ambiguities in some split-sample statistics are not large enough to challenge the VECM specification.

---

## 6. Synthesis

Stage 1 now supports four clear conclusions.

### 6.1 Preferred specification

The preferred external-disequilibrium specification is:

- `S1_B`
- `lag = 1`
- `rank = 1`

### 6.2 Preferred identification window

The preferred identification window is **PRE1974**, because:

- the long-run import requirement relation is the most balanced,
- machinery and NRS both contribute positively once normalized,
- the adjustment coefficient in imports is negative and significant without becoming excessively coercive.

### 6.3 Historical comparison result

The comparison window **POST1974** shows that the external block changes in a substantive way:

- imports adjust much faster,
- the long-run relation becomes more NRS-heavy,
- the ECT dispersion shrinks,
- the correction regime becomes harsher.

### 6.4 Function of the full sample

The **FULL** sample should be retained as a comparison object and robustness check, not as the primary identification anchor. Its long-run vector and adjustment coefficient sit between PRE1974 and POST1974, which is exactly what one would expect from a pooled sample averaging two structurally different regimes.

---

## 7. Stage 1 closure statement

A compact statement suitable for later writing is:

> The preferred Stage 1 specification is a rank-1 VECM for real imports, machinery capital, and non-reinvested surplus with one lag. The unit-root battery is broadly compatible with treating the three variables as approximately \(I(1)\), supporting the VECM specification. The PRE1974 window provides the cleanest anchor for the long-run import-requirement relation, while POST1974 exhibits a markedly faster and harsher import-side error correction. The full sample averages these two external regimes and is therefore retained as a comparison object rather than the primary identification window.

---

## 8. Core tables for later reuse

### Table A. Preferred Stage 1 comparison

| Sample | log_M | log_KME | log_NRS_proxy | alpha_log_M | alpha_log_KME | alpha_log_NRS |
|---|---:|---:|---:|---:|---:|---:|
| FULL | 1.0000 | -1.0112 | -0.1337 | -0.3850 | -0.0049 | 0.0072 |
| PRE1974 | 1.0000 | -0.6323 | -0.4965 | -0.3192 | -0.0112 | 0.1854 |
| POST1974 | 1.0000 | -0.5476 | -0.7750 | -0.7252 | -0.0593 | -0.2960 |

### Table B. ECT dispersion and import adjustment

| Sample | alpha_log_M | ect_mean | ect_sd | ect_range |
|---|---:|---:|---:|---:|
| FULL | -0.3850 | -4.5575 | 0.2661 | 1.8601 |
| PRE1974 | -0.3192 | -3.6963 | 0.3665 | 2.0690 |
| POST1974 | -0.7252 | -6.7050 | 0.1650 | 0.7340 |

### Table C. Unit-root guardrail verdict

| Sample | Verdict |
|---|---|
| FULL | compatible with I(1) |
| PRE1974 | compatible with I(1) |
| POST1974 | compatible with I(1) |

---
