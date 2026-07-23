$proposed = Import-Csv 'c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_explorer_m1_3\proposed_yaml_mapping.csv'

Write-Host "=== PROPOSED TYPE DISTRIBUTION ==="
$proposed | Group-Object Proposed_type | Select-Object Name, Count | Sort-Object Count -Descending | Format-Table -AutoSize

Write-Host "`n=== PROPOSED STATUS DISTRIBUTION ==="
$proposed | Group-Object Proposed_status | Select-Object Name, Count | Sort-Object Count -Descending | Format-Table -AutoSize

Write-Host "`n=== PROPOSED COUNTRY DISTRIBUTION ==="
$proposed | Group-Object Proposed_country | Select-Object Name, Count | Sort-Object Count -Descending | Format-Table -AutoSize

Write-Host "`n=== PROPOSED STAGE SCOPE DISTRIBUTION ==="
$proposed | Group-Object Proposed_stage_scope | Select-Object Name, Count | Sort-Object Count -Descending | Format-Table -AutoSize
