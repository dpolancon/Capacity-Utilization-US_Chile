param(
    [string]$ConfigPath = ""
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

function New-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Invoke-Git {
    param(
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )
    $previousErrorActionPreference = $ErrorActionPreference
    Push-Location $WorkingDirectory
    try {
        $ErrorActionPreference = "Continue"
        $output = & git @Arguments 2>&1
        $exitCode = $LASTEXITCODE
        $ErrorActionPreference = $previousErrorActionPreference
        return [pscustomobject]@{
            ExitCode = $exitCode
            Output = ($output -join "`n")
        }
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
        Pop-Location
    }
}

function Normalize-PathText {
    param([string]$Path)
    return ($Path -replace "\\", "/").Trim()
}

function Test-PathPattern {
    param(
        [string]$Path,
        [string]$Pattern
    )
    $p = Normalize-PathText $Path
    $pat = Normalize-PathText $Pattern
    if ($pat.EndsWith("*")) {
        return $p.StartsWith($pat.Substring(0, $pat.Length - 1), [System.StringComparison]::OrdinalIgnoreCase)
    }
    return [string]::Equals($p, $pat, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-AllowedPath {
    param(
        [string]$Path,
        [object[]]$Prefixes
    )
    foreach ($prefix in $Prefixes) {
        $prefixText = [string]$prefix
        if ((Normalize-PathText $Path).StartsWith((Normalize-PathText $prefixText), [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Test-ForbiddenPath {
    param(
        [string]$Path,
        [object[]]$Patterns
    )
    foreach ($pattern in $Patterns) {
        if (Test-PathPattern -Path $Path -Pattern ([string]$pattern)) {
            return $true
        }
    }
    return $false
}

function Add-Check {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Detail
    )
    $script:checks += [pscustomobject]@{
        check_name = $Name
        status = $Status
        detail = $Detail
    }
}

function Add-HumanReview {
    param([string]$Reason)
    $script:humanReviewReasons += $Reason
}

function Get-BranchFiles {
    param(
        [string]$Repo,
        [string]$Branch
    )
    $result = Invoke-Git -WorkingDirectory $Repo -Arguments @("ls-tree", "-r", "--name-only", "origin/$Branch")
    if ($result.ExitCode -ne 0) {
        throw "Unable to list files for origin/$Branch`: $($result.Output)"
    }
    if ([string]::IsNullOrWhiteSpace($result.Output)) {
        return @()
    }
    return @($result.Output -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Get-BlobText {
    param(
        [string]$Repo,
        [string]$Branch,
        [string]$Path
    )
    $result = Invoke-Git -WorkingDirectory $Repo -Arguments @("show", "origin/$Branch`:$Path")
    if ($result.ExitCode -ne 0) {
        return ""
    }
    return $result.Output
}

function Find-UniqueEvidence {
    param(
        [object]$Task,
        [string[]]$Files,
        [string]$Kind,
        [string]$Needle,
        [string[]]$AlternateNeedles,
        [string]$Repo
    )
    $evidenceMatches = @()
    foreach ($file in $Files) {
        $normalized = Normalize-PathText $file
        $namespace = Normalize-PathText ([string]$Task.outputNamespace)
        if (-not $normalized.StartsWith($namespace, [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }
        $lower = $normalized.ToLowerInvariant()
        if (($Kind -eq "completion") -and ($lower -notmatch "completion.*record|record.*completion")) {
            continue
        }
        if (($Kind -eq "validation") -and ($lower -notmatch "validation|completion|independent")) {
            continue
        }
        if (($Kind -eq "decision") -and ($lower -notmatch "decision|completion|handoff|summary")) {
            continue
        }
        if (($Kind -eq "status") -and ($lower -notmatch "decision|completion|handoff|summary|readiness")) {
            continue
        }
        if (($Kind -eq "result_commit") -and ($lower -notmatch "completion|decision|summary|validation|handoff")) {
            continue
        }
        $text = Get-BlobText -Repo $Repo -Branch ([string]$Task.branch) -Path $file
        $found = $false
        if (-not [string]::IsNullOrWhiteSpace($Needle) -and $text.Contains($Needle)) {
            $found = $true
        }
        if (-not $found -and $AlternateNeedles -ne $null) {
            foreach ($alternate in $AlternateNeedles) {
                if (-not [string]::IsNullOrWhiteSpace($alternate) -and $text.Contains($alternate)) {
                    $found = $true
                    break
                }
            }
        }
        if ($found) {
            $evidenceMatches += $file
        }
    }
    $unique = @($evidenceMatches | Sort-Object -Unique)
    if ($unique.Count -eq 1) {
        return [pscustomobject]@{ Status = "PASS"; Path = $unique[0]; Detail = "found" }
    }
    if ($unique.Count -eq 0) {
        return [pscustomobject]@{ Status = "HUMAN_REVIEW_REQUIRED_MISSING_COMPLETION_EVIDENCE"; Path = ""; Detail = "no $Kind evidence found" }
    }
    return [pscustomobject]@{ Status = "HUMAN_REVIEW_REQUIRED_AMBIGUOUS_COMPLETION_EVIDENCE"; Path = ($unique -join ";"); Detail = "multiple $Kind evidence files found" }
}

function Test-TextHasNeedle {
    param(
        [string]$Text,
        [string]$Needle,
        [string[]]$AlternateNeedles
    )
    if (-not [string]::IsNullOrWhiteSpace($Needle) -and $Text.Contains($Needle)) {
        return $true
    }
    if ($AlternateNeedles -ne $null) {
        foreach ($alternate in $AlternateNeedles) {
            if (-not [string]::IsNullOrWhiteSpace($alternate) -and $Text.Contains($alternate)) {
                return $true
            }
        }
    }
    return $false
}

function Get-NamedValueFromText {
    param(
        [string]$Text,
        [string[]]$Names
    )
    $cleanText = $Text.TrimStart([char]0xFEFF)
    try {
        $json = $cleanText | ConvertFrom-Json
        foreach ($name in $Names) {
            if ($json.PSObject.Properties.Name -contains $name) {
                return [pscustomobject]@{ Found = $true; Value = [string]$json.$name }
            }
        }
    }
    catch {
    }
    try {
        $rows = @($cleanText | ConvertFrom-Csv)
        if ($rows.Count -gt 0) {
            foreach ($name in $Names) {
                if ($rows[0].PSObject.Properties.Name -contains $name) {
                    return [pscustomobject]@{ Found = $true; Value = [string]$rows[0].$name }
                }
            }
        }
    }
    catch {
    }
    foreach ($line in ($cleanText -split "`r?`n")) {
        foreach ($name in $Names) {
            $namePattern = [regex]::Escape($name) -replace "\\_", "[_ -]"
            $match = [regex]::Match($line, "(?i)^\s*[""']?\s*$namePattern\s*[""']?\s*[:=]\s*[""']?([^""',#\r\n]*)")
            if ($match.Success) {
                return [pscustomobject]@{ Found = $true; Value = [string]$match.Groups[1].Value }
            }
        }
    }
    return [pscustomobject]@{ Found = $false; Value = "" }
}

function Test-PlaceholderCommitValue {
    param([string]$Value)
    $normalized = ($Value -replace '["'']', '').Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return $true
    }
    $placeholderPatterns = @(
        "^blank$",
        "^none$",
        "^null$",
        "pending",
        "not yet committed",
        "not available",
        "unavailable",
        "to be populated",
        "placeholder",
        "post.commit",
        "recorded.*final.*report",
        "final.*report.*commit"
    )
    foreach ($pattern in $placeholderPatterns) {
        if ($normalized -match $pattern) {
            return $true
        }
    }
    return $false
}

function Get-CompletionRecordCommitEvidence {
    param(
        [string]$Text,
        [string]$ExpectedTip
    )
    $valueResult = Get-NamedValueFromText -Text $Text -Names @("result_commit", "commit_hash", "result commit")
    if (-not $valueResult.Found) {
        return [pscustomobject]@{
            Status = "PASS_WITH_REMOTE_TIP_AUTHORITY"
            Path = ""
            Detail = "completion record was produced before the final commit; remote branch tip is authoritative"
        }
    }
    $value = ([string]$valueResult.Value).Trim()
    if (Test-PlaceholderCommitValue -Value $value) {
        return [pscustomobject]@{
            Status = "PASS_WITH_REMOTE_TIP_AUTHORITY"
            Path = ""
            Detail = "completion record was produced before the final commit; remote branch tip is authoritative"
        }
    }
    $hashMatch = [regex]::Match($value, "(?i)\b[0-9a-f]{40}\b")
    if ($hashMatch.Success -and $hashMatch.Value.ToLowerInvariant() -eq $ExpectedTip.ToLowerInvariant()) {
        return [pscustomobject]@{ Status = "PASS"; Path = ""; Detail = "completion record result commit matches configured expectedTip" }
    }
    return [pscustomobject]@{
        Status = "HUMAN_REVIEW_REQUIRED_COMPLETION_COMMIT_CONTRADICTION"
        Path = ""
        Detail = "completion record result commit contradicts configured expectedTip: $value"
    }
}

$script:checks = @()
$script:branchTipAudit = @()
$script:changedPathAudit = @()
$script:completionEvidenceAudit = @()
$script:mergeSimulation = @()
$script:humanReviewReasons = @()
$technicalFailure = $false
$cleanupStatus = "not_started"
$mainBefore = ""
$mainAfter = ""

try {
    if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        $ConfigPath = Join-Path $scriptDir "s30_merge_plan.json"
    }
    $config = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
    $repo = [string]$config.repositoryPath
    if (-not (Test-Path -LiteralPath $repo)) {
        throw "Repository path does not exist: $repo"
    }
    $outputRoot = Join-Path $repo "output\US\S30_MERGE_READINESS_AUDIT"
    $csvRoot = Join-Path $outputRoot "csv"
    $mdRoot = Join-Path $outputRoot "md"
    New-Directory $csvRoot
    New-Directory $mdRoot

    $gitDir = Invoke-Git -WorkingDirectory $repo -Arguments @("rev-parse", "--git-dir")
    if ($gitDir.ExitCode -eq 0) { Add-Check "git_repository_exists" "PASS" $gitDir.Output } else { Add-Check "git_repository_exists" "TECHNICAL_FAILURE" $gitDir.Output; $technicalFailure = $true }

    $origin = Invoke-Git -WorkingDirectory $repo -Arguments @("remote", "get-url", "origin")
    if ($origin.ExitCode -eq 0) { Add-Check "origin_available" "PASS" $origin.Output } else { Add-Check "origin_available" "TECHNICAL_FAILURE" $origin.Output; $technicalFailure = $true }

    $originMain = Invoke-Git -WorkingDirectory $repo -Arguments @("rev-parse", "origin/main")
    $mainBefore = $originMain.Output.Trim()
    if ($originMain.ExitCode -eq 0 -and $mainBefore -eq [string]$config.expectedOriginMain) {
        Add-Check "origin_main_expected_commit" "PASS" $mainBefore
    } else {
        Add-Check "origin_main_expected_commit" "HUMAN_REVIEW_REQUIRED" $mainBefore
        Add-HumanReview "origin/main did not match expected commit"
    }

    $mergeHead = (Invoke-Git -WorkingDirectory $repo -Arguments @("rev-parse", "--git-path", "MERGE_HEAD")).Output.Trim()
    $rebaseMerge = (Invoke-Git -WorkingDirectory $repo -Arguments @("rev-parse", "--git-path", "rebase-merge")).Output.Trim()
    $rebaseApply = (Invoke-Git -WorkingDirectory $repo -Arguments @("rev-parse", "--git-path", "rebase-apply")).Output.Trim()
    if ((Test-Path $mergeHead) -or (Test-Path $rebaseMerge) -or (Test-Path $rebaseApply)) {
        Add-Check "no_merge_or_rebase_in_progress" "TECHNICAL_FAILURE" "merge or rebase marker present"
        $technicalFailure = $true
    } else {
        Add-Check "no_merge_or_rebase_in_progress" "PASS" "no merge or rebase marker found"
    }

    foreach ($task in $config.tasks) {
        $branch = [string]$task.branch
        $expectedTip = [string]$task.expectedTip
        $tip = Invoke-Git -WorkingDirectory $repo -Arguments @("rev-parse", "origin/$branch")
        $tipText = $tip.Output.Trim()
        $tipStatus = "PASS"
        if ($tip.ExitCode -ne 0) {
            $tipStatus = "TECHNICAL_FAILURE"
            $technicalFailure = $true
        } elseif ($tipText -ne $expectedTip) {
            $tipStatus = "HUMAN_REVIEW_REQUIRED_REMOTE_TIP_MISMATCH"
            Add-HumanReview "$($task.id) remote branch tip mismatch"
        }
        $script:branchTipAudit += [pscustomobject]@{
            task = $task.id
            branch = $branch
            expected_tip = $expectedTip
            actual_tip = $tipText
            status = $tipStatus
        }

        $diff = Invoke-Git -WorkingDirectory $repo -Arguments @("diff", "--name-only", [string]$config.commonS30Base, $expectedTip)
        if ($diff.ExitCode -ne 0) {
            $technicalFailure = $true
            Add-Check "$($task.id)_changed_paths_listed" "TECHNICAL_FAILURE" $diff.Output
            continue
        }
        $files = @()
        if (-not [string]::IsNullOrWhiteSpace($diff.Output)) {
            $files = @($diff.Output -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        }
        foreach ($file in $files) {
            $allowed = Test-AllowedPath -Path $file -Prefixes $task.allowedPathPrefixes
            $status = "PASS"
            if (-not $allowed) {
                $status = "HUMAN_REVIEW_REQUIRED_UNEXPECTED_PATH"
                Add-HumanReview "$($task.id) changed unexpected path $file"
            }
            $script:changedPathAudit += [pscustomobject]@{
                task = $task.id
                file = $file
                status = $status
            }
        }

        $branchFiles = Get-BranchFiles -Repo $repo -Branch $branch
        $completion = Find-UniqueEvidence -Task $task -Files $branchFiles -Kind "completion" -Needle "result_commit" -AlternateNeedles @("validation_status") -Repo $repo
        $validation = Find-UniqueEvidence -Task $task -Files $branchFiles -Kind "validation" -Needle ([string]$task.expectedValidation) -AlternateNeedles ([string[]]$task.acceptableValidationTokens) -Repo $repo
        $decision = Find-UniqueEvidence -Task $task -Files $branchFiles -Kind "decision" -Needle ([string]$task.expectedDecision) -AlternateNeedles @() -Repo $repo
        $familyStatus = Find-UniqueEvidence -Task $task -Files $branchFiles -Kind "status" -Needle ([string]$task.expectedStatus) -AlternateNeedles @() -Repo $repo
        if ($tipStatus -eq "PASS") {
            $resultCommit = [pscustomobject]@{
                Status = "PASS"
                Path = "refs/remotes/origin/$branch"
                Detail = "remote branch tip matches configured expectedTip"
            }
        } else {
            $resultCommit = [pscustomobject]@{
                Status = $tipStatus
                Path = "refs/remotes/origin/$branch"
                Detail = "remote branch tip does not match configured expectedTip"
            }
        }
        $completionCommit = [pscustomobject]@{
            Status = "HUMAN_REVIEW_REQUIRED_MISSING_COMPLETION_EVIDENCE"
            Path = ""
            Detail = "completion record unavailable for commit contradiction inspection"
        }
        if ($completion.Status -eq "PASS") {
            $completionText = Get-BlobText -Repo $repo -Branch $branch -Path $completion.Path
            if (Test-TextHasNeedle -Text $completionText -Needle ([string]$task.expectedValidation) -AlternateNeedles ([string[]]$task.acceptableValidationTokens)) {
                $validation = [pscustomobject]@{ Status = "PASS"; Path = $completion.Path; Detail = "completion record contains validation evidence" }
            }
            if (Test-TextHasNeedle -Text $completionText -Needle ([string]$task.expectedDecision) -AlternateNeedles @()) {
                $decision = [pscustomobject]@{ Status = "PASS"; Path = $completion.Path; Detail = "completion record contains decision evidence" }
            }
            if (Test-TextHasNeedle -Text $completionText -Needle ([string]$task.expectedStatus) -AlternateNeedles @()) {
                $familyStatus = [pscustomobject]@{ Status = "PASS"; Path = $completion.Path; Detail = "completion record contains status evidence" }
            }
            $completionCommit = Get-CompletionRecordCommitEvidence -Text $completionText -ExpectedTip $expectedTip
            $completionCommit.Path = $completion.Path
        }
        $evidenceItems = @()
        $evidenceItems += [pscustomobject]@{ kind = "completion_record"; evidence = $completion }
        $evidenceItems += [pscustomobject]@{ kind = "validation_result"; evidence = $validation }
        $evidenceItems += [pscustomobject]@{ kind = "final_decision"; evidence = $decision }
        $evidenceItems += [pscustomobject]@{ kind = "family_or_scaffold_status"; evidence = $familyStatus }
        $evidenceItems += [pscustomobject]@{ kind = "result_commit_remote_tip"; evidence = $resultCommit }
        $evidenceItems += [pscustomobject]@{ kind = "completion_record_result_commit"; evidence = $completionCommit }
        foreach ($e in $evidenceItems) {
            $status = $e.evidence.Status
            if ($status -ne "PASS" -and $status -ne "PASS_WITH_REMOTE_TIP_AUTHORITY") {
                Add-HumanReview "$($task.id) $($e.kind): $status"
            }
            $script:completionEvidenceAudit += [pscustomobject]@{
                task = $task.id
                evidence_kind = $e.kind
                discovered_path = $e.evidence.Path
                status = $status
                detail = $e.evidence.Detail
            }
        }
    }

    $auditRoot = [string]$config.temporaryAuditWorktreeRoot
    New-Directory $auditRoot
    $stamp = (Get-Date).ToString("yyyyMMddHHmmss")
    $suffix = "$stamp-$PID"
    $auditPath = Join-Path $auditRoot "audit-$suffix"
    $auditBranch = ([string]$config.temporaryAuditBranchPrefix) + $suffix

    try {
        $addWt = Invoke-Git -WorkingDirectory $repo -Arguments @("worktree", "add", "-b", $auditBranch, $auditPath, "origin/main")
        if ($addWt.ExitCode -ne 0) {
            $technicalFailure = $true
            Add-Check "temporary_audit_worktree_created" "TECHNICAL_FAILURE" $addWt.Output
        } else {
            Add-Check "temporary_audit_worktree_created" "PASS" $auditPath
            $integratedPrefixes = @()
            foreach ($taskId in $config.mergeOrder) {
                $task = $null
                foreach ($candidate in $config.tasks) {
                    if ([string]$candidate.id -eq [string]$taskId) {
                        $task = $candidate
                        break
                    }
                }
                if ($null -eq $task) {
                    $technicalFailure = $true
                    $script:mergeSimulation += [pscustomobject]@{ task = $taskId; status = "TECHNICAL_FAILURE"; changed_files = ""; detail = "task not found in config" }
                    continue
                }
                $before = Invoke-Git -WorkingDirectory $auditPath -Arguments @("rev-parse", "HEAD")
                $merge = Invoke-Git -WorkingDirectory $auditPath -Arguments @("merge", "--no-ff", "--no-edit", "origin/$($task.branch)")
                if ($merge.ExitCode -ne 0) {
                    Add-HumanReview "$($task.id) simulated merge conflict or merge failure"
                    $script:mergeSimulation += [pscustomobject]@{
                        task = $task.id
                        status = "HUMAN_REVIEW_REQUIRED_MERGE_CONFLICT"
                        changed_files = ""
                        detail = $merge.Output
                    }
                    Invoke-Git -WorkingDirectory $auditPath -Arguments @("merge", "--abort") | Out-Null
                    break
                }
                $after = Invoke-Git -WorkingDirectory $auditPath -Arguments @("rev-parse", "HEAD")
                $changed = Invoke-Git -WorkingDirectory $auditPath -Arguments @("diff", "--name-only", $before.Output.Trim(), $after.Output.Trim())
                $changedFiles = @()
                if (-not [string]::IsNullOrWhiteSpace($changed.Output)) {
                    $changedFiles = @($changed.Output -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
                }
                $forbidden = @()
                foreach ($file in $changedFiles) {
                    if (Test-ForbiddenPath -Path $file -Patterns $config.forbiddenPaths) {
                        $forbidden += $file
                    }
                }
                $status = "PASS"
                $detail = "merge simulated"
                if ($forbidden.Count -gt 0) {
                    $status = "HUMAN_REVIEW_REQUIRED_FORBIDDEN_PATH"
                    $detail = "forbidden paths: " + ($forbidden -join ";")
                    Add-HumanReview "$($task.id) simulated merge touched forbidden path"
                }
                foreach ($prefix in $integratedPrefixes) {
                    $ls = Invoke-Git -WorkingDirectory $auditPath -Arguments @("ls-files", "$prefix*")
                    if ($ls.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($ls.Output)) {
                        $status = "HUMAN_REVIEW_REQUIRED_NAMESPACE_MISSING_AFTER_MERGE"
                        $detail = "previous namespace missing: $prefix"
                        Add-HumanReview "$($task.id) simulation lost previous namespace $prefix"
                    }
                }
                foreach ($prefix in $task.allowedPathPrefixes) {
                    $integratedPrefixes += [string]$prefix
                }
                $valid = Invoke-Git -WorkingDirectory $auditPath -Arguments @("status", "--short")
                if ($valid.ExitCode -ne 0) {
                    $status = "TECHNICAL_FAILURE"
                    $detail = "audit worktree invalid"
                    $technicalFailure = $true
                }
                $script:mergeSimulation += [pscustomobject]@{
                    task = $task.id
                    status = $status
                    changed_files = ($changedFiles -join ";")
                    detail = $detail
                }
            }
        }
    }
    finally {
        $cleanupMessages = @()
        if (Test-Path -LiteralPath $auditPath) {
            $remove = Invoke-Git -WorkingDirectory $repo -Arguments @("worktree", "remove", "--force", $auditPath)
            $cleanupMessages += "worktree_remove_exit=$($remove.ExitCode)"
        }
        $branchExists = Invoke-Git -WorkingDirectory $repo -Arguments @("show-ref", "--verify", "--quiet", "refs/heads/$auditBranch")
        if ($branchExists.ExitCode -eq 0) {
            $delete = Invoke-Git -WorkingDirectory $repo -Arguments @("branch", "-D", $auditBranch)
            $cleanupMessages += "branch_delete_exit=$($delete.ExitCode)"
        }
        $cleanupStatus = ($cleanupMessages -join "; ")
        if ([string]::IsNullOrWhiteSpace($cleanupStatus)) {
            $cleanupStatus = "nothing_to_clean"
        }
    }

    $originMainAfter = Invoke-Git -WorkingDirectory $repo -Arguments @("rev-parse", "origin/main")
    $mainAfter = $originMainAfter.Output.Trim()
    if ($mainAfter -eq [string]$config.expectedOriginMain) {
        Add-Check "real_main_unchanged" "PASS" $mainAfter
    } else {
        Add-Check "real_main_unchanged" "HUMAN_REVIEW_REQUIRED" $mainAfter
        Add-HumanReview "origin/main changed during dry run"
    }
}
catch {
    $technicalFailure = $true
    $exceptionDetail = $_.Exception.Message
    if ($_.InvocationInfo -ne $null -and -not [string]::IsNullOrWhiteSpace($_.InvocationInfo.PositionMessage)) {
        $exceptionDetail = $exceptionDetail + " " + ($_.InvocationInfo.PositionMessage -replace "`r?`n", " ")
    }
    Add-Check "script_exception" "TECHNICAL_FAILURE" $exceptionDetail
}

$finalDecision = "AUTHORIZE_CONTROLLED_S30_SEQUENTIAL_INTEGRATION"
$exitCode = 0
if ($technicalFailure) {
    $finalDecision = "TECHNICAL_FAILURE"
    $exitCode = 1
} elseif ($script:humanReviewReasons.Count -gt 0) {
    $finalDecision = "HUMAN_REVIEW_REQUIRED"
    $exitCode = 2
}

$decisionPath = Join-Path $mdRoot "S30_MERGE_READINESS_DECISION.md"
$reportPath = Join-Path $mdRoot "S30_MERGE_READINESS_REPORT.md"
$script:checks | Export-Csv -NoTypeInformation -Path (Join-Path $csvRoot "S30_merge_readiness_checks.csv")
$script:branchTipAudit | Export-Csv -NoTypeInformation -Path (Join-Path $csvRoot "S30_branch_tip_audit.csv")
$script:changedPathAudit | Export-Csv -NoTypeInformation -Path (Join-Path $csvRoot "S30_changed_path_audit.csv")
$script:completionEvidenceAudit | Export-Csv -NoTypeInformation -Path (Join-Path $csvRoot "S30_completion_evidence_audit.csv")
$script:mergeSimulation | Export-Csv -NoTypeInformation -Path (Join-Path $csvRoot "S30_sequential_merge_simulation.csv")

$reasonsText = "none"
if ($script:humanReviewReasons.Count -gt 0) {
    $reasonsText = ($script:humanReviewReasons | Sort-Object -Unique) -join "`n- "
    $reasonsText = "- " + $reasonsText
}

$report = @"
# S30 Merge-Readiness Report

Final decision: $finalDecision

## Scope

This was a dry-run audit for the S30A, S30B, S30C, S30D sequential integration order. It did not push, did not modify real `main`, and did not modify the S30 feature branches.

## Result

- Origin main before: $mainBefore
- Origin main after: $mainAfter
- Temporary cleanup: $cleanupStatus
- Human review reasons:
$reasonsText

## Audit Files

- `csv/S30_merge_readiness_checks.csv`
- `csv/S30_branch_tip_audit.csv`
- `csv/S30_changed_path_audit.csv`
- `csv/S30_completion_evidence_audit.csv`
- `csv/S30_sequential_merge_simulation.csv`

## Decision Rule

Integration is authorized only when branch tips, changed-path ownership, completion evidence, task results, sequential merge simulation, forbidden-path checks, and unchanged `main` all pass.
"@
$report | Set-Content -Encoding UTF8 -Path $reportPath

$decision = @"
# S30 Merge-Readiness Decision

Decision: $finalDecision

Human review reasons:
$reasonsText

Temporary cleanup: $cleanupStatus
"@
$decision | Set-Content -Encoding UTF8 -Path $decisionPath

Write-Host "S30 merge-readiness dry run: $finalDecision"
Write-Host "Report: $reportPath"
Write-Host "Decision: $decisionPath"
Write-Host "Temporary cleanup: $cleanupStatus"
exit $exitCode
