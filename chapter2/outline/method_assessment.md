---
type: methodological_review_memo
status: active
layer: econometric_admissibility
scope: interactive_cointegration_cpr
topics:
  - I(2) Trap
  - FM-OLS / DOLS / IM-OLS adaptations
  - Multicollinearity & Orthogonalization
  - State-Dependent vs Time-Varying Elasticities
---

# Assessment of Methodological Conclusions

## Overall Assessment

The methodological guide presents **largely adequate and well-grounded conclusions** for estimating time-varying elasticities in interactive cointegrating regressions. The document demonstrates strong command of the relevant econometric literature and provides practical guidance that is both theoretically sound and empirically applicable.

---

## Key Conclusions Evaluated

### 1. **The "I(2) Trap" and Polynomial Cointegration**

**Conclusion:** The interaction term \((x_t \cdot y_{t-1})\) of two I(1) variables is I(2), requiring a Polynomial Cointegration (CPR) framework rather than standard linear cointegration methods.

**Assessment:** ✅ **Adequate and mathematically correct**

**Mathematical Verification:**

For two independent I(1) processes:
- \(x_t = x_{t-1} + \varepsilon_t\) where \(\varepsilon_t \sim I(0)\)
- \(y_t = y_{t-1} + \eta_t\) where \(\eta_t \sim I(0)\)

The product \(z_t = x_t \cdot y_{t-1}\) has the property:
- \(E[z_t] = O(t)\) (linear trend in expectation)
- \(Var(z_t) = O(t^2)\) (variance grows at rate \(t^2\))

For a process to be I(2), its second difference must be stationary:
\[\Delta^2 z_t = \Delta(z_t - z_{t-1}) = O_p(1)\]

Indeed, the product of two I(1) processes typically requires differencing twice to achieve stationarity (see Granger & Newbold, 1986; Phillips, 1991). This confirms the I(2) classification.

The recommendation to use CPR frameworks (Wagner & Hong, 2016) is correct, as these estimators are designed for mixed-integration-order regressors.

---

### 2. **Adaptation of FM-OLS, DOLS, and IM-OLS**

**Conclusion:** All three estimators can be adapted to CPRs, with IM-OLS offering advantages in avoiding LRCV estimation and lead-lag proliferation.

**Assessment:** ✅ **Adequate, with some nuance**

**Checking the IM-OLS Claim:**

Vogelsang & Wagner (2014) demonstrate that IM-OLS is derived from the partial-sum transformation:

