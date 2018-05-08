$sessionName = "JeaEndpointDemo"
if(Get-PSSessionConfiguration -Name $sessionName -ErrorAction SilentlyContinue)
{
    Unregister-PSSessionConfiguration -Name $sessionName -ErrorAction Stop
}
$ErrorActionPreference = 'Stop'

# IMPORTANT: Replace these group names with the correct ones for your environment
$GeneralLev1Group = "lovdot103b\JeaUser"
#$GeneralLev2Group = "lovdot103b\JeaUser"
$IISLev1Group     = "lovdot103b\thomas"
#$IISLev2Group     = "lovdot103b\JeaUser"


# Create the Role Capability file. RoleCapabilities blir namnet "Maintenance" i detta fallet.
#New-PSRoleCapabilityFile -Path “$env:ProgramFiles\WindowsPowerShell\Modules\DemoModule2\RoleCapabilities\Maintenance.psrc" @MaintenanceRoleCapabilityCreationParams

# Specify the session configuration details
$PSSCparams = @{
    Path = "$env:ProgramData\JEAConfiguration\SampleJEAConfig.pssc"
    Author = 'Microsoft and Microsoft IT'
    Description = 'This session configuration grants users access to the general and IIS server maintenance roles.'
    SessionType = 'RestrictedRemoteServer'
    TranscriptDirectory = "$env:ProgramData\JEAConfiguration\Transcripts"
    RunAsVirtualAccount = $true
    Full = $true
    RoleDefinitions = @{
        $GeneralLev1Group = @{ RoleCapabilities = 'General-Lev1' }
        #$GeneralLev2Group = @{ RoleCapabilities = 'General-Lev1', 'General-Lev2' }
        $IISLev1Group     = @{ RoleCapabilities = 'IIS-Lev1' }
        #$IISLev2Group     = @{ RoleCapabilities = 'IIS-Lev1', 'IIS-Lev2' }
    }
}

# Ensure the PSSC path exists
if (-not (Test-Path "$env:ProgramData\JEAConfiguration")) {
    New-Item "$env:ProgramData\JEAConfiguration" -ItemType Directory
}

# Create the PSSC
New-PSSessionConfigurationFile @PSSCparams

# Register the PSSC
# Note: you can change the name of the endpoint to anything you want
Register-PSSessionConfiguration -Path $PSSCparams['Path'] -Name $sessionName -Verbose

# Try out the JEA endpoint
# $Sune=get-credential lovdot103b\JeaUser
# Enter-PSSession -ComputerName . -ConfigurationName 'JEA' -Credential $Sune
