# S30A Real Output Family Closure Decision

Decision: AUTHORIZE_OUTPUT_FAMILY_CONSUMPTION

Family status: OUTPUT_FAMILY_CLOSED_CONSUMABLE

S30A closes the output family on the NFC real-GVA boundary. The authoritative level is `Y_REAL_NFC_GVA_BASELINE`; the authoritative log-level representation is `y_real_nfc_gva_baseline`. The concept is effective-demand-realized output, not productive capacity. Productive capacity and capacity utilization are not constructed here.

The deflator rule is locked to the same-boundary NFC implicit GVA deflator reconstructed in S12B from NIPA T11400 line 17 current-dollar NFC GVA and line 41 chained-dollar NFC GVA, with T115 line 1 retained as validation-only. CORP and FC real-output or price residuals remain blocked, and proxy deflators remain robustness-only under their own names.

S30A authorizes output-family consumption by later cross-family closure auditing only. It does not authorize a cross-family join, canonical dataset construction, complete-case sample, estimation sample, q, theta, productive capacity, capacity utilization, modeling, or econometrics.
