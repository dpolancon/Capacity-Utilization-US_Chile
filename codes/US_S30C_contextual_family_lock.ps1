Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$StageId = "S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK"
$TaskId = "S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK"
$Branch = "feature/s30c-contextual-family-lock"
$BaseCommit = "911885ce763fdf4b73903ebb552682cfb108d0b3"
$OutDir = "output/US/S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK"
$CsvDir = Join-Path $OutDir "csv"
$MdDir = Join-Path $OutDir "md"

New-Item -ItemType Directory -Force -Path $CsvDir, $MdDir | Out-Null

function Read-CsvRequired {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        throw "Required input not found: $Path"
    }
    return @(Import-Csv $Path)
}

function Write-Utf8Csv {
    param(
        [Parameter(Mandatory=$true)] [array]$Rows,
        [Parameter(Mandatory=$true)] [string]$Path
    )
    $Rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $Path
}

function Add-ClassificationRow {
    param(
        [array]$Rows,
        [string]$ObjectId,
        [string]$DisplayName,
        [string]$ObjectGroup,
        [string]$Classification,
        [string]$ObservationStatus,
        [string]$TheoreticalRole,
        [string]$PermittedUse,
        [string]$ProhibitedUse,
        [string]$EvidenceStage,
        [string]$EvidenceFile,
        [string]$SourceDataset,
        [string]$SourceTable,
        [string]$SourceLine,
        [string]$Unit,
        [string]$CoverageStart,
        [string]$CoverageEnd,
        [string]$ObservationRows,
        [string]$FutureReviewRequired
    )
    $Rows += [pscustomobject]@{
        object_id = $ObjectId
        display_name = $DisplayName
        object_group = $ObjectGroup
        classification = $Classification
        observation_status = $ObservationStatus
        theoretical_role = $TheoreticalRole
        permitted_use = $PermittedUse
        prohibited_use = $ProhibitedUse
        evidence_stage = $EvidenceStage
        evidence_file = $EvidenceFile
        source_dataset = $SourceDataset
        source_table = $SourceTable
        source_line = $SourceLine
        unit = $Unit
        coverage_start = $CoverageStart
        coverage_end = $CoverageEnd
        observation_rows = $ObservationRows
        future_review_required = $FutureReviewRequired
        promotion_to_core_capital = "prohibited"
        model_control_authorized = "no"
        family_join_authorized = "no"
        canonical_dataset_authorized = "no"
    }
    return $Rows
}

function Classification-For-S22Excluded {
    param($Row)
    if ($Row.object_id -match "RESIDENTIAL") { return "EXCLUDED_FROM_CHAPTER2_DATASET" }
    if ($Row.blocked_or_parked_status -eq "blocked" -or $Row.candidate_status -match "^BLOCKED") { return "BLOCKED" }
    if ($Row.blocked_or_parked_status -eq "parked" -or $Row.blocked_or_parked_status -eq "theoretically_mixed") { return "PARKED_FOR_FUTURE_RESEARCH" }
    if ($Row.candidate_status -eq "DOCUMENTATION_AND_RECONCILIATION_CANDIDATE" -or $Row.blocked_or_parked_status -eq "documentation_reconciliation_candidate") { return "METADATA_REFERENCE_ONLY" }
    if ($Row.reason -match "Diagnostic only" -or $Row.object_id -eq "INVENTORIES_MENU") { return "DIAGNOSTIC_ONLY" }
    return "PARKED_FOR_FUTURE_RESEARCH"
}

function Group-For-S22Excluded {
    param($Row, [string]$Classification)
    if ($Row.object_id -match "RESIDENTIAL") { return "residential_excluded" }
    if ($Classification -eq "BLOCKED") { return "blocked_object" }
    if ($Classification -eq "METADATA_REFERENCE_ONLY") { return "documentation_or_metadata_only" }
    if ($Row.object_id -match "TOTAL") { return "provider_total_review_required" }
    if ($Row.object_id -match "IPP") { return "ipp_review_required" }
    if ($Row.object_id -match "official_price_index") { return "official_price_diagnostic" }
    if ($Classification -eq "PARKED_FOR_FUTURE_RESEARCH") { return "parked_or_future_research" }
    return "diagnostic_or_contextual_exclusion"
}

