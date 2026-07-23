$files = Get-ChildItem -Recurse -Filter '*.md' c:\ReposGitHub\Capacity-Utilization-US_Chile | Where-Object { $_.FullName -notmatch '\\\.agents\\' -and $_.FullName -notmatch '\\\.claude\\' -and $_.FullName -notmatch '\\\.vscode\\' }
$mandatory = @('type', 'status', 'depends_on', 'stage_scope', 'country', 'last_updated')
$records = @()

foreach ($f in $files) {
    $relPath = $f.FullName.Replace('c:\ReposGitHub\Capacity-Utilization-US_Chile\', '')
    $content = Get-Content -Path $f.FullName -Raw -ErrorAction SilentlyContinue
    $lines = Get-Content -Path $f.FullName -ErrorAction SilentlyContinue
    $firstLine = if ($lines -and $lines.Count -gt 0) { $lines[0] } else { "" }
    
    $hasYaml = $false
    $yamlFields = @{}
    $missingFields = $mandatory

    if ($content -and $content.StartsWith('---')) {
        $parts = $content -split '---', 3
        if ($parts.Length -ge 3) {
            $header = $parts[1]
            $hasYaml = $true
            $headerLines = $header -split "`r?`n"
            foreach ($hl in $headerLines) {
                if ($hl -match '^([a-zA-Z0-9_]+)\s*:\s*(.*)$') {
                    $k = $matches[1].Trim()
                    $v = $matches[2].Trim()
                    $yamlFields[$k] = $v
                }
            }
            $foundKeys = $yamlFields.Keys
            $missingFields = $mandatory | Where-Object { $_ -notin $foundKeys }
        }
    }

    $records += [PSCustomObject]@{
        Path = $relPath
        LastWriteTime = $f.LastWriteTime.ToString('yyyy-MM-dd')
        Size = $f.Length
        HasYAML = $hasYaml
        ExistingType = if ($yamlFields.ContainsKey('type')) { $yamlFields['type'] } else { "" }
        ExistingStatus = if ($yamlFields.ContainsKey('status')) { $yamlFields['status'] } else { "" }
        ExistingCountry = if ($yamlFields.ContainsKey('country')) { $yamlFields['country'] } else { "" }
        ExistingStageScope = if ($yamlFields.ContainsKey('stage_scope')) { $yamlFields['stage_scope'] } else { "" }
        ExistingDependsOn = if ($yamlFields.ContainsKey('depends_on')) { $yamlFields['depends_on'] } else { "" }
        ExistingLastUpdated = if ($yamlFields.ContainsKey('last_updated')) { $yamlFields['last_updated'] } else { "" }
        MissingFields = ($missingFields -join ';')
        FirstLine = $firstLine
    }
}

$records | Export-Csv -Path 'c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_explorer_m1_3\full_md_audit.csv' -NoTypeInformation
Write-Host "Detailed audit complete for $($records.Count) files."
