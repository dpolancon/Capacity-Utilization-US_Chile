$data = Import-Csv 'c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_explorer_m1_3\yaml_audit.csv'

foreach ($item in $data) {
    $p = $item.Path
    # Clean lead path
    $p = $p -replace '^C:\\ReposGitHub\\Capacity-Utilization-US_Chile\\', ''
    $p = $p -replace '^c:\\ReposGitHub\\Capacity-Utilization-US_Chile\\', ''
    $item.Path = $p
}

Write-Host "Total files scanned: $($data.Count)"
Write-Host "Files with YAML headers: $(($data | Where-Object { $_.HasYAML -eq 'True' }).Count)"
Write-Host "Files without YAML headers: $(($data | Where-Object { $_.HasYAML -eq 'False' }).Count)"
Write-Host "Files missing ANY of 6 mandatory fields: $(($data | Where-Object { $_.MissingFields -ne '' }).Count)"

Write-Host "`n--- Summary by Top-Level Directory ---"
$data | Group-Object { ($_.Path -split '\\')[0] } | Select-Object Name, Count, 
    @{N='HasYAML'; E={($_.Group | Where-Object {$_.HasYAML -eq 'True'}).Count}},
    @{N='CompleteYAML'; E={($_.Group | Where-Object {$_.MissingFields -eq ''}).Count}},
    @{N='MissingMandatory'; E={($_.Group | Where-Object {$_.MissingFields -ne ''}).Count}} | Format-Table -AutoSize
