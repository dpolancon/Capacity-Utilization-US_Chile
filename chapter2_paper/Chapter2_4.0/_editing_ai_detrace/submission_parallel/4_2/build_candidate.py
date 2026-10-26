import os

baseline_path = "_editing_ai_detrace/submission_parallel/4_2/01_BASELINE_SECTION4.tex"
candidate_path = "_editing_ai_detrace/submission_parallel/4_2/02_CANDIDATE_4_2.tex"

with open(baseline_path, "r", encoding="utf-8") as f:
    text = f.read()

targets = {}

targets["CH2-S04.02-P001"] = (
"""This subsection presents stylized facts and descriptive statistics of my data set for the United States (1931--2024) and Chile
(1940--2010). First, the data presented for output correspond always to Non Financial Corporate Sector, while the measurement of capital stock correspond to gross measures following my own implementation of \\citet{Shaikh2016} \\textit{Generalized Perpetual Inventory Method} (GPIM) as presented above.  Second, output and capital stocks drift together over the long run in both economies, motivating a cointegrating approach. Third, the level of the output--capital ratio drifts through time in both countries of interest: in the United States presents a declining trend in the long-run, suggesting that their long-run relation might be governed by a transformation elasticity below unity; while in the case in Chile the relation is unclear, while its composition when distinguishing between non-residential construction and machinery and equipments accounts discretely shifts across historical regimes, this motivates a formulation of heterogeneous capital. Third, in the US capital accumulates faster than output on average. Fourth, the state variables that condition
the transformation---the distributive state in both economies and the
external bottleneck components in the periphery---shift discretely across
institutional regimes, motivating a state-dependent and threshold
co-integration empirical strategies presented in the next Section~4.3.""",
"""This subsection presents stylized facts and descriptive statistics of my data set for the United States (1931--2024) and Chile (1940--2010). First, output data correspond to the Non Financial Corporate Sector, while capital stock measurement corresponds to gross measures following my implementation of \\citet{Shaikh2016} \\textit{Generalized Perpetual Inventory Method} (GPIM) presented above. Second, output and capital stocks drift together over the long run in both economies, motivating a cointegrating approach. Third, the output--capital ratio drifts through time in both countries: in the United States, capital accumulates faster than output on average and the ratio presents a declining long-run trend, suggesting that their long-run relation might be governed by a transformation elasticity below unity; in Chile, the relation is unclear, while capital composition between non-residential construction and machinery and equipment shifts discretely across historical regimes, motivating a formulation of heterogeneous capital. Fourth, the state variables that condition the transformation---the distributive state in both economies and the external bottleneck components in the periphery---shift discretely across institutional regimes, motivating the state-dependent and threshold cointegration empirical strategies presented in Section~4.3."""
)

targets["CH2-S04.02.01-P001"] = (
"""To ground the subsequent econometric analysis in empirical reality, this subsection documents the key stylized facts of the U.S. non-financial corporate economy over the 94-year sample period from 1931 to 2024. Table~\\ref{tab:us_stylized_facts_summary} provides the summary statistics for the core macroeconomic and distributive variables, capturing the long-run means and volatilities of real output, capital accumulation, functional income distribution, and the evolving composition of the capital stock. While these aggregate moments establish the foundational structural characteristics of the economy—such as the persistent divergence between capital and output growth and the shifting dynamics of the wage share—the temporal evolution and historical regime shifts underlying these averages require a detailed chronological examination. The following figures therefore trace the secular trends, cyclical fluctuations, and structural breaks across these dimensions, providing the empirical motivation for the theoretical and econometric specifications developed in the subsequent sections.""",
"""Table~\\ref{tab:us_stylized_facts_summary} provides summary statistics for the core macroeconomic and distributive variables of the U.S. non-financial corporate economy over the 94-year sample period from 1931 to 2024, capturing the long-run means and volatilities of real output, capital accumulation, functional income distribution, and the evolving composition of the capital stock. While these aggregate moments record the persistent divergence between capital and output growth and the shifting dynamics of the wage share, the historical regime shifts underlying these averages require chronological examination. The series that follow trace the secular trends, cyclical fluctuations, and structural breaks across these dimensions, providing the empirical motivation for the theoretical and econometric specifications developed in subsequent sections."""
)

