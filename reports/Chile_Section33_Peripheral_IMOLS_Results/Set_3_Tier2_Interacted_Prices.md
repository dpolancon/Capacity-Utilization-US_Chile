# Set 3: Tier 2 — Interacted Price Specifications

This set evaluates models with relative price interactions (p_kappa * kappa_t). Note the VIF diagnostic alert: Tier 2 exhibits VIF > 88 due to collinearity among interaction terms.

### Sample Window: 1940_2024



|Tier   |Model_ID                                    |Spec_Name               |Price_Proxy    |Thresh_Var      | Gamma_Val|V1             |V2            |V3           |V4             |V5             |V6             |V7             |V8             |
|:------|:-------------------------------------------|:-----------------------|:--------------|:---------------|---------:|:--------------|:-------------|:------------|:--------------|:--------------|:--------------|:--------------|:--------------|
|Tier 2 |T2_1940_2024_p_kappa_rer_thresh_solvr_m0    |Interact p_kappa_rer    |p_kappa_rer    |thresh_solvr_m0 | 4.2544522|3.303 (1.61)   |0.762 (8.31)  |0.468 (0.97) |-0.190 (-0.77) |0.169 (0.57)   |0.288 (1.38)   |-0.060 (-0.23) |0.007 (0.02)   |
|Tier 2 |T2_1940_2024_p_kappa_rer_thresh_solvr_m1    |Interact p_kappa_rer    |p_kappa_rer    |thresh_solvr_m1 | 2.3307395|2.148 (1.40)   |0.824 (11.85) |0.692 (1.52) |-0.451 (-1.50) |0.306 (0.69)   |-0.167 (-0.51) |0.351 (1.08)   |-0.245 (-0.54) |
|Tier 2 |T2_1940_2024_p_kappa_ipmusa_thresh_solvr_m0 |Interact p_kappa_ipmusa |p_kappa_ipmusa |thresh_solvr_m0 | 4.2544522|4.991 (2.01)   |0.676 (5.87)  |0.550 (1.19) |-0.611 (-1.84) |-1.780 (-2.71) |0.174 (1.05)   |0.315 (0.98)   |1.696 (2.67)   |
|Tier 2 |T2_1940_2024_p_kappa_ipmusa_thresh_solvr_m1 |Interact p_kappa_ipmusa |p_kappa_ipmusa |thresh_solvr_m1 | 0.2176285|-3.863 (-2.29) |1.130 (13.72) |0.368 (1.05) |-0.356 (-1.91) |0.126 (2.70)   |-0.319 (-1.30) |0.614 (1.91)   |0.128 (1.56)   |


### Sample Window: 1932_2024



|Tier   |Model_ID                                    |Spec_Name               |Price_Proxy    |Thresh_Var      | Gamma_Val|V1             |V2            |V3           |V4             |V5             |V6             |V7             |V8             |
|:------|:-------------------------------------------|:-----------------------|:--------------|:---------------|---------:|:--------------|:-------------|:------------|:--------------|:--------------|:--------------|:--------------|:--------------|
|Tier 2 |T2_1932_2024_p_kappa_rer_thresh_solvr_m0    |Interact p_kappa_rer    |p_kappa_rer    |thresh_solvr_m0 | 4.2544522|3.303 (1.61)   |0.762 (8.31)  |0.468 (0.97) |-0.190 (-0.77) |0.169 (0.57)   |0.288 (1.38)   |-0.060 (-0.23) |0.007 (0.02)   |
|Tier 2 |T2_1932_2024_p_kappa_rer_thresh_solvr_m1    |Interact p_kappa_rer    |p_kappa_rer    |thresh_solvr_m1 | 2.3307395|2.148 (1.40)   |0.824 (11.85) |0.692 (1.52) |-0.451 (-1.50) |0.306 (0.69)   |-0.167 (-0.51) |0.351 (1.08)   |-0.245 (-0.54) |
|Tier 2 |T2_1932_2024_p_kappa_ipmusa_thresh_solvr_m0 |Interact p_kappa_ipmusa |p_kappa_ipmusa |thresh_solvr_m0 | 4.2544522|4.991 (2.01)   |0.676 (5.87)  |0.550 (1.19) |-0.611 (-1.84) |-1.780 (-2.71) |0.174 (1.05)   |0.315 (0.98)   |1.696 (2.67)   |
|Tier 2 |T2_1932_2024_p_kappa_ipmusa_thresh_solvr_m1 |Interact p_kappa_ipmusa |p_kappa_ipmusa |thresh_solvr_m1 | 0.2176285|-3.863 (-2.29) |1.130 (13.72) |0.368 (1.05) |-0.356 (-1.91) |0.126 (2.70)   |-0.319 (-1.30) |0.614 (1.91)   |0.128 (1.56)   |


