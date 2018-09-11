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

#Find-Module cNtfsAccessControl, xSMBShare, xWebAdministration | Install-Module -Force
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


$ConfigData=@{
    # Node specific data
    AllNodes = @(

       # All Servers need following identical information 
       @{
            NodeName           = '*'
            #PSDscAllowPlainTextPassword = $true;
            #PSDscAllowDomainUser = $true
       },

       # Unique Data for each Role
       @{
            NodeName = 'S1'
            Role = @('Web', 'TestWeb')
           
            #SourcePath = '\\client\WebSiteForDemo' # Content Source Location
            DestinationPath = 'd:\WebSites' # Content Destination Location
            WebAppPoolName = 'AppPool' # Name of the Application Pool to create
            WebSiteName = 'supercow.se' # Name of the website to create - this will also be hostname for DNS
            DomainName = 'supercow.se' # Remaining Domain name for Host Header i.e. Company.com and DNS
            DNSIPAddress = '*' # IP Address for DNS of the Website
        }
      @{
            NodeName = 'S1'
            Role = @('Web', 'TestWeb')
           
            #SourcePath = '\\client\WebSiteForDemo' # Content Source Location
            DestinationPath = 'd:\WebSites' # Content Destination Location
            WebAppPoolName = 'AppPool' # Name of the Application Pool to create
            WebSiteName = 'supercow.se' # Name of the website to create - this will also be hostname for DNS
            DomainName = 'supercow.se' # Remaining Domain name for Host Header i.e. Company.com and DNS
            DNSIPAddress = '*' # IP Address for DNS of the Website
        }
        <#
        @{
            NodeName = 's2'
            Role = @('Web', 'TestSite')
            SourcePath = '' # Content Source Location - not used for this app
            DestinationPath = 'C:\Windows\web\PowerShellWebAccess\wwwroot' # Empty Content Destination - to be filled with app install         
            WebAppPoolName = 'PSWAPool' # Name of the Application Pool to create
            WebSiteName = 'PSWA' # Name of the website to create - this will also be hostname for DNS           
            DomainName = 'Company.Pri' # Remaining Domain name for Host Header i.e. Company.com and DNS            
            DNSIPAddress = '192.168.3.52' # IP Address for DNS of the Website
            ThumbPrint = Invoke-Command -Computername 's2.company.pri' {Get-Childitem Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -like "*wild*"} | Select-Object -ExpandProperty ThumbPrint}
        }
        #>
    );
} 


Configuration Configuration_IIS
{
    param(
        [Parameter(Mandatory=$true)]
        $computername
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration
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
            DependsOn = "WindowsFeature[Web-WebServer]"
            Ensure = 'Present'
            Type = "Directory"
        }
        


    }
}



# $creds = (Get-Credential tal008adm)
# $cimsession =  (new-cimsession web01a -Credential $creds)

Configuration_IIS -OutputPath $env:TEMP -verbose
Start-DscConfiguration -ComputerName web01a -Path $env:TEMP -Wait -Verbose -Credential $creds -Force
# Test-DscConfiguration -ComputerName web01a -Credential $creds
# Get-DscConfiguration -CimSession $cimsession
#Remove-DscConfigurationDocument -CimSession $cimsession -Stage pending -Force
# Get-DscConfigurationStatus -CimSession (New-CimSession web01a -Credential tal008adm)