Let \(Y_t = \sum_{s=1}^t y_s\) and \(X_t = \sum_{s=1}^t x_s\). The regression becomes:
\[Y_t = X_t'\beta + \text{correction terms} + \text{error}\]

This transformation implicitly handles:
1. Serial correlation (through integration)
2. Endogeneity (through the construction of correction terms)

The proof shows that the IM-OLS estimator has the same limiting distribution as FM-OLS without requiring explicit LRCV estimation. This is a legitimate theoretical advantage.

**Nuance:** The claim that IM-OLS "sidesteps" LRV estimation is somewhat overstated—IM-OLS still requires estimation of the long-run variance for its standard errors and for some correction terms, though less directly.

---

### 3. **Multicollinearity Diagnosis and Mitigation**

**Conclusion:** The interactive specification creates severe multicollinearity requiring systematic diagnosis (VIF, condition indices) and mitigation (orthogonalization, ridge regression).

**Assessment:** ✅ **Adequate and practically important**

**Verification of Orthogonalization:**

The orthogonalization approach:
1. Regress \((x_t \cdot y_{t-1})\) on \(x_t\) and \(y_{t-1}\)
2. Use the residuals \(r_t\) as the interaction term

This yields:
\[(x_t \cdot y_{t-1}) = \gamma_0 + \gamma_1 x_t + \gamma_2 y_{t-1} + r_t\]
where \(r_t\) is orthogonal to \(x_t\) and \(y_{t-1}\) by construction.

This is mathematically sound and follows from the Frisch-Waugh-Lovell theorem. The residual \(r_t\) captures the unique nonlinear variation in the interaction term.

**Ridge Regression Justification:**

The ridge estimator:
\[\hat{\beta}_{ridge} = (X'X + \lambda I)^{-1}X'y\]

The bias-variance tradeoff is well-established. When \(X'X\) is near-singular (severe multicollinearity), the OLS estimator has high variance:
\[Var(\hat{\beta}_{OLS}) = \sigma^2(X'X)^{-1}\]

Ridge regression stabilizes this by adding \(\lambda\) to the eigenvalues of \(X'X\). This is a valid approach in finite samples, though one should be cautious about inference (standard errors require special treatment).

---

### 4. **State-Dependent vs. Time-Varying Elasticities**

**Conclusion:** The static model captures state-dependent elasticity (\(b + d\cdot y_{t-1}\) with constant \(d\)), while TVP elasticities require advanced methods (TVC, functional coefficient models).

**Assessment:** ✅ **Adequate and conceptually important**

**Verification of the Marginal Effect:**

For the model:
\[y_t = a + b x_t + c y_{t-1} + d(x_t \cdot y_{t-1}) + e_t\]

The partial effect of \(x_t\) on \(y_t\) is:
\[\frac{\partial y_t}{\partial x_t} = b + d \cdot y_{t-1}\]

This is state-dependent because it varies with \(y_{t-1}\), even though \(d\) is constant. This is mathematically correct.

**TVP Model Specification:**

If \(d_t\) is time-varying:
\[y_t = a + b x_t + c y_{t-1} + d_t(x_t \cdot y_{t-1}) + e_t\]
where \(d_t = d_{t-1} + \eta_t\) (random walk specification)

The marginal effect becomes:
\[\frac{\partial y_t}{\partial x_t} = b + d_t \cdot y_{t-1}\]

This is fundamentally different from state-dependent elasticity. The guide correctly notes that this requires different estimation methods (Kalman filter, local likelihood, etc.).

---

### 5. **Empirical Strategy Recommendations**

**Conclusion:** A structured approach with pre-estimation testing, careful implementation, and post-estimation diagnostics.

**Assessment:** ✅ **Adequate, with some limitations**

**Checking the Cointegration Testing Logic:**

The two-step residual-based approach:
1. Estimate \(y_t = a + b x_t + c y_{t-1} + d(x_t \cdot y_{t-1}) + e_t\) by OLS
2. Test residuals for stationarity using ADF/PP tests

This is a valid extension of the Engle-Granger method to nonlinear cointegration, though:
- Critical values may differ from linear case
- Power can be low if the interaction term is weak

The guide correctly notes that specialized nonlinear cointegration tests should be preferred.

**Limitation:** The guide does not discuss:
- Potential size distortion in residual-based tests for CPRs
- The choice of lag length in the ADF test for residuals
- The possibility of multiple cointegrating relationships

---

## Critical Assessment of Mathematical Claims

### Claim 1: "The product of two I(1) variables is I(2)"

**Verified:** ✅ Correct for the general case. The proof relies on the behavior of cross-products of integrated processes:

For \(x_t, y_t \sim I(1)\):
- \(x_t y_t = O_p(t)\) in magnitude (since each is \(O_p(\sqrt{t})\))
- The first difference: \(\Delta(x_t y_t) = x_{t-1}\Delta y_t + y_t\Delta x_t + O_p(1) = O_p(1)\)
- The second difference: \(\Delta^2(x_t y_t)\) is stationary

However, note that in special cases (e.g., if the variables are cointegrated), the product may be I(1). The guide appropriately treats this as the general case requiring caution.

### Claim 2: "Super-consistent estimators require all regressors to share the same integration order"

**Verified:** ✅ Standard super-consistency results (Stock, 1987) assume all regressors are I(1). When regressors have mixed integration orders, standard asymptotics fail. This is why the CPR framework is necessary.

### Claim 3: "IM-OLS avoids explicit LRCV estimation"

**Verified:** Partially correct. IM-OLS replaces the LRCV estimation with a "prewhitening" through integration. However, for standard error estimation and some correction terms, LRCV is still needed. The claim is somewhat overstated.

---

## Missing Considerations

### 1. **Spurious Regression Risk in CPRs**
The guide does not adequately address the risk of spurious regression when the cointegration condition fails. In CPRs, the I(2) interaction term can create severe spurious relationships if not properly cointegrated.

### 2. **Small Sample Properties**
While the guide acknowledges finite-sample issues, it does not provide guidance on:
- Minimum sample size requirements for CPRs
- The effect of the number of leads/lags on DOLS performance
- The impact of bandwidth choice on FM-OLS

### 3. **Alternative Approaches**
The guide dismisses full I(2) cointegration analysis (Johansen's approach) as "overly complex." While this is a reasonable pragmatic choice, it overlooks:
- The possibility of I(2) cointegration providing better identification
- The ability to test multiple cointegrating relationships
- The greater theoretical rigor of the I(2) framework

### 4. **Instrumental Variables Approaches**
The guide does not discuss IV/GMM estimation, which could be relevant if there are concerns about the exogeneity of \(x_t\) or the interaction term.

### 5. **Panel Data Extensions**
The guide focuses exclusively on time series, ignoring panel data applications, which are common in empirical work.

---

## Practical Recommendations Assessment

The practical recommendations are generally sound:

| Recommendation | Assessment |
|----------------|------------|
| Use unit root tests with structural breaks | ✅ Good practice |
| Test for nonlinear cointegration | ✅ Essential |
| Consider IM-OLS as preferred estimator | ✅ Reasonable preference |
| Diagnose multicollinearity with VIF/condition indices | ✅ Standard practice |
| Use orthogonalization or ridge regression | ✅ Appropriate |
| Interpret d as state-dependent (not TVP) elasticity | ✅ Correct interpretation |
| Use TVP models if instability detected | ✅ Necessary extension |

---

## Minor Technical Issues

### 1. **Notation Confusion**
The guide sometimes uses \(yt\) and \(y_t\) interchangeably, which could confuse readers. This is a minor presentation issue.

### 2. **Oversimplification of the I(2) Issue**
The product of two I(1) variables can be I(1) in some cases (e.g., if they are cointegrated with negative coefficients). The guide could have noted this caveat.

### 3. **DOLS Augmentation**
The guide recommends including leads and lags of \(\Delta(x_t \cdot y_{t-1})\). This is correct, but the optimal lag selection deserves more attention, as the I(2) nature of the interaction term may require different lag structures.

### 4. **Ridge Regression and Inference**
The guide recommends ridge regression but does not discuss the complications it introduces for inference (e.g., non-standard limiting distributions).

---

## Overall Verdict

**The conclusions are ADEQUATE and methodologically sound.**

The guide successfully:
1. Identifies the critical I(2) trap problem
2. Proposes the correct theoretical framework (CPR)
3. Evaluates three valid estimation approaches
4. Provides practical multicollinearity solutions
5. Distinguishes between state-dependent and TVP elasticities
6. Offers a structured empirical strategy

**Strengths:**
- Strong theoretical grounding
- Practical, actionable guidance
- Clear explanation of technical issues
- Balanced assessment of estimators

**Weaknesses:**
- Overlooks some small-sample issues
- Does not fully address spurious regression risks
- Dismisses I(2) cointegration too quickly
- Missing panel data and IV approaches

**Final Recommendation:** The guide's conclusions are supported by the econometric literature and can be confidently applied by researchers. The theoretical framework is correct, and the practical recommendations are valuable. The few omissions do not undermine the core methodology.