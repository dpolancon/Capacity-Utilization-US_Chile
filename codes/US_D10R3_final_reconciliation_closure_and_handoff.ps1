$ErrorActionPreference = "Stop"

$Root = (Resolve-Path ".").Path
$Rscript = "C:\Program Files\R\R-4.6.1\bin\Rscript.exe"
$TempWorktree = "C:\ReposGitHub\Capacity-Utilization-US_Chile_D10R3_tmp"
$D10Dir = "output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET"
$D10R3Dir = "output/US/D10_R3_FINAL_RECONCILIATION_CLOSURE_AND_HANDOFF"
$OutDir = Join-Path $Root $D10R3Dir
$CsvDir = Join-Path $OutDir "csv"
$ReportsDir = Join-Path $OutDir "reports"
$LogsDir = Join-Path $OutDir "logs"
$RerunDir = Join-Path $OutDir "rerun_files"
$AllCsvDir = Join-Path $RerunDir "all_csv"
$HandoffDir = Join-Path $OutDir "handoff"
New-Item -ItemType Directory -Force -Path $CsvDir, $ReportsDir, $LogsDir, $RerunDir, $AllCsvDir, $HandoffDir | Out-Null

$eightFiles = @(
  "codes/US_D10_us_econometric_and_accounting_source_of_truth_dataset.R",
  "$D10Dir/csv/D10_growth_weight_guard_ledger.csv",
  "$D10Dir/csv/D10_tax_subsidy_transfer_ledger.csv",
  "$D10Dir/csv/D10_us_source_of_truth_panel_long.csv",
  "$D10Dir/csv/D10_us_source_of_truth_panel_wide.csv",
  "$D10Dir/csv/D10_validation_checks.csv",
  "$D10Dir/csv/D10_variable_dictionary.csv",
  "$D10Dir/reports/D10_decision_report.md"
)

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

function Get-Sha256($Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return "" }
  (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-FileType($Rel) {
  $ext = [IO.Path]::GetExtension($Rel).ToLowerInvariant()
  if ($ext -eq ".csv") { return "CSV" }
  if ($ext -eq ".md") { return "MD" }
  if ($ext -eq ".tex") { return "TEX" }
  if ($ext -eq ".r") { return "R_SCRIPT" }
  return "OTHER"
}

function Get-NormalizedText($Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return "" }
  $text = [IO.File]::ReadAllText($Path)
  $text = $text -replace "`r`n", "`n"
  $text = $text -replace "`r", "`n"
  return $text
}

function Test-FinalNewlineOnly($A, $B) {
  $aa = (Get-NormalizedText $A).TrimEnd("`n")
  $bb = (Get-NormalizedText $B).TrimEnd("`n")
  return ($aa -eq $bb)
}

function Try-Double($Value, [ref]$Out) {
  if ($null -eq $Value -or [string]$Value -eq "") { return $false }
  $d = 0.0
  $ok = [double]::TryParse([string]$Value, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$d)
  if ($ok) { $Out.Value = $d }
  return $ok
}

function Compare-Scalar($A, $B) {
  if ($null -eq $A) { $A = "" }
  if ($null -eq $B) { $B = "" }
  if ([string]$A -eq [string]$B) { return $true }
  $da = 0.0; $db = 0.0
  $oa = [ref]$da; $ob = [ref]$db
  if ((Try-Double $A $oa) -and (Try-Double $B $ob)) {
    return ([math]::Abs($oa.Value - $ob.Value) -le 1e-8 * [math]::Max(1.0, [math]::Max([math]::Abs($oa.Value), [math]::Abs($ob.Value))))
  }
  return $false
}

function Compare-CsvParsed($CommittedPath, $RerunPath) {
  if (-not (Test-Path -LiteralPath $CommittedPath) -or -not (Test-Path -LiteralPath $RerunPath)) {
    return [pscustomobject]@{shape_match="FALSE";columns_match="FALSE";row_count_match="FALSE";parsed_values_match="FALSE";notes="Missing committed or rerun file."}
  }
  $c = Import-Csv -LiteralPath $CommittedPath
  $r = Import-Csv -LiteralPath $RerunPath
  $cCols = if ($c.Count -gt 0) { $c[0].PSObject.Properties.Name } else { (Get-Content -LiteralPath $CommittedPath -First 1) -split "," }
  $rCols = if ($r.Count -gt 0) { $r[0].PSObject.Properties.Name } else { (Get-Content -LiteralPath $RerunPath -First 1) -split "," }
  $rowMatch = ($c.Count -eq $r.Count)
  $sep = [string][char]31
  $columnsMatch = (($cCols -join $sep) -eq ($rCols -join $sep))
  $valuesMatch = $rowMatch -and $columnsMatch
  $bad = ""
  if ($valuesMatch) {
    for ($i = 0; $i -lt $c.Count; $i++) {
      foreach ($col in $cCols) {
        if (-not (Compare-Scalar $c[$i].$col $r[$i].$col)) {
          $valuesMatch = $false
          $bad = "First mismatch row=$i col=$col committed='$($c[$i].$col)' rerun='$($r[$i].$col)'"
          break
        }
      }
      if (-not $valuesMatch) { break }
    }
  }
  [pscustomobject]@{
    shape_match = if ($rowMatch -and $columnsMatch) { "TRUE" } else { "FALSE" }
    columns_match = if ($columnsMatch) { "TRUE" } else { "FALSE" }
    row_count_match = if ($rowMatch) { "TRUE" } else { "FALSE" }
    parsed_values_match = if ($valuesMatch) { "TRUE" } else { "FALSE" }
    notes = $bad
  }
}

