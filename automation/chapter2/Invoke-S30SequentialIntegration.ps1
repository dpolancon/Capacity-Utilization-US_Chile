param(
    [switch]$Apply,
    [string]$Confirmation = "",
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

function Test-AllowedPath {
    param(
        [string]$Path,
        [object[]]$Prefixes
    )
    $normalizedPath = Normalize-PathText $Path
    foreach ($prefix in $Prefixes) {
        if ($normalizedPath.StartsWith((Normalize-PathText ([string]$prefix)), [System.StringComparison]::OrdinalIgnoreCase)) {
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
    $normalizedPath = Normalize-PathText $Path
    foreach ($pattern in $Patterns) {
        $normalizedPattern = Normalize-PathText ([string]$pattern)
        if ($normalizedPattern.EndsWith("*")) {
            if ($normalizedPath.StartsWith($normalizedPattern.Substring(0, $normalizedPattern.Length - 1), [System.StringComparison]::OrdinalIgnoreCase)) {
                return $true
            }
        } elseif ([string]::Equals($normalizedPath, $normalizedPattern, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Get-BranchFiles {
    param(
        [string]$Repo,
        [string]$Branch
    )
    $result = Invoke-Git -WorkingDirectory $Repo -Arguments @("ls-tree", "-r", "--name-only", "origin/$Branch")
    if ($result.ExitCode -ne 0) {
        throw "Unable to list origin/$Branch files: $($result.Output)"
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

function Find-CompletionRecord {
    param(
        [object]$Task,
        [string[]]$Files,
        [string]$Repo
    )
    $matches = @()
    foreach ($file in $Files) {
        $normalized = Normalize-PathText $file
        $namespace = Normalize-PathText ([string]$Task.outputNamespace)
        if (-not $normalized.StartsWith($namespace, [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }
        if ($normalized.ToLowerInvariant() -notmatch "completion.*record|record.*completion") {
            continue
        }
        $text = Get-BlobText -Repo $Repo -Branch ([string]$Task.branch) -Path $file
        if ($text.Contains("validation_status") -or $text.Contains("result_commit")) {
            $matches += $file
        }
    }
    $unique = @($matches | Sort-Object -Unique)
    if ($unique.Count -eq 1) {
        return [pscustomobject]@{ Status = "PASS"; Path = $unique[0]; Detail = "unique completion record found" }
    }
    if ($unique.Count -eq 0) {
        return [pscustomobject]@{ Status = "HUMAN_REVIEW_REQUIRED"; Path = ""; Detail = "missing completion record" }
    }
    return [pscustomobject]@{ Status = "HUMAN_REVIEW_REQUIRED"; Path = ($unique -join ";"); Detail = "ambiguous completion records" }
}

function Test-TextHasAny {
    param(
        [string]$Text,
        [string[]]$Needles
    )
    foreach ($needle in $Needles) {
        if (-not [string]::IsNullOrWhiteSpace($needle) -and $Text.Contains($needle)) {
            return $true
        }
    }
    return $false
}

function Test-TaskEvidence {
    param(
        [object]$Task,
        [string]$Repo
    )
    $files = Get-BranchFiles -Repo $Repo -Branch ([string]$Task.branch)
    $completion = Find-CompletionRecord -Task $Task -Files $files -Repo $Repo
    if ($completion.Status -ne "PASS") {
        return [pscustomobject]@{
            completion = $completion.Status
            validation = "NOT_RUN"
            decision = "NOT_RUN"
            status = "NOT_RUN"
            handoff = "NOT_RUN"
            consumer = "NOT_RUN"
            detail = $completion.Detail
        }
    }
    $text = Get-BlobText -Repo $Repo -Branch ([string]$Task.branch) -Path $completion.Path
    $validationNeedles = @()
    foreach ($token in $Task.acceptableValidationTokens) {
        $validationNeedles += [string]$token
    }
    $validationPass = Test-TextHasAny -Text $text -Needles $validationNeedles
    $decisionPass = $text.Contains([string]$Task.expectedDecision)
    $statusPass = $text.Contains([string]$Task.expectedStatus)
    $handoffPass = ($text -match '(?i)handoff_ready["\s,:]+(yes|true|"yes"|"true")')
    $consumerPass = ($text -match '(?i)consumer_intake_ready["\s,:]+(yes|true|"yes"|"true")')
    return [pscustomobject]@{
        completion = "PASS"
        validation = $(if ($validationPass) { "PASS" } else { "HUMAN_REVIEW_REQUIRED" })
        decision = $(if ($decisionPass) { "PASS" } else { "HUMAN_REVIEW_REQUIRED" })
        status = $(if ($statusPass) { "PASS" } else { "HUMAN_REVIEW_REQUIRED" })
        handoff = $(if ($handoffPass) { "PASS" } else { "HUMAN_REVIEW_REQUIRED" })
        consumer = $(if ($consumerPass) { "PASS" } else { "HUMAN_REVIEW_REQUIRED" })
        detail = $completion.Path
    }
}

function Add-Step {
    param(
        [object]$Task,
        [string]$FeatureTip,
        [string]$PreMergeMain,
        [string]$MergeCommit,
        [string]$PostPushOriginMain,
        [string]$ChangedPathCheck,
        [string]$CompletionEvidenceCheck,
        [string]$ValidationCheck,
        [string]$DecisionCheck,
        [string]$StatusCheck,
        [string]$ForbiddenPathCheck,
        [string]$PushStatus,
        [string]$StepStatus
    )
    $script:steps += [pscustomobject]@{
        task_id = $Task.id
        feature_branch = $Task.branch
        feature_tip = $FeatureTip
        pre_merge_main = $PreMergeMain
        merge_commit = $MergeCommit
        post_push_origin_main = $PostPushOriginMain
        changed_path_check = $ChangedPathCheck
        completion_evidence_check = $CompletionEvidenceCheck
        validation_check = $ValidationCheck
        decision_check = $DecisionCheck
        status_check = $StatusCheck
        forbidden_path_check = $ForbiddenPathCheck
        push_status = $PushStatus
        step_status = $StepStatus
    }
}

function Write-Audit {
    param(
        [string]$Repo,
        [string]$Decision,
        [string]$CleanupStatus,
        [string]$HumanReviewReason,
        [string]$TechnicalReason
    )
    $outputRoot = Join-Path $Repo "output\US\S30_SEQUENTIAL_INTEGRATION_AUDIT"
    $csvRoot = Join-Path $outputRoot "csv"
    $mdRoot = Join-Path $outputRoot "md"
    New-Directory $csvRoot
    New-Directory $mdRoot
    $script:steps | Export-Csv -NoTypeInformation -Path (Join-Path $csvRoot "S30_integration_steps.csv")
    $script:mainTips | Export-Csv -NoTypeInformation -Path (Join-Path $csvRoot "S30_main_tip_progression.csv")
    $script:postChecks | Export-Csv -NoTypeInformation -Path (Join-Path $csvRoot "S30_post_merge_checks.csv")
    $report = @"
# S30 Sequential Integration Report

Decision: $Decision

Integration worktree: $script:integrationWorktree
Temporary branch: $script:integrationBranch
Starting origin/main: $script:startingOriginMain
Final origin/main: $script:finalOriginMain
Cleanup: $CleanupStatus

Human review reason: $HumanReviewReason
Technical reason: $TechnicalReason
"@
    $report | Set-Content -Encoding UTF8 -Path (Join-Path $mdRoot "S30_SEQUENTIAL_INTEGRATION_REPORT.md")
    $decisionText = @"
# S30 Sequential Integration Decision

Decision: $Decision

Human review reason: $HumanReviewReason
Technical reason: $TechnicalReason
Cleanup: $CleanupStatus
"@
    $decisionText | Set-Content -Encoding UTF8 -Path (Join-Path $mdRoot "S30_SEQUENTIAL_INTEGRATION_DECISION.md")
}

$requiredConfirmation = "APPLY_S30_SEQUENTIAL_INTEGRATION"
$script:steps = @()
$script:mainTips = @()
$script:postChecks = @()
$script:integrationWorktree = "C:\ReposGitHub\CUUSChile_Automation\S30SequentialIntegration_Run"
$script:integrationBranch = ""
$script:startingOriginMain = ""
$script:finalOriginMain = ""
$script:repoRoot = ""
$cleanupStatus = "not_started"
$decision = "TECHNICAL_FAILURE"
$humanReviewReason = "none"
$technicalReason = "none"
$exitCode = 1
$mergeCommitCreated = $false
$preserveWorktree = $false

try {
    if (-not $Apply -or $Confirmation -ne $requiredConfirmation) {
        Write-Host "Refusing to run: -Apply and exact confirmation token are required."
        exit 2
    }
    if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        $ConfigPath = Join-Path $scriptDir "s30_merge_plan.json"
    }
    $config = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
    $repo = [string]$config.repositoryPath
    $script:repoRoot = $repo
    $script:startingOriginMain = [string]$config.expectedOriginMain
    $readinessScript = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "Test-S30MergeReadiness.ps1"
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $readinessScript | Out-Host
    $readinessExit = $LASTEXITCODE
    $readinessDecisionPath = Join-Path $repo "output\US\S30_MERGE_READINESS_AUDIT\md\S30_MERGE_READINESS_DECISION.md"
    $readinessDecision = ""
    if (Test-Path -LiteralPath $readinessDecisionPath) {
        $readinessDecision = Get-Content -Raw -LiteralPath $readinessDecisionPath
    }
    if ($readinessExit -ne 0 -or $readinessDecision -notmatch "AUTHORIZE_CONTROLLED_S30_SEQUENTIAL_INTEGRATION") {
        $decision = "HUMAN_REVIEW_REQUIRED"
        $humanReviewReason = "readiness recheck failed"
        $exitCode = 2
        Write-Audit -Repo $repo -Decision $decision -CleanupStatus $cleanupStatus -HumanReviewReason $humanReviewReason -TechnicalReason $technicalReason
        exit $exitCode
    }
    $path = $script:integrationWorktree
    if (Test-Path -LiteralPath $path) {
        $decision = "HUMAN_REVIEW_REQUIRED"
        $humanReviewReason = "HUMAN_REVIEW_REQUIRED_INTEGRATION_WORKTREE_CONFLICT: $path exists"
        $exitCode = 2
        Write-Audit -Repo $repo -Decision $decision -CleanupStatus $cleanupStatus -HumanReviewReason $humanReviewReason -TechnicalReason $technicalReason
        exit $exitCode
    }
    $fetch = Invoke-Git -WorkingDirectory $repo -Arguments @("fetch", "origin")
    if ($fetch.ExitCode -ne 0) {
        throw "fetch failed: $($fetch.Output)"
    }
    $originMain = Invoke-Git -WorkingDirectory $repo -Arguments @("rev-parse", "origin/main")
    $expectedRemoteMain = [string]$config.expectedOriginMain
    if ($originMain.Output.Trim() -ne $expectedRemoteMain) {
        $decision = "HUMAN_REVIEW_REQUIRED"
        $humanReviewReason = "HUMAN_REVIEW_REQUIRED_REMOTE_MAIN_DIVERGED"
        $exitCode = 2
        Write-Audit -Repo $repo -Decision $decision -CleanupStatus $cleanupStatus -HumanReviewReason $humanReviewReason -TechnicalReason $technicalReason
        exit $exitCode
    }
    $stamp = (Get-Date).ToString("yyyyMMddHHmmss")
    $script:integrationBranch = "tmp/s30-controlled-integration-$stamp-$PID"
    $parent = Split-Path -Parent $path
    New-Directory $parent
    $add = Invoke-Git -WorkingDirectory $repo -Arguments @("worktree", "add", "-b", $script:integrationBranch, $path, "origin/main")
    if ($add.ExitCode -ne 0) {
        throw "unable to create integration worktree: $($add.Output)"
    }
    foreach ($taskId in $config.mergeOrder) {
        $task = $null
        foreach ($candidate in $config.tasks) {
            if ([string]$candidate.id -eq [string]$taskId) {
                $task = $candidate
                break
            }
        }
        if ($null -eq $task) {
            throw "task not found in plan: $taskId"
        }
        $fetchStep = Invoke-Git -WorkingDirectory $repo -Arguments @("fetch", "origin")
        if ($fetchStep.ExitCode -ne 0) {
            throw "fetch failed before $($task.id): $($fetchStep.Output)"
        }
        $remoteMain = (Invoke-Git -WorkingDirectory $repo -Arguments @("rev-parse", "origin/main")).Output.Trim()
        $featureTip = (Invoke-Git -WorkingDirectory $repo -Arguments @("rev-parse", "origin/$($task.branch)")).Output.Trim()
        if ($remoteMain -ne $expectedRemoteMain) {
            $decision = "HUMAN_REVIEW_REQUIRED"
            $humanReviewReason = "HUMAN_REVIEW_REQUIRED_REMOTE_MAIN_DIVERGED before $($task.id)"
            $preserveWorktree = $mergeCommitCreated
            $exitCode = 2
            break
        }
        if ($featureTip -ne [string]$task.expectedTip) {
            $decision = "HUMAN_REVIEW_REQUIRED"
            $humanReviewReason = "remote feature tip mismatch for $($task.id)"
            $exitCode = 2
            break
        }
        $preMerge = (Invoke-Git -WorkingDirectory $path -Arguments @("rev-parse", "HEAD")).Output.Trim()
        $merge = Invoke-Git -WorkingDirectory $path -Arguments @("merge", "--no-ff", "--no-commit", "origin/$($task.branch)")
        if ($merge.ExitCode -ne 0) {
            Invoke-Git -WorkingDirectory $path -Arguments @("merge", "--abort") | Out-Null
            $decision = "HUMAN_REVIEW_REQUIRED"
            $humanReviewReason = "HUMAN_REVIEW_REQUIRED_MERGE_CONFLICT at $($task.id)"
            Add-Step -Task $task -FeatureTip $featureTip -PreMergeMain $preMerge -MergeCommit "" -PostPushOriginMain "" -ChangedPathCheck "NOT_RUN" -CompletionEvidenceCheck "NOT_RUN" -ValidationCheck "NOT_RUN" -DecisionCheck "NOT_RUN" -StatusCheck "NOT_RUN" -ForbiddenPathCheck "NOT_RUN" -PushStatus "NOT_PUSHED" -StepStatus "HUMAN_REVIEW_REQUIRED_MERGE_CONFLICT"
            $exitCode = 2
            break
        }
        $unresolved = Invoke-Git -WorkingDirectory $path -Arguments @("diff", "--name-only", "--diff-filter=U")
        if (-not [string]::IsNullOrWhiteSpace($unresolved.Output)) {
            Invoke-Git -WorkingDirectory $path -Arguments @("merge", "--abort") | Out-Null
            $decision = "HUMAN_REVIEW_REQUIRED"
            $humanReviewReason = "unresolved files after $($task.id) merge"
            $exitCode = 2
            break
        }
        $changed = Invoke-Git -WorkingDirectory $path -Arguments @("diff", "--name-only", "HEAD")
        $changedFiles = @()
        if (-not [string]::IsNullOrWhiteSpace($changed.Output)) {
            $changedFiles = @($changed.Output -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        }
        $changedPathCheck = "PASS"
        $forbiddenPathCheck = "PASS"
        foreach ($file in $changedFiles) {
            if (-not (Test-AllowedPath -Path $file -Prefixes $task.allowedPathPrefixes)) {
                $changedPathCheck = "HUMAN_REVIEW_REQUIRED"
            }
            if (Test-ForbiddenPath -Path $file -Patterns $config.forbiddenPaths) {
                $forbiddenPathCheck = "HUMAN_REVIEW_REQUIRED"
            }
        }
        $evidence = Test-TaskEvidence -Task $task -Repo $repo
        $diffCheck = Invoke-Git -WorkingDirectory $path -Arguments @("diff", "--check")
        if ($changedPathCheck -ne "PASS" -or $forbiddenPathCheck -ne "PASS" -or $evidence.completion -ne "PASS" -or $evidence.validation -ne "PASS" -or $evidence.decision -ne "PASS" -or $evidence.status -ne "PASS" -or $diffCheck.ExitCode -ne 0) {
            Invoke-Git -WorkingDirectory $path -Arguments @("merge", "--abort") | Out-Null
            $decision = "HUMAN_REVIEW_REQUIRED"
            $humanReviewReason = "pre-commit validation failed for $($task.id)"
            Add-Step -Task $task -FeatureTip $featureTip -PreMergeMain $preMerge -MergeCommit "" -PostPushOriginMain "" -ChangedPathCheck $changedPathCheck -CompletionEvidenceCheck $evidence.completion -ValidationCheck $evidence.validation -DecisionCheck $evidence.decision -StatusCheck $evidence.status -ForbiddenPathCheck $forbiddenPathCheck -PushStatus "NOT_PUSHED" -StepStatus "HUMAN_REVIEW_REQUIRED"
            $exitCode = 2
            break
        }
        $message = switch ([string]$task.id) {
            "S30A" { "Merge S30A real output family closure" }
            "S30B" { "Merge S30B income distribution family closure" }
            "S30C" { "Merge S30C contextual family classification lock" }
            "S30D" { "Merge S30D dataset release scaffold" }
            default { "Merge $($task.id)" }
        }
        $commit = Invoke-Git -WorkingDirectory $path -Arguments @("commit", "-m", $message)
        if ($commit.ExitCode -ne 0) {
            throw "commit failed for $($task.id): $($commit.Output)"
        }
        $mergeCommitCreated = $true
        $mergeCommit = (Invoke-Git -WorkingDirectory $path -Arguments @("rev-parse", "HEAD")).Output.Trim()
        $prePushFetch = Invoke-Git -WorkingDirectory $repo -Arguments @("fetch", "origin")
        if ($prePushFetch.ExitCode -ne 0) {
            throw "pre-push fetch failed for $($task.id): $($prePushFetch.Output)"
        }
        $remoteBeforePush = (Invoke-Git -WorkingDirectory $repo -Arguments @("rev-parse", "origin/main")).Output.Trim()
        if ($remoteBeforePush -ne $expectedRemoteMain) {
            $decision = "HUMAN_REVIEW_REQUIRED"
            $humanReviewReason = "HUMAN_REVIEW_REQUIRED_REMOTE_MAIN_DIVERGED before push for $($task.id)"
            $preserveWorktree = $true
            $exitCode = 2
            break
        }
        $push = Invoke-Git -WorkingDirectory $path -Arguments @("push", "origin", "HEAD:main")
        if ($push.ExitCode -ne 0) {
            $decision = "TECHNICAL_FAILURE"
            $technicalReason = "TECHNICAL_FAILURE_PUSH at $($task.id): $($push.Output)"
            $preserveWorktree = $true
            $exitCode = 1
            break
        }
        $afterPushFetch = Invoke-Git -WorkingDirectory $repo -Arguments @("fetch", "origin")
        if ($afterPushFetch.ExitCode -ne 0) {
            throw "post-push fetch failed for $($task.id): $($afterPushFetch.Output)"
        }
        $postPushMain = (Invoke-Git -WorkingDirectory $repo -Arguments @("rev-parse", "origin/main")).Output.Trim()
        if ($postPushMain -ne $mergeCommit) {
            $decision = "TECHNICAL_FAILURE"
            $technicalReason = "origin/main did not advance to $($task.id) merge commit"
            $preserveWorktree = $true
            $exitCode = 1
            break
        }
        $script:mainTips += [pscustomobject]@{
            task_id = $task.id
            pre_merge_main = $preMerge
            expected_remote_main_before_push = $expectedRemoteMain
            merge_commit = $mergeCommit
            post_push_origin_main = $postPushMain
        }
        Add-Step -Task $task -FeatureTip $featureTip -PreMergeMain $preMerge -MergeCommit $mergeCommit -PostPushOriginMain $postPushMain -ChangedPathCheck $changedPathCheck -CompletionEvidenceCheck $evidence.completion -ValidationCheck $evidence.validation -DecisionCheck $evidence.decision -StatusCheck $evidence.status -ForbiddenPathCheck $forbiddenPathCheck -PushStatus "PUSHED" -StepStatus "PASS"
        $expectedRemoteMain = $mergeCommit
        $mergeCommitCreated = $false
    }
    $script:finalOriginMain = (Invoke-Git -WorkingDirectory $repo -Arguments @("rev-parse", "origin/main")).Output.Trim()
    if ($decision -eq "TECHNICAL_FAILURE" -or $decision -eq "HUMAN_REVIEW_REQUIRED") {
    } else {
        $finalPass = $true
        foreach ($task in $config.tasks) {
            $ancestor = Invoke-Git -WorkingDirectory $repo -Arguments @("merge-base", "--is-ancestor", [string]$task.expectedTip, "origin/main")
            $script:postChecks += [pscustomobject]@{ check_name = "$($task.id)_feature_tip_ancestor"; status = $(if ($ancestor.ExitCode -eq 0) { "PASS" } else { "FAIL" }); detail = [string]$task.expectedTip }
            if ($ancestor.ExitCode -ne 0) { $finalPass = $false }
            foreach ($prefix in $task.allowedPathPrefixes) {
                $ls = Invoke-Git -WorkingDirectory $repo -Arguments @("ls-tree", "-r", "--name-only", "origin/main", "$prefix*")
                if ([string]::IsNullOrWhiteSpace($ls.Output)) { $finalPass = $false }
            }
        }
        $automationAncestor = Invoke-Git -WorkingDirectory $repo -Arguments @("merge-base", "--is-ancestor", "HEAD", "origin/main")
        $script:postChecks += [pscustomobject]@{ check_name = "automation_controller_branch_not_merged"; status = $(if ($automationAncestor.ExitCode -ne 0) { "PASS" } else { "FAIL" }); detail = "controller HEAD not ancestor of origin/main" }
        if ($automationAncestor.ExitCode -eq 0) { $finalPass = $false }
        $s31 = Invoke-Git -WorkingDirectory $repo -Arguments @("ls-tree", "-r", "--name-only", "origin/main", "output/US/S31*")
        $script:postChecks += [pscustomobject]@{ check_name = "no_s31_outputs_created"; status = $(if ([string]::IsNullOrWhiteSpace($s31.Output)) { "PASS" } else { "FAIL" }); detail = $s31.Output }
        if (-not [string]::IsNullOrWhiteSpace($s31.Output)) { $finalPass = $false }
        if ($finalPass) {
            $decision = "S30_SEQUENTIAL_INTEGRATION_COMPLETE"
            $exitCode = 0
        } else {
            $decision = "HUMAN_REVIEW_REQUIRED"
            $humanReviewReason = "final verification failed"
            $exitCode = 2
        }
    }
}
catch {
    $decision = "TECHNICAL_FAILURE"
    $technicalReason = $_.Exception.Message
    $exitCode = 1
}
finally {
    if (-not $preserveWorktree -and (Test-Path -LiteralPath $script:integrationWorktree)) {
        $remove = Invoke-Git -WorkingDirectory $script:repoRoot -Arguments @("worktree", "remove", $script:integrationWorktree)
        $cleanupStatus = "worktree_remove_exit=$($remove.ExitCode)"
        if (-not [string]::IsNullOrWhiteSpace($script:integrationBranch)) {
            $delete = Invoke-Git -WorkingDirectory $script:repoRoot -Arguments @("branch", "-D", $script:integrationBranch)
            $cleanupStatus = "$cleanupStatus; branch_delete_exit=$($delete.ExitCode)"
        }
    } elseif ($preserveWorktree) {
        $cleanupStatus = "preserved_for_inspection: $script:integrationWorktree"
    }
    try {
        if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
            $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
            $ConfigPath = Join-Path $scriptDir "s30_merge_plan.json"
        }
        $repoForAudit = [string]((Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json).repositoryPath)
        Write-Audit -Repo $repoForAudit -Decision $decision -CleanupStatus $cleanupStatus -HumanReviewReason $humanReviewReason -TechnicalReason $technicalReason
    }
    catch {
        Write-Host "Audit write failed: $($_.Exception.Message)"
    }
}

Write-Host "S30 sequential integration: $decision"
Write-Host "Integration worktree: $script:integrationWorktree"
Write-Host "Temporary branch: $script:integrationBranch"
Write-Host "Final origin/main: $script:finalOriginMain"
Write-Host "Cleanup: $cleanupStatus"
exit $exitCode
