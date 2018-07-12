cls
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

#Find-Module cNtfsAccessControl, PSDesiredStateConfiguration, xSMBShare, xWebAdministration | Install-Module -Force
#Get-DscResource -Module PSDesiredStateConfiguration
#Get-DscResource -Module xSMBShare
#Get-DscResource -Module xWebAdministration
#Get-DscResource -Module cNtfsAccessControl


$dscResources=@("PSDesiredStateConfiguration","xWebAdministration","xSMBShare","cNtfsAccessControl")

$enabled_featurenames=@(
"Web-Server",
"Web-WebServer",
"Web-Common-Http",
"Web-Default-Doc",
"Web-Dir-Browsing",
"Web-Http-Errors",
"Web-Static-Content",
"Web-Health",
"Web-Http-Logging",
"Web-Custom-Logging",
"Web-Log-Libraries",
"Web-Request-Monitor",
"Web-Http-Tracing",
"Web-Performance",
"Web-Stat-Compression",
"Web-Security",
"Web-Filtering",
"Web-Basic-Auth",
"Web-Client-Auth",
"Web-Cert-Auth",
"Web-IP-Security",
"Web-Windows-Auth",
"Web-App-Dev",
"Web-Net-Ext",
"Web-Net-Ext45",
"Web-ASP",
"Web-Asp-Net",
"Web-Asp-Net45",
"Web-ISAPI-Ext",
"Web-ISAPI-Filter",
"Web-Mgmt-Tools",
"Web-Mgmt-Console",
"Web-Scripting-Tools",
"Web-Mgmt-Service",
"NET-Framework-Features",
"NET-Framework-Core",
"NET-Framework-45-Features",
"NET-Framework-45-Core",
"NET-Framework-45-ASPNET",
"NET-WCF-Services45"
)


$disabled_featurenames=@(
"Search-Service",
"Windows-Server-Backup",
"Migration",
"WindowsStorageManagementService",
"WSRM",
"Windows-TIFF-IFilter",
"WinRM-IIS-Ext",
"WINS",
"Wireless-Networking",
"Biometric-Framework",
"WFF",
"Windows-Identity-Foundation",
"Windows-Internal-Database",
"RPC-over-HTTP-Proxy",
"Simple-TCPIP",
"SMTP-Server",
"SNMP-Service",
"SNMP-WMI-Provider",
"Subsystem-UNIX-Apps",
"Telnet-Client",
"Telnet-Server",
"TFTP-Client",
"RSAT-Role-Tools",
"RSAT",
"Multipath-IO",
"NLB",
"PNRP",
"qWave",
"CMAK",
"MSMQ",
"BitLocker",
"BitLocker-NetworkUnlock",
"BranchCache",
"NFS-Client",
"Data-Center-Bridging",
"EnhancedStorage",
"Failover-Clustering",
"GPMC",
"InkAndHandwritingServices",
"Internet-Print-Client",
"IPAM",
"ISNS",
"LPR-Port-Monitor",
"ManagementOdata",
"BITS",
"VolumeActivation",
"UpdateServices",
"WDS",
"Remote-Desktop-Services",
"Print-Services",
"Hyper-V",
"NPAS",
"Application-Server",
"ADLDS",
"ADRMS",
"AD-Domain-Services",
"AD-Federation-Services",
"AD-Certificate"
"DHCP",
"DNS",
"Fax",
"RemoteAccess",
"Web-WHC"
"Remote-Assistance",
"Web-Mgmt-Compat",
"Web-CertProvider",
"PowerShell-ISE"
)