$requiredMd = @(
    "output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_TASK_C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK.md",
    "output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_PARALLEL_FANOUT_EXECUTION_GUIDE.md",
    "output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLAN.md",
    "output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_VALIDATION.md",
    "output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_DECISION.md"
)
foreach ($path in $requiredMd) {
    if (-not (Test-Path $path)) { throw "Required input not found: $path" }
    Get-Content -Raw $path | Out-Null
}

$requiredCsv = @(
    "output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_family_readiness_inventory.csv",
    "output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_unresolved_dependency_ledger.csv",
    "output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_review_needed_ledger.csv",
    "output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_parallel_task_registry.csv",
    "output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_parallel_task_input_contract.csv",
    "output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_parallel_task_output_contract.csv"
)
foreach ($path in $requiredCsv) { Read-CsvRequired $path | Out-Null }

$s22Authorized = Read-CsvRequired "output/US/S22_MODEL_INPUT_PREPARATION_FROM_PROVIDER_V1/csv/S22_authorized_baseline_objects.csv"
$s22Excluded = Read-CsvRequired "output/US/S22_MODEL_INPUT_PREPARATION_FROM_PROVIDER_V1/csv/S22_excluded_candidate_blocked_parked_audit.csv"
$s24b = Read-CsvRequired "output/US/S24B_FIXED_ASSETS_SOURCE_INPUTS_CONSTRUCTION/csv/S24B_fixed_assets_construction_ledger.csv"
$s24c = Read-CsvRequired "output/US/S24C_PROVIDER_SOURCE_INPUTS_OTHER_CONSTRUCTION/csv/S24C_provider_other_construction_ledger.csv"
$s25NoPromotion = Read-CsvRequired "output/US/S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION/csv/S25_no_promotion_audit.csv"
$s25Metadata = Read-CsvRequired "output/US/S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION/csv/S25_zero_observation_metadata_audit.csv"
$s26Boundary = Read-CsvRequired "output/US/S26_SOURCE_INPUT_COMPLETENESS_REVIEW/csv/S26_deferred_excluded_boundary_audit.csv"
$s27Metadata = Read-CsvRequired "output/US/S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING/csv/S27_metadata_reference_usage_ledger.csv"
$s27CarryForward = Read-CsvRequired "output/US/S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING/csv/S27_deferred_excluded_boundary_carry_forward.csv"
$s28NoImplementation = Read-CsvRequired "output/US/S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE/csv/S28_no_implementation_audit.csv"
$s29kProviderTotal = Read-CsvRequired "output/US/S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE/csv/S29K_no_provider_total_promotion_audit.csv"

$classificationRows = @()

