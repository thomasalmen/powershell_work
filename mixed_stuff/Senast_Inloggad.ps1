$com="."
Get-WmiObject -Class Win32_NetworkLoginProfile -ComputerName $com | 
Sort-Object -Property LastLogon -Descending | 
Select-Object -Property *  | 
Where-Object {$_.LastLogon -match "(\d{14})"} | 
Foreach-Object { New-Object PSObject -Property @{ Name=$_.Name;LastLogon=[datetime]::ParseExact($matches[0], "yyyyMMddHHmmss", $null)}}