Configuration Configuration_Web01a
{
    param(
        [Parameter(Mandatory=$true)]
        $computername
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration -ModuleVersion 1.20.0.0
    Import-DscResource -ModuleName xSMBShare -ModuleVersion 2.1.0.0
    Import-DscResource -ModuleName cNtfsAccessControl

    Node $computername
    {
        $enabled_featurenames.ForEach({
        #$node.Features.foreach({
            WindowsFeature $_ {
                Name = $_
                Ensure = 'Present'
            }
        }) #foreach

        $disabled_featurenames.ForEach({
        #$node.Features.foreach({
            WindowsFeature $_ {
                Name = $_
                Ensure = 'Absent'
            }
        }) #foreach

        File WebsitesFolder
        {
            DestinationPath = "d:\websites"
            #[DependsOn = [string[]]]
            Ensure = 'Present'
            Type = "Directory"
        }
        File BasisFolder
        {
            DestinationPath = "d:\websites\basis.orebroll.se\CurrentVersion"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }
        File BehorighetsportalenFolder
        {
            DestinationPath = "d:\websites\behorighetsportalen.orebroll.se\CurrentVersion"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }
        File EfotoFolder
        {
            DestinationPath = "d:\websites\efoto.orebroll.se\CurrentVersion"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }
        File EnterpriseModeFolder
        {
            DestinationPath = "d:\websites\enterprisemode"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }
        File JourlistanFolder
        {
            DestinationPath = "d:\websites\jourlistan.orebroll.se\CurrentVersion"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }
        <# Katalogadmin #>
        File KatalogadminApacheFolder
        {
            DestinationPath = "d:\websites\katalogadmin.orebroll.se\apache-tomcat-9.0.4"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }
        File KatalogadminJavaFolder
        {
            DestinationPath = "d:\websites\katalogadmin.orebroll.se\jre1.8.0_151"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }
        <# /Katalogadmin #>

        File LabmedFolder
        {
            DestinationPath = "d:\websites\labmed.orebroll.se\CurrentVersion"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }
        File LoggwebbFolder
        {
            DestinationPath = "d:\websites\loggwebb.orebroll.se\CurrentVersion"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }
        File LokalbokningFolder
        {
            DestinationPath = "d:\websites\lokalbokning.orebroll.se\CurrentVersion"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }
        File NetassetFolder
        {
            DestinationPath = "d:\websites\netasset.orebroll.se\CurrentVersion"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }
        File ProvtagningsanvisningarinternFolder
        {
            DestinationPath = "d:\websites\provtagningsanvisningarintern.orebroll.se\CurrentVersion"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }

        <# Skvader obs absent! #>
        File SkvaderDummyFolder1
        {
            DestinationPath = "d:\websites\skvaderdummy"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Absent'
            Type = "Directory"
            Force = $true
        }
        File SkvaderDummyFolder2
        {
            DestinationPath = "d:\websites\SkvaderEkonomiSystemTjanster"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Absent'
            Type = "Directory"
            Force = $true
        }
        <# Skvader obs absent! #>

        File SpFolder
        {
            DestinationPath = "d:\websites\sp.orebroll.se\CurrentVersion"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }
        File TransporterFolder
        {
            DestinationPath = "d:\websites\transporter.orebroll.se\CurrentVersion"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }
        File WebappFolder
        {
            DestinationPath = "d:\websites\webapp.orebroll.se\CurrentVersion"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }
        File WebprogFolder
        {
            DestinationPath = "d:\websites\webprog.orebroll.se"
            DependsOn = "[File]WebsitesFolder"
            Ensure = 'Present'
            Type = "Directory"
        }



        #region filepermissions
        <#
        cNtfsPermissionEntry localusers
        {
            Ensure = 'Present'
            DependsOn = "[file]Folder1"
            Path = "d:\Easit"
            Principal = 'BUILTIN\Users'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'ReadAndExecute'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }

        cNtfsPermissionEntry jka091 {
            Ensure = 'Present'
            DependsOn = "[file]Folder1"
            Principal = "$($env:userdomain)\jka091"
            Path = 'd:\Easit'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'FullControl'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                })
        }

        #Permissions for admins
        cNtfsPermissionEntry AdminPermissions
        {
            Ensure = 'Present'
            Path = "d:\Easit"
            DependsOn = '[File]folder1'
            Principal = 'BUILTIN\Administrators'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                    Inheritance = 'ThisFolderOnly'
                    NoPropagateInherit = $false
                }
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'ReadAndExecute'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'AppendData', 'CreateFiles'
                    Inheritance = 'SubfoldersAndFilesOnly'
                    NoPropagateInherit = $false
                }
            )
        
        }
        #Grupp dl_cayenne_easit_l read and execute
        cNtfsPermissionEntry dl_cayenne_easit_l
        {
            Ensure = 'Present'
            Path = "d:\Easit"
            DependsOn = '[File]folder1'
            Principal = 'dl_cayenne_easit_l'
            AccessControlInformation = @(

                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'ReadAndExecute'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        
        }

        #Servicekonto srvacc_easit
        cNtfsPermissionEntry srvacc_easit
        {
            Ensure = 'Present'
            Path = "d:\Easit"
            DependsOn = '[File]folder1'
            Principal = 'srvacc_easit'
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
        #>
        #endregion

    





    }
}



# $creds = (Get-Credential tal008adm)
# $cimsession =  (new-cimsession web01a -Credential $creds)

Configuration_Web01a -OutputPath $env:TEMP -Computername web01a -verbose
Start-DscConfiguration -ComputerName web01a -Path $env:TEMP -Wait -Verbose -Credential $creds -Force
# Test-DscConfiguration -ComputerName web01a -Credential $creds
# Get-DscConfiguration -CimSession $cimsession
#Remove-DscConfigurationDocument -CimSession $cimsession -Stage pending -Force
# Get-DscConfigurationStatus -CimSession (New-CimSession web01a -Credential tal008adm)
