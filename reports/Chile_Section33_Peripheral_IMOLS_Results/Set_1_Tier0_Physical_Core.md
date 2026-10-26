# Set 1: Tier 0 — Physical Core Baseline Models

This set evaluates the baseline physical transformation relation without price controls across 4 distributive conflict proxies (omega_gross, omega_net, e_gross, e_net), 2 solvency thresholds (SolvR_M0, SolvR_M1), and multiple sample windows.

### Sample Window: 1940_2024



|Tier   |Model_ID                                     |Spec_Name                |Price_Proxy |Thresh_Var      | Gamma_Val|V1             |V2            |V3             |V4             |V5             |V6             |
|:------|:--------------------------------------------|:------------------------|:-----------|:---------------|---------:|:--------------|:-------------|:--------------|:--------------|:--------------|:--------------|
|Tier 0 |T0_1940_2024_omega_gross_lag_thresh_solvr_m0 |Baseline omega_gross_lag |None        |thresh_solvr_m0 | 0.6803588|2.366 (0.87)   |0.789 (6.15)  |-1.326 (-3.76) |2.689 (2.87)   |1.460 (2.81)   |-2.824 (-2.92) |
|Tier 0 |T0_1940_2024_omega_gross_lag_thresh_solvr_m1 |Baseline omega_gross_lag |None        |thresh_solvr_m1 | 0.3790122|1.310 (0.80)   |0.858 (11.07) |-0.313 (-1.46) |1.032 (1.91)   |0.746 (2.41)   |-1.406 (-2.47) |
|Tier 0 |T0_1940_2024_omega_net_lag_thresh_solvr_m0   |Baseline omega_net_lag   |None        |thresh_solvr_m0 | 5.0901306|2.423 (1.22)   |0.805 (9.22)  |0.113 (0.22)   |0.019 (0.06)   |0.412 (1.72)   |-0.239 (-0.75) |
|Tier 0 |T0_1940_2024_omega_net_lag_thresh_solvr_m1   |Baseline omega_net_lag   |None        |thresh_solvr_m1 | 0.2176285|-0.826 (-0.51) |0.961 (13.39) |0.054 (0.12)   |-0.093 (-0.39) |0.202 (0.62)   |-0.280 (-0.66) |
|Tier 0 |T0_1940_2024_e_gross_lag_thresh_solvr_m0     |Baseline e_gross_lag     |None        |thresh_solvr_m0 | 0.6803588|1.679 (0.61)   |0.820 (6.29)  |0.604 (1.12)   |-0.669 (-2.68) |-0.679 (-2.80) |0.676 (2.61)   |
|Tier 0 |T0_1940_2024_e_gross_lag_thresh_solvr_m1     |Baseline e_gross_lag     |None        |thresh_solvr_m1 | 0.3790122|1.216 (0.77)   |0.863 (11.45) |0.474 (1.48)   |-0.264 (-1.91) |-0.337 (-2.51) |0.357 (2.44)   |
|Tier 0 |T0_1940_2024_e_net_lag_thresh_solvr_m0       |Baseline e_net_lag       |None        |thresh_solvr_m0 | 5.0901306|2.357 (1.20)   |0.809 (9.43)  |0.168 (0.54)   |-0.011 (-0.08) |0.156 (1.53)   |0.154 (1.16)   |
|Tier 0 |T0_1940_2024_e_net_lag_thresh_solvr_m1       |Baseline e_net_lag       |None        |thresh_solvr_m1 | 2.5643455|1.777 (1.26)   |0.844 (13.44) |0.255 (1.14)   |0.073 (0.53)   |0.131 (1.71)   |-0.026 (-0.16) |


### Sample Window: 1932_2024