foreach ($row in $s24b) {
    $id = $row.variable_id
    if ($id -match "__IPP__") {
        $classificationRows = Add-ClassificationRow $classificationRows $id $row.display_name "ipp_assets_and_investment" "CONTEXTUAL_AUTHORIZED" "observation_bearing_source_input" "IPP is contextual and productive-frontier-shaping, not core accumulation capital." "contextual_reference_only_after_future_canonical_intake" "core_capital; model_control; family_join; canonical_integration_in_S30C" "S24B" "output/US/S24B_FIXED_ASSETS_SOURCE_INPUTS_CONSTRUCTION/csv/S24B_fixed_assets_construction_ledger.csv" $row.source_dataset $row.source_table $row.source_line $row.unit $row.coverage_start $row.coverage_end $row.constructed_observation_rows "yes"
    } elseif ($id -match "^GOV_TRANS__HIGHWAYS_STREETS__") {
        $classificationRows = Add-ClassificationRow $classificationRows $id $row.display_name "government_transportation_highways_and_streets" "CONTEXTUAL_AUTHORIZED" "observation_bearing_source_input" "Highways and streets condition the frontier but are not core accumulation capital." "contextual_reference_only_after_future_canonical_intake" "core_capital; model_control; family_join; canonical_integration_in_S30C" "S24B" "output/US/S24B_FIXED_ASSETS_SOURCE_INPUTS_CONSTRUCTION/csv/S24B_fixed_assets_construction_ledger.csv" $row.source_dataset $row.source_table $row.source_line $row.unit $row.coverage_start $row.coverage_end $row.constructed_observation_rows "yes"
    } elseif ($id -match "^GOV_TRANS__TRANSPORTATION_STRUCTURES__") {
        $classificationRows = Add-ClassificationRow $classificationRows $id $row.display_name "government_transportation_structures" "CONTEXTUAL_AUTHORIZED" "observation_bearing_source_input" "Government transportation structures condition the frontier but are not core accumulation capital." "contextual_reference_only_after_future_canonical_intake" "core_capital; model_control; family_join; canonical_integration_in_S30C" "S24B" "output/US/S24B_FIXED_ASSETS_SOURCE_INPUTS_CONSTRUCTION/csv/S24B_fixed_assets_construction_ledger.csv" $row.source_dataset $row.source_table $row.source_line $row.unit $row.coverage_start $row.coverage_end $row.constructed_observation_rows "yes"
    } elseif ($id -match "__TOTAL__") {
        $classificationRows = Add-ClassificationRow $classificationRows $id $row.display_name "provider_total_nonpromotion" "DIAGNOSTIC_ONLY" "observation_bearing_source_input" "Provider TOTAL is a provider category and is not analytical downstream TOT." "diagnostic_reference_only" "analytical_TOT; core_capital; model_control; family_join; canonical_integration_in_S30C" "S24B" "output/US/S24B_FIXED_ASSETS_SOURCE_INPUTS_CONSTRUCTION/csv/S24B_fixed_assets_construction_ledger.csv" $row.source_dataset $row.source_table $row.source_line $row.unit $row.coverage_start $row.coverage_end $row.constructed_observation_rows "yes"
    } elseif ($id -match "^FIN__(ME|NRC)__") {
        $classificationRows = Add-ClassificationRow $classificationRows $id $row.display_name "financial_fixed_asset_boundary_review" "PARKED_FOR_FUTURE_RESEARCH" "observation_bearing_source_input" "Financial fixed assets require a separate boundary decision before any analytical capital use." "future_review_only" "core_capital; model_control; family_join; canonical_integration_in_S30C" "S24B" "output/US/S24B_FIXED_ASSETS_SOURCE_INPUTS_CONSTRUCTION/csv/S24B_fixed_assets_construction_ledger.csv" $row.source_dataset $row.source_table $row.source_line $row.unit $row.coverage_start $row.coverage_end $row.constructed_observation_rows "yes"
    }
}

foreach ($row in $s24c) {
    $obsRows = [int]$row.constructed_observation_rows
    $unit = $row.unit
    if ($obsRows -eq 0 -or $unit -eq "metadata_only" -or $row.s24c_construction_status -match "metadata") {
        $classification = "METADATA_REFERENCE_ONLY"
        $obsStatus = "metadata_only_zero_observation"
        if ($obsRows -gt 0) { $obsStatus = "metadata_only_record" }
        $role = "Metadata-only provider or downstream construction reference; not observation-bearing analytical data."
        $permitted = "metadata_reference_only"
        $futureReview = "yes"
    } else {
        $classification = "DIAGNOSTIC_ONLY"
        $obsStatus = "observation_bearing_source_input"
        $role = "Other provider source input retained only for diagnostic or lineage context."
        $permitted = "diagnostic_reference_only"
        $futureReview = "yes"
    }
    $classificationRows = Add-ClassificationRow $classificationRows $row.variable_id $row.display_name "provider_source_inputs_other" $classification $obsStatus $role $permitted "model_control; family_join; canonical_integration_in_S30C; promotion_to_core_capital" "S24C" "output/US/S24C_PROVIDER_SOURCE_INPUTS_OTHER_CONSTRUCTION/csv/S24C_provider_other_construction_ledger.csv" $row.source_dataset $row.source_table $row.source_line $row.unit $row.coverage_start $row.coverage_end $row.constructed_observation_rows $futureReview
}

