
### What §3.4 Will Contain (Edited Later)

When we reach §3.4, we will consolidate:

1. **From §3.1:** Linearization of θ(ω)θ(ω) → cointegrating equation (Spec A)
2. **From §3.2:** Linearization of θSpecBθSpecB → cointegrating equation with heterogeneous capital (Spec B)
3. **From §3.3:** Corner solution identification → peripheral specification (Spec C)
4. **Consolidated Hypotheses:** H1, H2, H3 in a single numbered block with sign restrictions
5. **Capacity Recovery Protocol:** Stated ONCE (not repeated)
6. **Single-sector bounding sentence** (BINDING FLAG L-08)
7. **Bridge to Section 4:** Regressor orthogonalization, integration-order screening, fixed-bb inference
----

\subsubsection{Empirical Identification Strategy of the Baseline State-Dependent Elasticity}

\paragraph{A}
The theoretical model derived in Sections 3.1.1 and 3.1.2 establishes that the transformation elasticity $\theta$ is an endogenous function of distributive pressure ($\omega$). To bridge this formal analytical model with empirical data, we translate the continuous growth relation into an estimable long-run cointegrating specification.

\paragraph{B}
By definition, the aggregate transformation elasticity governs the marginal response of potential log output ($y_t^p = \ln Y_t^p$) to log real capital stock ($k_t = \ln K_t$):

\[ g_{Y^p} = \theta_t g_K \quad \implies \quad \frac{d y_t^p}{d k_t} = \theta_t \]

\paragraph{C}
Linearizing the theoretical function $\theta(\omega)$ around the initial state yields the baseline state-dependent elasticity specification:

\[ \theta_t = \theta_0 + \theta_1 \omega_{t-1} \]

\paragraph{D}
where $\theta_0$ is the baseline transformation elasticity of capital at the initial state, and $\theta_1 = \frac{\partial \theta_t}{\partial \omega_{t-1}}$ measures the marginal shift in capital efficiency induced by distributive class pressure. We condition the wage share at lag 1 ($\omega_{t-1}$) to reflect the institutional lag between distributive bargaining and corporate capital expenditure execution.

\paragraph{E}
Integrating the differential relation $d y_t^p = (\theta_0 + \theta_1 \omega_{t-1}) d k_t$ over time yields the log-level potential capacity equation:

\[ y_t^p = \alpha + \theta_0 k_t + \theta_1 \left( k_t \cdot \omega_{t-1} \right) \]

\paragraph{F}
where $\alpha$ is a constant of integration. Adding a stationary stochastic error term $u_t$ under the null hypothesis of cointegration yields the estimating equation:

\[ y_t = \alpha + \theta_0 k_t + \theta_1 \left( k_t \cdot \omega_{t-1} \right) + u_t \]

\paragraph{G}
\textbf{Capacity Recovery and the Residual Critique.} Capacity utilization ($\mu_t$) is not the regression residual, nor a detrended output gap. Following the locked capacity level anchor pinch year protocol, $\mu_t$ is recovered by applying the estimated baseline state-dependent elasticity $\hat{\theta}_t$ to capital growth ($g_{K,t}$), anchoring the level at the pinch year ($t^*_{US} = 1973$), and extrapolating against aggregate real output ($Y_t = \text{GDP}_t$). The full four-step sequence is executed in Section 4.2.

\paragraph{H}
\textbf{Testable Hypothesis.} This baseline state-dependent specification yields a testable empirical proposition:

\begin{itemize}
  \item \textbf{Hypothesis 1 (The Okishio Distributive Dividend):} Domestic wage pressure compels cost-minimizing firms to substitute machinery for labor along the Mechanization Productive Frontier. The interaction coefficient between log capital and the lagged wage share is strictly positive: \[ \hat{\theta}_1 > 0 \] If $\hat{\theta}_1 > 0$, distributive pressure enhances the capacity-generating efficiency of capital, confirming that mechanization is endogenously induced by class struggle rather than driven by exogenous technical shocks.
\end{itemize}