targets["CH2-S04.02.01-P002"] = (
"""Figure~\\ref{fig:us_stylized_1_y_kcap} plots log real non-financial corporate output ($y_t$) and the log of aggregate gross capital stock $k_t^{cap} = \\ln(K_t^{\\text{ME}} + K_t^{\\text{NRC}})$. Over the 94-year sample, the two levels drift together along a common upward trend. From the early 1980s onward, the capital stock runs systematically above output, generating a persistent overaccumulation gap. Estimating in first differences would discard exactly this shared long-run cointegrating trajectory.""",
"""Log real non-financial corporate output ($y_t$) and the log of aggregate gross capital stock $k_t^{cap} = \\ln(K_t^{\\text{ME}} + K_t^{\\text{NRC}})$ drift together along a common upward trend over the 94-year sample (Figure~\\ref{fig:us_stylized_1_y_kcap}). From the early 1980s onward, the capital stock runs systematically above output, generating a persistent overaccumulation gap. Estimating in first differences would discard exactly this shared long-run cointegrating trajectory."""
)

targets["CH2-S04.02.01-P003"] = (
"""Figure~\\ref{fig:us_stylized_2_yk_ratio} plots the corresponding log output--capital ratio ($y_t - k_t^{cap}$). The ratio spikes to its historical maximum under wartime mobilization (1944), falls through the early Cold War, recovers part of the decline in a Fordist hump around 1966, and declines secularly thereafter. The LOESS trend traces a downward drift from 1950 onward, steepening after 1970 and again after 2000. A ratio that falls for decades while capital accumulates provides an empirical suggestion of an over-accumulation tendency $\\theta < 1$: capacity formation persistently lags capital accumulation. The balanced-growth knife-edge $\\theta = 1$ does not renders as a long-run tendency, once the measurement of capital stock and the dual valuation distinction and the purpose of measurement is considered.""",
"""The corresponding log output--capital ratio ($y_t - k_t^{cap}$, Figure~\\ref{fig:us_stylized_2_yk_ratio}) spikes to its historical maximum under wartime mobilization (1944), falls through the early Cold War, recovers part of the decline in a Fordist hump around 1966, and declines secularly thereafter. The LOESS trend traces a downward drift from 1950 onward, steepening after 1970 and again after 2000. A ratio that falls for decades while capital accumulates provides an empirical suggestion of an over-accumulation tendency $\\theta < 1$: capacity formation persistently lags capital accumulation. The balanced-growth knife-edge $\\theta = 1$ does not render as a long-run tendency, once the measurement of capital stock, the dual valuation distinction, and the purpose of measurement are considered."""
)

targets["CH2-S04.02.01-P004"] = (
"""Figure~\\ref{fig:us_stylized_2b_kappa} plots the mechanization gap $\\kappa_t = k_t^{\\text{ME}} - k_t^{\\text{NRC}}$ (mean $-0.637$, SD $0.278$, Table~\\ref{tab:us_stylized_facts_summary}). The gap remains depressed throughout the Great Depression and World War II ($\\approx -1.15$), embarks on a sustained upward march across the Golden Age of Atlantic Fordism as machinery and equipment outpaced industrial structures, and peaks in the late 1990s ($\\approx -0.313$) during the information-technology equipment boom. From 2000 onward, $\\kappa_t$ declines as investment shifted toward structures and commercial real estate while Intellectual Property Products absorbed intangible accumulation, leaving direct physical machinery accumulation subdued. The capital composition ratio is therefore a regime-shifting series rather than a smooth trend, motivating the heterogeneous-capital specification in which the transformation elasticity $\\theta$ depends dynamically on $\\kappa_t$.""",
"""The mechanization gap $\\kappa_t = k_t^{\\text{ME}} - k_t^{\\text{NRC}}$, plotted in Figure~\\ref{fig:us_stylized_2b_kappa} (mean $-0.637$, SD $0.278$, Table~\\ref{tab:us_stylized_facts_summary}), remains depressed throughout the Great Depression and World War II ($\\approx -1.15$), embarks on a sustained upward march across the Golden Age of Atlantic Fordism as machinery and equipment outpaced industrial structures, and peaks in the late 1990s ($\\approx -0.313$) during the information-technology equipment boom. From 2000 onward, $\\kappa_t$ declines as investment shifted toward structures and commercial real estate while Intellectual Property Products absorbed intangible accumulation, leaving direct physical machinery accumulation subdued. The capital composition ratio is therefore a regime-shifting series rather than a smooth trend, motivating the heterogeneous-capital specification in which the transformation elasticity $\\theta$ depends dynamically on $\\kappa_t$."""
)