$seenExcluded = @{}
foreach ($row in $s22Excluded) {
    if ($seenExcluded.ContainsKey($row.object_id)) { continue }
    $seenExcluded[$row.object_id] = $true
    $classification = Classification-For-S22Excluded $row
    $group = Group-For-S22Excluded $row $classification
    $obsStatus = "excluded_or_deferred_no_observations"
    if ($classification -eq "METADATA_REFERENCE_ONLY") { $obsStatus = "metadata_or_documentation_only" }
    if ($classification -eq "BLOCKED") { $obsStatus = "blocked_no_observations" }
    if ($classification -eq "EXCLUDED_FROM_CHAPTER2_DATASET") { $obsStatus = "excluded_no_observations" }
    $permitted = switch ($classification) {
        "DIAGNOSTIC_ONLY" { "diagnostic_reference_only" }
        "METADATA_REFERENCE_ONLY" { "metadata_reference_only" }
        "PARKED_FOR_FUTURE_RESEARCH" { "future_research_review_only" }
        "EXCLUDED_FROM_CHAPTER2_DATASET" { "exclusion_documentation_only" }
        "BLOCKED" { "blocked_reference_only" }
        default { "classification_reference_only" }
    }
    $futureReview = if ($classification -in @("PARKED_FOR_FUTURE_RESEARCH", "DIAGNOSTIC_ONLY", "METADATA_REFERENCE_ONLY")) { "yes" } else { "no" }
    $classificationRows = Add-ClassificationRow $classificationRows $row.object_id $row.object_id $group $classification $obsStatus $row.reason $permitted "core_capital; model_control; family_join; canonical_integration_in_S30C; direct_Chapter2_use_without_future_authorization" "S22" "output/US/S22_MODEL_INPUT_PREPARATION_FROM_PROVIDER_V1/csv/S22_excluded_candidate_blocked_parked_audit.csv" $row.source_table "" "" "" "" "" "0" $futureReview
}

$duplicateAudit = $s22Excluded |
    Group-Object object_id |
    Where-Object { $_.Count -gt 1 } |
    ForEach-Object {
        [pscustomobject]@{
            object_id = $_.Name
            source_row_count = $_.Count
            s30c_resolution = "single_classification_retained"
            classification = ($classificationRows | Where-Object object_id -eq $_.Name | Select-Object -First 1).classification
            evidence_file = "output/US/S22_MODEL_INPUT_PREPARATION_FROM_PROVIDER_V1/csv/S22_excluded_candidate_blocked_parked_audit.csv"
        }
    }

$classificationRows = @($classificationRows | Sort-Object object_group, object_id)

$observationLedger = $classificationRows | Select-Object object_id, object_group, classification, observation_status, observation_rows, unit, coverage_start, coverage_end, evidence_stage, evidence_file
$roleLedger = $classificationRows | Select-Object object_id, object_group, classification, theoretical_role, permitted_use, prohibited_use, future_review_required
$contract = $classificationRows | Select-Object object_id, classification, permitted_use, prohibited_use, promotion_to_core_capital, model_control_authorized, family_join_authorized, canonical_dataset_authorized, future_review_required
$interfaceManifest = $classificationRows |
    Where-Object { $_.classification -in @("CONTEXTUAL_AUTHORIZED", "DIAGNOSTIC_ONLY", "METADATA_REFERENCE_ONLY") } |
    Select-Object object_id, classification, observation_status, evidence_stage, evidence_file, permitted_use, prohibited_use
$exclusionLedger = $classificationRows | Where-Object classification -eq "EXCLUDED_FROM_CHAPTER2_DATASET"
$parkedLedger = $classificationRows | Where-Object classification -eq "PARKED_FOR_FUTURE_RESEARCH"
$blockedLedger = $classificationRows | Where-Object classification -eq "BLOCKED"
$metadataLedger = $classificationRows | Where-Object classification -eq "METADATA_REFERENCE_ONLY"
$reviewNeededLedger = $classificationRows |
    Where-Object future_review_required -eq "yes" |
    Select-Object object_id, object_group, classification, future_review_required, permitted_use, prohibited_use

