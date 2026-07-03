$ErrorActionPreference = "Stop"

$Root = (Resolve-Path ".").Path
$OutDir = Join-Path $Root "output/US/D10_R2_OUTPUT_HASH_DIFFERENCE_RECONCILIATION"
$CsvDir = Join-Path $OutDir "csv"
$ReportsDir = Join-Path $OutDir "reports"
$LogsDir = Join-Path $OutDir "logs"
$D10Dir = "output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET"
$D10RDir = "output/US/D10_R_RECONCILIATION_AND_REPRODUCIBILITY_CHECK"
$TempWorktree = "C:\ReposGitHub\Capacity-Utilization-US_Chile_D10R_tmp"

New-Item -ItemType Directory -Force -Path $CsvDir, $ReportsDir, $LogsDir | Out-Null

$openingStatus = git status --short --branch
$openingLog = git log --oneline --decorate -8
$openingDivergence = git rev-list --left-right --count HEAD...origin/main
$d10OutputDiff = git diff --name-status -- $D10Dir

$allowedNoise = @(
  "chapter2_vault/.obsidian/appearance.json",
  "chapter2_vault/.obsidian/core-plugins.json",
  "chapter2_vault/Untitled.md"
)
$unrelatedLines = $openingStatus | Where-Object { $_ -match "^\s*(M|\?\?)\s+" -and $_ -notmatch "D10_R2_OUTPUT_HASH_DIFFERENCE_RECONCILIATION" -and $_ -notmatch "US_D10R2_output_hash_difference_reconciliation.ps1" }
$unrelatedUnexpected = @()
foreach ($line in $unrelatedLines) {
  $path = ($line -replace "^\s*(M|\?\?)\s+", "").Replace("\", "/")
  if ($allowedNoise -notcontains $path) { $unrelatedUnexpected += $path }
}

$hashComparisonPath = Join-Path $Root "$D10RDir/csv/D10R_hash_comparison.csv"
$shapeComparisonPath = Join-Path $Root "$D10RDir/csv/D10R_csv_shape_comparison.csv"
$validationReviewPath = Join-Path $Root "$D10RDir/csv/D10R_validation_review.csv"
$d10rReportPath = Join-Path $Root "$D10RDir/reports/D10R_decision_report.md"

$hashComparison = Import-Csv -LiteralPath $hashComparisonPath
$shapeComparison = Import-Csv -LiteralPath $shapeComparisonPath
$validationReview = Import-Csv -LiteralPath $validationReviewPath
$hashDiffRows = $hashComparison | Where-Object { $_.match_status -eq "HASH_DIFFERENCE" }
$rerunFilesAvailable = Test-Path -LiteralPath $TempWorktree

function Get-FileType($rel) {
  $ext = [IO.Path]::GetExtension($rel).ToLowerInvariant()
  if ($ext -eq ".csv") { return "CSV" }
  if ($ext -eq ".md") { return "MD" }
  if ($ext -eq ".tex") { return "TEX" }
  if ($ext -eq ".r") { return "R_SCRIPT" }
  return "OTHER"
}

$shapeByPath = @{}
foreach ($row in $shapeComparison) { $shapeByPath[$row.relative_path] = $row.shape_match }

$classification = foreach ($row in $hashDiffRows) {
  $fileType = Get-FileType $row.relative_path
  $shapeMatch = if ($shapeByPath.ContainsKey($row.relative_path)) { $shapeByPath[$row.relative_path] } else { "NOT_APPLICABLE" }
  [pscustomobject]@{
    relative_path = $row.relative_path
    file_type = $fileType
    committed_sha256 = $row.committed_sha256
    rerun_sha256 = $row.rerun_sha256
    shape_match = $shapeMatch
    column_names_match = if ($fileType -eq "CSV" -and $shapeMatch -eq "TRUE") { "UNKNOWN_RERUN_FILE_NOT_AVAILABLE" } elseif ($fileType -eq "CSV") { "REVIEW_REQUIRED" } else { "NOT_APPLICABLE" }
    normalized_content_match = "UNKNOWN_RERUN_FILE_NOT_AVAILABLE"
    difference_type = "RERUN_FILE_NOT_AVAILABLE_FOR_DIFF"
    substantive_status = "REVIEW_REQUIRED"
    notes = "D10-R removed the temporary worktree after rerun. Hashes and shapes were retained, but rerun file bodies are unavailable for D10-R2 value/format classification without regenerating comparison artifacts."
  }
}
$classification | Export-Csv -LiteralPath (Join-Path $CsvDir "D10R2_hash_difference_classification.csv") -NoTypeInformation

$coreCsvs = @(
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
$hashByPath = @{}
foreach ($row in $hashComparison) { $hashByPath[$row.relative_path] = $row.match_status }
$coreAudit = foreach ($rel in $coreCsvs) {
  $shape = if ($shapeByPath.ContainsKey($rel)) { $shapeByPath[$rel] } else { "UNKNOWN" }
  $hashStatus = if ($hashByPath.ContainsKey($rel)) { $hashByPath[$rel] } else { "UNKNOWN" }
  $pass = ($hashStatus -eq "MATCH" -and $shape -eq "TRUE")
  [pscustomobject]@{
    relative_path = $rel
    shape_match = $shape
    columns_match = if ($pass) { "TRUE" } elseif ($shape -eq "TRUE") { "UNKNOWN_RERUN_FILE_NOT_AVAILABLE" } else { "REVIEW_REQUIRED" }
    parsed_values_match = if ($pass) { "TRUE" } else { "UNKNOWN_RERUN_FILE_NOT_AVAILABLE" }
    status = if ($pass) { "PASS" } else { "REVIEW_REQUIRED" }
    notes = if ($pass) { "D10-R hash and shape match; byte-identical rerun artifact was recorded." } else { "D10-R shape matched but hash differed, or rerun file body is unavailable after temp worktree removal." }
  }
}
$coreAudit | Export-Csv -LiteralPath (Join-Path $CsvDir "D10R2_core_csv_value_audit.csv") -NoTypeInformation

$wide = Import-Csv -LiteralPath (Join-Path $Root "$D10Dir/csv/D10_us_source_of_truth_panel_wide.csv")
$wideColumns = ($wide | Select-Object -First 1).PSObject.Properties.Name
$d10Validation = Import-Csv -LiteralPath (Join-Path $Root "$D10Dir/csv/D10_validation_checks.csv")
$d10ValidationByCheck = @{}
foreach ($row in $d10Validation) { $d10ValidationByCheck[$row.check_id] = $row.status }
$qCols = $wideColumns | Where-Object { $_ -match "q_omega|q_exploitation|distribution.weighted|lagged.wage.share.weighted" }
$blocked = Import-Csv -LiteralPath (Join-Path $Root "$D10Dir/csv/D10_blocked_parked_variable_ledger.csv")

$boundary = @(
  [pscustomobject]@{check="Q_OMEGA_PARKED";status=if (($blocked | Where-Object { $_.status -eq "PARKED_TRANSFORMATION_UNTIL_NEW_COMMAND" }).Count -ge 1) {"PASS"} else {"FAIL"};notes="Blocked/parked ledger carries q_omega parking rows."}
  [pscustomobject]@{check="NO_Q_OMEGA_COLUMNS";status=if ($qCols.Count -eq 0) {"PASS"} else {"FAIL"};notes=($qCols -join ";")}
  [pscustomobject]@{check="NO_D09_S_SENSITIVITY_STOCK_BASELINE";status=$d10ValidationByCheck["NO_D09_S_SENSITIVITY_STOCK_CONSUMED_AS_BASELINE"];notes="Confirmed from D10 validation checks."}
  [pscustomobject]@{check="ME_L14_NRC_L30_RECONFIRMED";status=$d10ValidationByCheck["ME_L14_NRC_L30_BASELINE_RECORDED"];notes="D10 validation recorded ME L14 alpha1.7 and NRC L30 alpha1.6."}
  [pscustomobject]@{check="K_CAPACITY_EQUALS_ME_PLUS_NRC_STATUS_RECONFIRMED";status=$d10ValidationByCheck["K_CAPACITY_EQUALS_ME_PLUS_NRC"];notes="D10 validation identity check remains PASS."}
  [pscustomobject]@{check="NO_TOTAL_CAPITAL_BASELINE";status=$d10ValidationByCheck["NO_TOTAL_CAPITAL_BASELINE"];notes="Confirmed from D10 validation checks."}
  [pscustomobject]@{check="NO_IPP_BASELINE";status=$d10ValidationByCheck["NO_IPP_BASELINE"];notes="Confirmed from D10 validation checks."}
  [pscustomobject]@{check="NO_RESIDENTIAL_BASELINE";status=$d10ValidationByCheck["NO_RESIDENTIAL_BASELINE"];notes="Confirmed from D10 validation checks."}
  [pscustomobject]@{check="NO_GOV_TRANSPORT_BASELINE";status=$d10ValidationByCheck["NO_GOV_TRANSPORT_BASELINE"];notes="Confirmed from D10 validation checks."}
  [pscustomobject]@{check="NO_ALL_BEA_FIXED_ASSETS_BASELINE";status=$d10ValidationByCheck["NO_ALL_BEA_FIXED_ASSETS_BASELINE"];notes="Confirmed from D10 validation checks."}
)
$boundary | Export-Csv -LiteralPath (Join-Path $CsvDir "D10R2_boundary_reconfirmation.csv") -NoTypeInformation

$allHashDiffsUnavailable = (($classification | Where-Object { $_.difference_type -ne "RERUN_FILE_NOT_AVAILABLE_FOR_DIFF" }).Count -eq 0)
$coreAuditPass = (($coreAudit | Where-Object { $_.status -ne "PASS" }).Count -eq 0)
$boundaryPass = (($boundary | Where-Object { $_.status -ne "PASS" }).Count -eq 0)
$qomegaPass = (($boundary | Where-Object { $_.check -eq "NO_Q_OMEGA_COLUMNS" }).status -eq "PASS")
$unexpectedUnrelated = ($unrelatedUnexpected.Count -gt 0)

$decision = if (-not $qomegaPass) {
  "BLOCK_D10R2_QOMEGA_REINTRODUCTION"
} elseif (-not $boundaryPass) {
  "BLOCK_D10R2_BASELINE_BOUNDARY_LEAKAGE"
} elseif ($allHashDiffsUnavailable) {
  "REQUIRE_D10R_COMPARISON_ARTIFACT_REGENERATION"
} elseif (-not $coreAuditPass) {
  "REQUIRE_D10_OUTPUT_RECONCILIATION"
} else {
  "AUTHORIZE_D11_INTEGRATION_AND_ESTIMATION_READINESS_REVIEW"
}

$validationChecks = @(
  [pscustomobject]@{check_id="REPO_STATE_RECORDED";status="PASS";notes="Branch may be ahead by D10-R commit. Divergence: $openingDivergence."}
  [pscustomobject]@{check_id="D10R_HASH_COMPARISON_READ";status=if (Test-Path -LiteralPath $hashComparisonPath) {"PASS"} else {"FAIL"};notes=$hashComparisonPath}
  [pscustomobject]@{check_id="HASH_DIFFERENCE_ROWS_IDENTIFIED";status=if ($hashDiffRows.Count -eq 8) {"PASS"} else {"FAIL"};notes="$($hashDiffRows.Count) HASH_DIFFERENCE rows identified."}
  [pscustomobject]@{check_id="HASH_DIFFERENCE_CLASSIFICATION_CREATED";status="PASS";notes="Classification ledger created."}
  [pscustomobject]@{check_id="CORE_CSV_VALUE_AUDIT_CREATED";status="PASS";notes="Core CSV audit created; rerun file bodies unavailable for hash-difference files."}
  [pscustomobject]@{check_id="BOUNDARY_RECONFIRMATION_CREATED";status="PASS";notes="Boundary reconfirmation ledger created."}
  [pscustomobject]@{check_id="Q_OMEGA_REMAINS_PARKED";status=(($boundary | Where-Object { $_.check -eq "Q_OMEGA_PARKED" }).status);notes="From D10 blocked/parked ledger."}
  [pscustomobject]@{check_id="NO_Q_OMEGA_COLUMNS";status=(($boundary | Where-Object { $_.check -eq "NO_Q_OMEGA_COLUMNS" }).status);notes="Committed wide panel column scan."}
  [pscustomobject]@{check_id="NO_BASELINE_BOUNDARY_LEAKAGE";status=if ($boundaryPass) {"PASS"} else {"FAIL"};notes="D10 validation boundary checks reviewed."}
  [pscustomobject]@{check_id="NO_D10_SOURCE_OUTPUT_MUTATION";status=if ($d10OutputDiff.Count -eq 0) {"PASS"} else {"FAIL"};notes=($d10OutputDiff -join " | ")}
  [pscustomobject]@{check_id="UNRELATED_OBSIDIAN_NOISE_NOT_STAGED";status=if ($unexpectedUnrelated) {"FAIL"} else {"PASS"};notes="Allowed local UI/noise files left unstaged: chapter2_vault/.obsidian/appearance.json; chapter2_vault/.obsidian/core-plugins.json; chapter2_vault/Untitled.md user-confirmed note."}
  [pscustomobject]@{check_id="DECISION_RECORDED";status="PASS";notes=$decision}
)
$validationChecks | Export-Csv -LiteralPath (Join-Path $CsvDir "D10R2_validation_checks.csv") -NoTypeInformation

$hashDiffList = $hashDiffRows | ForEach-Object { "- ``{0}``" -f $_.relative_path }
$classificationList = $classification | ForEach-Object { "- ``{0}``: ``{1}``, ``{2}``" -f $_.relative_path, $_.difference_type, $_.substantive_status }
$coreSummary = $coreAudit | Group-Object status | ForEach-Object { "- $($_.Name): $($_.Count)" }
$boundarySummary = $boundary | Group-Object status | ForEach-Object { "- $($_.Name): $($_.Count)" }
$report = @(
  "# D10-R2 Decision Report",
  "",
  "D10-R2 classifies the eight D10-R hash differences without rerunning D10 and without modifying D10 source-of-truth outputs.",
  "",
  "## Opening Repo State",
  "- `git status --short --branch`: $($openingStatus -join ' | ')",
  "- `git rev-list --left-right --count HEAD...origin/main`: $openingDivergence",
  "- Branch is ahead of origin/main by the D10-R commit.",
  "- Unrelated local UI/noise files left unstaged: `chapter2_vault/.obsidian/appearance.json`, `chapter2_vault/.obsidian/core-plugins.json`, and user-confirmed `chapter2_vault/Untitled.md`.",
  "",
  "## Hash-Difference Files",
  $hashDiffList,
  "",
  "## Classification",
  $classificationList,
  "",
  "The D10-R temp worktree was removed, so rerun file bodies are not available for D10-R2 line-level, numeric, or normalized-content comparison. D10-R retained hashes, shapes, and validation review, but not the rerun output files themselves.",
  "",
  "## Core CSV Value Audit Summary",
  $coreSummary,
  "",
  "Core CSVs with matching hashes pass. Core CSVs with hash differences remain review-required because rerun file bodies are unavailable.",
  "",
  "## Boundary And q_omega Status",
  $boundarySummary,
  "- q_omega remains parked and no q_omega-family columns exist in the committed D10 wide panel.",
  "- Baseline capital boundary remains ME L14 + NRC L30; K_capacity identity remains PASS in D10 validation.",
  "",
  "## D10 Source Output Mutation",
  "- D10 output diff in main worktree: $(if ($d10OutputDiff.Count -eq 0) { 'none' } else { $d10OutputDiff -join ' | ' })",
  "",
  "## Final Decision",
  $decision
)
$report | Set-Content -LiteralPath (Join-Path $ReportsDir "D10R2_decision_report.md") -Encoding UTF8

"D10R2 decision: $decision" | Set-Content -LiteralPath (Join-Path $LogsDir "D10R2_run.log") -Encoding UTF8
Write-Output $decision
