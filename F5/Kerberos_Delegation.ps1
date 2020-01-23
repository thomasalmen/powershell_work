New-ADUser -Name "F5-DELEGATION" -UserPrincipalName F5-SSO@supercow.se -SamAccountName "F5-DELEGATION" -PasswordNeverExpires $true -Enabled $true -AccountPassword (ConvertTo-SecureString -AsPlainText "P@ssw0rd" -Force) 

#Fixa SPN 
Set-AdUser -Identity F5-SSO -ServicePrincipalNames @{Add="host/F5-DELEGATIONHOST.supercow.se"}


# Fixa delegationrättighet. I detta fall mot websajt testweb.xxx.se
Get-AdUser -Identity F5-DELEGATION | Set-ADObject -Add @{"msDS-AllowedToDelegateTo"="http/testweb.xxx.se"}  
 

# Sätt delegationsrättighet för denna specifia service 
Set-ADAccountControl -Identity F5-DELEGATION -TrustedForDelegation $false 
Set-ADAccountControl -Identity F5-DELEGATION -TrustedToAuthForDelegation $true  
