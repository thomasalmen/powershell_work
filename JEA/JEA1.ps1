# Set Up Maintenance Role Capability File
# Run the following commands to create the demo “role capability” file we will be using for the next section.  Later in this guide, you will learn about what this file does.
$powerShellPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0" 

# Create some directorys the demo module, which will contain the demo Role Capability File
New-Item -Path “$env:ProgramFiles\WindowsPowerShell\Modules\DemoModule2” -ItemType Directory -Force
New-ModuleManifest -Path “$env:ProgramFiles\WindowsPowerShell\Modules\DemoModule2\DemoModule2.psd1"
New-Item -Path “$env:ProgramFiles\WindowsPowerShell\Modules\DemoModule2\RoleCapabilities” -ItemType Directory  -Force

# Fields in the role capability
$MaintenanceRoleCapabilityCreationParams = @{
    Author = "tal008"
    ModulesToImport= "Microsoft.PowerShell.Core"
    #VisibleCmdlets="Restart-Service"
    
    VisibleCmdlets = 
    @{ Name = 'restart-Service'; Parameters = @{ Name = 'Name'; ValidateSet = 'Katalogadmin' }}, 
    @{ Name = 'stop-Service'; Parameters = @{ Name = 'Name'; ValidateSet = 'Katalogadmin','bits' }}, 
    @{ Name = ‘start-Service'; Parameters = @{ Name = 'Name'; ValidateSet = "Katalogadmin" }}

    #VisibleExternalCommands = "C:\Windows\system32\ipconfig.exe"
    CompanyName="OLL"
    #FunctionDefinitions = @{ Name = 'Get-UserInfo'; ScriptBlock = {$PSSenderInfo}}
}

# Create the Role Capability file
New-PSRoleCapabilityFile -Path “$env:ProgramFiles\WindowsPowerShell\Modules\DemoModule2\RoleCapabilities\Maintenance.psrc" @MaintenanceRoleCapabilityCreationParams



# Create and Register Demo Session Configuration File
# Run the following commands to create and register the demo “session configuration” file we will be using for the next section.
# Later in this guide, you will learn about what this file does.
#Determine domain
#$domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain

#Replace with your non-admin group name
$NonAdministrator = "orebroll\tal008"

$JEAConfigParams = @{
        SessionType= "RestrictedRemoteServer" 
        RunAsVirtualAccount = $true
        #Testkommentar
        RoleDefinitions = @{ 
            'orebroll\bha039'    = @{ RoleCapabilities = 'Maintenance' }
            'orebroll\tal008' = @{ RoleCapabilities = 'Maintenance'}
            'orebroll\aos019'  = @{ RoleCapabilities = 'Maintenance' }
            'orebroll\psa015'  = @{ RoleCapabilities = 'Maintenance' }
            'orebroll\fka011'  = @{ RoleCapabilities = 'Maintenance' }
        }
        
        TranscriptDirectory = "$env:ProgramData\JEAConfiguration\Transcripts”
        }
     
if(-not (Test-Path "$env:ProgramData\JEAConfiguration"))
{
    New-Item -Path "$env:ProgramData\JEAConfiguration” -ItemType Directory -Force
}

# Här sätts namnet
$sessionName = "JEADemo1"

if(Get-PSSessionConfiguration -Name $sessionName -ErrorAction SilentlyContinue)
{
    Unregister-PSSessionConfiguration -Name $sessionName -ErrorAction Stop
}

New-PSSessionConfigurationFile -Path "$env:ProgramData\JEAConfiguration\JEADemo.pssc" @JEAConfigParams
#endregion

#region Register the session configuration
Register-PSSessionConfiguration -Name $sessionName -Path "$env:ProgramData\JEAConfiguration\JEADemo.pssc"
Restart-Service WinRM 

#endregion

#Enter-PSSession -ComputerName . -ConfigurationName $sessionName -Credential $credz