targets["CH2-S04.02.01-P005"] = (
"""Figure~\\ref{fig:us_stylized_3_growth_rates} contrasts annual growth rates. Over the full sample, aggregate gross capital accumulation grows faster than output on average (5.9\\% against 3.9\\% per year, Table~\\ref{tab:us_stylized_facts_summary}), a long-run relation consistent with overaccumulation under an unbalanced growth closure. The two series have comparable standard deviations (0.051 against 0.045) because the pre-1950 window contains large swings in both, including capital-growth spikes around 1946 and 1974. The asymmetry that matters for estimation appears after 1950: output growth repeatedly turns negative in recessions while capital accumultion remains positive, reflecting the durability of physical capiatl in operation reflected by gross measurements. From the mid-1960s, the capital-growth series sits mostly above the output-growth line.""",
"""Annual growth rates of output and capital are contrasted in Figure~\\ref{fig:us_stylized_3_growth_rates}. Over the full sample, aggregate gross capital accumulation grows faster than output on average (5.9\\% against 3.9\\% per year, Table~\\ref{tab:us_stylized_facts_summary}), a long-run relation consistent with overaccumulation under an unbalanced growth closure. The two series have comparable standard deviations (0.051 against 0.045) because the pre-1950 window contains large swings in both, including capital-growth spikes around 1946 and 1974. The asymmetry that matters for estimation appears after 1950: output growth repeatedly turns negative in recessions while capital accumulation remains positive, reflecting the durability of physical capital in operation captured by gross measurements. From the mid-1960s, the capital-growth series sits mostly above the output-growth line."""
)

targets["CH2-S04.02.02-P001"] = (
"""This section documents the stylized facts of the Chilean economy over the 1940--2010 sample. Table~\\ref{tab:cl_stylized_facts_summary} presents summary statistics for the core macroeconomic, distributive, and external variables, capturing the long-run means and volatilities of real output, capital accumulation, income distribution, and the balance of payments. Because these aggregate moments obscure the pronounced historical regime shifts characteristic of the periphery, the following figures trace the temporal evolution of these series to highlight the structural breaks, distributive fractures, and variables related to the external constraints of peripheral capitalism that motivate the heterogeneous-capital analyitical framework previously presented in Section~3.3 and the threshold emirical strategy developed below.""",
"""Table~\\ref{tab:cl_stylized_facts_summary} presents summary statistics for the core macroeconomic, distributive, and external variables of the Chilean economy over the 1940--2010 sample, capturing the long-run means and volatilities of real output, capital accumulation, income distribution, and the balance of payments. Because these aggregate moments obscure the pronounced historical regime shifts characteristic of the periphery, the series that follow trace the structural breaks, distributive fractures, and external constraint variables that motivate the heterogeneous-capital analytical framework presented in Section~3.3 and the threshold empirical strategy developed below."""
)

targets["CH2-S04.02.02-P002"] = (
"""Figure~\\ref{fig:cl_stylized_1a_y_kcap} plots log real GDP ($y_t$) and the aggregate gross core capital stock ($k_t^{cap} = \\ln[K_t^{\\text{ME}} + K_t^{\\text{NRC}}]$) on the same 2003 CLP price basis for Chile (1940--2010). Over seven decades, output and capital drift together along a shared upward trajectory, motivating the cointegrating specification. Dotted vertical lines mark the 1973 military coup and 1990 the post-dictatorship period.""",
"""Log real GDP ($y_t$) and aggregate gross core capital stock ($k_t^{cap} = \\ln[K_t^{\\text{ME}} + K_t^{\\text{NRC}}]$) for Chile (1940--2010) are plotted on the same 2003 CLP price basis in Figure~\\ref{fig:cl_stylized_1a_y_kcap}. Over seven decades, output and capital drift together along a shared upward trajectory, motivating the cointegrating specification. Dotted vertical lines mark the 1973 military coup and the 1990 post-dictatorship period."""
)

targets["CH2-S04.02.02-P003"] = (
"""Figure~\\ref{fig:cl_stylized_1b_yk_ratio} plots the corresponding log output--capital ratio ($y_t - k_t^{cap}$) for Chile, providing the symmetric parallel to the U.S. series. Unlike the continuous secular decline in the center, the peripheral output--capital ratio exhibits pronounced regime shifts: rising during the initial state-led ISI phase (1940--1955), collapsing during the 1972--1975 breakdown and the 1982 debt crisis, and settling into an unconstrained expansion during the 1990s commodity boom.""",
"""The corresponding log output--capital ratio ($y_t - k_t^{cap}$) for Chile is plotted in Figure~\\ref{fig:cl_stylized_1b_yk_ratio}. Unlike the continuous secular decline in the center, the peripheral output--capital ratio exhibits pronounced regime shifts: rising during the initial state-led ISI phase (1940--1955), collapsing during the 1972--1975 breakdown and the 1982 debt crisis, and settling into an unconstrained expansion during the 1990s commodity boom."""
)