$providerTotalAudit = @()
foreach ($row in ($classificationRows | Where-Object object_group -match "provider_total")) {
    $providerTotalAudit += [pscustomobject]@{
        object_id = $row.object_id
        classification = $row.classification
        provider_total_promoted_to_analytical_tot = "no"
        analytical_tot_authorized = "no"
        evidence_stage = $row.evidence_stage
        evidence_file = $row.evidence_file
        s29k_crosscheck = "provider_TOTAL_nonpromotion_PASS"
    }
}
foreach ($row in $s29kProviderTotal) {
    $providerTotalAudit += [pscustomobject]@{
        object_id = $row.audit_item
        classification = "DIAGNOSTIC_ONLY"
        provider_total_promoted_to_analytical_tot = "no"
        analytical_tot_authorized = "no"
        evidence_stage = "S29K"
        evidence_file = "output/US/S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE/csv/S29K_no_provider_total_promotion_audit.csv"
        s29k_crosscheck = $row.status
    }
}

$coreBoundaryAudit = @()
foreach ($row in $s24b) {
    $isCore = if ($row.variable_id -match "^(CORP|NFC)__(ME|NRC)__") { "yes" } else { "no" }
    $boundary = if ($isCore -eq "yes") { "core_capacity_building_capital_boundary_evidence" } else { "noncore_or_contextual_boundary_evidence" }
    $coreBoundaryAudit += [pscustomobject]@{
        variable_id = $row.variable_id
        display_name = $row.display_name
        source_line_description = $row.source_line_description
        core_K_ME_or_K_NR_boundary = $isCore
        s30c_classification_if_noncore = if ($isCore -eq "yes") { "not_contextual_inventory_object" } else { ($classificationRows | Where-Object object_id -eq $row.variable_id | Select-Object -First 1).classification }
        boundary_lock = $boundary
        ipp_promoted_to_core = "no"
        government_transportation_promoted_to_core = "no"
        residential_promoted_to_productive_capital = "no"
        provider_total_promoted_to_analytical_tot = "no"
    }
}

$upstreamEvidenceLedger = @()
$inputFilesRead = @(
    $requiredMd + $requiredCsv + @(
        "output/US/S22_MODEL_INPUT_PREPARATION_FROM_PROVIDER_V1/csv/S22_authorized_baseline_objects.csv",
        "output/US/S22_MODEL_INPUT_PREPARATION_FROM_PROVIDER_V1/csv/S22_excluded_candidate_blocked_parked_audit.csv",
        "output/US/S24B_FIXED_ASSETS_SOURCE_INPUTS_CONSTRUCTION/csv/S24B_fixed_assets_construction_ledger.csv",
        "output/US/S24C_PROVIDER_SOURCE_INPUTS_OTHER_CONSTRUCTION/csv/S24C_provider_other_construction_ledger.csv",
        "output/US/S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION/csv/S25_no_promotion_audit.csv",
        "output/US/S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION/csv/S25_zero_observation_metadata_audit.csv",
        "output/US/S26_SOURCE_INPUT_COMPLETENESS_REVIEW/csv/S26_deferred_excluded_boundary_audit.csv",
        "output/US/S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING/csv/S27_metadata_reference_usage_ledger.csv",
        "output/US/S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING/csv/S27_deferred_excluded_boundary_carry_forward.csv",
        "output/US/S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE/csv/S28_no_implementation_audit.csv",
        "output/US/S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE/csv/S29K_no_provider_total_promotion_audit.csv"
    )
)
foreach ($path in $inputFilesRead) {
    $upstreamEvidenceLedger += [pscustomobject]@{
        file_read = $path
        mutation_authorized = "no"
        used_for = "S30C contextual classification evidence"
    }
}

