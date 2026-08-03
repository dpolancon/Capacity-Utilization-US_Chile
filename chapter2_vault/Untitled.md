## 3.2.4 The Aggregate Transformation Elasticity and the Benchmark of Smooth Reproduction

The macroeconomic stability of the aggregate transformation elasticity ($\theta^{SpecB}_t$) depends entirely on this state-dependent mechanism. We define the aggregate elasticity as the total derivative of potential capacity with respect to aggregate log capital stock ($k^{cap}_t$).

Aggregate capital is the Divisia index of its components: $k^{cap}_t \approx s_{ME,t} k^{ME}_t + s_{NRC,t} k^{NRC}_t + s_{GTC,t} k^{GTC}_t$. Substituting the definition of the mechanization gap ($k^{ME}_t = \kappa_t + k^{NRC}_t$) and noting that $s_{ME,t} + s_{NRC,t} + s_{GTC,t} = 1$, we simplify the aggregate capital stock to:

$$ k^{cap}_t \approx s_{ME,t} \kappa_t + (1 - s_{GTC,t}) k^{NRC}_t + s_{GTC,t} k^{GTC}_t $$

To find the aggregate elasticity, we take the total derivative of potential capacity ($y^p_t$) and aggregate capital ($k^{cap}_t$) with respect to the private extensive envelope ($k^{NRC}_t$) along the empirical path, treating the state-determined public capital ($k^{GTC}_t$) as an exogenous shifter:

$$ \frac{dy^p_t}{dk^{NRC}_t} = \theta_{NRC} + MP_\kappa \frac{d\kappa_t}{dk^{NRC}_t} $$

$$ \frac{dk^{cap}_t}{dk^{NRC}_t} = (1 - s_{GTC,t}) + s_{ME,t} \frac{d\kappa_t}{dk^{NRC}_t} $$

### The Marginal Composition of Accumulation and Long-Run Tendencies

The term $\phi_t \equiv \frac{d\kappa_t}{dk^{NRC}_t}$ represents the **marginal composition of private accumulation**—the tactical choice of technique dictating how much machinery is added per unit of structural envelope. 

If $\phi_t$ is treated purely as a short-run empirical realization, $\theta^{SpecB}_t$ becomes a noisy cyclical indicator. However, for the transformation elasticity to serve as a **benchmark of smooth reproduction** (the balanced, long-run expansion of the capital fractions), $\phi_t$ must be calibrated by long-run tendencies. We therefore decompose the marginal composition of accumulation into a long-run structural trend and a short-run cyclical deviation:

$$ \phi_t = \phi^{LR} + \Delta \phi_t $$

where $\phi^{LR}$ is the long-run calibrated tendency of the mechanization gap (derived from the steady-state of the induced innovation model or historical trend technical change), and $\Delta \phi_t$ captures short-run tactical disequilibria.

### The Benchmark vs. Realized Transformation Elasticity

Applying the chain rule, the **Realized Aggregate Transformation Elasticity** is the ratio of these path derivatives:

$$ \theta^{SpecB}_t = \frac{\theta_{NRC} + MP_{\kappa,t} \phi_t}{(1 - s_{GTC,t}) + s_{ME,t} \phi_t} $$

Conversely, the **Benchmark Transformation Elasticity** ($\bar{\theta}^{SpecB}$), which defines the structural capacity of the economy to smoothly transform capital into output under normal reproduction conditions, is evaluated at the long-run tendency $\phi^{LR}$ and the normal state variables ($\bar{\omega}, \bar{p}^\kappa$):

$$ \bar{\theta}^{SpecB} = \frac{\theta_{NRC} + \overline{MP}_\kappa \phi^{LR}}{(1 - \bar{s}_{GTC}) + \bar{s}_{ME} \phi^{LR}} $$

> [!conclusion] The Overaccumulation Regime ($\theta_t^{SpecB} < 1$)
> Under conditions of **smooth reproduction**, the realized elasticity converges to the benchmark ($\theta^{SpecB}_t \approx \bar{\theta}^{SpecB} \ge 1$), anchored by the long-run tendency $\phi^{LR}$ and strong labor closure (high $\bar{\omega}$). 
> 
> However, under **weak labor closure**, rising machinery costs, or realization crises, the tactical choice of technique breaks down. Firms halt machinery accumulation relative to structures, causing a sharp negative deviation in the marginal composition of accumulation ($\Delta \phi_t \ll 0$). Simultaneously, the state-dependent marginal viability yield ($MP_{\kappa,t}$) collapses. 
> 
> This mechanically drives the *realized* aggregate transformation elasticity below the benchmark, and ultimately below unity:
> $$ \theta_t^{SpecB} < \bar{\theta}^{SpecB} \implies \theta_t^{SpecB} < 1 $$
> This inequality formally defines the **Structural Overaccumulation Regime**: a historical phase in which short-run tactical deviations ($\Delta \phi_t$) and collapsing viability yields decouple the intensive mechanization margin from the extensive structural envelope, rendering additional private capital accumulation incapable of generating proportional capacity expansion.
^overaccumulation-regime