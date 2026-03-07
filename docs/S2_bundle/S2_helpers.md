# S2 Helper Functions (tsDyn)

Example helper functions used in the S2 pipeline.

``` r
fit_vecm_model <- function(data, p, r, det_type){
  tsDyn::VECM(
    data,
    lag = p,
    r = r,
    include = det_type,
    estim = "ML"
  )
}
```

``` r
extract_loglik <- function(model){
  as.numeric(logLik(model))
}
```

``` r
compute_k_total <- function(model){
  length(coef(model))
}
```

``` r
check_stability <- function(model){
  roots <- roots(model)
  all(Mod(roots) < 1 + 1e-6)
}
```
