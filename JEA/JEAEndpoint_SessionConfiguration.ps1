
#Skapar endpoint som vem som helst kan ansluta till.
# Går att låsa ner "lätt" med -LanguageMode NoLanguage|RestrictedLanguage
# The first pair of commands uses the **New-PSSessionConfigurationFile** cmdlet to create two session configuration files. The first command creates a no-language file. The second command creates a restricted-language file. Other than the value of the *LanguageMode* parameter, the session configuration files are equivalent.
# New-PSSessionConfigurationFile -Path .\NoLanguage.pssc -LanguageMode NoLanguage
# New-PSSessionConfigurationFile -Path .\RestrictedLanguage.pssc -LanguageMode RestrictedLanguage
# The second pair of commands uses the configuration files to create session configurations on the local computer.
# Register-PSSessionConfiguration -Path .\NoLanguage.pssc -Name NoLanguage -Force
# Register-PSSessionConfiguration -Path .\RestrictedLanguage.pssc -Name RestrictedLanguage -Force
# The third pair of commands creates two sessions, each of which uses one of the session configurations that were created in the previous command pair.
#$NoLanguage = New-PSSession -ComputerName . -ConfigurationName NoLanguage
#$RestrictedLanguage = New-PSSession -ComputerName . -ConfigurationName RestrictedLanguage






## Skapa en endpoint (Session Configuration)
# Scriptet använder en role capability fil "Maintenance"
# Den styr vad olika users/grupper har tillgång till.
$nonadminuser='lovdot103b\JeaUser'
#$sune=Get-Credential lovdot103b\JeaUser

# Namn på sessionen (Endpointen)
$SessionName = "JEADemo2"

# Ta bort gammal endpoint JEADemo2 
if(Get-PSSessionConfiguration -Name $sessionName -ErrorAction SilentlyContinue)
{
    Unregister-PSSessionConfiguration -Name $SessionName -ErrorAction Stop
}


New-PSRoleCapabilityFile -Path "$env:ProgramData\JEAConfiguration\Maintenance.psrc" -VisibleCmdlets "Restart-Service", @{ Name = "-Computer"; Parameters = @{ Name = "ComputerName"; ValidatePattern = "VDI\d+" }}


# This generates a blank Session Configuration File called “JEADemo2.pssc”  
New-PSSessionConfigurationFile -Path "$env:ProgramData\JEAConfiguration\JEADemo2.pssc" -SessionType 'RestrictedRemoteServer' -TranscriptDirectory “C:\ProgramData\JEAConfiguration\Transcripts” -RunAsVirtualAccount -LanguageMode FullLanguage -RoleDefinitions @{$nonadminuser = @{ RoleCapabilities = 'Maintenance' }} 

#STEP 2: Open it in PowerShell ISE, or your favorite text editor to edit.
# psEdit "$env:ProgramData\JEAConfiguration\JEADemo2.pssc" 

#To create a Session Configuration from a Session Configuration file, you need to register the file.
# Requires 
# 1. the path to the Session Configuration File (.pssc).
# 2. The name of your registered Session Configuration ($sessionname)

Register-PSSessionConfiguration -Name $SessionName -Path "$env:ProgramData\JEAConfiguration\JEADemo2.pssc"
Restart-Service WinRM 

# Test the Endpoint
# $sune=get-credential lovdot103b\JeaUser
 Enter-PSSession -ComputerName . -ConfigurationName JEADemo2 -Credential $sune