\paragraph{I}
Section 3.1 closes the analytical identification of the homogeneous capital model. Translating the capacity equation into an estimable cointegrating specification — regressor orthogonalization, integration-order screening, and non-standard fixed-$b$ inference — is executed in Section 4.

---




\subsection{Heterogeneous Capital, the Mechanization Gap, and State-Dependent Viability}

\paragraph{A}
Mainstream macroeconomics treats the capital stock as a homogeneous aggregate, erasing the internal architecture of the firm. Following Vidal’s (2015, 2019) theory of the divided firm, we unbundle aggregate productive capital into extensive Nonresidential Structures ($K^{NRC}$) and intensive Machinery ($K^{ME}$). These components do not enter the labor process symmetrically. Structures form the passive infrastructure envelope—the factory floor and logistics shell. Machinery is the active, revolutionary force that restructures the production of relative surplus value (Marx, Vol. I, Ch. 15).

\subsubsection{The Extensive Envelope and the Intensive Margin}

\paragraph{A}
Nonresidential structures ($K^{NRC}$) define the \textbf{extensive margin} of accumulation. By construction, $K^{NRC}$ evolves independently of short-run distributive conflict ($\omega$) and anchors the mechanization productive frontier. It follows a normal accumulation corridor governed by long-run reproduction conditions and institutional closure:

\[ g_{K^{NRC}, t}^N = \chi^N r^N_t - \delta \]

\paragraph{B}
This extensive envelope $\Gamma(K^{NRC})$ bounds the space of tactical technique choice.

\paragraph{C}
Given this fixed infrastructural envelope, the \textbf{intensive margin} of accumulation is the tactical choice of the mechanization gap, defined in natural logs as:

\[ \kappa_t = k^{ME}_t - k^{NRC}_t \]

\paragraph{D}
This gap measures mechanization intensity relative to the extensive plant scale. The capacity identity decomposes potential output into the extensive envelope and the intensive capacity yield $\Psi_t$:

\[ y^p_t = \theta_{NRC} k^{NRC}_t + \Psi_t(\kappa_t, \omega_{t-1}, p^\kappa_t) \]

\paragraph{E}
$\Psi_t$ is not a fixed engineering constant. It is the outcome of a decentralized cost-minimization problem governed by the regime of accumulation.

\subsubsection{Cost-Surplus Maximization and the Okishio Viability Yield}

\paragraph{A}
The firm chooses the mechanization gap $\kappa_t$ to maximize the net viability surplus, subject to the regime-conditioned mechanization frontier $\Phi(\kappa_t) = \lambda_0 + \lambda_1 \kappa_t + \lambda_2 \kappa_t^2$.

\paragraph{B}
However, the \textit{realized} capacity yield is governed by the \textbf{Marx-Okishio Viability Condition}: a cost-minimizing firm deploys a new technique only if it reduces unit costs at current distributive and price parameters. We formalize this as a cost-surplus maximization problem. The firm maximizes the gross engineering yield of the gap minus the effective distributive and price costs:

\[ \max_{\kappa_t} \ c(\kappa_t) = \Phi(\kappa_t) - \kappa_t \cdot MC(\omega_{t-1}, p^\kappa_t) \]

\paragraph{C}
where $MC(\omega_{t-1}, p^\kappa_t)$ is the marginal viability cost of the gap. This cost is determined by two channels:

\begin{enumerate}
  \item \textbf{The Distributive Dividend (Labor Saving):} Increasing $\kappa_t$ substitutes machinery for labor. The value of this displacement is strictly proportional to the lagged wage share ($\omega_{t-1}$), reflecting the wage settlement period prior to current capacity realization. A higher wage share \textit{reduces} the net cost of mechanization, as the firm saves more on wages.
  \item \textbf{The Relative Price Penalty (Capital Cost):} Increasing $\kappa_t$ requires accumulating machinery faster than structures. The cost of this composition shift is proportional to the log relative price of machinery ($p^\kappa_t = \ln P^{ME}_t - \ln P^{NRC}_t$). A higher relative price \textit{increases} the marginal cost of the gap.
\end{enumerate}

\paragraph{D}
We specify the marginal viability cost as:

\[ MC(\omega_{t-1}, p^\kappa_t) = \gamma_0 - \gamma_1 \omega_{t-1} + \gamma_2 p^\kappa_t \]

\paragraph{E}
where $\gamma_1 > 0$ captures the wage-savings dividend and $\gamma_2 > 0$ captures the relative price penalty. Substituting the frontier and the cost function into the objective yields the unconstrained tactical problem:

\[ c(\kappa_t) = \lambda_0 + \left[ \lambda_1 - (\gamma_0 - \gamma_1 \omega_{t-1} + \gamma_2 p^\kappa_t) \right] \kappa_t + \lambda_2 \kappa_t^2 \]

\paragraph{F}
\textbf{First-Order Condition:} Differentiating with respect to $\kappa_t$ and setting to zero:

\[ \frac{dc}{d\kappa_t} = \lambda_1 - \gamma_0 + \gamma_1 \omega_{t-1} - \gamma_2 p^\kappa_t + 2\lambda_2 \kappa_t^* = 0 \]

\paragraph{G}
\textbf{Optimal Mechanization Gap:}

\[ \kappa_t^*(\omega_{t-1}, p^\kappa_t) = \frac{(\gamma_0 - \lambda_1) - \gamma_1 \omega_{t-1} + \gamma_2 p^\kappa_t}{2\lambda_2} \]

\paragraph{H}
Strict concavity ($2\lambda_2 < 0$) guarantees a unique maximum. The comparative statics establish the induced innovation mechanism:

\[ \frac{\partial \kappa_t^*}{\partial \omega_{t-1}} = -\frac{\gamma_1}{2\lambda_2} > 0 \]
\[ \frac{\partial \kappa_t^*}{\partial p^\kappa_t} = \frac{\gamma_2}{2\lambda_2} < 0 \]

\paragraph{I}
A rising wage share forces cost-minimizing firms to widen the mechanization gap, substituting machinery for labor. Conversely, a rising relative price of machinery suppresses the optimal gap, as the structural cost of the composition shift penalizes the mechanization program.

\subsubsection{The Marginal Capacity Payoff and the Econometric Bridge}

\paragraph{A}
The macroeconomic mapping from the mechanization gap to potential capacity is given by the \textbf{Marginal Capacity Payoff} ($MP_\kappa$), which is the derivative of the intensive capacity yield $\Psi_t$ with respect to the gap $\kappa_t$.

\paragraph{B}
By the envelope theorem, the marginal capacity payoff is exactly the net marginal viability yield evaluated at the optimum:

\[ MP_\kappa = \frac{\partial \Psi_t}{\partial \kappa_t} = \frac{\partial \Phi}{\partial \kappa_t} - MC(\omega_{t-1}, p^\kappa_t) \]

\paragraph{C}
Substituting the derivatives:

\[ MP_\kappa = (\lambda_1 + 2\lambda_2 \kappa_t) - (\gamma_0 - \gamma_1 \omega_{t-1} + \gamma_2 p^\kappa_t) \]

\paragraph{D}
Rearranging terms to isolate the state variables yields the state-dependent marginal product:

\[ MP_\kappa = \underbrace{(\lambda_1 - \gamma_0 + 2\lambda_2 \kappa_t)}_{\text{Autonomous Yield}} + \gamma_1 \omega_{t-1} - \gamma_2 p^\kappa_t \]

\paragraph{E}
Integrating the marginal payoff with respect to $\kappa_t$ (treating $\omega_{t-1}$ and $p^\kappa_t$ as predetermined shifters) and defining $\theta_\kappa$, $\theta_{\omega\kappa} = \gamma_1$, and $\theta_{\kappa p\kappa} = -\gamma_2$ yields the intensive capacity yield function:

\[ \Psi_t = \theta_\kappa \kappa_t + \theta_{\omega\kappa} (\omega_{t-1} \kappa_t) + \theta_{\kappa p\kappa} (p^\kappa_t \kappa_t) \]

\paragraph{F}
Substituting $\Psi_t$ back into the capacity decomposition recovers the structural capacity equation:

\[ y^p_t = \theta_{NRC} k^{NRC}_t + \theta_\kappa \kappa_t + \theta_{\omega\kappa} (\omega_{t-1} \kappa_t) + \theta_{\kappa p\kappa} (p^\kappa_t \kappa_t) \]

\paragraph{G}
The interaction terms are not ad-hoc econometric additions; they are the macroeconomic footprint of the divided firm's Okishio viability constraint. Distributive pressure and relative price enter because they alter the marginal capacity payoff of the mechanization gap.

\subsubsection{The Aggregate Transformation Elasticity}

\paragraph{A}
The aggregate transformation elasticity ($\theta^{SpecB}_t$) is the ratio of the total differentials of potential capacity ($dy^p_t$) and aggregate log capital ($dk^{cap}_t$) along the historical accumulation path.

\paragraph{B}
The total differential of the capacity equation, holding the slow-moving state variables fixed, separates the extensive envelope from the intensive margin:

\[ dy^p_t = \frac{\partial y^p_t}{\partial k^{NRC}_t} dk^{NRC}_t + \frac{\partial y^p_t}{\partial \kappa_t} d\kappa_t \]

\paragraph{C}
Substituting $\partial y^p_t / \partial k^{NRC}_t = \theta_{NRC}$ and $\partial y^p_t / \partial \kappa_t = MP_\kappa$:

\[ dy^p_t = \theta_{NRC} dk^{NRC}_t + MP_\kappa d\kappa_t \]
\[ dy^p_t = \theta_{NRC} dk^{NRC}_t + \left( \theta_\kappa + \theta_{\omega\kappa} \omega_{t-1} + \theta_{\kappa p\kappa} p^\kappa_t \right) d\kappa_t \]

\paragraph{D}
The variation in aggregate capital ($dk^{cap}_t$) follows from the Divisia index of the heterogeneous components:

\[ dk^{cap}_t \approx s_{ME,t} dk^{ME}_t + s_{NRC,t} dk^{NRC}_t \]

\paragraph{E}
Since $s_{ME,t} + s_{NRC,t} = 1$ and $d\kappa_t = dk^{ME}_t - dk^{NRC}_t$, aggregate capital simplifies to:

\[ dk^{cap}_t \approx s_{ME,t} (d\kappa_t + dk^{NRC}_t) + s_{NRC,t} dk^{NRC}_t = dk^{NRC}_t + s_{ME,t} d\kappa_t \]

\paragraph{F}
Dividing numerator and denominator by $dk^{NRC}_t$ yields the elasticity along the empirical growth path $\frac{d\kappa_t}{dk^{NRC}_t}$:

\[ \theta^{SpecB}_t = \frac{dy^p_t}{dk^{cap}_t} = \frac{\theta_{NRC} dk^{NRC}_t + MP_\kappa d\kappa_t}{dk^{NRC}_t + s_{ME,t} d\kappa_t} = \frac{\theta_{NRC} + MP_\kappa \frac{d\kappa_t}{dk^{NRC}_t}}{1 + s_{ME,t} \frac{d\kappa_t}{dk^{NRC}_t}} \]

\paragraph{G}
Expanding $MP_\kappa$ yields the structural expression:

\[ \theta^{SpecB}_t = \frac{\theta_{NRC} + \left( \theta_\kappa + \theta_{\omega\kappa} \omega_{t-1} + \theta_{\kappa p\kappa} p^\kappa_t \right) \frac{d\kappa_t}{dk^{NRC}_t}}{1 + s_{ME,t} \frac{d\kappa_t}{dk^{NRC}_t}} \]

\paragraph{H}
\textbf{Definition (Structural Overaccumulation Regime).} Under \textbf{strong labor closure} (high $\omega_{t-1}$), the induced-efficiency parameter $\theta_{\omega\kappa}$ anchors the elasticity, ensuring that mechanization translates smoothly into capacity. Conversely, under \textbf{weak labor closure} and rising machinery costs, the state-dependent marginal viability yield collapses. This mechanically drives the aggregate transformation elasticity below unity:
\[ \theta_t^{SpecB} < 1 \]
This inequality defines the \textbf{Structural Overaccumulation Regime}: a historical phase in which additional capital accumulation yields diminishing or negative capacity expansion, decoupling the intensive mechanization margin from the extensive structural envelope.