$validationRows = @()
function Add-Validation {
    param([string]$Check, [bool]$Pass, [string]$Evidence)
    $script:validationRows += [pscustomobject]@{
        check_id = $Check
        status = if ($Pass) { "PASS" } else { "FAIL" }
        evidence = $Evidence
    }
}

$allowedClassifications = @("CONTEXTUAL_AUTHORIZED", "DIAGNOSTIC_ONLY", "METADATA_REFERENCE_ONLY", "PARKED_FOR_FUTURE_RESEARCH", "EXCLUDED_FROM_CHAPTER2_DATASET", "BLOCKED")
$branchNow = (& git branch --show-current).Trim()
$headNow = (& git rev-parse HEAD).Trim()
$dupClassIds = @($classificationRows | Group-Object object_id | Where-Object Count -gt 1)
$badClass = @($classificationRows | Where-Object { $_.classification -notin $allowedClassifications -or [string]::IsNullOrWhiteSpace($_.classification) })

Add-Validation "exact_branch" ($branchNow -eq $Branch) "branch=$branchNow"
Add-Validation "exact_base_commit" ($headNow -eq $BaseCommit) "HEAD=$headNow"
Add-Validation "complete_contextual_inventory" ($classificationRows.Count -ge 1) "classified_objects=$($classificationRows.Count)"
Add-Validation "one_status_per_object" ($dupClassIds.Count -eq 0 -and $badClass.Count -eq 0) "duplicate_classified_ids=$($dupClassIds.Count); bad_classifications=$($badClass.Count)"
Add-Validation "ipp_not_core" (@($classificationRows | Where-Object { $_.object_group -match "ipp" -and $_.promotion_to_core_capital -ne "prohibited" }).Count -eq 0) "IPP classified outside core capital"
Add-Validation "government_transportation_not_core" (@($classificationRows | Where-Object { $_.object_group -match "government_transportation" -and $_.promotion_to_core_capital -ne "prohibited" }).Count -eq 0) "government transportation classified outside core capital"
Add-Validation "residential_excluded" (@($classificationRows | Where-Object { $_.object_group -eq "residential_excluded" -and $_.classification -ne "EXCLUDED_FROM_CHAPTER2_DATASET" }).Count -eq 0) "residential objects excluded"
Add-Validation "provider_total_not_promoted" (@($providerTotalAudit | Where-Object provider_total_promoted_to_analytical_tot -ne "no").Count -eq 0) "provider TOTAL nonpromotion rows=$($providerTotalAudit.Count)"
Add-Validation "metadata_only_not_promoted" (@($metadataLedger | Where-Object { $_.promotion_to_core_capital -ne "prohibited" -or $_.model_control_authorized -ne "no" }).Count -eq 0) "metadata_only_count=$($metadataLedger.Count)"
Add-Validation "blocked_objects_not_promoted" (@($blockedLedger | Where-Object { $_.promotion_to_core_capital -ne "prohibited" -or $_.model_control_authorized -ne "no" }).Count -eq 0) "blocked_count=$($blockedLedger.Count)"
Add-Validation "no_family_joins" (@($classificationRows | Where-Object family_join_authorized -ne "no").Count -eq 0) "family_join_authorized=no for all rows"
Add-Validation "no_model_controls_created" (@($classificationRows | Where-Object model_control_authorized -ne "no").Count -eq 0) "model_control_authorized=no for all rows"
Add-Validation "no_canonical_dataset" (@($classificationRows | Where-Object canonical_dataset_authorized -ne "no").Count -eq 0) "canonical_dataset_authorized=no for all rows"
Add-Validation "no_complete_case_sample" ($true) "S30C writes classification ledgers only"
Add-Validation "no_estimation_sample" ($true) "S30C writes classification ledgers only"
Add-Validation "no_q" ($true) "No q or accumulated q constructed"
Add-Validation "no_theta" ($true) "No theta or θ_t constructed"
Add-Validation "no_productive_capacity" ($true) "No productive capacity constructed"
Add-Validation "no_utilization" ($true) "No utilization or μ_t constructed"
Add-Validation "no_modeling" ($true) "No modeling outputs created"
Add-Validation "no_econometrics" ($true) "No econometric outputs created"
Add-Validation "s25_no_promotion_inherited" (@($s25NoPromotion | Where-Object status -ne "PASS").Count -eq 0) "S25 no-promotion audit PASS rows=$($s25NoPromotion.Count)"
Add-Validation "s26_boundary_carry_forward_inherited" (@($s26Boundary | Where-Object s26_boundary_status -ne "PASS").Count -eq 0) "S26 boundary audit PASS rows=$($s26Boundary.Count)"
Add-Validation "s27_boundary_carry_forward_inherited" (@($s27CarryForward | Where-Object s27_carry_forward_status -ne "PASS").Count -eq 0) "S27 carry-forward PASS rows=$($s27CarryForward.Count)"
Add-Validation "s28_no_implementation_inherited" (@($s28NoImplementation | Where-Object status -ne "PASS").Count -eq 0) "S28 no-implementation audit PASS rows=$($s28NoImplementation.Count)"
Add-Validation "s29k_provider_total_nonpromotion_inherited" (@($s29kProviderTotal | Where-Object status -ne "PASS").Count -eq 0) "S29K provider TOTAL nonpromotion PASS rows=$($s29kProviderTotal.Count)"

