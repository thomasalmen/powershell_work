 @{
    # Node specific data
    AllNodes = @(

       # All Servers need following identical information 
       @{
            NodeName           = '*'
            PSDscAllowPlainTextPassword = $false;
            PSDscAllowDomainUser = $true
            # The path to the .cer file containing the public key of the Encryption Certificate used to encrypt credentials for this node.
            CertificateFile             = "$env:TEMP\DscPublicKey.cer"
            # The thumbprint of the Encryption Certificate used to decrypt the credentials on target node.
            Thumbprint                  = "C64242683D7E6511FD35055FEEC55C71BE6920AF"

            Domainname = "supercow.se"
            WebSiteName = 'www.supercow.se' 
            WebAppPoolName = 'www.supercow.se_pool' # Name of the Application Pool to create
            Protocol = "http"
            IPAddress = "*"
            Port = 80
            WebsajtRoot = "c:\inetpub\wwwroot\www.supercow.se\CurrentVersion"
       },

       # Unique Data for each Role
       @{
            NodeName = "S1"
            Role = @('httpweb')

            # Sajtens namn. Kommer också att användas som DNS/IIS host header.

            CertificateSubject    = "CN=blaha.supercow.se"
            CertificteThumbprint = "E405C9C0196E3681C32A2BD6F7BB644A3D9B9626"
            CertificateStoreName  = "MY"
            #ThumbPrint = Invoke-Command -Computername 's1' -Credential administrator {Get-Childitem Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -match "S1"} | Select-Object -ExpandProperty ThumbPrint}

            #Source för filer som ska kopieras till websajten
            SourcePath = "\\PCSE05767\Websajt_Filer\S1\"
           
            #Destination dit websajtens filer ska kopieras.
            #DestinationPath = 'C:\inetpub\wwwroot\www.supercow.se\CurrentVersion'
            ipnummer = "10.10.30.13"
            mask = "255.255.255.0"
            gateway = "10.10.30.1"
            DNS = "10.10.30.15"
        }
       @{
            NodeName = "S2"
            Role = @('httpweb')

            CertificateSubject    = "CN=blaha.orebroll.se"
            CertificteThumbprint = "E405C9C0196E3681C32A2BD6F7BB644A3D9B9626"
            CertificateStoreName  = "MY"
            #ThumbPrint = Invoke-Command -Computername 's1' -Credential administrator {Get-Childitem Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -match "S1"} | Select-Object -ExpandProperty ThumbPrint}

            #Source för filer som ska kopieras till websajten
            # Obs, ska vara ett UNC-share
            SourcePath = "\\PCSE05767\Websajt_Filer\S2\"

           
            #Destination dit websajtens filer ska kopieras.
            #DestinationPath = 'C:\inetpub\wwwroot\www.supercow.se\CurrentVersion'
            ipnummer = "10.10.30.14"
            mask = "255.255.255.0"
            gateway = "10.10.30.1"
            DNS = "10.10.30.15"
        }
      
        @{
            # Node Specific Data
            NodeName = 'DC'
            Role = @('DC', 'DHCP','DNS')
        }

    )

     IIS_Global_Site_Data = @{
        ApplyTo = 'Machine'
        LogFormat = 'W3C'
        AllowSubDirConfig = 'true'
     }

     IIS_Global_AppPool_Data = @{
        ApplyTo = 'Machine'
        ManagedRuntimeVersion = 'v4.0'
        IdentityType = 'ApplicationPoolIdentity'
     }

        ## Features som ska vara enabled
        # Kolla att serverversionen stödjer alla roller (ex core)
        # Vissa features kräver installation (Source files). Ex .net 4, 5 mm.
        IIS_enabled_featurenames=@("Web-Server",
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
        "Web-Client-Auth",
        "Web-Cert-Auth",
        "Web-IP-Security",
        "Web-Windows-Auth",
        "Web-App-Dev",
        "Web-Net-Ext45",
        #"Web-ASP",
        #"Web-Asp-Net",
        "Web-Asp-Net45",
        "Web-ISAPI-Ext",
        "Web-ISAPI-Filter",
        "Web-Mgmt-Tools",
        #"Web-Mgmt-Console",
        "Web-Mgmt-Service",
        "Web-Scripting-Tools"
        #"NET-Framework-Features",
        #"NET-Framework-Core",
        #"NET-Framework-45-Features",
        #"NET-Framework-45-Core",
        #"NET-Framework-45-ASPNET",
        #"NET-WCF-Services45"
        )

        IIS_disabled_featurenames=@(
        #"Search-Service",

        "Windows-Server-Backup",
        "Migration",
        "WindowsStorageManagementService",
        #"WSRM",
        #"Windows-TIFF-IFilter",
        "WinRM-IIS-Ext",
        "WINS",
        #"Wireless-Networking",
        #"Biometric-Framework",
        #"WFF",
        #"Windows-Identity-Foundation",
        "Windows-Internal-Database",
        "RPC-over-HTTP-Proxy",
        "Simple-TCPIP",
        #"SMTP-Server",
        #"SNMP-Service",
        "SNMP-WMI-Provider",
        #"Subsystem-UNIX-Apps",
        "Telnet-Client",
        #"Telnet-Server",
        #"TFTP-Client",
        "RSAT-Role-Tools",
        "RSAT",
        "Multipath-IO",
        "NLB",
        "PNRP",
        "qWave",
        #"CMAK",
        "MSMQ",
        "BitLocker",
        #"BitLocker-NetworkUnlock",
        "BranchCache",
        "NFS-Client",
        "Data-Center-Bridging",
        "EnhancedStorage",
        "Failover-Clustering",
        "GPMC",
        #"InkAndHandwritingServices",
        #"Internet-Print-Client",
        "IPAM",
        "ISNS",
        #"LPR-Port-Monitor",
        "ManagementOdata",
        "BITS",
        "VolumeActivation",
        "UpdateServices",
        #"WDS",
        "Remote-Desktop-Services",
        "Print-Services",
        "Hyper-V",
        #"NPAS",
        #"Application-Server",
        "ADLDS",
        "ADRMS",
        "AD-Domain-Services",
        #"AD-Federation-Services",
        "AD-Certificate",
        "DHCP",
        "DNS",
        #"Fax",
        "RemoteAccess",
        "Web-WHC",
        #"Remote-Assistance",

        "web-asp",
        "web-basic-auth",
        "Web-Mgmt-Compat",
        "Web-CertProvider"
        #"PowerShell-ISE"
        )

} 