|Tier   |Model_ID                                     |Spec_Name                |Price_Proxy |Thresh_Var      | Gamma_Val|V1             |V2            |V3             |V4             |V5             |V6             |
|:------|:--------------------------------------------|:------------------------|:-----------|:---------------|---------:|:--------------|:-------------|:--------------|:--------------|:--------------|:--------------|
|Tier 0 |T0_1932_2024_omega_gross_lag_thresh_solvr_m0 |Baseline omega_gross_lag |None        |thresh_solvr_m0 | 0.3603074|-3.670 (-3.19) |1.071 (19.92) |-1.051 (-3.03) |0.581 (1.31)   |0.922 (1.99)   |-1.794 (-2.14) |
|Tier 0 |T0_1932_2024_omega_gross_lag_thresh_solvr_m1 |Baseline omega_gross_lag |None        |thresh_solvr_m1 | 0.9937790|-3.530 (-2.67) |1.092 (16.75) |-0.059 (-0.15) |-0.466 (-0.79) |-0.070 (-0.21) |0.030 (0.05)   |
|Tier 0 |T0_1932_2024_omega_net_lag_thresh_solvr_m0   |Baseline omega_net_lag   |None        |thresh_solvr_m0 | 5.0901306|2.423 (1.22)   |0.805 (9.22)  |0.113 (0.22)   |0.019 (0.06)   |0.412 (1.72)   |-0.239 (-0.75) |
|Tier 0 |T0_1932_2024_omega_net_lag_thresh_solvr_m1   |Baseline omega_net_lag   |None        |thresh_solvr_m1 | 0.2176285|-0.826 (-0.51) |0.961 (13.39) |0.054 (0.12)   |-0.093 (-0.39) |0.202 (0.62)   |-0.280 (-0.66) |
|Tier 0 |T0_1932_2024_e_gross_lag_thresh_solvr_m0     |Baseline e_gross_lag     |None        |thresh_solvr_m0 | 0.3603074|-3.805 (-3.31) |1.077 (20.05) |-0.611 (-3.09) |-0.160 (-1.30) |-0.490 (-2.37) |0.489 (2.12)   |
|Tier 0 |T0_1932_2024_e_gross_lag_thresh_solvr_m1     |Baseline e_gross_lag     |None        |thresh_solvr_m1 | 0.9937790|-3.540 (-2.69) |1.092 (16.84) |-0.415 (-1.85) |0.118 (0.86)   |-0.061 (-0.38) |0.007 (0.05)   |
|Tier 0 |T0_1932_2024_e_net_lag_thresh_solvr_m0       |Baseline e_net_lag       |None        |thresh_solvr_m0 | 5.0901306|2.357 (1.20)   |0.809 (9.43)  |0.168 (0.54)   |-0.011 (-0.08) |0.156 (1.53)   |0.154 (1.16)   |
|Tier 0 |T0_1932_2024_e_net_lag_thresh_solvr_m1       |Baseline e_net_lag       |None        |thresh_solvr_m1 | 2.5643455|1.777 (1.26)   |0.844 (13.44) |0.255 (1.14)   |0.073 (0.53)   |0.131 (1.71)   |-0.026 (-0.16) |


### Sample Window: 1932_1973



|Tier   |Model_ID                                     |Spec_Name                |Price_Proxy |Thresh_Var      | Gamma_Val|V1             |V2            |V3             |V4             |V5             |V6             |
|:------|:--------------------------------------------|:------------------------|:-----------|:---------------|---------:|:--------------|:-------------|:--------------|:--------------|:--------------|:--------------|
|Tier 0 |T0_1932_1973_omega_gross_lag_thresh_solvr_m0 |Baseline omega_gross_lag |None        |thresh_solvr_m0 | 0.3810107|-5.110 (-4.40) |1.180 (22.17) |-0.132 (-0.31) |-0.535 (-1.34) |-0.382 (-1.62) |0.722 (1.65)   |
|Tier 0 |T0_1932_1973_omega_gross_lag_thresh_solvr_m1 |Baseline omega_gross_lag |None        |thresh_solvr_m1 | 0.2164781|-5.110 (-4.40) |1.180 (22.17) |-0.132 (-0.31) |-0.535 (-1.34) |-0.382 (-1.62) |0.722 (1.65)   |
|Tier 0 |T0_1932_1973_omega_net_lag_thresh_solvr_m0   |Baseline omega_net_lag   |None        |thresh_solvr_m0 | 0.6670614|-2.626 (-2.43) |1.053 (20.11) |0.193 (0.68)   |-0.465 (-1.69) |-0.457 (-2.10) |0.534 (1.94)   |
|Tier 0 |T0_1932_1973_omega_net_lag_thresh_solvr_m1   |Baseline omega_net_lag   |None        |thresh_solvr_m1 | 0.3463779|-3.230 (-3.38) |1.086 (23.82) |-0.079 (-0.41) |-0.196 (-1.03) |-0.205 (-1.41) |0.254 (1.32)   |
|Tier 0 |T0_1932_1973_e_gross_lag_thresh_solvr_m0     |Baseline e_gross_lag     |None        |thresh_solvr_m0 | 0.3810107|-5.276 (-4.85) |1.187 (23.38) |-0.568 (-3.48) |0.121 (1.29)   |0.164 (1.48)   |-0.176 (-1.49) |
|Tier 0 |T0_1932_1973_e_gross_lag_thresh_solvr_m1     |Baseline e_gross_lag     |None        |thresh_solvr_m1 | 0.2164781|-5.276 (-4.85) |1.187 (23.38) |-0.568 (-3.48) |0.121 (1.29)   |0.164 (1.48)   |-0.176 (-1.49) |
|Tier 0 |T0_1932_1973_e_net_lag_thresh_solvr_m0       |Baseline e_net_lag       |None        |thresh_solvr_m0 | 0.6670614|-2.759 (-2.49) |1.060 (19.78) |-0.273 (-1.72) |0.300 (1.70)   |0.060 (1.04)   |-0.332 (-1.88) |
|Tier 0 |T0_1932_1973_e_net_lag_thresh_solvr_m1       |Baseline e_net_lag       |None        |thresh_solvr_m1 | 0.3463779|-3.231 (-3.30) |1.086 (23.29) |-0.264 (-1.74) |0.100 (0.91)   |0.032 (0.74)   |-0.126 (-1.13) |


