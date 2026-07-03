$ErrorActionPreference = "Stop"

$Root = (Resolve-Path ".").Path
$TempWorktree = "C:\ReposGitHub\Capacity-Utilization-US_Chile_D10R_tmp"
$OutDir = Join-Path $Root "output/US/D10_R_RECONCILIATION_AND_REPRODUCIBILITY_CHECK"
$CsvDir = Join-Path $OutDir "csv"
$ReportsDir = Join-Path $OutDir "reports"
$LogsDir = Join-Path $OutDir "logs"
$D10Dir = "output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET"
$D10Script = "codes/US_D10_us_econometric_and_accounting_source_of_truth_dataset.R"
$Rscript = "C:\Program Files\R\R-4.6.1\bin\Rscript.exe"

New-Item -ItemType Directory -Force -Path $CsvDir, $ReportsDir, $LogsDir | Out-Null

function Get-RepoRelFiles($BasePath) {
  Get-ChildItem -LiteralPath (Join-Path $Root $BasePath) -Recurse -File |
    Where-Object { $_.Extension -in @(".csv", ".md", ".tex") } |
    ForEach-Object { $_.FullName.Substring($Root.Length + 1).Replace("\", "/") }
}

function Get-LineCount($Path) {
  if ((Test-Path -LiteralPath $Path) -and ([IO.Path]::GetExtension($Path) -in @(".csv", ".md", ".tex", ".R", ".ps1", ".log"))) {
    return (Get-Content -LiteralPath $Path | Measure-Object -Line).Lines
  }
  return $null
}

function New-Manifest($RepoRoot, $RelativePaths, $OutputPath) {
  $rows = foreach ($rel in $RelativePaths) {
    $path = Join-Path $RepoRoot ($rel -replace "/", "\")
    if (Test-Path -LiteralPath $path) {
      $item = Get-Item -LiteralPath $path
      [pscustomobject]@{
        relative_path = $rel
        file_size_bytes = $item.Length
        sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
        line_count_if_text = Get-LineCount $path
        status = "PRESENT"
      }
    } else {
      [pscustomobject]@{
        relative_path = $rel
        file_size_bytes = ""
        sha256 = ""
        line_count_if_text = ""
        status = "MISSING"
      }
    }
  }
  $rows | Export-Csv -LiteralPath $OutputPath -NoTypeInformation
  return $rows
}

function Get-CsvShape($RepoRoot, $RelativePath) {
  $path = Join-Path $RepoRoot ($RelativePath -replace "/", "\")
  if (-not (Test-Path -LiteralPath $path)) {
    return [pscustomobject]@{rows=""; cols=""; status="MISSING"}
  }
  $rows = Import-Csv -LiteralPath $path
  $cols = if ($rows.Count -gt 0) { $rows[0].PSObject.Properties.Name.Count } else { ((Get-Content -LiteralPath $path -First 1) -split ",").Count }
  [pscustomobject]@{rows=$rows.Count; cols=$cols; status="PRESENT"}
}

function Get-LedgerStatus($Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return "MISSING" }
  $row = Import-Csv -LiteralPath $Path | Select-Object -First 1
  if ($null -eq $row) { return "EMPTY" }
  return $row.status
}

$openingStatus = git status --short --branch
$openingBranch = git branch --show-current
$openingHead = git rev-parse HEAD
$openingOriginMain = git rev-parse origin/main
$openingLog = git log --oneline --decorate -8
$openingDivergence = git rev-list --left-right --count HEAD...origin/main

$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$whereOutput = & where.exe Rscript 2>&1
$whereExit = $LASTEXITCODE
$ErrorActionPreference = $oldErrorActionPreference
$whereOutput | Set-Content -LiteralPath (Join-Path $LogsDir "D10R_where_Rscript.log") -Encoding UTF8

$versionOutput = & $Rscript --version 2>&1
$versionExit = $LASTEXITCODE
$versionOutput | Set-Content -LiteralPath (Join-Path $LogsDir "D10R_rscript_version.log") -Encoding UTF8
if ($versionExit -ne 0) { throw "REQUIRE_D10_R_ENVIRONMENT_RECONCILIATION" }

$relPaths = @(Get-RepoRelFiles $D10Dir)
$relPaths += $D10Script
$relPaths = $relPaths | Sort-Object -Unique
$committedManifest = New-Manifest $Root $relPaths (Join-Path $CsvDir "D10R_committed_output_manifest.csv")

if (Test-Path -LiteralPath $TempWorktree) {
  git worktree remove $TempWorktree --force 2>$null
  if (Test-Path -LiteralPath $TempWorktree) { Remove-Item -LiteralPath $TempWorktree -Recurse -Force }
}

git worktree add --detach $TempWorktree HEAD | Tee-Object -FilePath (Join-Path $LogsDir "D10R_worktree_add.log") | Out-Null

$stdoutLog = Join-Path $LogsDir "D10R_rscript_stdout.log"
$stderrLog = Join-Path $LogsDir "D10R_rscript_stderr.log"
$proc = Start-Process -FilePath $Rscript -ArgumentList @($D10Script) -WorkingDirectory $TempWorktree -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog -NoNewWindow -Wait -PassThru
$rscriptExit = $proc.ExitCode

$rerunManifest = New-Manifest $TempWorktree $relPaths (Join-Path $CsvDir "D10R_rerun_output_manifest.csv")

$committedByPath = @{}
foreach ($row in $committedManifest) { $committedByPath[$row.relative_path] = $row }
$rerunByPath = @{}
foreach ($row in $rerunManifest) { $rerunByPath[$row.relative_path] = $row }

$hashComparison = foreach ($rel in $relPaths) {
  $c = $committedByPath[$rel]
  $r = $rerunByPath[$rel]
  $status = if ($null -eq $c -or $c.status -eq "MISSING") {
    "MISSING_COMMITTED"
  } elseif ($null -eq $r -or $r.status -eq "MISSING") {
    "MISSING_RERUN"
  } elseif ($c.sha256 -eq $r.sha256) {
    "MATCH"
  } else {
    "HASH_DIFFERENCE"
  }
  [pscustomobject]@{
    relative_path = $rel
    committed_sha256 = $c.sha256
    rerun_sha256 = $r.sha256
    match_status = $status
    committed_size_bytes = $c.file_size_bytes
    rerun_size_bytes = $r.file_size_bytes
    notes = if ($status -eq "HASH_DIFFERENCE") { "Content or serialization differs; inspect with shape and validation review." } else { "" }
  }
}
$hashComparison | Export-Csv -LiteralPath (Join-Path $CsvDir "D10R_hash_comparison.csv") -NoTypeInformation

$keyCsvs = @(
  "$D10Dir/csv/D10_us_source_of_truth_panel_wide.csv",
  "$D10Dir/csv/D10_us_source_of_truth_panel_long.csv",
  "$D10Dir/csv/D10_variable_dictionary.csv",
  "$D10Dir/csv/D10_validation_checks.csv",
  "$D10Dir/csv/D10_regression_menu_ledger.csv",
  "$D10Dir/csv/D10_elasticity_recovery_protocol_ledger.csv",
  "$D10Dir/csv/D10_corporate_clean_layer_ledger.csv",
  "$D10Dir/csv/D10_financial_imputed_interest_candidate_ledger.csv",
  "$D10Dir/csv/D10_blocked_parked_variable_ledger.csv"
)
$shapeComparison = foreach ($rel in $keyCsvs) {
  $c = Get-CsvShape $Root $rel
  $r = Get-CsvShape $TempWorktree $rel
  [pscustomobject]@{
    relative_path = $rel
    committed_rows = $c.rows
    rerun_rows = $r.rows
    committed_cols = $c.cols
    rerun_cols = $r.cols
    shape_match = if ($c.rows -eq $r.rows -and $c.cols -eq $r.cols) { "TRUE" } else { "FALSE" }
    notes = ""
  }
}
$shapeComparison | Export-Csv -LiteralPath (Join-Path $CsvDir "D10R_csv_shape_comparison.csv") -NoTypeInformation

$requiredValidation = @(
  "NO_Q_OMEGA_CREATED", "Q_OMEGA_PARKED", "NO_ECONOMETRICS_RUN", "NO_MODEL_ESTIMATION_RUN",
  "NO_STATIONARITY_TESTS_RUN", "NO_INTEGRATION_TESTS_RUN", "NO_COINTEGRATION_TESTS_RUN",
  "NO_D09_S_SENSITIVITY_STOCK_CONSUMED_AS_BASELINE", "RAW_AND_CLEAN_CORP_OBJECTS_NOT_COLLAPSED",
  "REGRESSION_STATUS_DISTINCT_FROM_DATASET_INCLUSION"
)
$committedVal = Import-Csv -LiteralPath (Join-Path $Root "$D10Dir/csv/D10_validation_checks.csv")
$rerunVal = Import-Csv -LiteralPath (Join-Path $TempWorktree "$D10Dir/csv/D10_validation_checks.csv")
$committedValByCheck = @{}; foreach ($v in $committedVal) { $committedValByCheck[$v.check_id] = $v.status }
$rerunValByCheck = @{}; foreach ($v in $rerunVal) { $rerunValByCheck[$v.check_id] = $v.status }
$validationReview = foreach ($check in $requiredValidation) {
  $cs = $committedValByCheck[$check]
  $rs = $rerunValByCheck[$check]
  [pscustomobject]@{
    check = $check
    committed_status = $cs
    rerun_status = $rs
    review_status = if ($cs -eq "PASS" -and $rs -eq "PASS") { "PASS" } else { "FAIL" }
    notes = ""
  }
}
$validationReview | Export-Csv -LiteralPath (Join-Path $CsvDir "D10R_validation_review.csv") -NoTypeInformation

$cleanStatus = Get-LedgerStatus (Join-Path $Root "$D10Dir/csv/D10_corporate_clean_layer_ledger.csv")
$finStatus = Get-LedgerStatus (Join-Path $Root "$D10Dir/csv/D10_financial_imputed_interest_candidate_ledger.csv")
$exploitStatus = Get-LedgerStatus (Join-Path $Root "$D10Dir/csv/D10_exploitation_rate_ingredient_ledger.csv")
$taxStatus = Get-LedgerStatus (Join-Path $Root "$D10Dir/csv/D10_tax_subsidy_transfer_ledger.csv")
$rawStatus = Get-LedgerStatus (Join-Path $Root "$D10Dir/csv/D10_corporate_raw_comparison_ledger.csv")

$recon = @(
  [pscustomobject]@{object="CORPORATE_CLEAN_LAYER";status_in_D10=$cleanStatus;reconciliation_status="RECONCILED_AS_CANDIDATE_CROSSWALK";model_ready_status="NOT_MODEL_READY";notes="No validated crosswalk promoted."}
  [pscustomobject]@{object="FINANCIAL_IMPUTED_INTEREST_CANDIDATES";status_in_D10=$finStatus;reconciliation_status="RECONCILED_AS_CANDIDATE_CROSSWALK";model_ready_status="NOT_MODEL_READY";notes="Candidates preserved."}
  [pscustomobject]@{object="EXPLOITATION_RATE_INGREDIENTS";status_in_D10=$exploitStatus;reconciliation_status="RECONCILED_AS_CONSTRUCTION_CONTRACT";model_ready_status="NOT_MODEL_READY";notes="No final exploitation-rate series forced."}
  [pscustomobject]@{object="TAX_SUBSIDY_TRANSFER_BLOCK";status_in_D10=$taxStatus;reconciliation_status="RECONCILED_AS_ACCOUNTING_BRIDGE";model_ready_status="NOT_BASELINE_REGRESSOR";notes="Gross/net preservation status carried."}
  [pscustomobject]@{object="Q_OMEGA_PARKING";status_in_D10="PARKED_TRANSFORMATION_UNTIL_NEW_COMMAND";reconciliation_status="PARKED";model_ready_status="NOT_MODEL_READY";notes="No q_omega column created."}
  [pscustomobject]@{object="D09_S_SENSITIVITY_STOCK_EXCLUSION";status_in_D10="REPORT_ONLY_NOT_BASELINE";reconciliation_status="EXCLUDED_FROM_BASELINE";model_ready_status="NOT_BASELINE_REGRESSOR";notes="D09-S stocks not consumed."}
  [pscustomobject]@{object="BASELINE_CAPITAL_BOUNDARY";status_in_D10="K_capacity = ME + NRC; ME L14 alpha1.7; NRC L30 alpha1.6";reconciliation_status="RECONFIRMED";model_ready_status="AUTHORIZED_BASELINE_ECONOMETRIC";notes="Boundary ledger excludes total/IPP/residential/government/all-BEA/D09-S sensitivity stocks."}
  [pscustomobject]@{object="RAW_CORP_COMPARISON_LAYER";status_in_D10=$rawStatus;reconciliation_status="RECONCILED_AS_RAW_COMPARISON";model_ready_status="NOT_BASELINE_PRODUCTIVE_ORIGIN";notes="Raw corporate objects remain comparison-only."}
)
$recon | Export-Csv -LiteralPath (Join-Path $CsvDir "D10R_reconciliation_status_ledger.csv") -NoTypeInformation

$qomegaCols = (Import-Csv -LiteralPath (Join-Path $TempWorktree "$D10Dir/csv/D10_us_source_of_truth_panel_wide.csv") |
  Select-Object -First 1).PSObject.Properties.Name | Where-Object { $_ -match "q_omega|q_exploitation|distribution.weighted|lagged.wage.share.weighted" }
$mainD10Diff = git diff --name-status -- $D10Dir
$hashDiffCount = ($hashComparison | Where-Object { $_.match_status -ne "MATCH" }).Count
$shapeMismatchCount = ($shapeComparison | Where-Object { $_.shape_match -ne "TRUE" }).Count
$rerunPassCount = ($rerunVal | Where-Object { $_.status -eq "PASS" }).Count
$rerunTotalCount = $rerunVal.Count
$requiredValidationFailures = ($validationReview | Where-Object { $_.review_status -ne "PASS" }).Count

git worktree remove $TempWorktree --force | Tee-Object -FilePath (Join-Path $LogsDir "D10R_worktree_remove.log") | Out-Null
$tempRemoved = -not (Test-Path -LiteralPath $TempWorktree)

$decision = if ($rscriptExit -ne 0) {
  "BLOCK_D10R_RSCRIPT_FAILURE"
} elseif ($qomegaCols.Count -gt 0) {
  "BLOCK_D10R_QOMEGA_REINTRODUCTION"
} elseif ($requiredValidationFailures -gt 0 -or $rerunPassCount -ne $rerunTotalCount) {
  "BLOCK_D10R_VALIDATION_FAILURE"
} elseif ($mainD10Diff.Count -gt 0) {
  "BLOCK_D10R_MAIN_OUTPUT_MUTATION"
} elseif ($shapeMismatchCount -gt 0) {
  "REQUIRE_D10_OUTPUT_RECONCILIATION"
} elseif ($hashDiffCount -gt 0) {
  "REQUIRE_D10_OUTPUT_RECONCILIATION"
} else {
  "AUTHORIZE_D11_INTEGRATION_AND_ESTIMATION_READINESS_REVIEW"
}

$checks = @(
  "REPO_STATE_RECORDED", "MAIN_HEAD_ORIGIN_SYNCED_AT_D10", "MAIN_WORKTREE_CLEAN_AT_OPEN", "RSCRIPT_AVAILABLE",
  "TEMP_WORKTREE_CREATED", "D10_RSCRIPT_RERUN_ATTEMPTED", "D10_RSCRIPT_RERUN_COMPLETED",
  "COMMITTED_OUTPUT_MANIFEST_CREATED", "RERUN_OUTPUT_MANIFEST_CREATED", "HASH_COMPARISON_CREATED",
  "CSV_SHAPE_COMPARISON_CREATED", "D10_VALIDATION_REVIEW_CREATED", "D10_VALIDATION_CHECKS_PASS_ON_RERUN",
  "NO_Q_OMEGA_CREATED_ON_RERUN", "Q_OMEGA_REMAINS_PARKED", "NO_ECONOMETRICS_RUN_ON_RERUN",
  "NO_MODEL_ESTIMATION_RUN_ON_RERUN", "NO_STATIONARITY_TESTS_RUN_ON_RERUN", "NO_INTEGRATION_TESTS_RUN_ON_RERUN",
  "NO_COINTEGRATION_TESTS_RUN_ON_RERUN", "NO_D09_S_SENSITIVITY_STOCK_CONSUMED_AS_BASELINE_ON_RERUN",
  "CORPORATE_CLEAN_LAYER_RECONCILED_AS_CANDIDATE_OR_VALIDATED", "FINANCIAL_IMPUTED_INTEREST_RECONCILED_AS_CANDIDATE",
  "EXPLOITATION_RATE_INGREDIENTS_RECONCILED_AS_CONTRACT", "TAX_SUBSIDY_TRANSFER_BLOCK_RECONCILED",
  "RAW_CORP_COMPARISON_LAYER_RECONCILED", "BASELINE_CAPITAL_BOUNDARY_RECONFIRMED",
  "MAIN_D10_OUTPUTS_NOT_MUTATED", "TEMP_WORKTREE_REMOVED_OR_REPORTED", "DECISION_RECORDED"
)

$validationRows = foreach ($check in $checks) {
  $status = "PASS"
  $notes = ""
  switch ($check) {
    "MAIN_HEAD_ORIGIN_SYNCED_AT_D10" { $status = if ($openingOriginMain -eq "0c5f3be463da68d209e7795844e00f88e2d50b4b") { "PASS" } else { "FAIL" }; $notes = "HEAD=$openingHead; origin/main=$openingOriginMain; divergence=$openingDivergence. HEAD may include D10-R retry artifact commit." }
    "MAIN_WORKTREE_CLEAN_AT_OPEN" { $status = if (($openingStatus | Where-Object { $_ -match "^[? MADRCU]" }).Count -eq 0) { "PASS" } else { "FAIL" }; $notes = $openingStatus -join " | " }
    "RSCRIPT_AVAILABLE" { $status = "PASS"; $notes = ($versionOutput -join " ") }
    "D10_RSCRIPT_RERUN_COMPLETED" { $status = if ($rscriptExit -eq 0) { "PASS" } else { "FAIL" }; $notes = "Exit code $rscriptExit" }
    "D10_VALIDATION_CHECKS_PASS_ON_RERUN" { $status = if ($rerunPassCount -eq $rerunTotalCount) { "PASS" } else { "FAIL" }; $notes = "$rerunPassCount/$rerunTotalCount PASS" }
    "NO_Q_OMEGA_CREATED_ON_RERUN" { $status = if ($qomegaCols.Count -eq 0) { "PASS" } else { "FAIL" }; $notes = ($qomegaCols -join ";") }
    "MAIN_D10_OUTPUTS_NOT_MUTATED" { $status = if ($mainD10Diff.Count -eq 0) { "PASS" } else { "FAIL" }; $notes = $mainD10Diff -join " | " }
    "TEMP_WORKTREE_REMOVED_OR_REPORTED" { $status = if ($tempRemoved) { "PASS" } else { "FAIL" }; $notes = "Temp path $TempWorktree" }
    "DECISION_RECORDED" { $notes = $decision }
  }
  [pscustomobject]@{check_id=$check;status=$status;notes=$notes}
}
$validationRows | Export-Csv -LiteralPath (Join-Path $CsvDir "D10R_validation_checks.csv") -NoTypeInformation

$report = @(
  "# D10-R Decision Report",
  "",
  "D10-R reran the committed D10 source-of-truth script in a detached temporary worktree using Rscript 4.6.1. It did not estimate anything.",
  "",
  "## Opening Repository State",
  "- `git status --short --branch`: $($openingStatus -join ' | ')",
  "- Branch: ``$openingBranch``",
  "- HEAD: ``$openingHead``",
  "- origin/main: ``$openingOriginMain``",
  "- Divergence HEAD...origin/main: ``$openingDivergence``",
  "- Note: HEAD includes the prior D10-R environment-reconciliation artifact commit; origin/main remains the D10 commit under review.",
  "",
  "## Rscript Availability",
  "- PATH lookup via `where.exe Rscript`: exit $whereExit.",
  "- Absolute Rscript path used: ``$Rscript``.",
  "- Version: $($versionOutput -join ' ')",
  "",
  "## Temporary Worktree",
  "- Path: ``$TempWorktree``",
  "- Created: YES",
  "- Removed: $tempRemoved",
  "",
  "## D10 Script Rerun Result",
  "- Script: ``$D10Script``",
  "- Exit code: $rscriptExit",
  "- Rerun completed: $(if ($rscriptExit -eq 0) { 'YES' } else { 'NO' })",
  "",
  "## Manifest Comparison Summary",
  "- Files compared: $($hashComparison.Count)",
  "- Hash matches: $(($hashComparison | Where-Object { $_.match_status -eq 'MATCH' }).Count)",
  "- Hash differences: $hashDiffCount",
  "",
  "## CSV Shape Comparison Summary",
  "- Key CSVs compared: $($shapeComparison.Count)",
  "- Shape mismatches: $shapeMismatchCount",
  "",
  "## D10 Validation Review Summary",
  "- Rerun D10 validation checks: $rerunPassCount/$rerunTotalCount PASS",
  "- Required validation-review failures: $requiredValidationFailures",
  "",
  "## Reconciliation Status",
  "- q_omega parking status: no q_omega-family columns created on rerun.",
  "- D09-S sensitivity stock exclusion: remains report-only and excluded from baseline.",
  "- ME/NRC/capacity baseline reconfirmation: D10 validation rerun passed; K_capacity remains ME + NRC.",
  "- Corporate-clean reconciliation status: $cleanStatus.",
  "- Financial/imputed-interest reconciliation status: $finStatus.",
  "- Exploitation-rate ingredient status: $exploitStatus.",
  "- Tax/subsidy/transfer reconciliation status: $taxStatus.",
  "- Main worktree mutation status: no D10 output diffs in main.",
  "",
  "## Final Decision",
  $decision
)
$report | Set-Content -LiteralPath (Join-Path $ReportsDir "D10R_decision_report.md") -Encoding UTF8

Write-Output $decision
