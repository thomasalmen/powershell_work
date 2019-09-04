$configurationdata= @{
    # Node specific data
    AllNodes = @(

       # All Servers need following identical information 
       @{
            NodeName           = '*'
           # PSDscAllowPlainTextPassword = $false;
           # PSDscAllowDomainUser = $true
            # The path to the .cer file containing the public key of the Encryption Certificate used to encrypt credentials for this node.
           # CertificateFile             = "c:\windows\temp\DscPublicKey.cer"
            # The thumbprint of the Encryption Certificate used to decrypt the credentials on target node.
           # Thumbprint                  = "0A62DEAEB60D383FF877902F0EAACB38AE425B21"

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
            NodeName = "thomasweb"
            Role = @('httpweb')

            # Sajtens namn. Kommer också att användas som DNS/IIS host header.

            #CertificateSubject    = "CN=blaha.supercow.se"
            #CertificteThumbprint = "E405C9C0196E3681C32A2BD6F7BB644A3D9B9626"
            #CertificateStoreName  = "MY"
            #ThumbPrint = Invoke-Command -Computername 's1' -Credential administrator {Get-Childitem Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -match "S1"} | Select-Object -ExpandProperty ThumbPrint}

            #Source för filer som ska kopieras till websajten
            #SourcePath = "\\PCSE05767\Websajt_Filer\S1\"
           
            #Destination dit websajtens filer ska kopieras.
            #DestinationPath = 'C:\inetpub\wwwroot\www.supercow.se\CurrentVersion'
            #ipnummer = "10.10.30.13"
            #mask = "255.255.255.0"
            #gateway = "10.10.30.1"
            #DNS = "10.10.30.15"
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
        "web-basic-auth",
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
        "Telnet-Client",
        "NLB",
        "web-asp",
        "Web-Mgmt-Compat",
        "Web-CertProvider"
        )

} 






# ##################################################### #
#         Konfig som ska gälla alla IISservrar          #
# ##################################################### #
#$VerbosePreference="Silentlycontinue"
Configuration Configuration_IIS
{
    param(
        #[Parameter(Mandatory=$true)]
        #[ValidateNotNullorEmpty()]
        #[PsCredential] $ShareCreds
        )

    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module xWebAdministration
    Import-DscResource -Module NetworkingDsc

    # Dynamically find the applicable nodes from configuration data
    Node $AllNodes.where{$_.Role -eq 'httpweb'}.NodeName {

        LocalConfigurationManager
        {
            # Går att ha satt till $true men enbart för testmiljö
            RebootNodeIfNeeded = $true
            ActionAfterReboot = 'ContinueConfiguration'
            # The thumbprint of a certificate used to secure credentials passed in a configuration.
            CertificateId = $node.Thumbprint
            ConfigurationMode = 'ApplyAndAutoCorrect'
            
        }

        #Globala features som ska enablas
        $configurationdata.IIS_enabled_featurenames.ForEach({
            WindowsFeature $_ {
                Name = $_
                Ensure = 'Present'
            }
        }) #foreach

        #Globala features som ska disablas
        $configurationdata.IIS_disabled_featurenames.ForEach({
            WindowsFeature $_ {
                Name = $_
                Ensure = 'Absent'
            }
        }) #foreach


         # Globala IISinställningar
         $IIS_Global_Site_Data = $configurationdata.IIS_Global_Site_Data
         xWebSiteDefaults SiteDefaults
         {
            ApplyTo = $IIS_Global_Site_Data.ApplyTo
            LogFormat = $IIS_Global_Site_Data.LogFormat
            AllowSubDirConfig = $IIS_Global_Site_Data.AllowSubDirConfig
         }

         # Globala AppPoolinställningar
         $IIS_Global_AppPool_Data = $configurationdata.IIS_Global_AppPool_Data
         xWebAppPoolDefaults PoolDefaults
         {
            ApplyTo = $IIS_Global_AppPool_Data.ApplyTo
            ManagedRuntimeVersion = $IIS_Global_AppPool_Data.ManagedRuntimeVersion
            IdentityType = $IIS_Global_AppPool_Data.IdentityType
         }

        Registry EnableWmSvc
        {
            #Enabla IIS remote Admin
            # IIS remote admin extension - https://www.microsoft.com/en-us/download/details.aspx?id=41177
            # set-ItemProperty HKLM:\SOFTWARE\Microsoft\WebManagement\Server\ -Name EnableRemoteManagement -Value 1
            # EnableRemoteManagemetn är av typen DWORD
            # $key = Get-Item -Path "HKLM:\SOFTWARE\Microsoft\WebManagement\Server\"
            # $key.GetValueKind('EnableRemoteManagement')
            Key = "HKLM:\SOFTWARE\Microsoft\WebManagement\Server\"
            ValueName = "EnableRemoteManagement"
            ValueData = "1"
            ValueType ='Dword'
            Ensure = 'Present'
        }
        
        # Autostarta WmSvc
        Service Autostart_WmSvc {
        Name = "wmsvc"
        State = 'Running'
        StartupType = 'Automatic'
        Ensure = 'Present'
        DependsOn = "[windowsfeature]Web-Mgmt-Service"
        }

        # Ta bort default website på noden
        xWebsite DefaultSite
        {
            Ensure          = "Absent"
            Name            = "Default Web Site"
            State           = "Stopped"
            PhysicalPath    = "C:\inetpub\wwwroot"
            DependsOn       = "[WindowsFeature]Web-WebServer"
        }

        Firewall Firewall
        {
            Name                  = "Allow IIS - Port 80/443/21/8080  "
            Enabled = $true
            DisplayName           = "Firewall Rule for IIS"
            Ensure                = "Present"
            Profile               = ("Domain")
            Direction             = "InBound"
            LocalPort             = (80,443,8080,21)
            Protocol              = "TCP"
            Description           = "Firewall Rule for IIS" 
        }

    }
}

Configuration_IIS -OutputPath "$env:TEMP\DSC_IIS\Install" -ConfigurationData $configurationdata



#[string[]]$computers="S1","S2"

#$Session = New-CimSession -ComputerName $computers -Credential (get-credential administrator)
#
#Set-DscLocalConfigurationManager -Path "$env:TEMP\DSC_IIS\Install" -Force -Verbose #-cimsession $session
#start-DscConfiguration -Wait -verbose -Path "$env:TEMP\DSC_IIS\Install" -Force #-cimsession $session