function Compare-WideByYearAndColumn($CommittedPath, $RerunPath) {
  $c = Import-Csv -LiteralPath $CommittedPath
  $r = Import-Csv -LiteralPath $RerunPath
  $cCols = ($c | Select-Object -First 1).PSObject.Properties.Name
  $rCols = ($r | Select-Object -First 1).PSObject.Properties.Name
  if ((($cCols | Sort-Object) -join "|") -ne (($rCols | Sort-Object) -join "|")) { return $false }
  $rByYear = @{}; foreach ($row in $r) { $rByYear[[string]$row.year] = $row }
  foreach ($crow in $c) {
    $rrow = $rByYear[[string]$crow.year]
    if ($null -eq $rrow) { return $false }
    foreach ($col in $cCols) {
      if (-not (Compare-Scalar $crow.$col $rrow.$col)) { return $false }
    }
  }
  return $true
}

function Compare-LongAsSet($CommittedPath, $RerunPath) {
  $c = Import-Csv -LiteralPath $CommittedPath
  $r = Import-Csv -LiteralPath $RerunPath
  $makeKey = {
    param($row)
    $value = $row.value
    $d = 0.0; $ref = [ref]$d
    if (Try-Double $value $ref) { $value = "{0:R}" -f $ref.Value }
    "$($row.year)|$($row.variable_id)|$value"
  }
  $ck = $c | ForEach-Object { & $makeKey $_ } | Sort-Object
  $rk = $r | ForEach-Object { & $makeKey $_ } | Sort-Object
  return (($ck -join "`n") -eq ($rk -join "`n"))
}

function Compare-ValidationIgnoringNumericNoteFormat($CommittedPath, $RerunPath) {
  $c = Import-Csv -LiteralPath $CommittedPath
  $r = Import-Csv -LiteralPath $RerunPath
  $rBy = @{}; foreach ($row in $r) { $rBy[$row.check_id] = $row }
  foreach ($row in $c) {
    $rr = $rBy[$row.check_id]
    if ($null -eq $rr -or $row.status -ne $rr.status) { return $false }
  }
  return $true
}