\paragraph{I}
\textbf{Capacity Recovery and the Residual Critique.} Capacity utilization ($\mu_t$) is not the regression residual, nor a detrended output gap. Following the locked capacity level anchor pinch year protocol, $\mu_t$ is recovered by applying the estimated $\hat{\theta}^{SpecB}_t$ to aggregate capital growth ($g_{K^{cap},t}$), anchoring the level at the pinch year ($t^*_{US} = 1973$), and extrapolating against aggregate real output ($Y_t = \text{GDP}_t$). The full four-step sequence is executed in Section 4.3.

\paragraph{J}
\textbf{Testable Hypotheses.} Three testable predictions follow from the model for the U.S. corporate sector:

\begin{itemize}
  \item \textbf{Hypothesis 1 (The Okishio Distributive Dividend):} $\hat{\theta}_{\omega\kappa} > 0$. Distributive wage pressure structurally increases the capacity-generating yield of the mechanization gap.
  \item \textbf{Hypothesis 2 (The Relative Price Penalty):} $\hat{\theta}_{\kappa p\kappa} < 0$. Relative price inflation in machinery penalizes the intensive margin, reducing the capacity payoff of mechanization.
  \item \textbf{Hypothesis 3 (The Structural Overaccumulation Regime):} Under weak labor closure (post-Fordism), the collapse of the state-dependent marginal viability yield drives the aggregate transformation elasticity below unity ($\theta_t^{SpecB} < 1$), producing chronic industrial stagnation.
\end{itemize}

\paragraph{K}
Section 3.2 closes the analytical identification of the heterogeneous capital model. Translating the capacity equation into an estimable cointegrating specification — regressor orthogonalization, integration-order screening, and non-standard fixed-$b$ inference — is executed in Section 4.3.




%% ============================================================
%% FLAGGED FOR RELOCATION TO §3.4 (Consolidated Identification)
%% The following three paragraphs will be moved when §3.4 is
%% edited. They are retained here temporarily to preserve
%% content integrity.
%% ============================================================

\paragraph{3.22}
\textbf{[RELOCATE TO §3.4]} Capacity utilization ($\mu_t$)
is not the regression residual, nor a detrended output gap.
Following the locked capacity level anchor pinch year
protocol, $\mu_t$ is recovered by applying the estimated
$\hat{\theta}^{SpecB}_t$ to aggregate capital growth
($g_{K^{cap},t}$), anchoring the level at the pinch year
($t^*_{US} = 1973$), and extrapolating against aggregate
real output ($Y_t = \text{GDP}_t$). The full four-step
sequence is executed in Section~4.3.

\paragraph{3.23}
\textbf{[RELOCATE TO §3.4]} Three testable predictions
follow from the model for the U.S. corporate sector:
\begin{itemize}
  \item \textbf{Hypothesis 1 (The Okishio distributive
  dividend):} $\hat{\theta}_{\omega\kappa} > 0$.
  Distributive wage pressure structurally increases the
  capacity-generating yield of the mechanization gap.
  \item \textbf{Hypothesis 2 (The relative price penalty):}
  $\hat{\theta}_{\kappa p\kappa} < 0$. Relative price
  inflation in machinery penalizes the intensive margin,
  reducing the capacity payoff of mechanization.
  \item \textbf{Hypothesis 3 (The structural
  overaccumulation regime):} Under weak labor closure
  (post-Fordism), the collapse of the state-dependent
  marginal viability yield drives the aggregate
  transformation elasticity below unity
  ($\theta_t^{SpecB} < 1$), producing chronic industrial
  stagnation.
\end{itemize}

\paragraph{3.24}
\textbf{[RELOCATE TO §3.4]} Section~3.2 closes the
analytical identification of the heterogeneous capital
model. Translating the capacity equation into an estimable
cointegrating specification---regressor orthogonalization,
integration-order screening, and non-standard fixed-$b$
inference---is executed in Section~4.3.