
$value ="00,00,00,00,00,00,00,00,02,00,00,00,00,00,3A,00,00,00,00,00"
$hexified = $value.Split(',') | ForEach-Object { "0x$_"}

New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout\' -Name "Scancode map" -PropertyType "Binary" -Value $hexified
Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout\' 