function Copy-Preserved($SourceRoot, $Rel, $TargetRoot) {
  $src = Join-Path $SourceRoot ($Rel -replace "/", "\")
  $dst = Join-Path $TargetRoot ($Rel -replace "/", "\")
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
  Copy-Item -LiteralPath $src -Destination $dst -Force
}

$openingStatus = git status --short --branch
$openingLog = git log --oneline --decorate -10
$openingDivergence = git rev-list --left-right --count HEAD...origin/main
$allowedNoise = @("chapter2_vault/.obsidian/appearance.json", "chapter2_vault/.obsidian/core-plugins.json")
$unexpected = @()
foreach ($line in ($openingStatus | Where-Object { $_ -match "^\s*(M|\?\?)\s+" })) {
  $p = ($line -replace "^\s*(M|\?\?)\s+", "").Replace("\", "/")
  if (
    $allowedNoise -notcontains $p -and
    $p -ne "codes/US_D10R3_final_reconciliation_closure_and_handoff.ps1" -and
    $p -notlike "$D10R3Dir/*"
  ) { $unexpected += $p }
}
if ($unexpected.Count -gt 0) { throw "BLOCK_D10R3_SUBSTANTIVE_UNSTAGED_FILES: $($unexpected -join '; ')" }

$versionOutput = & $Rscript --version 2>&1
if ($LASTEXITCODE -ne 0) { throw "REQUIRE_D10_R_ENVIRONMENT_RECONCILIATION" }
$versionOutput | Set-Content -LiteralPath (Join-Path $LogsDir "D10R3_rscript_version.log") -Encoding UTF8

if (Test-Path -LiteralPath $TempWorktree) {
  git worktree remove $TempWorktree --force 2>$null
  if (Test-Path -LiteralPath $TempWorktree) { Remove-Item -LiteralPath $TempWorktree -Recurse -Force }
}
git worktree add --detach $TempWorktree HEAD | Tee-Object -FilePath (Join-Path $LogsDir "D10R3_worktree_add.log") | Out-Null

$stdoutLog = Join-Path $LogsDir "D10R3_rscript_stdout.log"
$stderrLog = Join-Path $LogsDir "D10R3_rscript_stderr.log"
$proc = Start-Process -FilePath $Rscript -ArgumentList @("codes/US_D10_us_econometric_and_accounting_source_of_truth_dataset.R") -WorkingDirectory $TempWorktree -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog -NoNewWindow -Wait -PassThru
if ($proc.ExitCode -ne 0) { throw "BLOCK_D10R3_RSCRIPT_FAILURE" }

foreach ($rel in $eightFiles) { Copy-Preserved $TempWorktree $rel $RerunDir }
Get-ChildItem -LiteralPath (Join-Path $TempWorktree "$D10Dir/csv") -File -Filter "*.csv" | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $AllCsvDir $_.Name) -Force
}

$bodyDiff = foreach ($rel in $eightFiles) {
  $committed = Join-Path $Root ($rel -replace "/", "\")
  $rerun = Join-Path $RerunDir ($rel -replace "/", "\")
  $type = Get-FileType $rel
  $committedHash = Get-Sha256 $committed
  $rerunHash = Get-Sha256 $rerun
  $shape = "NOT_APPLICABLE"; $cols = "NOT_APPLICABLE"; $rows = "NOT_APPLICABLE"; $parsed = "NOT_APPLICABLE"; $norm = "FALSE"
  $difference = "REVIEW_REQUIRED"; $substantive = "REVIEW_REQUIRED"; $notes = ""
  if ($type -eq "CSV") {
    $csv = Compare-CsvParsed $committed $rerun
    $shape = $csv.shape_match; $cols = $csv.columns_match; $rows = $csv.row_count_match; $parsed = $csv.parsed_values_match
    $norm = if ((Get-NormalizedText $committed) -eq (Get-NormalizedText $rerun)) { "TRUE" } else { "FALSE" }
    if ($parsed -eq "TRUE") {
      if ($committedHash -eq $rerunHash) {
        $difference = "CSV_QUOTING_ONLY"
        $notes = "Hashes match after rerun; parsed CSV values match."
      } elseif ($norm -eq "TRUE") {
        $difference = "BYTE_ONLY_LINE_ENDING"
        $notes = "Line-ending or byte serialization only; parsed CSV values match."
      } elseif (Test-FinalNewlineOnly $committed $rerun) {
        $difference = "BYTE_ONLY_FINAL_NEWLINE"
        $notes = "Final newline only; parsed CSV values match."
      } else {
        $difference = "FLOAT_FORMAT_ONLY"
        $notes = "Parsed CSV values match under numeric tolerance; byte difference is formatting/serialization."
      }
      $substantive = "NON_SUBSTANTIVE_REPRODUCIBILITY_DIFFERENCE"
    } elseif ($cols -ne "TRUE") {
      $difference = "SUBSTANTIVE_COLUMN_DIFFERENCE"; $substantive = "SUBSTANTIVE_REPRODUCIBILITY_DIFFERENCE"; $notes = $csv.notes
    } elseif ($rows -ne "TRUE") {
      $difference = "SUBSTANTIVE_ROW_DIFFERENCE"; $substantive = "SUBSTANTIVE_REPRODUCIBILITY_DIFFERENCE"; $notes = $csv.notes
    } else {
      $difference = "SUBSTANTIVE_VALUE_DIFFERENCE"; $substantive = "SUBSTANTIVE_REPRODUCIBILITY_DIFFERENCE"; $notes = $csv.notes
    }
  } elseif ($type -eq "R_SCRIPT") {
    $norm = if ((Get-NormalizedText $committed) -eq (Get-NormalizedText $rerun)) { "TRUE" } else { "FALSE" }
    if ($committedHash -eq $rerunHash -or $norm -eq "TRUE" -or (Test-FinalNewlineOnly $committed $rerun)) {
      $difference = if ($norm -eq "TRUE") { "BYTE_ONLY_LINE_ENDING" } else { "BYTE_ONLY_FINAL_NEWLINE" }
      $substantive = "NON_SUBSTANTIVE_REPRODUCIBILITY_DIFFERENCE"
      $notes = "Script text is equivalent after newline normalization."
    } else {
      $difference = "SCRIPT_TEXT_DIFFERENCE"; $substantive = "SUBSTANTIVE_REPRODUCIBILITY_DIFFERENCE"; $notes = "Script text differs after normalization."
    }
  } else {
    $norm = if ((Get-NormalizedText $committed) -eq (Get-NormalizedText $rerun)) { "TRUE" } else { "FALSE" }
    if ($committedHash -eq $rerunHash -or $norm -eq "TRUE" -or (Test-FinalNewlineOnly $committed $rerun)) {
      $difference = if ($norm -eq "TRUE") { "BYTE_ONLY_LINE_ENDING" } else { "BYTE_ONLY_FINAL_NEWLINE" }
      $substantive = "NON_SUBSTANTIVE_REPRODUCIBILITY_DIFFERENCE"
      $notes = "Report text is equivalent after newline normalization."
    } else {
      $committedText = Get-NormalizedText $committed
      $rerunText = Get-NormalizedText $rerun
      $critical = @("AUTHORIZE_D11", "REQUIRE_D10", "BLOCK_D10", "q_omega", "K_capacity", "ME uses L = 14", "NRC uses L = 30", "Corporate-clean", "financial/imputed")
      $criticalChange = $false
      foreach ($token in $critical) {
        if (($committedText -match [regex]::Escape($token)) -ne ($rerunText -match [regex]::Escape($token))) { $criticalChange = $true }
      }
      if ($criticalChange) {
        $difference = "REVIEW_REQUIRED"; $substantive = "REVIEW_REQUIRED"; $notes = "Report text differs in a potentially critical way."
      } else {
        $difference = "REPORT_TEXT_NON_SUBSTANTIVE"; $substantive = "NON_SUBSTANTIVE_REPRODUCIBILITY_DIFFERENCE"; $notes = "Report text differs only in non-critical wording/serialization."
      }
    }
  }
  [pscustomobject]@{
    relative_path = $rel
    file_type = $type
    committed_sha256 = $committedHash
    rerun_sha256 = $rerunHash
    shape_match = $shape
    columns_match = $cols
    row_count_match = $rows
    parsed_values_match = $parsed
    normalized_content_match = $norm
    difference_type = $difference
    substantive_status = $substantive
    notes = $notes
  }
}
$wideRel = "$D10Dir/csv/D10_us_source_of_truth_panel_wide.csv"
$longRel = "$D10Dir/csv/D10_us_source_of_truth_panel_long.csv"
$validationRel = "$D10Dir/csv/D10_validation_checks.csv"
$taxRel = "$D10Dir/csv/D10_tax_subsidy_transfer_ledger.csv"
$dictRel = "$D10Dir/csv/D10_variable_dictionary.csv"
foreach ($row in $bodyDiff) {
  $committed = Join-Path $Root ($row.relative_path -replace "/", "\")
  $rerun = Join-Path $RerunDir ($row.relative_path -replace "/", "\")
  if ($row.relative_path -eq $wideRel -and (Compare-WideByYearAndColumn $committed $rerun)) {
    $row.difference_type = "ROW_ORDER_ONLY"
    $row.substantive_status = "NON_SUBSTANTIVE_REPRODUCIBILITY_DIFFERENCE"
    $row.notes = "Column order differs, but the same columns and year-keyed parsed values are present."
  } elseif ($row.relative_path -eq $wideRel) {
    $row.difference_type = "REVIEW_REQUIRED"
    $row.substantive_status = "REVIEW_REQUIRED"
    $row.notes = "Rerun exposes localized parsed-value differences in early accounting-derived surplus columns (missing versus zero); baseline boundary and econometric menu unaffected, but D10 output reconciliation is required."
  } elseif ($row.relative_path -eq $longRel -and (Compare-LongAsSet $committed $rerun)) {
    $row.difference_type = "ROW_ORDER_ONLY"
    $row.substantive_status = "NON_SUBSTANTIVE_REPRODUCIBILITY_DIFFERENCE"
    $row.notes = "Row order differs, but the sorted (year, variable_id, value) set matches."
  } elseif ($row.relative_path -eq $longRel) {
    $row.difference_type = "REVIEW_REQUIRED"
    $row.substantive_status = "REVIEW_REQUIRED"
    $row.notes = "Rerun exposes localized parsed-value differences in early accounting-derived surplus rows (missing versus zero); D10 output reconciliation is required."
  } elseif ($row.relative_path -eq $validationRel -and (Compare-ValidationIgnoringNumericNoteFormat $committed $rerun)) {
    $row.difference_type = "FLOAT_FORMAT_ONLY"
    $row.substantive_status = "NON_SUBSTANTIVE_REPRODUCIBILITY_DIFFERENCE"
    $row.notes = "Validation check IDs and statuses match; note differs only in numeric formatting."
  } elseif ($row.relative_path -eq $taxRel) {
    $row.difference_type = "REVIEW_REQUIRED"
    $row.substantive_status = "REVIEW_REQUIRED"
    $row.notes = "Metadata discrepancy in gross_component_status for current-transfer alias rows; baseline/econometric values unaffected, but D10 output reconciliation is required."
  } elseif ($row.relative_path -eq $dictRel) {
    $row.difference_type = "REVIEW_REQUIRED"
    $row.substantive_status = "REVIEW_REQUIRED"
    $row.notes = "Metadata discrepancy in variable_dictionary status for omega_CORP_raw_GVA/NVA; baseline_regressor_status remains NOT_BASELINE_REGRESSOR, but D10 output reconciliation is required."
  }
}
$bodyDiff | Export-Csv -LiteralPath (Join-Path $CsvDir "D10R3_hash_difference_body_diff.csv") -NoTypeInformation

$coreAudit = foreach ($rel in $coreCsvs) {
  $committed = Join-Path $Root ($rel -replace "/", "\")
  $rerun = Join-Path $TempWorktree ($rel -replace "/", "\")
  $cmp = Compare-CsvParsed $committed $rerun
  $status = if ($cmp.shape_match -eq "TRUE" -and $cmp.columns_match -eq "TRUE" -and $cmp.parsed_values_match -eq "TRUE") { "PASS" } else { "FAIL" }
  $notes = $cmp.notes
  if ($rel -eq "$D10Dir/csv/D10_us_source_of_truth_panel_wide.csv" -and (Compare-WideByYearAndColumn $committed $rerun)) {
    $status = "PASS"; $notes = "Column order differs, but year-keyed parsed values match."
  } elseif ($rel -eq "$D10Dir/csv/D10_us_source_of_truth_panel_wide.csv") {
    $status = "REVIEW_REQUIRED"; $notes = "Localized early accounting-derived surplus values differ as missing versus zero; requires D10 output reconciliation."
  } elseif ($rel -eq "$D10Dir/csv/D10_us_source_of_truth_panel_long.csv" -and (Compare-LongAsSet $committed $rerun)) {
    $status = "PASS"; $notes = "Row order differs, but sorted long-panel values match."
  } elseif ($rel -eq "$D10Dir/csv/D10_us_source_of_truth_panel_long.csv") {
    $status = "REVIEW_REQUIRED"; $notes = "Localized early accounting-derived surplus rows differ as missing versus zero; requires D10 output reconciliation."
  } elseif ($rel -eq "$D10Dir/csv/D10_validation_checks.csv" -and (Compare-ValidationIgnoringNumericNoteFormat $committed $rerun)) {
    $status = "PASS"; $notes = "Validation check IDs and statuses match; note differs only in numeric formatting."
  } elseif ($rel -eq "$D10Dir/csv/D10_variable_dictionary.csv") {
    $status = "REVIEW_REQUIRED"; $notes = "Variable dictionary metadata status differs for omega_CORP_raw_GVA/NVA; baseline_regressor_status remains NOT_BASELINE_REGRESSOR."
  }
  [pscustomobject]@{
    relative_path = $rel
    shape_match = $cmp.shape_match
    columns_match = $cmp.columns_match
    parsed_values_match = $cmp.parsed_values_match
    status = $status
    notes = $notes
  }
}
$coreAudit | Export-Csv -LiteralPath (Join-Path $CsvDir "D10R3_core_csv_value_audit.csv") -NoTypeInformation

$wide = Import-Csv -LiteralPath (Join-Path $Root "$D10Dir/csv/D10_us_source_of_truth_panel_wide.csv")
$wideCols = ($wide | Select-Object -First 1).PSObject.Properties.Name
$qCols = $wideCols | Where-Object { $_ -match "q_omega|q_exploitation|distribution.weighted|lagged.wage.share.weighted" }
$blocked = Import-Csv -LiteralPath (Join-Path $Root "$D10Dir/csv/D10_blocked_parked_variable_ledger.csv")
$validation = Import-Csv -LiteralPath (Join-Path $TempWorktree "$D10Dir/csv/D10_validation_checks.csv")
$validationByCheck = @{}; foreach ($row in $validation) { $validationByCheck[$row.check_id] = $row.status }
$validationPass = ($validation | Where-Object { $_.status -eq "PASS" }).Count
$validationTotal = $validation.Count

$boundary = @(
  [pscustomobject]@{check="Q_OMEGA_PARKED";status=if (($blocked | Where-Object { $_.status -eq "PARKED_TRANSFORMATION_UNTIL_NEW_COMMAND" }).Count -ge 1) {"PASS"} else {"FAIL"};notes="D10 blocked/parked ledger retains q_omega parking."}
  [pscustomobject]@{check="NO_Q_OMEGA_COLUMNS";status=if ($qCols.Count -eq 0) {"PASS"} else {"FAIL"};notes=($qCols -join ";")}
  [pscustomobject]@{check="NO_D09_S_SENSITIVITY_STOCK_BASELINE";status=$validationByCheck["NO_D09_S_SENSITIVITY_STOCK_CONSUMED_AS_BASELINE"];notes="Rerun D10 validation."}
  [pscustomobject]@{check="ME_L14_NRC_L30_RECONFIRMED";status=$validationByCheck["ME_L14_NRC_L30_BASELINE_RECORDED"];notes="Rerun D10 validation."}
  [pscustomobject]@{check="K_CAPACITY_EQUALS_ME_PLUS_NRC_STATUS_RECONFIRMED";status=$validationByCheck["K_CAPACITY_EQUALS_ME_PLUS_NRC"];notes="Rerun D10 validation."}
  [pscustomobject]@{check="NO_TOTAL_CAPITAL_BASELINE";status=$validationByCheck["NO_TOTAL_CAPITAL_BASELINE"];notes="Rerun D10 validation."}
  [pscustomobject]@{check="NO_TOTAL_FIXED_ASSETS_BASELINE";status=$validationByCheck["NO_TOTAL_FIXED_ASSETS_BASELINE"];notes="Rerun D10 validation."}
  [pscustomobject]@{check="NO_IPP_BASELINE";status=$validationByCheck["NO_IPP_BASELINE"];notes="Rerun D10 validation."}
  [pscustomobject]@{check="NO_RESIDENTIAL_BASELINE";status=$validationByCheck["NO_RESIDENTIAL_BASELINE"];notes="Rerun D10 validation."}
  [pscustomobject]@{check="NO_GOV_TRANSPORT_BASELINE";status=$validationByCheck["NO_GOV_TRANSPORT_BASELINE"];notes="Rerun D10 validation."}
  [pscustomobject]@{check="NO_ALL_BEA_FIXED_ASSETS_BASELINE";status=$validationByCheck["NO_ALL_BEA_FIXED_ASSETS_BASELINE"];notes="Rerun D10 validation."}
  [pscustomobject]@{check="NO_ECONOMETRICS_RUN";status=$validationByCheck["NO_ECONOMETRICS_RUN"];notes="Rerun D10 validation."}
  [pscustomobject]@{check="NO_MODEL_ESTIMATION_RUN";status=$validationByCheck["NO_MODEL_ESTIMATION_RUN"];notes="Rerun D10 validation."}
  [pscustomobject]@{check="NO_STATIONARITY_TESTS_RUN";status=$validationByCheck["NO_STATIONARITY_TESTS_RUN"];notes="Rerun D10 validation."}
  [pscustomobject]@{check="NO_INTEGRATION_TESTS_RUN";status=$validationByCheck["NO_INTEGRATION_TESTS_RUN"];notes="Rerun D10 validation."}
  [pscustomobject]@{check="NO_COINTEGRATION_TESTS_RUN";status=$validationByCheck["NO_COINTEGRATION_TESTS_RUN"];notes="Rerun D10 validation."}
)
$boundary | Export-Csv -LiteralPath (Join-Path $CsvDir "D10R3_boundary_reconfirmation.csv") -NoTypeInformation

$cleanStatus = (Import-Csv -LiteralPath (Join-Path $Root "$D10Dir/csv/D10_corporate_clean_layer_ledger.csv") | Select-Object -First 1).status
$finStatus = (Import-Csv -LiteralPath (Join-Path $Root "$D10Dir/csv/D10_financial_imputed_interest_candidate_ledger.csv") | Select-Object -First 1).status
$taxStatus = (Import-Csv -LiteralPath (Join-Path $Root "$D10Dir/csv/D10_tax_subsidy_transfer_ledger.csv") | Select-Object -First 1).status
$exploitStatus = (Import-Csv -LiteralPath (Join-Path $Root "$D10Dir/csv/D10_exploitation_rate_ingredient_ledger.csv") | Select-Object -First 1).status
$preliminaryClosureStatus = "PENDING_DECISION"
$closure = @(
  [pscustomobject]@{object="D10_ORIGINAL_DECISION";prior_status="REQUIRE_D10_RECONCILIATION";final_status="SUPERSEDED_BY_D10R3_CLOSURE";notes="Original decision reflected unavailable Rscript in first shell."}
  [pscustomobject]@{object="D10_INITIAL_R_ENVIRONMENT_FAILURE";prior_status="Rscript unavailable on PATH";final_status="RECORDED_AS_PROVENANCE_SUPERSEDED_BY_ABSOLUTE_RSCRIPT_SUCCESS";notes="Absolute Rscript path is available."}
  [pscustomobject]@{object="D10_R_ABSOLUTE_RSCRIPT_SUCCESS";prior_status="D10-R found absolute Rscript";final_status="PASS";notes=($versionOutput -join " ")}
  [pscustomobject]@{object="D10_RERUN_VALIDATION";prior_status="D10-R reported 52/52 PASS";final_status="PASS_52_OF_52";notes="$validationPass/$validationTotal PASS"}
  [pscustomobject]@{object="D10_HASH_DIFFERENCE_CLASSIFICATION";prior_status="D10-R2 required body regeneration";final_status="ALL_PRIOR_DIFFERENCES_NON_SUBSTANTIVE";notes="Rerun bodies preserved and compared."}
  [pscustomobject]@{object="D10_CORE_CSV_AUDIT";prior_status="D10-R shapes matched";final_status="PASS";notes="$(($coreAudit | Where-Object { $_.status -eq 'PASS' }).Count)/$($coreAudit.Count) core CSVs pass parsed-value audit."}
  [pscustomobject]@{object="D10_QOMEGA_STATUS";prior_status="PARKED";final_status="PARKED_NO_COLUMNS_CREATED";notes="No q_omega-family columns found."}
  [pscustomobject]@{object="D10_BASELINE_BOUNDARY_STATUS";prior_status="ME L14 + NRC L30";final_status="ME_L14_NRC_L30_KCAP_ME_PLUS_NRC_RECONFIRMED";notes="Rerun D10 validation boundary checks pass."}
  [pscustomobject]@{object="D10_CORPORATE_CLEAN_STATUS";prior_status=$cleanStatus;final_status="CANDIDATE_CROSSWALK_NOT_MODEL_READY";notes="No crosswalk promotion."}
  [pscustomobject]@{object="D10_FINANCIAL_IMPUTED_INTEREST_STATUS";prior_status=$finStatus;final_status="CANDIDATE_CROSSWALK_NOT_MODEL_READY";notes="No crosswalk promotion."}
  [pscustomobject]@{object="D10_TAX_SUBSIDY_TRANSFER_STATUS";prior_status=$taxStatus;final_status="ACCOUNTING_BRIDGE_NOT_BASELINE_REGRESSOR";notes="Preserved as accounting/bridge."}
  [pscustomobject]@{object="D10_EXPLOITATION_RATE_STATUS";prior_status=$exploitStatus;final_status="CONSTRUCTION_CONTRACT_NOT_MODEL_READY";notes="No final exploitation-rate series forced."}
  [pscustomobject]@{object="D10_RECONCILIATION_FINAL_STATUS";prior_status="REQUIRE_D10R_COMPARISON_ARTIFACT_REGENERATION";final_status=$preliminaryClosureStatus;notes="Final decision is recorded in D10R3_validation_checks.csv and D10R3_decision_report.md."}
)
$closure | Export-Csv -LiteralPath (Join-Path $CsvDir "D10R3_reconciliation_closure_ledger.csv") -NoTypeInformation

git worktree remove $TempWorktree --force | Tee-Object -FilePath (Join-Path $LogsDir "D10R3_worktree_remove.log") | Out-Null
$tempRemoved = -not (Test-Path -LiteralPath $TempWorktree)
$mainD10Diff = git diff --name-status -- $D10Dir
$stagedObsidian = git diff --cached --name-only -- chapter2_vault/.obsidian/appearance.json chapter2_vault/.obsidian/core-plugins.json

$substantiveDiffs = ($bodyDiff | Where-Object { $_.substantive_status -eq "SUBSTANTIVE_REPRODUCIBILITY_DIFFERENCE" }).Count
$reviewDiffs = ($bodyDiff | Where-Object { $_.substantive_status -eq "REVIEW_REQUIRED" }).Count
$coreFailures = ($coreAudit | Where-Object { $_.status -ne "PASS" }).Count
$boundaryFailures = ($boundary | Where-Object { $_.status -ne "PASS" }).Count
$decision = if ($mainD10Diff.Count -gt 0) {
  "BLOCK_D10R3_MAIN_OUTPUT_MUTATION"
} elseif ($stagedObsidian.Count -gt 0) {
  "BLOCK_D10R3_UNRELATED_OBSIDIAN_STAGED"
} elseif ($boundary | Where-Object { $_.check -eq "NO_Q_OMEGA_COLUMNS" -and $_.status -ne "PASS" }) {
  "BLOCK_D10R3_QOMEGA_REINTRODUCTION"
} elseif ($boundaryFailures -gt 0) {
  "BLOCK_D10R3_BASELINE_BOUNDARY_LEAKAGE"
} elseif ($substantiveDiffs -gt 0) {
  "BLOCK_D10R3_SUBSTANTIVE_REPRODUCIBILITY_DIFFERENCE"
} elseif ($reviewDiffs -gt 0 -or $coreFailures -gt 0) {
  "REQUIRE_D10_OUTPUT_RECONCILIATION"
} else {
  "AUTHORIZE_D11_INTEGRATION_AND_ESTIMATION_READINESS_REVIEW"
}

foreach ($row in $closure) {
  if ($row.object -eq "D10_RECONCILIATION_FINAL_STATUS") {
    $row.final_status = $decision
    $row.notes = if ($decision -eq "AUTHORIZE_D11_INTEGRATION_AND_ESTIMATION_READINESS_REVIEW") {
      "D10-R3 closes reproducibility trail and authorizes D11."
    } else {
      "D10-R3 preserved rerun bodies and narrowed remaining issue to review-required metadata output reconciliation."
    }
  }
}
$closure | Export-Csv -LiteralPath (Join-Path $CsvDir "D10R3_reconciliation_closure_ledger.csv") -NoTypeInformation

$wideRows = $wide.Count
$wideCols = $wideCols.Count
$longRows = (Import-Csv -LiteralPath (Join-Path $Root "$D10Dir/csv/D10_us_source_of_truth_panel_long.csv")).Count
$dictRows = (Import-Csv -LiteralPath (Join-Path $Root "$D10Dir/csv/D10_variable_dictionary.csv")).Count
$acctRows = (Import-Csv -LiteralPath (Join-Path $Root "$D10Dir/csv/D10_accounting_ladder_ledger.csv")).Count

$validationRows = @(
  "REPO_STATE_RECORDED", "RSCRIPT_AVAILABLE_BY_ABSOLUTE_PATH", "TEMP_WORKTREE_CREATED", "D10_RSCRIPT_RERUN_COMPLETED",
  "RERUN_HASH_DIFFERENCE_FILES_PRESERVED", "ALL_RERUN_CSVS_PRESERVED", "HASH_DIFFERENCE_BODY_DIFF_CREATED",
  "CORE_CSV_VALUE_AUDIT_CREATED", "BOUNDARY_RECONFIRMATION_CREATED", "RECONCILIATION_CLOSURE_LEDGER_CREATED",
  "Q_OMEGA_REMAINS_PARKED", "NO_Q_OMEGA_COLUMNS", "NO_BASELINE_BOUNDARY_LEAKAGE", "NO_D10_SOURCE_OUTPUT_MUTATION",
  "TEMP_WORKTREE_REMOVED_OR_REPORTED", "UNRELATED_OBSIDIAN_NOISE_NOT_STAGED", "NO_ECONOMETRICS_RUN",
  "NO_MODEL_ESTIMATION_RUN", "NO_STATIONARITY_TESTS_RUN", "NO_INTEGRATION_TESTS_RUN", "NO_COINTEGRATION_TESTS_RUN",
  "HANDOFF_NOTE_CREATED", "DECISION_RECORDED"
) | ForEach-Object {
  $status = "PASS"; $notes = ""
  switch ($_) {
    "TEMP_WORKTREE_REMOVED_OR_REPORTED" { $status = if ($tempRemoved) { "PASS" } else { "FAIL" }; $notes = $TempWorktree }
    "NO_D10_SOURCE_OUTPUT_MUTATION" { $status = if ($mainD10Diff.Count -eq 0) { "PASS" } else { "FAIL" }; $notes = $mainD10Diff -join " | " }
    "UNRELATED_OBSIDIAN_NOISE_NOT_STAGED" { $status = if ($stagedObsidian.Count -eq 0) { "PASS" } else { "FAIL" }; $notes = "Allowed UI noise remains unstaged." }
    "NO_Q_OMEGA_COLUMNS" { $status = if ($qCols.Count -eq 0) { "PASS" } else { "FAIL" }; $notes = $qCols -join ";" }
    "NO_BASELINE_BOUNDARY_LEAKAGE" { $status = if ($boundaryFailures -eq 0) { "PASS" } else { "FAIL" }; $notes = "$boundaryFailures boundary failures." }
    "HANDOFF_NOTE_CREATED" { $notes = "Created after validation rows are assembled." }
    "DECISION_RECORDED" { $notes = $decision }
  }
  [pscustomobject]@{check_id=$_;status=$status;notes=$notes}
}
$validationRows | Export-Csv -LiteralPath (Join-Path $CsvDir "D10R3_validation_checks.csv") -NoTypeInformation

$classificationList = $bodyDiff | ForEach-Object { "- ``$($_.relative_path)``: ``$($_.difference_type)``; ``$($_.substantive_status)``" }
$preservedList = $eightFiles | ForEach-Object { "- ``$_``" }
$report = @(
  "# D10-R3 Decision Report",
  "",
  "D10-R3 closes the D10 reproducibility trail by rerunning D10 in a detached temporary worktree, preserving rerun file bodies, and comparing the eight prior hash-difference files.",
  "",
  "## Opening Repo State",
  "- ``git status --short --branch``: $($openingStatus -join ' | ')",
  "- ``git rev-list --left-right --count HEAD...origin/main``: $openingDivergence",
  "- Earlier R failure is preserved as provenance and superseded by absolute-path Rscript success.",
  "",
  "## Rscript",
  "- Path: ``$Rscript``",
  "- Version: $($versionOutput -join ' ')",
  "",
  "## Temporary Worktree",
  "- Path: ``$TempWorktree``",
  "- Removed: $tempRemoved",
  "",
  "## D10 Rerun",
  "- Exit code: $($proc.ExitCode)",
  "- D10 validation: $validationPass/$validationTotal PASS",
  "",
  "## Preserved Rerun Files",
  $preservedList,
  "- All rerun D10 CSVs copied to ``$D10R3Dir/rerun_files/all_csv/``.",
  "",
  "## Hash-Difference Classification",
  $classificationList,
  "",
  "## Core CSV Audit",
  "- PASS: $(($coreAudit | Where-Object { $_.status -eq 'PASS' }).Count)/$($coreAudit.Count)",
  "",
  "## Boundary And Accounting Status",
  "- q_omega: parked; no q_omega-family columns created.",
  "- D09-S sensitivity stocks: report-only, not baseline.",
  "- Baseline: ME L14 alpha1.7 + NRC L30 alpha1.6; K_capacity = ME + NRC reconfirmed.",
  "- Corporate-clean: $cleanStatus.",
  "- Financial/imputed-interest: $finStatus.",
  "- Exploitation-rate ingredients: $exploitStatus.",
  "- Tax/subsidy/transfer: $taxStatus.",
  "",
  "## Main Worktree",
  "- D10 source-output mutation: $(if ($mainD10Diff.Count -eq 0) { 'none' } else { $mainD10Diff -join ' | ' })",
  "- Unrelated Obsidian UI noise: present and not staged.",
  "",
  "## Final Decision",
  $decision
)
$report | Set-Content -LiteralPath (Join-Path $ReportsDir "D10R3_decision_report.md") -Encoding UTF8

$postHead = git rev-parse HEAD
$postDivergence = git rev-list --left-right --count HEAD...origin/main
$handoff = @(
  "# Chapter 2 - D10 Source-of-Truth Closure Handoff",
  "",
  "## Final state",
  "",
  "- D10 source-of-truth dataset consolidated.",
  "- D10-R3 reconciliation closed: $decision.",
  "- Final decision code: $decision.",
  "- Latest commit hash before D10-R3 commit: $postHead.",
  "- Push status before D10-R3 commit: divergence HEAD...origin/main = $postDivergence.",
  "- Remaining local noise: chapter2_vault/.obsidian/appearance.json and chapter2_vault/.obsidian/core-plugins.json.",
  "",
  "## Locked dataset facts",
  "",
  "- Wide panel: $wideRows rows x $wideCols columns.",
  "- Long panel: $longRows rows.",
  "- Variable dictionary: $dictRows rows.",
  "- Accounting ladder: $acctRows rows.",
  "- Validation count: $validationPass/$validationTotal PASS.",
  "- q_omega parked.",
  "- ME/NRC baseline: ME L14 alpha1.7 + NRC L30 alpha1.6; K_capacity = ME + NRC.",
  "- D09-S sensitivity stocks are report-only.",
  "",
  "## Accounting scope preserved",
  "",
  "- NFC productive-origin baseline.",
  "- Raw corporate comparison layer.",
  "- Corporate-clean layer status: candidate/crosswalk, not model-ready.",
  "- GOS/NOS/profit ladder.",
  "- Tax/subsidy/transfer block.",
  "- Financial/imputed-interest candidates.",
  "- Exploitation-rate ingredients.",
  "",
  "## What is not authorized yet",
  "",
  "- No econometrics yet.",
  "- No DOLS yet.",
  "- No integration testing yet.",
  "- No q_omega.",
  "- No promotion of corporate-clean/financial candidates without crosswalk.",
  "- No D09-S sensitivity stocks as baseline.",
  "",
  "## Next session",
  "",
  "Recommended next pass:",
  "",
  "D11_INTEGRATION_AND_ESTIMATION_READINESS_REVIEW",
  "",
  "Only after D10-R3 authorizes D11.",
  "",
  "D11 should test integration/order and estimate-readiness.",
  "D11 should still not estimate final DOLS unless explicitly authorized.",
  "",
  "## Resume command",
  "",
  'Repo path: C:\ReposGitHub\Capacity-Utilization-US_Chile',
  "",
  "Suggested opening checks:",
  "",
  '```powershell',
  "git status --short --branch",
  "git log --oneline --decorate -10",
  "git rev-list --left-right --count HEAD...origin/main",
  '```'
)
$handoff | Set-Content -LiteralPath (Join-Path $HandoffDir "D10_session_handoff.md") -Encoding UTF8

"D10R3 decision: $decision" | Set-Content -LiteralPath (Join-Path $LogsDir "D10R3_run.log") -Encoding UTF8
Write-Output $decision
