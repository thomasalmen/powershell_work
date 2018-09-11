# DSC Configuration Script 
# Installerar en DC och två st webbar.

Configuration DSC
{

    param
    (
        [Parameter(Mandatory)] 
        [pscredential]$SafemodeAdministratorCred, 

        [Parameter(Mandatory)] 
        [pscredential]$DomainAdministratorCred, 

        [Parameter(Mandatory)] 
        [pscredential]$ADUserCred

        #[Parameter(Mandatory=$true)]
        #[ValidateNotNullorEmpty()]
        #[PsCredential]$creds
    )

    # Import DSC Resources
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration

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

    Node $AllNodes.nodename {
        
       LocalConfigurationManager
        {
            # Går att ha satt till $true men enbart för testmiljö
            RebootNodeIfNeeded = $false
            # The thumbprint of a certificate used to secure credentials passed in a configuration.
            CertificateId = $node.Thumbprint
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = "ApplyAndAutoCorrect"
        }
    }


    Node $AllNodes.Where{$_.Role -eq "DC01"}.Nodename
    {

        # Install Windows Feature "Active Directory Domain Services".
        WindowsFeature ADDSInstall
        {
            Ensure = "present"
            Name   = "AD-Domain-Services"
        }
        WindowsFeature InstallTools
        {
            name = "RSAT-ADDS"
            ensure='Present'
        }
        # Create AD Domain specified in HADCServerConfigData.
        xADDomain FirstDC
        {
            # Name of the remote domain. If no parent name is specified, this is the fully qualified domain name for the first domain in the forest.
            DomainName                    = $Node.DomainName
            # Credentials used to query for domain existence.
            DomainAdministratorCredential = $DomainAdministratorCred
            # Password for the administrator account when the computer is started in Safe Mode.
            SafemodeAdministratorPassword = $SafemodeAdministratorCred
            # Specifies the fully qualified, non-Universal Naming Convention (UNC) path to a directory on a fixed disk of the local computer that contains the domain database (optional).
            DatabasePath                  = "C:\NTDS"
            # Specifies the fully qualified, non-UNC path to a directory on a fixed disk of the local computer where the log file for this operation will be written (optional).
            LogPath                       = "C:\NTDS"
            # Specifies the fully qualified, non-UNC path to a directory on a fixed disk of the local computer where the Sysvol file will be written. (optional)
            SysvolPath                    = "C:\SYSVOL"
            # DependsOn specifies which resources depend on other resources, and the LCM ensures that they are applied in the correct order, regardless of the order in which resource instances are defined.
            DependsOn                     = "[WindowsFeature]ADDSInstall"
        }

        # Wait until AD Domain is created.
        xWaitForADDomain DomainWait
        {
            DomainName           = $Node.DomainName
            DomainUserCredential = $DomainAdministratorCred
            # Maximum number of retries to check for the domain's existence.
            RetryCount           = $Node.RetryCount
            # Interval to check for the domain's existence.
            RetryIntervalSec     = $Node.RetryIntervalSec
            DependsOn            = "[xADDomain]FirstDC"
        }

        # Enable Recycle Bin.
        xADRecycleBin RecycleBin
        {
            # Credential with Enterprise Administrator rights to the forest.
            EnterpriseAdministratorCredential = $DomainAdministratorCred
            # Fully qualified domain name of forest to enable Active Directory Recycle Bin.
            ForestFQDN                        = $Node.DomainName
            DependsOn                         = "[xWaitForADDomain]DomainWait"
        }

        # Create AD User "Test.User".
        xADUser ADUser
        {
            DomainName                    = $Node.DomainName
            DomainAdministratorCredential = $DomainAdministratorCred
            UserName                      = "Test.User"
            Password                      = $ADUserCred
            Ensure                        = "present"
            DependsOn                     = "[xWaitForADDomain]DomainWait"
        }
    }

    Node $AllNodes.Where{$_.Role -eq "DC02"}.Nodename
    {
        # Configure LCM to allow Windows to automatically reboot if needed. Note: NOT recommended for production!
        #LocalConfigurationManager
        #{
		#    # Set this to $true to automatically reboot the node after a configuration that requires reboot is applied. Otherwise, you will have to manually reboot the node for any configuration that requires it. The default (recommended for PRODUCTION servers) value is $false.
        #    RebootNodeIfNeeded = $false
		#    # The thumbprint of a certificate used to secure credentials passed in a configuration.
        #    CertificateId = $node.Thumbprint
        #}

        # Install Windows Feature AD Domain Services.
        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name   = "AD-Domain-Services"
        }

        # Ensure that the Active Directory Domain Services feature is installed.
        xWaitForADDomain DomainWait
        {
            DomainName           = $Node.DomainName
            DomainUserCredential = $DomainAdministratorCred
            RetryCount           = $Node.RetryCount
            RetryIntervalSec     = $Node.RetryIntervalSec
            DependsOn            = "[WindowsFeature]ADDSInstall"
        }

        # Ensure that the AD Domain is present before the second domain controller is added.
        xADDomainController SecondDC
        {
            DomainName                    = $Node.DomainName
            DomainAdministratorCredential = $DomainAdministratorCred
            SafemodeAdministratorPassword = $SafemodeAdministratorCred
            DependsOn                     = "[xWaitForADDomain]DomainWait"
        }
    }

    Node $AllNodes.where{ $_.role -eq "web" }.Nodename
    {
        #LocalConfigurationManager
        #{
        #    # Går att ha satt till $true men enbart för testmiljö
        #    RebootNodeIfNeeded = $false
        #    # The thumbprint of a certificate used to secure credentials passed in a configuration.
        #    CertificateId = $node.Thumbprint
        #    ActionAfterReboot = 'ContinueConfiguration'
        #}

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
            DestinationPath = $node.destinationpath
            #DependsOn = "WindowsFeature[Web-WebServer]"
            Ensure = 'Present'
            Type = "Directory"
        }
    }
}

#Testlösen: ABC.123/abc.123
DSC -ConfigurationData C:\Users\thalm\Desktop\WorkCode\powershell_work\DSC\DomainController\VmWareMaskiner\ConfigurationData.psd1 `
    -SafemodeAdministratorCred (Get-Credential -UserName Administrator -Message "Enter Domain Safe Mode Administrator Password") `
    -DomainAdministratorCred (Get-Credential -UserName supercow.se\administrator -Message "Enter Domain Administrator Credential") `
    -ADUserCred (Get-Credential -UserName Test.User -Message "Enter AD User Credential") `
    -OutputPath "C:\Users\thalm\Desktop\WorkCode\powershell_work\DSC\DomainController\VmWareMaskiner\temp"

# Make sure that LCM is set to continue configuration after reboot.
Set-DSCLocalConfigurationManager -Path C:\Users\thalm\Desktop\WorkCode\powershell_work\DSC\DomainController\VmWareMaskiner\temp –Verbose -Credential administrator -Force
# Start-DscConfiguration -Path "C:\Users\thalm\Desktop\WorkCode\powershell_work\DSC\DomainController\VmWareMaskiner\temp" -Wait -Verbose -force