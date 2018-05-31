## Sätter upp JEA för katalogtjänst så de kan starta om Tomcat

if($PSVersionTable.PSVersion.Major -lt 5 ){Write-host "Detta script kräver Powershell version 5 eller senare!" -ForegroundColor Red ;break}

# Set Up Maintenance Role Capability File

# Create some directorys the demo module, which will contain the demo Role Capability File
New-Item -Path “$env:ProgramFiles\WindowsPowerShell\Modules\JEA_Katalogtjanst” -ItemType Directory -Force
New-ModuleManifest -Path “$env:ProgramFiles\WindowsPowerShell\Modules\JEA_Katalogtjanst\JEA_Katalogtjanst.psd1"

# Run the following commands to create the demo “role capability” file we will be using for the next section.
New-Item -Path “$env:ProgramFiles\WindowsPowerShell\Modules\JEA_Katalogtjanst\RoleCapabilities” -ItemType Directory  -Force

if(-not (Test-Path “$env:ProgramFiles\WindowsPowerShell\Modules\JEA_Katalogtjanst\Transcripts" ))
{
    New-Item -Path “$env:ProgramFiles\WindowsPowerShell\Modules\JEA_Katalogtjanst\Transcripts” -ItemType Directory -Force
}

# Parameters for the role capability
$MaintenanceRoleCapabilityCreationParams = @{
    Author = "tal008"
    ModulesToImport= "Microsoft.PowerShell.Core"
    
    VisibleCmdlets = 
    @{ Name = 'restart-Service'; Parameters = @{ Name = 'Name'; ValidateSet = 'Katalogadmin' }}, 
    @{ Name = 'stop-Service'; Parameters = @{ Name = 'Name'; ValidateSet = 'Katalogadmin' }}, 
    @{ Name = ‘start-Service'; Parameters = @{ Name = 'Name'; ValidateSet = "Katalogadmin" }}

    #VisibleExternalCommands = "C:\Windows\system32\ipconfig.exe"
    CompanyName="OLL"
    #FunctionDefinitions = @{ Name = 'Get-UserInfo'; ScriptBlock = {$PSSenderInfo}}
}

# Create the Role Capability file
New-PSRoleCapabilityFile -Path "$env:ProgramFiles\WindowsPowerShell\Modules\JEA_Katalogtjanst\RoleCapabilities\KatalogMaintenance.psrc" @MaintenanceRoleCapabilityCreationParams

# Create and Register Session Configuration File
# Determine domain
# $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain

#Replace with your non-admin group name
#$NonAdministrator = "orebroll\tal008"




$JEAConfigParams = @{
        SessionType= "RestrictedRemoteServer" 
        RunAsVirtualAccount = $true
        #Testkommentar
        RoleDefinitions = @{ 
            'orebroll\tal008'    = @{ RoleCapabilities = 'KatalogMaintenance' }
            'orebroll\DL_WebDeploy_Katalogtjanst_M'    = @{ RoleCapabilities = 'KatalogMaintenance' }
        }
        
        TranscriptDirectory = "$env:ProgramFiles\WindowsPowerShell\Modules\JEA_Katalogtjanst\Transcripts”
        }
     


# Här sätts namnet
$sessionName = "KatalogMaintenance"

if(Get-PSSessionConfiguration -Name $sessionName -ErrorAction SilentlyContinue)
{
    Unregister-PSSessionConfiguration -Name $sessionName -ErrorAction Stop
}


if(-not (Test-Path "$env:ProgramFiles\WindowsPowerShell\Modules\JEA_Katalogtjanst\JEAConfiguration" ))
{
    New-Item -Path "$env:ProgramFiles\WindowsPowerShell\Modules\JEA_Katalogtjanst\JEAConfiguration" -ItemType Directory -Force
}
New-PSSessionConfigurationFile -Path "$env:ProgramFiles\WindowsPowerShell\Modules\JEA_Katalogtjanst\JEAConfiguration\JEADemo.pssc" @JEAConfigParams
#endregion

#region Register the session configuration
Register-PSSessionConfiguration -Name $sessionName -Path "$env:ProgramFiles\WindowsPowerShell\Modules\JEA_Katalogtjanst\JEAConfiguration\JEADemo.pssc"
Restart-Service WinRM 

#endregion

#Enter-PSSession -ComputerName . -ConfigurationName $sessionName -Credential $credz
