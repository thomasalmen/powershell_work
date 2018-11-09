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
            Name                  = "Allow IIS - Port 80/443  "
            Enabled = $true
            DisplayName           = "Firewall Rule for IIS"
            Ensure                = "Present"
            Profile               = ("Domain")
            Direction             = "InBound"
            LocalPort             = (80,443)
            Protocol              = "TCP"
            Description           = "Firewall Rule for IIS" 
        }

    }
}

Configuration_IIS -OutputPath "$env:TEMP\DSC_IIS\Install" -ConfigurationData "C:\Users\thalm\OneDrive\powershell_work\DSC\IIS\IIS_ConfigurationData.psd1" 

<#

[string[]]$computers="S1","S2"

$Session = New-CimSession -ComputerName $computers -Credential (get-credential administrator)

Set-DscLocalConfigurationManager -Path "$env:TEMP\DSC_IIS\Install" -Force -Verbose -cimsession $session
start-DscConfiguration -Wait -verbose -Path "$env:TEMP\DSC_IIS\Install" -Force -cimsession $session

#>


