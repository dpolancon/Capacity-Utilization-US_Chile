$norm = Import-Csv 'c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_explorer_m1_3\proposed_yaml_mapping_normalized.csv'

Write-Host "=== NORMALIZED TYPE DISTRIBUTION ==="
$norm | Group-Object Type | Select-Object Name, Count | Sort-Object Count -Descending | Format-Table -AutoSize

Write-Host "`n=== NORMALIZED STATUS DISTRIBUTION ==="
$norm | Group-Object Status | Select-Object Name, Count | Sort-Object Count -Descending | Format-Table -AutoSize

Write-Host "`n=== NORMALIZED COUNTRY DISTRIBUTION ==="
$norm | Group-Object Country | Select-Object Name, Count | Sort-Object Count -Descending | Format-Table -AutoSize

Write-Host "`n=== NORMALIZED STAGE SCOPE DISTRIBUTION ==="
$norm | Group-Object StageScope | Select-Object Name, Count | Sort-Object Count -Descending | Format-Table -AutoSize
