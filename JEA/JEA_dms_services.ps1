
#Namn på tjänst(-erna) = "Endpointen" som ska tillåta att starta/stoppas
[string[]]$servicename = "is_DMS_Orders","is_DMS_Results"


# Determine domain
# $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain

# Namnet på endpointen "Session name"
$sessionName = "dms_services"


#Namn på PS-modulen
$modulename = "dms_ServiceRestart"

# Removes existing sessionconfiguration with the same name as $sessionName
if(Get-PSSessionConfiguration -Name $sessionName -ErrorAction SilentlyContinue)
{
    Unregister-PSSessionConfiguration -Name $sessionName -ErrorAction Stop
}

# Create directory for the module, which will contain the demo Role Capability File
New-Item -Path “$env:ProgramFiles\WindowsPowerShell\Modules\$modulename” -ItemType Directory -Force

# Create a empty module manifest
New-ModuleManifest -Path “$env:ProgramFiles\WindowsPowerShell\Modules\$modulename\$modulename.psd1" -Author "tal008 - the great"

# Create the “role capability” file we will be using for the next section.
New-Item -Path “$env:ProgramFiles\WindowsPowerShell\Modules\$modulename\RoleCapabilities” -ItemType Directory  -Force

# Create the transcript directory
if(-not (Test-Path “$env:ProgramFiles\WindowsPowerShell\Modules\$modulename\Transcripts" ))
{
    New-Item -Path “$env:ProgramFiles\WindowsPowerShell\Modules\$modulename\Transcripts” -ItemType Directory -Force
}

# Parameters for the role capability
$RoleCapabilityParams = @{
    Author = "tal008 - the great"
    ModulesToImport= "Microsoft.PowerShell.Core"
    
    VisibleCmdlets = 
    @{ Name = 'Get-Service'; Parameters = @{ Name = 'Name'; ValidateSet = $servicename }}, 
    @{ Name = 'Restart-Service'; Parameters = @{ Name = 'Name'; ValidateSet = $servicename }}, 
    @{ Name = 'Stop-Service'; Parameters = @{ Name = 'Name'; ValidateSet = $servicename }}, 
    @{ Name = ‘Start-Service'; Parameters = @{ Name = 'Name'; ValidateSet = $servicename }}
    CompanyName="Region Örebro Län"

}

# Create the Role Capability file  - Filen måste heta likadant som sessionsnamnet
New-PSRoleCapabilityFile -Path "$env:ProgramFiles\WindowsPowerShell\Modules\$modulename\RoleCapabilities\$sessionName.psrc" @RoleCapabilityParams

# Create and Register Session Configuration File
$SessionConfigParams = @{
        RunAsVirtualAccount = $true
        RoleDefinitions = @{ 
            'orebroll\mca034' = @{ RoleCapabilities = $sessionName}
            'orebroll\ean058' = @{ RoleCapabilities = $sessionName}
            'orebroll\lja009' = @{ RoleCapabilities = $sessionName}
            'orebroll\ehe069' = @{ RoleCapabilities = $sessionName}
            'orebroll\tal008' = @{ RoleCapabilities = $sessionName}
        }
        
        TranscriptDirectory = "$env:ProgramFiles\WindowsPowerShell\Modules\$modulename\Transcripts”
        }
     
if(-not (Test-Path "$env:ProgramFiles\WindowsPowerShell\Modules\$modulename\SessionConfiguration" ))
{
    New-Item -Path "$env:ProgramFiles\WindowsPowerShell\Modules\$modulename\SessionConfiguration" -ItemType Directory -Force
}
New-PSSessionConfigurationFile -Path "$env:ProgramFiles\WindowsPowerShell\Modules\$modulename\SessionConfiguration\$modulename.pssc" @SessionConfigParams
#endregion

#region Register the session configuration
Register-PSSessionConfiguration -Name $sessionName -Path "$env:ProgramFiles\WindowsPowerShell\Modules\$modulename\SessionConfiguration\$modulename.pssc"
Restart-Service WinRM 
#endregion

#Enter-PSSession -ComputerName . -ConfigurationName $sessionName -Credential $credz
    