### Sample Window: 1932_1973



|Tier   |Model_ID                                    |Spec_Name               |Price_Proxy    |Thresh_Var      | Gamma_Val|V1             |V2            |V3             |V4             |V5             |V6             |V7           |V8             |
|:------|:-------------------------------------------|:-----------------------|:--------------|:---------------|---------:|:--------------|:-------------|:--------------|:--------------|:--------------|:--------------|:------------|:--------------|
|Tier 2 |T2_1932_1973_p_kappa_rer_thresh_solvr_m0    |Interact p_kappa_rer    |p_kappa_rer    |thresh_solvr_m0 | 0.6052423|-2.416 (-2.35) |1.046 (20.99) |0.122 (0.66)   |-0.179 (-1.25) |0.344 (2.30)   |-0.323 (-3.17) |0.253 (1.74) |-0.351 (-2.35) |
|Tier 2 |T2_1932_1973_p_kappa_rer_thresh_solvr_m1    |Interact p_kappa_rer    |p_kappa_rer    |thresh_solvr_m1 | 0.2199293|-2.402 (-2.01) |1.045 (18.44) |0.067 (0.28)   |-0.166 (-1.52) |0.203 (2.46)   |-0.358 (-3.50) |0.332 (2.82) |-0.223 (-2.65) |
|Tier 2 |T2_1932_1973_p_kappa_ipmusa_thresh_solvr_m0 |Interact p_kappa_ipmusa |p_kappa_ipmusa |thresh_solvr_m0 | 0.6670614|-2.759 (-1.97) |1.061 (14.62) |-2.086 (-2.63) |-0.325 (-1.48) |-1.056 (-2.55) |1.841 (2.25)   |0.393 (1.77) |1.065 (2.60)   |
|Tier 2 |T2_1932_1973_p_kappa_ipmusa_thresh_solvr_m1 |Interact p_kappa_ipmusa |p_kappa_ipmusa |thresh_solvr_m1 | 0.0781288|-2.389 (-1.33) |1.036 (11.14) |-0.455 (-2.10) |0.053 (0.91)   |-0.091 (-0.91) |0.146 (0.55)   |0.117 (0.67) |0.168 (1.48)   |


### Sample Window: 1974_2024



|Tier   |Model_ID                                    |Spec_Name               |Price_Proxy    |Thresh_Var      | Gamma_Val|V1             |V2            |V3             |V4           |V5             |V6             |V7             |V8             |
|:------|:-------------------------------------------|:-----------------------|:--------------|:---------------|---------:|:--------------|:-------------|:--------------|:------------|:--------------|:--------------|:--------------|:--------------|
|Tier 2 |T2_1974_2024_p_kappa_rer_thresh_solvr_m0    |Interact p_kappa_rer    |p_kappa_rer    |thresh_solvr_m0 |  1.483366|-8.712 (-3.46) |1.272 (10.85) |-2.780 (-6.97) |1.046 (6.72) |0.313 (2.86)   |0.821 (2.62)   |-1.627 (-4.63) |-1.239 (-2.05) |
|Tier 2 |T2_1974_2024_p_kappa_rer_thresh_solvr_m1    |Interact p_kappa_rer    |p_kappa_rer    |thresh_solvr_m1 |  1.017664|-8.257 (-9.02) |1.295 (30.37) |-1.349 (-8.32) |0.254 (4.09) |0.228 (5.83)   |0.488 (4.17)   |-0.156 (-1.20) |0.396 (1.50)   |
|Tier 2 |T2_1974_2024_p_kappa_ipmusa_thresh_solvr_m0 |Interact p_kappa_ipmusa |p_kappa_ipmusa |thresh_solvr_m0 |  5.335247|4.425 (2.39)   |0.649 (7.38)  |-1.348 (-4.80) |0.356 (1.64) |-2.717 (-2.43) |-0.126 (-1.20) |0.723 (2.87)   |2.235 (2.02)   |
|Tier 2 |T2_1974_2024_p_kappa_ipmusa_thresh_solvr_m1 |Interact p_kappa_ipmusa |p_kappa_ipmusa |thresh_solvr_m1 |  2.544185|0.635 (0.33)   |0.863 (9.09)  |-0.513 (-1.87) |0.010 (0.07) |-0.664 (-1.22) |-0.295 (-2.88) |0.461 (2.75)   |0.378 (0.74)   |


