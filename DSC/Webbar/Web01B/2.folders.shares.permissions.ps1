if($PSVersionTable.PSVersion.Major -lt 5 ){Write-host "Detta script kräver Powershell version 5 eller senare!" -ForegroundColor Red ;break}
#$VerbosePreference="SilentlyContinue"
try
{
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal -ArgumentList $identity
    if(! ($principal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator ) ) -eq $true) { return "Detta script måste köras som administrator!"}
}
catch
{
    throw "Failed to determine if the current user has elevated privileges. The error was: '{0}'." -f $_
}

#$credz=(Get-Credential tal008adm)
$computername = "web01b"


$computername.ForEach({
    try 
    {
        $cimsession = (New-CimSession -ComputerName $_ -Credential $credz)
    }
    catch{ "Gick inte att skapa cimsession till $_ " }
})

Configuration Configuration_Folders
{
    param(
        [Parameter(Mandatory=$true)]
        $computername
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -Module xWebAdministration -ModuleVersion 2.0.0.0
    Import-DscResource -ModuleName xSMBShare -ModuleVersion 2.1.0.0
    Import-DscResource -ModuleName cNtfsAccessControl

    Node $computername
    {

        #region Folders
        File WebsitesFolder
        {
            DestinationPath = "d:\websites"
            Ensure = 'Present'
            Type = "Directory"
        }
        File BasisFolder
        {
            DestinationPath = "d:\websites\basis.orebroll.se"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }

        File behorighetsportalenFolder
        {
            DestinationPath = "d:\websites\behorighetsportalen.orebroll.se"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }
        File efotoFolder
        {
            DestinationPath = "d:\websites\efoto.orebroll.se"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }                
        File jourlistanFolder
        {
            DestinationPath = "d:\websites\jourlistan.orebroll.se"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }                        
        File labmedFolder
        {
            DestinationPath = "d:\websites\labmed.orebroll.se"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }                        
        File loggwebbFolder
        {
            DestinationPath = "d:\websites\loggwebb.orebroll.se"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }                                
        File lokalbokningFolder
        {
            DestinationPath = "d:\websites\lokalbokning.orebroll.se"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }                            
        File netassetFolder
        {
            DestinationPath = "d:\websites\netasset.orebroll.se"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }   
        File spFolder
        {
            DestinationPath = "d:\websites\sp.orebroll.se"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }           
        File transporterFolder
        {
            DestinationPath = "d:\websites\transporter.orebroll.se"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }                   
        File webprogFolder
        {
            DestinationPath = "d:\websites\webprog.orebroll.se"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }
              

        #endregion





#region fileshares and permissions

        <# katalogadmin #>
        xSMBShare katalogadminShare {
            DependsOn = '[file]WebsitesFolder'
            Ensure = 'Present'
            Name = "katalogadmin.orebroll.se$"
            Description = 'Share för katalogstjänst self-deploy'
            Path = 'D:\websites\katalogadmin.orebroll.se'
            FullAccess = "authenticated users"
        }
        cNtfsPermissionEntry katalogadminPermissions
        {
            Ensure = 'Present'
            Path = "D:\websites\katalogadmin.orebroll.se"
            DependsOn = '[xSMBShare]katalogadminShare'
            Principal = 'DL_WebDeploy_Katalogtjanst_M'
            AccessControlInformation = @(

                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }
        <# /katalogadmin #>

        <# LABMED #>
        xSMBShare labmedShare {
            DependsOn = '[file]WebsitesFolder'
            Ensure = 'Present'
            Name = "labmed.orebroll.se$"
            Description = 'Share för förgodkända ändringar i labmed.orebroll.se'
            Path = 'D:\websites\labmed.orebroll.se\CurrentVersion'
            FullAccess = "authenticated users"
        }

        #orebroll\aka089
        cNtfsPermissionEntry labmedPermissions
        {
            Ensure = 'Present'
            Path = "D:\websites\labmed.orebroll.se\CurrentVersion"
            DependsOn = '[xSMBShare]labmedShare'
            Principal = 'aka089'
            AccessControlInformation = @(

                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }
        <# /LABMED #>

        <# VardRapp #>
        xSMBShare vardrappShare {
            DependsOn = '[file]WebsitesFolder'
            Ensure = 'Present'
            Name = "vardrapp"
            Description = 'Tillfälligt share så johan björk kan felsöka'
            Path = 'D:\websites\webapp.orebroll.se\CurrentVersion\vardrapp'
            FullAccess = "authenticated users"
        }
        cNtfsPermissionEntry vardrappPermissions
        {
            Ensure = 'Present'
            Path = "D:\websites\webapp.orebroll.se\CurrentVersion\vardrapp"
            DependsOn = '[xSMBShare]vardrappShare'
            Principal = 'bjo051'
            AccessControlInformation = @(

                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }
        <# /VardRapp #>

        <# xmlShare #>
        xSMBShare xmlShare {
            #DependsOn = '[file]WebsitesFolder'
            Ensure = 'Present'
            Name = "XML$"
            Description = 'Share för förgodkända ändringar i labmed.orebroll.se'
            Path = 'D:\websites\webapp.orebroll.se\CurrentVersion\mvkchangedbookings\XML'
            FullAccess = "authenticated users"
        }
        cNtfsPermissionEntry xmlPermissions
        {
            Ensure = 'Present'
            Path = "D:\websites\webapp.orebroll.se\CurrentVersion\mvkchangedbookings\XML"
            DependsOn = '[xSMBShare]xmlShare'
            Principal = 'aek028'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }
        cNtfsPermissionEntry xmlPermissions2
        {
            Ensure = 'Present'
            Path = "D:\websites\webapp.orebroll.se\CurrentVersion\mvkchangedbookings\XML"
            DependsOn = '[xSMBShare]xmlShare'
            Principal = 'scl002'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }
        cNtfsPermissionEntry xmlPermissions3
        {
            Ensure = 'Present'
            Path = "D:\websites\webapp.orebroll.se\CurrentVersion\mvkchangedbookings\XML"
            DependsOn = '[xSMBShare]xmlShare'
            Principal = 'mgu017'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }
        <# /xmlShare #>

            

        #endregion

    }
}

Configuration_Folders -OutputPath $env:TEMP -Computername $computername -verbose
Start-DscConfiguration -ComputerName $computername -Path $env:TEMP -Wait -Verbose -Credential $credz -Force
# Test-DscConfiguration -ComputerName $computername -Credential $credz
# Get-DscConfiguration -CimSession $cimsession
# Remove-DscConfigurationDocument -CimSession $cimsession -Stage pending -Force
# Get-DscConfigurationStatus -CimSession (New-CimSession $computername -Credential tal008adm)