$audit = Import-Csv 'c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_explorer_m1_3\full_md_audit.csv'

$proposedList = @()

foreach ($item in $audit) {
    $p = $item.Path
    $pClean = $p -replace '^C:\\ReposGitHub\\Capacity-Utilization-US_Chile\\', ''
    $pClean = $pClean -replace '^c:\\ReposGitHub\\Capacity-Utilization-US_Chile\\', ''
    
    $folder = ($pClean -split '\\')[0]
    $subfolder = if (($pClean -split '\\').Count -gt 1) { ($pClean -split '\\')[1] } else { "" }
    $filename = Split-Path -Leaf $pClean

    # Determine proposed type
    $type = "report"
    $status = "active"
    $stage = "none"
    $country = "none"
    $dependsOn = "[]"
    $lastUpdated = if ($item.ExistingLastUpdated -and $item.ExistingLastUpdated -ne "") { $item.ExistingLastUpdated } else { $item.LastWriteTime }

    # Country heuristic
    if ($pClean -match '\\US\\' -or $filename -match '^US_' -or $filename -match '^us_' -or $filename -match '_US\.md$' -or $filename -match '_US_') {
        $country = "US"
    } elseif ($pClean -match '\\CL\\' -or $pClean -match '\\Chile\\' -or $filename -match '^CL_' -or $filename -match '^chile_' -or $filename -match '_Chile\.md$' -or $filename -match 'chile') {
        $country = "CL"
    } elseif ($folder -eq "chapter2_vault" -or $folder -eq "output") {
        # Check if comparative or general
        if ($filename -match 'Chile' -and $filename -match 'US') {
            $country = "US_CL"
        }
    }

    # Folder & Subfolder specific rules
    if ($folder -eq "AGENTS.md" -or $folder -eq "CLAUDE.md" -or $folder -eq "PROJECT.md") {
        $type = "system_rules"
        $status = "active"
        $stage = "all_stages"
        $country = "US_CL"
        $dependsOn = "[chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]"
    } elseif ($folder -eq "README.md") {
        $type = "readme"
        $status = "active"
        $stage = "all_stages"
        $country = "US_CL"
        $dependsOn = "[]"
    } elseif ($folder -eq "chapter2_vault") {
        $country = if ($country -eq "none") { "US_CL" } else { $country }
        switch ($subfolder) {
            "00_constitutive_core" {
                $type = "constitutional_core"
                $status = "active"
                $stage = "S00"
                $dependsOn = "[chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md]"
            }
            "01_contradictory_utilization_configurations" {
                $type = "analytical_foundation"
                $status = "active"
                $stage = "S00"
                $dependsOn = "[chapter2_vault/00_constitutive_core/01_Governing_Memo.md]"
            }
            "02_analyitical_foundation" {
                $type = "theoretical_foundation"
                $status = "active"
                $stage = "S00"
                $dependsOn = "[chapter2_vault/00_constitutive_core/01_Governing_Memo.md]"
            }
            "03_econometrics" {
                $type = "econometric_protocol"
                $status = if ($filename -match '^R10' -or $filename -match 'superseded') { "superseded" } else { "active" }
                if ($filename -match 'S10') { $stage = "S10" }
                elseif ($filename -match 'S20') { $stage = "S20" }
                elseif ($filename -match 'S30') { $stage = "S30" }
                elseif ($filename -match 'S40') { $stage = "S40" }
                else { $stage = "all_stages" }
                $dependsOn = "[chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]"
            }
            "04_data_measurement" {
                $type = "data_measurement"
                $status = "active"
                $stage = "S10"
                $dependsOn = "[chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md]"
            }
            "05_codes_implementation" {
                $type = "code_implementation_memo"
                $status = "active"
                if ($filename -match 'S10') { $stage = "S10" }
                elseif ($filename -match 'S30') { $stage = "S30" }
                elseif ($filename -match 'S40') { $stage = "S40" }
                else { $stage = "all_stages" }
                $dependsOn = "[chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md]"
            }
            "06_paper_facing" {
                $type = if ($filename -match 'Constitution') { "constitutional_claim" } elseif ($filename -match 'Outline') { "paper_facing_outline" } else { "paper_facing_map" }
                $status = "locked"
                $stage = "all_stages"
                $dependsOn = "[chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]"
            }
            "07_WrittingSkills_and_Rules" {
                $type = "writing_rule"
                $status = "active"
                $stage = "none"
                $dependsOn = "[chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]"
            }
            "09_legacy" {
                $type = "legacy_note"
                $status = "legacy"
                $stage = "S00"
                $dependsOn = "[]"
            }
            "80_Prompts" {
                $type = "prompt_execution_contract"
                $status = "active"
                if ($filename -match 'S30') { $stage = "S30" } else { $stage = "all_stages" }
                $dependsOn = "[chapter2_vault/06_paper_facing/00N_Chapter2_PaperFacing_MAP.md]"
            }
            "99_inactive" {
                $type = "inactive_archive"
                $status = "inactive"
                $stage = "none"
                $dependsOn = "[]"
            }
            default {
                $type = "vault_note"
                $status = "active"
                $stage = "none"
                $dependsOn = "[]"
            }
        }
    } elseif ($folder -eq "reports") {
        $type = "audit_report"
        $status = "active"
        $stage = if ($filename -match 'GPIM' -or $filename -match 'D01' -or $filename -match 'D02') { "S10" } elseif ($filename -match 'S29' -or $filename -match 'S12') { "S20" } elseif ($filename -match 'SofT') { "S30" } else { "all_stages" }
        $dependsOn = "[chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md]"
    } elseif ($folder -eq "data") {
        $type = if ($filename -match 'README' -or $filename -match 'HANDOFF') { "data_manifest" } else { "validation_report" }
        $status = if ($pClean -match 'releases') { "frozen" } else { "active" }
        $stage = if ($pClean -match 'S10' -or $pClean -match 'FixedAssets') { "S10" } elseif ($pClean -match 'source_of_truth') { "S30" } else { "all_stages" }
        $dependsOn = "[data/provider_handoffs/US_BEA_FixedAssets/2026-06-11/HANDOFF.md]"
    } elseif ($folder -eq "docs") {
        $type = "documentation"
        $status = "active"
        $stage = "none"
        $dependsOn = "[]"
    } elseif ($folder -eq "codes") {
        $type = "stage_contract"
        $status = "active"
        $stage = "all_stages"
        $dependsOn = "[chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md]"
    } elseif ($folder -eq "output") {
        if ($pClean -match '_legacy\\writing\\drafts') {
            $type = "draft_section"
            $status = "draft"
            $stage = "S00"
            $dependsOn = "[chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]"
        } else {
            $type = "stage_report"
            $status = "active"
            if ($pClean -match '\\S10_') { $stage = "S10" }
            elseif ($pClean -match '\\S20_') { $stage = "S20" }
            elseif ($pClean -match '\\S22_') { $stage = "S22" }
            elseif ($pClean -match '\\S30_') { $stage = "S30" }
            elseif ($pClean -match '\\S31i_') { $stage = "S31i" }
            elseif ($pClean -match '\\S32_') { $stage = "S32" }
            elseif ($pClean -match '\\S32b_') { $stage = "S32b" }
            elseif ($pClean -match '\\S32c_') { $stage = "S32c" }
            elseif ($pClean -match '\\S35_') { $stage = "S35" }
            elseif ($pClean -match '\\S40_') { $stage = "S40" }
            elseif ($pClean -match '\\S90_') { $stage = "S90" }
            else { $stage = "all_stages" }
            $dependsOn = "[chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md]"
        }
    }

    # Respect existing values if present
    if ($item.ExistingType -and $item.ExistingType -ne "") { $type = $item.ExistingType }
    if ($item.ExistingStatus -and $item.ExistingStatus -ne "") { $status = $item.ExistingStatus }
    if ($item.ExistingCountry -and $item.ExistingCountry -ne "") { $country = $item.ExistingCountry }
    if ($item.ExistingStageScope -and $item.ExistingStageScope -ne "") { $stage = $item.ExistingStageScope }
    if ($item.ExistingDependsOn -and $item.ExistingDependsOn -ne "") { $dependsOn = $item.ExistingDependsOn }

    $proposedList += [PSCustomObject]@{
        Path = $pClean
        HasYAML = $item.HasYAML
        MissingFields = $item.MissingFields
        Proposed_type = $type
        Proposed_status = $status
        Proposed_depends_on = $dependsOn
        Proposed_stage_scope = $stage
        Proposed_country = $country
        Proposed_last_updated = $lastUpdated
    }
}

$proposedList | Export-Csv -Path 'c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_explorer_m1_3\proposed_yaml_mapping.csv' -NoTypeInformation
Write-Host "Generated proposed mapping table for $($proposedList.Count) files."
