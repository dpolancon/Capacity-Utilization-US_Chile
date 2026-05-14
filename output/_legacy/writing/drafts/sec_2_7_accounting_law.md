# §2.7 — The Accounting Law of Capital Accumulation
**Source authority:** `capital_accumulation_accounting_behavioral_id.md`
**Date drafted:** 2026-03-29
**Word count:** 500
**Self-check:** PASS

This section derives the accounting law that governs the relationship between gross accumulation, profitability, capacity utilization, and capital productivity. Every step is an identity manipulation — no behavioral equation is imposed. The behavioral content enters only through the question of whether the recapitalization rate is constant, a question deferred entirely to §2.8.

## From accumulation rate to investment share

Define the gross accumulation rate as

$$\iota_t \equiv \frac{I_t}{K_t}, \tag{2.9}$$

where $I_t$ is gross investment and $K_t$ is the capital stock. Since the investment share in output is $\phi_t \equiv I_t / Y_t$, and since $Y_t = \mu_t Y_t^p = \mu_t B_t K_t$ by the definitions established in §2.3, one obtains

$$\iota_t = \phi_t\, \mu_t\, B_t. \tag{2.10}$$

The gross accumulation rate is the product of the investment share, capacity utilization, and capital productivity at normal capacity. This is a tautology: it simply unpacks $I_t / K_t$ through the chain $I_t / Y_t \times Y_t / Y_t^p \times Y_t^p / K_t$.

## Utilization drops out at normal capacity

Observe that the product $\phi_t \mu_t$ simplifies:

$$\phi_t\, \mu_t = \frac{I_t}{Y_t} \cdot \frac{Y_t}{Y_t^p} = \frac{I_t}{Y_t^p} \equiv \phi_t^p, \tag{2.11}$$

where $\phi_t^p$ is the investment share evaluated at productive capacity rather than at realized output. Substituting into (2.10) gives

$$\iota_t = \phi_t^p\, B_t. \tag{2.12}$$

In this form, utilization drops out entirely: what matters for the accounting of accumulation is how much of productive capacity the economy commits to investment, multiplied by the productivity of the capital stock at normal utilization. The two representations — (2.10) with utilization explicit and (2.12) with utilization absorbed — are not rivals; they are linked accounting identities viewing the same magnitude from different angles.

## The recapitalization rate

A second decomposition introduces the recapitalization rate — the share of profits channeled into investment:

$$\beta_t \equiv \frac{I_t}{\Pi_t}, \tag{2.13}$$

where $\Pi_t$ denotes gross profits. Since the profit share is $\pi_t \equiv \Pi_t / Y_t$ and the profit rate is

$$r_t \equiv \frac{\Pi_t}{K_t} = \pi_t\, \mu_t\, B_t, \tag{2.14}$$

the investment share decomposes as $\phi_t = \beta_t \pi_t$. Substituting into (2.10) and collecting terms yields the boxed result:

$$\boxed{\iota_t = \beta_t\, \pi_t\, \mu_t\, B_t = \beta_t\, r_t.} \tag{2.15}$$

The gross accumulation rate equals the recapitalization rate times the profit rate. Equivalently, it equals the recapitalization rate times the profit share times utilization times capital productivity. The Weisskopf (1979) decomposition $r_t = \mu_t\, B_t\, \pi_t$ is the profitability reading of the same identity: the profit rate is demand-led through $\mu_t$, structurally mediated through $B_t$, and distributively conditioned through $\pi_t$.

## Two recapitalization lenses

The identity admits two complementary lenses on recapitalization. The ratio $\beta_t = I_t / \Pi_t$ measures the funding of investment out of profits: it asks what fraction of the surplus is plowed back into accumulation. The ratio $\phi_t^p = I_t / Y_t^p$ measures the claim of investment on productive-capacity output: it asks what fraction of the economy's structural output goes to capital formation. Both are accounting objects; neither requires a behavioral assumption. Their analytical value lies in what happens when one asks whether they are constant. If $\beta_t$ is constant, accumulation is fully determined by the accounting decomposition — capitalists mechanically reinvest a fixed share of profits regardless of structural conditions. If $\beta_t$ varies, then the question becomes: what does it respond to? That is the behavioral margin, and §2.8 takes it up directly, specifying the behavioral accumulation law in which $\beta_t$ responds to distribution, demand, and the structural transformation of capital productivity.