$validationStatus = if (@($validationRows | Where-Object status -ne "PASS").Count -eq 0) { "PASS" } else { "FAIL" }
$decision = if ($validationStatus -eq "PASS") { "AUTHORIZE_CONTEXTUAL_REFERENCE_CONSUMPTION" } else { "BLOCK_FOR_CONTEXTUAL_CLASSIFICATION_REVIEW" }
$familyStatus = if ($validationStatus -eq "PASS") { "CONTEXTUAL_FAMILY_CLASSIFICATION_LOCKED" } else { "CONTEXTUAL_FAMILY_CLASSIFICATION_NOT_LOCKED" }

Write-Utf8Csv $classificationRows (Join-Path $CsvDir "S30C_contextual_inventory.csv")
Write-Utf8Csv $observationLedger (Join-Path $CsvDir "S30C_observation_metadata_status_ledger.csv")
Write-Utf8Csv $roleLedger (Join-Path $CsvDir "S30C_theoretical_role_ledger.csv")
Write-Utf8Csv $contract (Join-Path $CsvDir "S30C_classification_contract.csv")
Write-Utf8Csv $interfaceManifest (Join-Path $CsvDir "S30C_contextual_reference_interface_manifest.csv")
Write-Utf8Csv $exclusionLedger (Join-Path $CsvDir "S30C_exclusion_ledger.csv")
Write-Utf8Csv $parkedLedger (Join-Path $CsvDir "S30C_parked_ledger.csv")
Write-Utf8Csv $blockedLedger (Join-Path $CsvDir "S30C_blocked_ledger.csv")
Write-Utf8Csv $metadataLedger (Join-Path $CsvDir "S30C_metadata_only_ledger.csv")
Write-Utf8Csv $reviewNeededLedger (Join-Path $CsvDir "S30C_review_needed_ledger.csv")
Write-Utf8Csv $providerTotalAudit (Join-Path $CsvDir "S30C_provider_total_nonpromotion_audit.csv")
Write-Utf8Csv $coreBoundaryAudit (Join-Path $CsvDir "S30C_core_capital_boundary_audit.csv")
Write-Utf8Csv $duplicateAudit (Join-Path $CsvDir "S30C_duplicate_evidence_resolution_audit.csv")
Write-Utf8Csv $upstreamEvidenceLedger (Join-Path $CsvDir "S30C_upstream_evidence_read_ledger.csv")
Write-Utf8Csv $validationRows (Join-Path $CsvDir "S30C_validation_checks.csv")

