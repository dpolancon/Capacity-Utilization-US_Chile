library(urca)
cl_df <- read.csv('data/processed/cl_s20/chile_orthogonalized_panel.csv')
us_df <- read.csv('data/processed/us_s31j/us_staged_pending_conditioners.csv')

run_one <- function(df, s, e, country, label, ec, nr_col='k_NR', dum=NULL) {
  if (!(nr_col %in% colnames(df))) nr_col <- 'k_NRC'
  sub <- df[df$year >= s & df$year <= e, ]
  sub <- sub[!is.na(sub$k_ME) & !is.na(sub[[nr_col]]), ]
  mat <- cbind(k_NR = sub[[nr_col]], k_ME = sub$k_ME)
  dum_mat <- NULL
  if (!is.null(dum)) {
    d_list <- list()
    for (d_yr in dum) d_list[[paste0('D_', d_yr)]] <- ifelse(sub$year >= d_yr, 1, 0)
    dum_mat <- as.matrix(as.data.frame(d_list))
  }
  jo <- urca::ca.jo(mat, type = 'trace', ecdet = ec, K = 2, dumvar = dum_mat)
  caj <- urca::cajorls(jo, r = 1)
  s_caj <- summary(caj$rlm)
  
  beta_knr <- jo@V[1, 1]
  beta_kme <- jo@V[2, 1]
  gamma_hat <- - beta_kme / beta_knr
  
  a_knr <- s_caj[[1]]$coefficients['ect1', 'Estimate'] * beta_knr
  t_knr <- s_caj[[1]]$coefficients['ect1', 't value']
  a_kme <- s_caj[[2]]$coefficients['ect1', 'Estimate'] * beta_knr
  t_kme <- s_caj[[2]]$coefficients['ect1', 't value']
  
  cat(sprintf('%s | %s (%s) | gamma: %.4f | a_NR: %.4f (t=%.2f) | a_ME: %.4f (t=%.2f)\n',
              country, label, ec, gamma_hat, a_knr, t_knr, a_kme, t_kme))
  
  d1_nr_nr <- s_caj[[1]]$coefficients['k_NR.dl1','Estimate']
  d1_nr_me <- s_caj[[1]]$coefficients['k_ME.dl1','Estimate']
  d1_me_nr <- s_caj[[2]]$coefficients['k_NR.dl1','Estimate']
  d1_me_me <- s_caj[[2]]$coefficients['k_ME.dl1','Estimate']
  
  cat(sprintf('   Short run (dk_NR): dNR(-1)=%.3f, dME(-1)=%.3f\n', d1_nr_nr, d1_nr_me))
  cat(sprintf('   Short run (dk_ME): dNR(-1)=%.3f, dME(-1)=%.3f\n\n', d1_me_nr, d1_me_me))
}

cat('=== CHILE COINTEGRATED MODELS ===\n')
run_one(cl_df, 1974, 1989, 'Chile', 'Dictatorship Shock', 'const')
run_one(cl_df, 1990, 2024, 'Chile', 'Democratic Neoliberal', 'const')
run_one(cl_df, 1920, 2024, 'Chile', 'Full Century Un-augmented', 'const')
run_one(cl_df, 1920, 2024, 'Chile', 'Full Century Inst-Break', 'const', dum=c(1973, 1982))
run_one(cl_df, 1920, 1938, 'Chile', 'Nitrate Crisis', 'trend')
run_one(cl_df, 1974, 1989, 'Chile', 'Dictatorship Shock', 'trend')

cat('=== US COINTEGRATED MODELS ===\n')
run_one(us_df, 1947, 1973, 'US', 'Fordist Expansion', 'const', nr_col='k_NRC')
run_one(us_df, 1925, 2021, 'US', 'Full Century Un-augmented', 'const', nr_col='k_NRC')
run_one(us_df, 1925, 2021, 'US', 'Full Century Un-augmented', 'trend', nr_col='k_NRC')
run_one(us_df, 1925, 2021, 'US', 'Full Century Inst-Break', 'trend', nr_col='k_NRC', dum=c(1973, 2008))
