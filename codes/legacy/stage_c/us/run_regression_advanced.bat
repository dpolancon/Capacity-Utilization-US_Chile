@echo off
echo ============================================================
echo  Advanced Regression Analysis — Master Runner
echo  Stage 1: Data preparation
echo  Stage 2: ARDL (AIC/BIC) + Bounds Test
echo  Stage 3: VECM + DOLS + Markdown assembly
echo ============================================================

cd /d C:\ReposGitHub\Capacity-Utilization-US_Chile

echo.
echo [1/3] Building analysis dataset...
Rscript codes/stage_c/us/regression_advanced_1_data.R
if %errorlevel% neq 0 (echo ERROR in Stage 1 & pause & exit /b 1)

echo.
echo [2/3] ARDL estimation...
Rscript codes/stage_c/us/regression_advanced_2_ardl.R
if %errorlevel% neq 0 (echo ERROR in Stage 2 & pause & exit /b 1)

echo.
echo [3/3] VECM + DOLS + report assembly...
Rscript codes/stage_c/us/regression_advanced_3_vecm_dols.R
if %errorlevel% neq 0 (echo ERROR in Stage 3 & pause & exit /b 1)

echo.
echo ============================================================
echo  ALL STAGES COMPLETE
echo  Report: output\results_package_us\tables\regression_advanced.md
echo ============================================================
pause
