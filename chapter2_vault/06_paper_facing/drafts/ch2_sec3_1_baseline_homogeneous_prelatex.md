---
type: paper_facing
status: draft
country: US_CL
stage_scope: N/A
last_updated: '2026-08-01'
depends_on: []
blocks: []
layer: design
scope: chapter2
priority: context
---

# Section 3.1: The Baseline Model of Cost-Minimizing Mechanization (Homogeneous Capital Stock)

Before formalizing the cost-minimizing choice of technique, we establish the descriptive macro context for the United States across five distinct historical windows: the pre-war Fordist recovery (1931–1941), the World War II mobilization block (1942–1945), the postwar Fordist Golden Age (1947–1973), the post-Fordist restructuring era prior to the Global Financial Crisis (1974–2007), and the post-GFC stagnation period (2008–2024). We track the average annual growth rates (mean annual log differences) of real corporate output alongside gross capital stocks built using the Gross Perpetual Inventory Method (GPIM), distinguishing private machinery and equipment (\(K^{\text{ME}}\)), private nonresidential structures (\(K^{\text{NRC}}\)), and public infrastructure in the form of government transportation, highways, and streets (\(K^{\text{GT}}\)). We report both Non-Financial Corporate sector Gross Value Added (\(y_t\)) and total economy Real GDP (\(y_{\text{total}}\)) to capture corporate-level dynamics relative to aggregate activity.[^data_provenance_footnote]

| Variable | Pre-war Fordism (1931–1941) | WWII Block (1942–1945) | Postwar Fordism (1947–1973) | Post-Fordism Pre-GFC (1974–2007) | Post-GFC (2008–2024) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| Real Corporate GVA (\(y_t\)) | 5.80% | 4.36% | 4.98% | 3.55% | 1.99% |
| Real GDP (Total Economy, \(y_{\text{total}}\)) | 3.94% | 9.92% | 3.76% | 2.97% | 1.95% |
| Gross Machinery & Equipment (\(K^{\text{ME}}\)) | 1.37% | 4.73% | 8.49% | 6.58% | 3.66% |
| Gross Nonresidential Structures (\(K^{\text{NRC}}\)) | 1.08% | 3.79% | 6.38% | 7.02% | 3.99% |
| Gross Government Transportation (\(K^{\text{GT}}\)) | 4.07% | -0.14% | 4.44% | 2.05% | 1.06% |

[^data_provenance_footnote]: **Data Provenance and GPIM Construction:** Output and capital series are compiled from the repository's open source of truth database release (`chapter2_us_source_of_truth_v1`). Real corporate output is measured by log real Non-Financial Corporate Gross Value Added (BEA NIPA Table 1.14). The pre-war window begins in 1931 due to NIPA Table 1.14 reporting limits. Total economy output is real GDP in millions of 2017 chained dollars, constructed by deflating nominal GDP (FRED variable `GDPA`) by the GDP implicit price deflator (FRED variable `A191RD3A086NBEA`). Private capital stocks (\(K^{\text{ME}}\) and \(K^{\text{NRC}}\)) are gross GPIM stocks compiled from BEA Fixed Assets Table 4.1 investment inputs. They are convolved with Weibull survival functions: \(L = 14\text{ yr}, \alpha = 1.7\) for machinery, and \(L = 30\text{ yr}, \alpha = 1.6\) for structures. Government transportation stock (\(K^{\text{GT}}\)) is the real gross stock convolved with Weibull parameters \(L = 60\text{ yr}\) (Fraumeni U.S. design life lock) and \(\alpha = 1.3\) (Nomura 2005 road hazard shape proxy), constructed from BEA Fixed Assets Table 7.1 investment lines for Highways and Streets and Transportation Structures (Stage S41 diagnostic branch).

These indicators show the structural breaks defining each regime. During the pre-war recovery (1931–1941), corporate GVA grew at a rapid 5.80% per year. Public investment drove this, with infrastructure expanding at 4.07% while private accumulation lagged. World War II changed everything. The mobilization block (1942–1945) redirected capital toward war production. Civilian infrastructure contracted at -0.14% per year, while military spending pushed total GDP growth to a massive 9.92%. The postwar Golden Age (1947–1973) represents the historical peak of coupled accumulation. Machinery grew at 8.49% annually, structures at 6.38%, and public infrastructure at 4.44%. This balanced growth sustained a 4.98% average expansion of real corporate GVA. In the post-Fordist era, this coordination broke down. Public infrastructure growth fell to 2.05% before the GFC, and sank to a mere 1.06% after 2008. Meanwhile, private structures decoupled, growing at 7.02% pre-GFC before dropping to 3.99% post-GFC. This combination of private overaccumulation and public decay explains the long-run slowdown of corporate capacity formation.

Following heterodox political economy, we represent actual aggregate output using a Leontief production function with fixed technical coefficients:

$$ Y = \min\left( A L, \ \mu B K \right) $$

where $A = Y/L$ is actual labor productivity, $\mu = Y/Y^p$ is capacity utilization, and $B = Y^p/K$ is maximum capital productivity. This production structure directly governs the rate of profit ($r$) through the fundamental heterodox accounting identity:

$$ r = \mu B (1 - \omega) $$

where $\omega$ is the wage share. Standard macroeconomic models frequently treat the structural coefficient $B$ as an exogenous technological given, while treating the utilization rate $\mu$ as a behavioral constant smoothly targeted by a unified firm. We explicitly reject these assumptions. Instead, we treat the components of the profit rate identity as endogenous outcomes of class struggle and decentralized market anarchy.

This section formalizes how distributive pressure forces cost-minimizing firms to alter their tactical choice of technique, endogenously determining the structural capacity coefficient $B$.

## 3.1.1 Tactical Choice of Technique and Induced Innovation

Firms select a mechanization growth rate $q$ to maximize the net productivity surplus. We define $a$ as the growth rate of labor productivity and $\omega$ as the wage share. The effective distributive cost of deploying mechanization growth is therefore $q(1-\omega)$. The firm solves the following tactical optimization problem:

$$ \max_{q} \ c(q) = a - q(1-\omega) $$

This objective captures the induced-innovation logic: firms accelerate mechanization to expand labor productivity growth ($a$), but the distributive cost of capital intensity ($1-\omega$) holds them back. A technological frontier bounds this choice:

$$ a = \Phi(q) = \lambda_0 + \lambda_1 q + \lambda_2 q^2 $$

The frontier parameters govern the structural limits of technical change. The base productivity growth $\lambda_0 > 0$ sets the floor without advanced machinery. The linear coefficient $\lambda_1 > 0$ captures the direct productivity payoff of mechanization. We impose the concavity condition $\lambda_2 < 0$ to ensure diminishing marginal returns to mechanization.

Substituting the technological frontier into the objective function yields the unconstrained tactical problem:

$$ c(q) = (\lambda_0 + \lambda_1 q + \lambda_2 q^2) - q(1-\omega) $$

Factoring out $q$ gives the final objective function in terms of mechanization growth:

$$ c(q) = \lambda_0 + (\lambda_1 - (1-\omega)) q + \lambda_2 q^2 $$

Differentiating with respect to $q$ and setting the result to zero yields the first-order condition for optimal mechanization growth:

$$ \frac{dc}{dq} = \lambda_1 - (1-\omega) + 2\lambda_2 q^* = 0 $$

Solving for the optimal mechanization growth $q^*$ gives:

$$ q^*(\omega) = \frac{(1-\omega) - \lambda_1}{2\lambda_2} $$

The strict concavity of the frontier ($c''(q) = 2\lambda_2 < 0$) guarantees a unique and stable maximum. Differentiating $q^*$ with respect to the wage share $\omega$ formally establishes the induced innovation mechanism:

$$ \frac{\partial q^*}{\partial \omega} = -\frac{1}{2\lambda_2} > 0 $$

A rise in the wage share ($\omega \uparrow$) forces cost-minimizing firms to substitute machinery for labor. Rising wages drive mechanization directly through the first-order condition, pushing optimal capital intensity growth $q^*$ upward.

## 3.1.2 Endogenous Transformation Elasticity

Substituting the optimal technique back into the technological frontier recovers the normal growth rate of labor productivity under smooth reproduction:

$$ a^N(\omega) = \lambda_0 + \lambda_1 q^*(\omega) + \lambda_2 \left[ q^*(\omega) \right]^2 $$

This optimal technique dictates the structural trajectory of the Leontief parameter $B$. By definition, maximum capital productivity is the ratio of potential output to capital ($B = Y^p / K$). Expressed in dynamic growth rates, the growth of capital productivity ($b$) is the difference between capacity growth and capital accumulation ($b = g_{Y^p} - g_K$). Equivalently, it is the gap between labor productivity growth and mechanization growth ($b = a - q$).

Evaluated at the smooth reproduction benchmark, this optimal gap is $b^N(\omega) = a^N(\omega) - q^*(\omega)$. 

We define the transformation elasticity ($\theta$) as the structural parameter that translates capital accumulation into productive capacity growth ($g_{Y^p} = \theta g_K$). Substituting this definition into the growth rate of capital productivity ($b = \theta g_K - g_K$) reveals the fundamental mathematical link between the level coefficient $B$ and the elasticity $\theta$:

$$ \theta = 1 + \frac{b}{g_K} $$

To evaluate this elasticity, we must anchor the optimal technique to a baseline rate of capital accumulation. Following the normal reproduction path, the normal rate of capital accumulation ($g_K^N$) is driven by the normal profit rate ($r^N$) and the normal recapitalization share ($\chi^N$), net of depreciation ($\delta$):

$$ g_K^N = \chi^N r^N - \delta $$

Expressed dynamically relative to this normal accumulation path, the aggregate transformation elasticity becomes:

$$ \theta(\omega) = 1 + \frac{b^N(\omega)}{g_K^N} = 1 + \frac{a^N(\omega) - q^*(\omega)}{g_K^N} $$

This proves a crucial point: the transformation elasticity is not an exogenous technical constant. It emerges endogenously from the cost-minimizing choice of technique. When distributive pressure forces firms to alter mechanization, it simultaneously shifts the structural efficiency of accumulation.
