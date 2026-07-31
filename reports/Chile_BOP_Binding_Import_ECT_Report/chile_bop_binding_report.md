# When Does Chile's Balance-of-Payments Constraint Bind?

## A reproducible RER-controlled import-system audit, 1920–2024

### Abstract

This report rebuilds the Chilean import-system analysis from source snapshots through a frozen release, exact split samples, formal integration-order gates, RER-controlled VECMs, observed-threshold conditional VECMs, and a triangulated balance-of-payments screening index. The legacy four-variable long-run coefficients reproduce to a maximum absolute difference of 1.03e-10.

The reproduction succeeds, but the promoted machinery model does not: log gross machinery capital remains unresolved or at risk of I(2) in both 1920–1973 and 1974–2024. The machinery VECM and machinery-defined threshold VECM are therefore blocked. Reduced admissible systems find no RER-threshold effect (bootstrap p = 0.330 before 1974 and 0.573 after 1973). The resulting episode chronology is a screening device, not a validated latent-state estimator.

**Keywords:** Chile; balance of payments; imports; machinery; real exchange rate; VECM; threshold VECM; Kaldor; Thirlwall

### Resumen

Este informe reconstruye el análisis chileno de importaciones desde las fuentes hasta una versión de datos congelada. La reproducción de los coeficientes heredados es exacta, pero el capital bruto de maquinaria no supera la compuerta de orden de integración en ninguna submuestra. Por tanto, el VECM de maquinaria y su versión umbral no se promueven. Los sistemas reducidos tampoco rechazan linealidad (p = 0.330 y p = 0.573). La cronología final triangula presión del ECT e indicadores observados y debe leerse como diagnóstico de episodios, no como fechamiento definitivo.

## 1. Introduction and verdict

Chile's industrialization made foreign exchange a condition of productive transformation: machinery and intermediate imports expanded the productive apparatus, while weak export performance periodically restricted the capacity to finance those imports. That historical mechanism makes an import disequilibrium measure worth testing, but it does not authorize classifying crises from a residual alone.

This paper examines whether the import requirement associated with non-reinvested surplus, gross machinery accumulation, distribution, and the real exchange rate yields an admissible long-run system and whether its adjustment identifies periods in which Chile's balance-of-payments constraint became binding. The answer is disciplined by the gate: the legacy relation is computationally reproducible, but gross machinery capital fails the required I(1) classification in both political-economic samples, so the central machinery VECM cannot carry the proposed inference.

## 2. Mechanism and identification

Kaldor's mechanism runs from manufacturing expansion to increasing returns and productivity growth; Thirlwall's closure makes sustained growth conditional on export earnings, import intensity, and financing. For Chile, official and structural evidence connects these mechanisms through the imported capital and intermediate goods required by industrialization. The report therefore treats machinery imports as a structural hypothesis and the external constraint as an empirical state, not as identities imposed on the data.

## 3. Data architecture and RER splice

All estimators consume the frozen 1920–2024 release. GDP, imports, investment, non-reinvested surplus, and gross machinery capital are documented in 2003 CLP; the BCCh monthly RER is annualized by arithmetic mean and rebased to the ClioLab 2003 scale. The overlap produces level and growth correlations of 0.825 and 0.750, a median level gap of 9.34%, and a 2011 boundary change of 0.133 log points. The splice passes the declared audit, but the measured source difference requires sensitivity checks and rules out describing the series as definitionally seamless.

![ClioLab and BCCh RER overlap](figures/rer_overlap.pdf)

## 4. Split-sample VECM audit

The exact samples are 1920–1973 and 1974–2024. ADF and KPSS tests are applied in levels and first differences before rank selection. Gross machinery capital remains unresolved or at risk of I(2) in both samples; the pre-1974 wage share is stationary and enters as a control, while the post-1974 RER has mixed level evidence and is held out of the promoted long-run state. These results block the requested machinery system before its rank, coefficients, or ECT can become report-facing evidence.

The archived coefficients nonetheless reproduce exactly, with a maximum absolute difference of 1.03e-10. This reconciliation proves that the rebuild preserves the historical calculation; it does not validate the stochastic assumptions underneath it.

![Raw split-sample system](figures/raw_system.pdf)

## 5. Threshold test

The formal threshold stage uses a reduced, gate-admissible system and observed annual RER change as the threshold variable. The 15% trimmed search uses 160 candidates, regime-size checks, and 999 conditional residual bootstrap replications in each sample. The pre-1974 LR statistic is 3.270 (p = 0.330), and the post-1973 statistic is 2.246 (p = 0.573). Neither sample rejects linear adjustment, so the estimated thresholds are descriptive profile minima rather than evidence of distinct regimes.

![Threshold objective profiles](figures/threshold_profile.pdf)

## 6. Balance-of-payments screening state

The normalized reduced-system import ECT is signed so that negative ECT means imports below their estimated long-run requirement and import-shortfall pressure equals minus the ECT. Confirmed binding requires that pressure plus at least one observed external signal; ECT-only and observed-only years remain separate. The screen identifies 1953–1955, 1958, 1973, 1975–1976, and 1978–1979 as confirmed runs.

The chronology does not confirm the officially documented 1961 crisis. That false-negative benchmark is decisive: the index is useful for organizing evidence, but it is not a definitive latent-variable estimator and should not be used to declare that all other years were unconstrained.

![Triangulated BOP-binding index](figures/binding_index.pdf)

## 7. Robustness

The robustness stage covers alternative splice dates, ClioLab-only and spliced RER inputs, deterministic terms, lag orders, adjacent sample boundaries, threshold bootstraps, leave-one-episode-out checks, condition numbers, and confidence-band overlap. The machinery system remains blocked throughout; robustness maps the instability of a held specification but cannot convert it into an admissible estimator.

