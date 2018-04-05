## Skapa en endpoint (Session Configuration)
#$nonadmincredz=Get-Credential orebroll\tal008
# Ta bort gammal endpoint JEADemo2 
Unregister-PSSessionConfiguration -Name JEADemo2

$SessionName = "JEADemo2"
# STEP 1: Run the following script to generate a blank PowerShell Session Configuration file.
# This generates a blank Session Configuration File called “JEADemo2.pssc”  
New-PSSessionConfigurationFile -Path "$env:ProgramData\JEAConfiguration\JEADemo2.pssc" -SessionType 'RestrictedRemoteServer' -TranscriptDirectory “C:\ProgramData\JEAConfiguration\Transcripts” -RunAsVirtualAccount -RoleDefinitions @{'orebroll\tal008' = @{ RoleCapabilities =  'Maintenance' }}

#STEP 2: Open it in PowerShell ISE, or your favorite text editor to edit.
# psEdit "$env:ProgramData\JEAConfiguration\JEADemo2.pssc" 

#To create a Session Configuration from a Session Configuration file, you need to register the file.  This requires a few pieces of information:
# 1.	The path to the Session Configuration File (.pssc).
# 2.	The name of your registered Session Configuration The argument users provide to the “ConfigurationName” parameter when they connect to your endpoint.

Register-PSSessionConfiguration -Name $SessionName -Path "$env:ProgramData\JEAConfiguration\JEADemo2.pssc"
Restart-Service WinRM 

# Test the Endpoint
# Enter-PSSession -ComputerName . -ConfigurationName JEADemo2 -Credential $nonadmincredz