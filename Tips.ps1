$servers="Server1","Server2"
$services="MyService1","MyService2"

Write-Warning 'What would you like this script to do? '
Write-Warning '1. Stop Services'
Write-Warning '2. Start Services'
Write-Warning '3. Re-start Services'
Write-Warning '4. Quit'
while($ActionType.length -lt 1)
{
 $ActionType=Read-Host "Enter the number to correspond with your desired action. " 
 $ActionType=[string]$ActionType.trim()
}
 
switch ($ActionType)
{
 1 
 {
  $stop=$true
  $start=$false
 }
 2 
 {
  $stop=$false
  $start=$true
 }
 3
 {
  $stop=$true
  $start=$true
 }
 4 {Exit}
 default {throw ("Unexpected input from action type inquriy.")}
}
 
foreach ($server in $servers)
{
 if ($stop)
 {
  foreach ($service in $services)
  {
   Write-Debug "Stopping $service on $Server"
   Invoke-Command -ComputerName $server -ScriptBlock {Stop-Service -Name $args[0]} -ArgumentList $service
   if ($? -eq $false){throw "TERMINATING SCRIPT; UNABLE TO STOP SERVICE. Check permissions and ensure target machine $server is up"}
   Write-Warning "Service $service stopped on $server"
  }
 }
 start-sleep -Milliseconds 500

 if ($start)
 {
  #Start Services
  foreach ($service in $services)
  {
   Write-Debug "Starting $service on $server"
   Invoke-Command -ComputerName $server -ScriptBlock {Start-Service -Name $args[0]} -ArgumentList $service
   if ($? -eq $false){throw "TERMINATING SCRIPT; UNABLE TO START SERVICE. Check permissions and ensure target machine $server is up"}
   Write-Warning "Service $service started on $server"
  }
 }
}
Write-Warning "All actions complete!"