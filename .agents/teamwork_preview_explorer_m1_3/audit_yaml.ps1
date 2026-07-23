$files = Get-ChildItem -Recurse -Filter '*.md' c:\ReposGitHub\Capacity-Utilization-US_Chile | Where-Object { $_.FullName -notmatch '\\\.agents\\' -and $_.FullName -notmatch '\\\.claude\\' -and $_.FullName -notmatch '\\\.vscode\\' }
$results = @()
$mandatory = @('type', 'status', 'depends_on', 'stage_scope', 'country', 'last_updated')

foreach ($f in $files) {
    $relPath = $f.FullName.Replace('c:\ReposGitHub\Capacity-Utilization-US_Chile\', '')
    $content = Get-Content -Path $f.FullName -Raw -ErrorAction SilentlyContinue
    $hasYaml = $false
    $fieldsFound = @()
    $missingFields = $mandatory

    if ($content -and $content.StartsWith('---')) {
        $parts = $content -split '---', 3
        if ($parts.Length -ge 3) {
            $header = $parts[1]
            $hasYaml = $true
            foreach ($m in $mandatory) {
                if ($header -match "(?m)^${m}\s*:") {
                    $fieldsFound += $m
                }
            }
            $missingFields = $mandatory | Where-Object { $_ -notin $fieldsFound }
        }
    }
    $results += [PSCustomObject]@{
        Path = $relPath
        HasYAML = $hasYaml
        FieldsFound = ($fieldsFound -join ';')
        MissingFields = ($missingFields -join ';')
    }
}
$results | Export-Csv -Path 'c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_explorer_m1_3\yaml_audit.csv' -NoTypeInformation
Write-Host "Scanned $($results.Count) files. CSV saved."
