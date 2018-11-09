

#$Names = Import-CSV "C:\Users\thalm\OneDrive\powershell_work\DSC\DEV\DomainController\CreateUsers\FirstLastEurope.csv"
$Namesfile = Import-CSV "C:\Users\thalm\OneDrive\powershell_work\DSC\DEV\DomainController\CreateUsers\FirstLastEurope.csv"

$scriptblock={

$names = import-csv c:\windows\temp\users.csv
#$Names = Import-CSV "C:\Users\thalm\OneDrive\powershell_work\DSC\DEV\DomainController\CreateUsers\FirstLastEurope.csv"

$NumUsers = 100
$OU = "CN=Users,DC=supercow,DC=se"
$Departments = @("IT","Finance","Logistics","Sourcing","Human Resources")

$firstnames = $Names.Firstname
$lastnames = $Names.Lastname
$Password = "Pa`$`$w0rd"

#Import required module ActiveDirectory
try{
Import-Module ActiveDirectory -ErrorAction Stop
}
catch{
throw "Module GroupPolicy not Installed"
}

while ($NumUsers -gt 0)
{
      #Choose a 'random' department Firstname and Lastname
      
      $i = Get-Random -Minimum 0 -Maximum $firstnames.count
      $firstname = $FirstNames[$i]
      $i = Get-Random -Minimum 0 -Maximum $lastnames.count
      $lastname = $LastNames[$i]

      if (($firstname -eq "Johan") -or ($firstname -eq  "Andreas")) {
                $Department = "Cool Department" 
            } else {
                $i = get-random -Minimum 0 -Maximum $Departments.count
                $Department = $Departments[$i]
            }
      #Generate username and check for duplicates
      
      $username = $firstname.Substring(0,3).tolower() + $lastname.Substring(0,3).tolower()
      $exit = 0
      $count = 1
        do
        { 
             try { 
                 $userexists = Get-AdUser -Identity $username
                 $username = $firstname.Substring(0,3).tolower() + $lastname.Substring(0,3).tolower() + $count++
             }
             catch {
                 $exit = 1
             }
         }
        while ($exit -eq 0)

      #Set Displayname and UserPrincipalNBame
      $displayname = $firstname + " " + $lastname
      $upn = $username + "@" + (get-addomain).DNSRoot

      #Create the user
      Write-Host "Creating user $username in $ou"
      
      New-ADUser –Name $displayname –DisplayName $displayname `
      <#           –SamAccountName $username -UserPrincipalName $upn `
                 -GivenName $firstname -Surname $lastname -description "Test User" `
                 -Path $ou –Enabled $true –ChangePasswordAtLogon $false -Department $Department `
                 -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -force) 
      #>
      $NumUsers-- 
}

}

 #Slut scriptblock


$s=New-PSSession dc -Credential administrator
Copy-Item C:\Users\thalm\OneDrive\powershell_work\DSC\DEV\DomainController\CreateUsers\FirstLastEurope.csv -Destination c:\windows\temp\users.csv -ToSession $s
icm -Session $s  { iex  $using:scriptblock }