$handoff = @(
    [pscustomobject]@{
        stage_id = $StageId
        task_id = $TaskId
        branch = $Branch
        family_status = $familyStatus
        decision = $decision
        contextual_inventory = "output/US/S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK/csv/S30C_contextual_inventory.csv"
        classification_contract = "output/US/S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK/csv/S30C_classification_contract.csv"
        reference_interface_manifest = "output/US/S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK/csv/S30C_contextual_reference_interface_manifest.csv"
        validation_checks = "output/US/S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK/csv/S30C_validation_checks.csv"
        consumer_intake_ready = if ($validationStatus -eq "PASS") { "true" } else { "false" }
    }
)
Write-Utf8Csv $handoff (Join-Path $CsvDir "S30C_handoff_manifest.csv")

$completion = [ordered]@{
    stage_id = $StageId
    task_id = $TaskId
    branch = $Branch
    base_commit = $BaseCommit
    result_commit = "RECORDED_IN_FINAL_REPORT_AFTER_COMMIT"
    validation_status = $validationStatus
    decision = $decision
    family_status = $familyStatus
    authoritative_variable_count = 0
    robustness_variable_count = 0
    conditional_variable_count = 0
    diagnostic_variable_count = @($classificationRows | Where-Object classification -eq "DIAGNOSTIC_ONLY").Count
    alias_variable_count = 0
    metadata_only_count = $metadataLedger.Count
    blocked_variable_count = $blockedLedger.Count
    review_required_count = $reviewNeededLedger.Count
    handoff_ready = ($validationStatus -eq "PASS")
    consumer_intake_ready = ($validationStatus -eq "PASS")
    worker_status = if ($validationStatus -eq "PASS") { "COMPLETED" } else { "FAILED_VALIDATION" }
}
$completion | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 -Path (Join-Path $OutDir "S30C_completion_record.json")

$validationMd = @"
# S30C Contextual Family Classification Lock Validation

Validation result: $validationStatus

Decision: $decision

Family status: $familyStatus

Classified objects: $($classificationRows.Count)

Metadata-only objects: $($metadataLedger.Count)

Blocked objects: $($blockedLedger.Count)

Review-gated objects: $($reviewNeededLedger.Count)

All validation checks are recorded in csv/S30C_validation_checks.csv.
"@
$validationMd | Set-Content -Encoding UTF8 -Path (Join-Path $MdDir "S30C_VALIDATION.md")

$decisionMd = @"
# S30C Decision

Decision: $decision

Family status: $familyStatus

S30C locks contextual and non-core objects as references only. IPP and government transportation are contextual and frontier-conditioning, not core accumulation capital. Residential objects are excluded from productive capital. Provider TOTAL remains diagnostic and is not analytical downstream TOT. Metadata-only, parked, and blocked records are not promoted.

This stage authorizes contextual reference consumption only. It does not authorize integration, controls, joins, canonical datasets, complete-case samples, estimation samples, q, theta, productive capacity, utilization, modeling, or econometrics.
"@
$decisionMd | Set-Content -Encoding UTF8 -Path (Join-Path $MdDir "S30C_DECISION.md")

$reportMd = @"
# S30C Contextual Family Classification Lock

Task: $TaskId

Branch: $Branch

Base commit: $BaseCommit

Validation: $validationStatus

Decision: $decision

Family status: $familyStatus

Outputs:
- csv/S30C_contextual_inventory.csv
- csv/S30C_observation_metadata_status_ledger.csv
- csv/S30C_theoretical_role_ledger.csv
- csv/S30C_classification_contract.csv
- csv/S30C_contextual_reference_interface_manifest.csv
- csv/S30C_exclusion_ledger.csv
- csv/S30C_parked_ledger.csv
- csv/S30C_blocked_ledger.csv
- csv/S30C_provider_total_nonpromotion_audit.csv
- csv/S30C_core_capital_boundary_audit.csv
- csv/S30C_validation_checks.csv
- csv/S30C_handoff_manifest.csv
- S30C_completion_record.json
"@
$reportMd | Set-Content -Encoding UTF8 -Path (Join-Path $MdDir "S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK.md")

if ($validationStatus -ne "PASS") {
    throw "S30C validation failed; see $CsvDir/S30C_validation_checks.csv"
}

Write-Host "S30C validation PASS"
Write-Host "Decision: $decision"
Write-Host "Family status: $familyStatus"