### Sample Window: 1974_2024



|Tier   |Model_ID                                     |Spec_Name                |Price_Proxy |Thresh_Var      | Gamma_Val|V1             |V2            |V3             |V4             |V5             |V6             |
|:------|:--------------------------------------------|:------------------------|:-----------|:---------------|---------:|:--------------|:-------------|:--------------|:--------------|:--------------|:--------------|
|Tier 0 |T0_1974_2024_omega_gross_lag_thresh_solvr_m0 |Baseline omega_gross_lag |None        |thresh_solvr_m0 |  3.156754|5.355 (1.99)   |0.650 (5.16)  |-0.314 (-0.91) |1.406 (3.03)   |1.048 (4.28)   |-1.943 (-3.61) |
|Tier 0 |T0_1974_2024_omega_gross_lag_thresh_solvr_m1 |Baseline omega_gross_lag |None        |thresh_solvr_m1 |  1.017664|-1.229 (-1.02) |0.970 (16.65) |-0.504 (-3.65) |0.526 (2.18)   |0.662 (2.50)   |-1.171 (-2.07) |
|Tier 0 |T0_1974_2024_omega_net_lag_thresh_solvr_m0   |Baseline omega_net_lag   |None        |thresh_solvr_m0 |  1.483366|-2.783 (-1.61) |0.991 (12.39) |-2.148 (-6.04) |1.023 (5.78)   |1.141 (4.02)   |-1.259 (-3.47) |
|Tier 0 |T0_1974_2024_omega_net_lag_thresh_solvr_m1   |Baseline omega_net_lag   |None        |thresh_solvr_m1 |  1.017664|-3.391 (-2.45) |1.062 (16.72) |-0.851 (-2.30) |0.227 (1.33)   |0.448 (1.89)   |-0.446 (-1.46) |
|Tier 0 |T0_1974_2024_e_gross_lag_thresh_solvr_m0     |Baseline e_gross_lag     |None        |thresh_solvr_m0 |  3.156754|4.259 (1.58)   |0.702 (5.57)  |0.577 (1.52)   |-0.305 (-2.80) |-0.393 (-2.46) |0.444 (3.70)   |
|Tier 0 |T0_1974_2024_e_gross_lag_thresh_solvr_m1     |Baseline e_gross_lag     |None        |thresh_solvr_m1 |  1.017664|-1.064 (-0.89) |0.961 (16.67) |-0.098 (-0.55) |-0.135 (-2.27) |-0.191 (-1.44) |0.265 (2.34)   |
|Tier 0 |T0_1974_2024_e_net_lag_thresh_solvr_m0       |Baseline e_net_lag       |None        |thresh_solvr_m0 |  4.694041|-1.511 (-0.57) |0.964 (7.89)  |-0.621 (-1.65) |-0.181 (-1.85) |0.055 (0.72)   |0.161 (1.42)   |
|Tier 0 |T0_1974_2024_e_net_lag_thresh_solvr_m1       |Baseline e_net_lag       |None        |thresh_solvr_m1 |  1.017664|-3.049 (-2.09) |1.047 (15.76) |-0.581 (-2.06) |-0.069 (-0.74) |0.028 (0.41)   |0.204 (1.19)   |


