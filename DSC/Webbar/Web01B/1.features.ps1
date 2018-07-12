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
#region enabled features
$enabled_featurenames=@(
"FileAndStorage-Services",
"File-Services",
"FS-FileServer",
"Storage-Services",
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
"NET-WCF-Services45",
"NET-WCF-HTTP-Activation45",
"NET-WCF-TCP-PortSharing45",
"InkAndHandwritingServices",
"Server-Media-Foundation",
"RDC",
"User-Interfaces-Infra",
"Server-Gui-Mgmt-Infra",
"Desktop-Experience",
"Server-Gui-Shell",
"PowerShellRoot",
"PowerShell",
"PowerShell-ISE",
"WAS",
"WAS-Process-Model",
"WAS-Config-APIs",
"WoW64-Support"
)
#endregion

#region disabled features
$disabled_featurenames=@(
"AD-Certificate",
"ADCS-Cert-Authority",
"ADCS-Enroll-Web-Pol",
"ADCS-Enroll-Web-Svc",
"ADCS-Web-Enrollment",
"ADCS-Device-Enrollment",
"ADCS-Online-Cert",
"AD-Domain-Services",
"AD-Federation-Services",
"ADFS-Federation",
"ADFS-Web-Agents",
"ADFS-Claims",
"ADFS-Windows-Token",
"ADFS-Proxy",
"ADLDS",
"ADRMS",
"ADRMS-Server",
"ADRMS-Identity",
"Application-Server",
"AS-NET-Framework",
"AS-Ent-Services",
"AS-Dist-Transaction",
"AS-WS-Atomic",
"AS-Incoming-Trans",
"AS-Outgoing-Trans",
"AS-TCP-Port-Sharing",
"AS-Web-Support",
"AS-WAS-Support",
"AS-HTTP-Activation",
"AS-MSMQ-Activation",
"AS-Named-Pipes",
"AS-TCP-Activation",
"DHCP",
"DNS",
"Fax",
"FS-BranchCache",
"FS-Data-Deduplication",
"FS-DFS-Namespace",
"FS-DFS-Replication",
"FS-Resource-Manager",
"FS-VSS-Agent",
"FS-iSCSITarget-Server",
"iSCSITarget-VSS-VDS",
"FS-NFS-Service",
"Hyper-V",
"NPAS",
"NPAS-Policy-Server",
"NPAS-Health",
"NPAS-Host-Cred",
"Print-Services",
"Print-Server",
"Print-Scan-Server",
"Print-Internet",
"Print-LPD-Service",
"RemoteAccess",
"DirectAccess-VPN",
"Routing",
"Remote-Desktop-Services",
"RDS-Connection-Broker",
"RDS-Gateway",
"RDS-Licensing",
"RDS-RD-Server",
"RDS-Web-Access",
"RDS-Virtualization",
"Web-Http-Redirect",
"Web-DAV-Publishing",
"Web-ODBC-Logging",
"Web-Dyn-Compression",
"Web-CertProvider",
"Web-Digest-Auth",
"Web-Url-Auth",
"Web-AppInit",
"Web-CGI",
"Web-Includes",
"Web-WebSockets",
"Web-Ftp-Server",
"Web-Ftp-Service",
"Web-Ftp-Ext",
"Web-WHC",
"Web-Mgmt-Compat",
"Web-Metabase",
"Web-Lgcy-Mgmt-Console",
"Web-Lgcy-Scripting",
"Web-WMI",
"WDS",
"WDS-Deployment",
"WDS-Transport",
"UpdateServices",
"UpdateServices-WidDB",
"UpdateServices-Services",
"UpdateServices-DB",
"VolumeActivation",
"NET-HTTP-Activation",
"NET-Non-HTTP-Activ",
"NET-WCF-MSMQ-Activation45",
"NET-WCF-Pipe-Activation45",
"NET-WCF-TCP-Activation45",
"BITS",
"BITS-IIS-Ext",
"BITS-Compact-Server",
"BitLocker",
"BitLocker-NetworkUnlock",
"BranchCache",
"NFS-Client",
"Data-Center-Bridging",
"EnhancedStorage",
"Failover-Clustering",
"GPMC",
"Internet-Print-Client",
"IPAM",
"ISNS",
"LPR-Port-Monitor",
"ManagementOdata",
"MSMQ",
"MSMQ-Services",
"MSMQ-Server",
"MSMQ-Directory",
"MSMQ-HTTP-Support",
"MSMQ-Triggers",
"MSMQ-Multicasting",
"MSMQ-Routing",
"MSMQ-DCOM",
"Multipath-IO",
"NLB",
"PNRP",
"qWave",
"CMAK",
"Remote-Assistance",
"RSAT",
"RSAT-Feature-Tools",
"RSAT-SMTP",
"RSAT-Feature-Tools-BitLocker",
"RSAT-Feature-Tools-BitLocker-RemoteAdminTool",
"RSAT-Feature-Tools-BitLocker-BdeAducExt",
"RSAT-Bits-Server",
"RSAT-Clustering",
"RSAT-Clustering-Mgmt",
"RSAT-Clustering-CmdInterface",
"IPAM-Client-Feature",
"RSAT-NLB",
"RSAT-SNMP",
"WSRM-RSAT",
"RSAT-WINS",
"RSAT-Role-Tools",
"RSAT-AD-Tools",
"RSAT-AD-PowerShell",
"RSAT-ADDS",
"RSAT-AD-AdminCenter",
"RSAT-ADDS-Tools",
"RSAT-NIS",
"RSAT-ADLDS",
"RSAT-Hyper-V-Tools",
"Hyper-V-Tools",
"Hyper-V-PowerShell",
"RSAT-RDS-Tools",
"RSAT-RDS-Gateway",
"RSAT-RDS-Licensing-Diagnosis-UI",
"RDS-Licensing-UI",
"UpdateServices-RSAT",
"UpdateServices-API",
"UpdateServices-UI",
"RSAT-ADCS",
"RSAT-ADCS-Mgmt",
"RSAT-Online-Responder"
"RSAT-ADRMS",
"RSAT-DHCP",
"RSAT-DNS-Server",
"RSAT-Fax",
"RSAT-File-Services",
"RSAT-DFS-Mgmt-Con",
"RSAT-FSRM-Mgmt",
"RSAT-NFS-Admin",
"RSAT-CoreFile-Mgmt",
"RSAT-NPAS",
"RSAT-Print-Services",
"RSAT-RemoteAccess",
"RSAT-RemoteAccess-Mgmt"
"RSAT-RemoteAccess-Powershell",
"WDS-AdminPack",
"RSAT-VA-Tools",
"RPC-over-HTTP-Proxy",
"Simple-TCPIP",
"SMTP-Server",
"SNMP-Service",
"SNMP-WMI-Provider",
"Subsystem-UNIX-Apps",
"Telnet-Client",
"Telnet-Server",
"TFTP-Client",
"Biometric-Framework",
"WFF",
"Windows-Identity-Foundation"
"Windows-Internal-Database",
"PowerShell-V2",
"DSC-Service"
"WindowsPowerShellWebAccess",
"WAS-NET-Environment",
"Search-Service",
"Windows-Server-Backup"
"Migration",
"WindowsStorageManagementService",
"WSRM"
"Windows-TIFF-IFilter",
"WinRM-IIS-Ext",
"WINS",
"Wireless-Networking",
"XPS-Viewer"
)
#endregion

$computername.ForEach({
    try 
    {
        $cimsession = (New-CimSession -ComputerName $_ -Credential $credz)

        Configuration Configuration_Features
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
                #region windows features

                $enabled_featurenames.ForEach({
                    WindowsFeature $_ {
                        Name = $_
                        Ensure = 'Present'
                    }
                }) #foreach

                $disabled_featurenames.ForEach({
                    WindowsFeature $_ {
                        Name = $_
                        Ensure = 'Absent'
                    }
                }) #foreach
                #endregion
            }
        }

        Configuration_Features -OutputPath C:\Users\tal008\Desktop\DSC-tester -Computername $computername -verbose
        break
        ## Start-DscConfiguration -ComputerName $computername -Path C:\Users\tal008\Desktop\DSC-tester -Wait -Verbose -Credential $credz -Force
        # Test-DscConfiguration -ComputerName $computername -Credential $credz
        # Get-DscConfiguration -CimSession $cimsession
        # Remove-DscConfigurationDocument -CimSession $cimsession -Stage pending -Force
        # Get-DscConfigurationStatus -CimSession (New-CimSession $computername -Credential tal008adm)

    }
    catch{ "Gick inte att skapa cimsession till $_ " }
})