Alternative observed threshold variables reveal reduced-system nonlinearity that the RER-change threshold does not. Current-account pressure rejects linearity before and after 1974 (p = 0.035 and 0.039), while the annual change in financing pressure rejects only before 1974 (p = 0.048; post-1973 p = 0.519). Because current-account pressure is an observed BOP outcome, these results condition adjustment but do not independently validate the screening chronology. The binary financing-compression indicator is held because its episode regime contains only one and three observations.

![Boundary sensitivity of the held machinery relation](figures/boundary_sensitivity.pdf)

## 8. Conclusion

The rebuild succeeds as an audit and rejects the central econometric shortcut. Chile's imported-machinery and foreign-exchange mechanism is historically coherent, but the current gross machinery series does not support the proposed split-sample machinery VECM. The reduced systems provide no formal evidence of RER-defined threshold adjustment, while external-account pressure conditions adjustment nonlinearly. Those thresholds are mechanism evidence, not independent date validation. The report therefore retains the BOP index as a transparent screening panel and directs the next research step toward resolving the machinery stock's stochastic properties and validating crisis dates against independent historical records.

## Data availability and reproducibility

The frozen release is `data/releases/chile_bop_binding_v1/`. Every report table and figure is copied from completed stage ledgers. The report builder performs no estimation and records input hashes.

## Limitations

The annual sample is small, the RER splice joins related but non-identical source definitions, the gross machinery series fails the I(1) gate, the reduced Johansen ranks are descriptive rather than bootstrapped rank claims, and the BOP indicators are incomplete proxies for reserves, rationing, and financing access. These limits bind the interpretation.

## Declarations

**Ethics:** The study uses historical aggregate data and involves no human subjects.

**Author contributions (CRediT):** Conceptualization, methodology, software, validation, formal analysis, data curation, visualization, and writing are documented in the repository workflow; final scholarly responsibility remains with the dissertation author.

**Funding:** No project-specific funding information was supplied.

**Conflicts of interest:** None declared.

**AI-use disclosure:** Codex assisted with reproducible code, evidence organization, diagnostics, and report assembly under human direction. All claims remain auditable against the frozen release, stage ledgers, and verified sources.

## References


Albala-Bertrand, J. M. (2006). Changes in Chile's production structure, 1986–1996: Output and industrial interdependence. *CEPAL Review, 88*, 159–172. https://repositorio.cepal.org/server/api/core/bitstreams/8b0c80bc-2006-4abb-b9ac-cc45e7fb6ba0/content

Álvarez, R., & Fuentes, J. R. (2003). *Trade reforms and manufacturing industry in Chile* (Working Paper No. 210). Banco Central de Chile. https://www.bcentral.cl/contenido/-/details/documento-de-trabajo-n-210

Banco Central de Chile. (2025). *100 años de política económica y comercio exterior de Chile*. https://www.bcentral.cl/en/w/blog/100-anios-de-politica-economica-y-comercio-exterior-de-chile

Ffrench-Davis, R. (1983a). El experimento monetarista en Chile: Una síntesis crítica. *Desarrollo Económico, 23*(90), 163–196. https://doi.org/10.2307/3466468

Ffrench-Davis, R. (1983b). Deuda externa y balanza de pagos de América Latina: Tendencias recientes y perspectivas. *Estudios Internacionales, 16*(62), 281–304. https://doi.org/10.5354/0719-3769.1983.16673

Ffrench-Davis, R. (2002). *Economic reforms in Chile: From dictatorship to democracy*. University of Michigan Press. https://doi.org/10.3998/mpub.17208

Kaldor, N. (1967). *Strategic factors in economic development*. New York State School of Industrial and Labor Relations, Cornell University. https://books.google.com/books?id=_IgeAAAAMAAJ

Kaldor, N. (1970). The case for regional policies. *Scottish Journal of Political Economy, 17*(3), 337–348. https://doi.org/10.1111/j.1467-9485.1970.tb00712.x

Marconi, N., Reis, C. F. de B., & Araújo, E. C. de. (2016). Manufacturing and economic development: The actuality of Kaldor's first and second laws. *Structural Change and Economic Dynamics, 37*, 75–89. https://doi.org/10.1016/j.strueco.2015.12.002

Moreno-Brid, J. C. (2003). Capital flows, interest payments and the balance-of-payments constrained growth model: A theoretical and empirical analysis. *Metroeconomica, 54*(2–3), 346–365. https://doi.org/10.1111/1467-999X.00170

Palma, J. G. (2019). Desindustrialización, desindustrialización “prematura” y “síndrome holandés”. *El Trimestre Económico, 86*(344), 901–966. https://doi.org/10.20430/ete.v86i344.970

Solimano, A., & Zapata-Román, G. (2024). *Chilean economic development under neoliberalism: Structural transformation, high inequality and environmental fragility*. Cambridge University Press. https://doi.org/10.1017/9781009477352

Thirlwall, A. P. (1979). The balance of payments constraint as an explanation of international growth rate differences. *PSL Quarterly Review, 32*(128), 45–53. https://doi.org/10.13133/2037-3643/12804

Thirlwall, A. P., & Hussain, M. N. (1982). The balance of payments constraint, capital flows and growth rate differences between developing countries. *Oxford Economic Papers, 34*(3), 498–510. https://doi.org/10.1093/oxfordjournals.oep.a041565

Yunga Medina, F., Tapia Morquecho, C., Camacho Manzanillas, S., & Cueva Jiménez, A. (2022). Does the balance of payments constrain economic growth? New evidence for Chile 1980–2019: The role of capital flows. *Boletín de Coyuntura, 35*, 25–35. https://doi.org/10.31243/bcoyu.35.2022.1851

