 #Importera lokal fil med namn
 $namefile = Import-CSV "$(get-location)\Users.csv"


 $scriptblock = {
 
 $names = $using:namefile
 
 $NumUsers = 100
 
 $OU = "CN=Users,DC=supercow,DC=se"
 $Departments = @("IT","Ekonomi","Administration","HR")
 $firstnames = $Names.Firstname
 
 $lastnames = $Names.Lastname
 $Password = "P@ssw0rd"
 
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
 
       $i = get-random -Minimum 0 -Maximum $Departments.count
       $Department = $Departments[$i]
 
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
           –SamAccountName $username -UserPrincipalName $upn `
           -GivenName $firstname -Surname $lastname -description "Test User" `
           -Path $ou –Enabled $true –ChangePasswordAtLogon $false -Department $Department `
           -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -force) 
       $NumUsers-- 
 
 }
 
 }
 #Slut scriptblock
 
 
 
 <# Kör script remote
     $s=New-PSSession localhost -Credential administrator
     icm -Session $s -ScriptBlock $scriptblock 
 #>
     
 