targets["CH2-S04.02.02-P004"] = (
"""Figure~\\ref{fig:cl_stylized_2_kappa_mechanization} plots the mechanization
gap $\\kappa_t = k_t^{\\text{ME}} - k_t^{\\text{NRC}}$ (mean $-1.106$, SD
$0.211$, Table~\\ref{tab:cl_stylized_facts_summary}). The gap widens from the
late 1940s through state-led ISI to 1972, stagnates under the early
neoliberal regime with a debt-boom hump at 1981 and a post-crisis trough in
the late 1980s, and rises sharply after redemocratization, when
export-oriented mining pulled machinery accumulation ahead of structures.
The gap is therefore a regime-shifting series rather than a smooth trend,
which is what motivates the heterogeneous-capital specification in which
$\\theta$ depends on $\\kappa_t$.""",
"""The mechanization gap $\\kappa_t = k_t^{\\text{ME}} - k_t^{\\text{NRC}}$, plotted in Figure~\\ref{fig:cl_stylized_2_kappa_mechanization} (mean $-1.106$, SD $0.211$, Table~\\ref{tab:cl_stylized_facts_summary}), widens from the late 1940s through state-led ISI to 1972, stagnates under the early neoliberal regime with a debt-boom hump at 1981 and a post-crisis trough in the late 1980s, and rises sharply after redemocratization, when export-oriented mining pulled machinery accumulation ahead of structures. The gap is therefore a regime-shifting series rather than a smooth trend, which is what motivates the heterogeneous-capital specification in which $\\theta$ depends on $\\kappa_t$."""
)

targets["CH2-S04.02.02-P006"] = (
"""Figure~\\ref{fig:cl_stylized_4_minipages} disaggregates the external
bottleneck into its components. The solvency ratio (Panel a), central bank
reserves relative to base money, is flat and low until 1975, jumps after the
debt crisis as the Bank accumulated reserves, and declines again after the
mid-2000s. The terms of trade (Panel b) deteriorate through the 1970s and
1980s and recover only with the commodity super-cycle. Real exports
(Panel c) grow smoothly, so the binding episodes are driven by reserve
solvency and import demand rather than by export failure; the import
imbalance series follows the World Historical Balance of Payments database
of \\citet{NievasPiketty2025}. Machinery investment (Panel d) grows in bursts
separated by the crisis dates, consistent with mechanization that is
interrupted rather than smoothly accumulated. Section~4.5 assembles these
components into the composite index through a grid search, and estimates the threshold at which the external constraint becomes binding and counteract the mechanization bias productivity gain.""",
"""Figure~\\ref{fig:cl_stylized_4_minipages} disaggregates the external
bottleneck into its components. The solvency ratio (Panel a), central bank
reserves relative to base money, is flat and low until 1975, jumps after the
debt crisis as the Bank accumulated reserves, and declines again after the
mid-2000s. The terms of trade (Panel b) deteriorate through the 1970s and
1980s and recover only with the commodity super-cycle. Real exports
(Panel c) grow smoothly, so the binding episodes are driven by reserve
solvency and import demand rather than by export failure; the import
imbalance series follows the World Historical Balance of Payments database
of \\citet{NievasPiketty2025}. Machinery investment (Panel d) grows in bursts
separated by the crisis dates, consistent with mechanization that is
interrupted rather than smoothly accumulated. Section~4.5 assembles these
components into the composite index through a grid search, and estimates the threshold at which the external constraint becomes binding and counteracts the mechanization bias productivity gain."""
)

candidate_text = text
for pid, (orig, cand) in targets.items():
    if orig not in candidate_text:
        print(f"ERROR: Target {pid} not found in text!")
    count = candidate_text.count(orig)
    if count != 1:
        print(f"ERROR: Target {pid} found {count} times!")
    candidate_text = candidate_text.replace(orig, cand, 1)

with open(candidate_path, "w", encoding="utf-8") as f:
    f.write(candidate_text)

print("Candidate generated successfully:", candidate_path)
