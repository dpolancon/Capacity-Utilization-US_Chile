$data = Import-Csv 'c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_explorer_m1_3\yaml_audit.csv'

foreach ($item in $data) {
    $p = $item.Path
    $p = $p -replace '^C:\\ReposGitHub\\Capacity-Utilization-US_Chile\\', ''
    $p = $p -replace '^c:\\ReposGitHub\\Capacity-Utilization-US_Chile\\', ''
    $item.Path = $p
}

Write-Host "--- Breakdown of chapter2_vault subdirectories ---"
$vault = $data | Where-Object { $_.Path -like 'chapter2_vault\*' }
$vault | Group-Object { ($_.Path -split '\\')[0..1] -join '\' } | Select-Object Name, Count,
    @{N='HasYAML'; E={($_.Group | Where-Object {$_.HasYAML -eq 'True'}).Count}},
    @{N='MissingYAML'; E={($_.Group | Where-Object {$_.HasYAML -eq 'False'}).Count}} | Format-Table -AutoSize

Write-Host "`n--- Breakdown of fields found in existing YAML headers ---"
$withYaml = $data | Where-Object { $_.HasYAML -eq 'True' }
$fieldCounts = @{}
foreach ($item in $withYaml) {
    $fields = $item.FieldsFound -split ';'
    foreach ($f in $fields) {
        if ($f) {
            $fieldCounts[$f] = ($fieldCounts[$f] -as [int]) + 1
        }
    }
}
$fieldCounts.GetEnumerator() | Sort-Object Value -Descending | Format-Table Key, Value -AutoSize
