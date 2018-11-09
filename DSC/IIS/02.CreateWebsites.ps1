#WebsiteConfiguration 
Configuration IIS_WebSites
{
    param(
        #[Parameter(Mandatory=$true)]
        #[ValidateNotNullorEmpty()]
        #[PsCredential] $ShareCreds
        )

    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module xWebAdministration

    # Dynamically find the applicable nodes from configuration data
    Node $AllNodes.where{$_.Role -eq 'httpweb'}.NodeName {
        
        LocalConfigurationManager
        {
            # The thumbprint of a certificate used to secure credentials passed in a configuration.
            CertificateId = $node.Thumbprint
        }
        

        # Skapa ny nodspecifik Application Pool 
        xWebAppPool WebAppPool
        {
            Name = $node.WebAppPoolName
            Ensure                         = 'Present'
            State                          = 'Started'
            autoStart                      = $true
            CLRConfigFile                  = ''
            enable32BitAppOnWin64          = $false
            enableConfigurationOverride    = $true
            managedPipelineMode            = 'Integrated'
            managedRuntimeLoader           = 'webengine4.dll'
            managedRuntimeVersion          = 'v4.0'
            passAnonymousToken             = $true
            startMode                      = 'OnDemand'
            queueLength                    = 1000
            cpuAction                      = 'NoAction'
            cpuLimit                       = 90000
            cpuResetInterval               = (New-TimeSpan -Minutes 5).ToString()
            cpuSmpAffinitized              = $false
            cpuSmpProcessorAffinityMask    = 4294967295
            cpuSmpProcessorAffinityMask2   = 4294967295
            identityType                   = 'ApplicationPoolIdentity'
            idleTimeout                    = (New-TimeSpan -Minutes 20).ToString()
            idleTimeoutAction              = 'Terminate'
            loadUserProfile                = $true
            logEventOnProcessModel         = 'IdleTimeout'
            logonType                      = 'LogonBatch'
            manualGroupMembership          = $false
            maxProcesses                   = 1
            pingingEnabled                 = $true
            pingInterval                   = (New-TimeSpan -Seconds 30).ToString()
            pingResponseTime               = (New-TimeSpan -Seconds 90).ToString()
            setProfileEnvironment          = $false
            shutdownTimeLimit              = (New-TimeSpan -Seconds 90).ToString()
            startupTimeLimit               = (New-TimeSpan -Seconds 90).ToString()
            orphanActionExe                = ''
            orphanActionParams             = ''
            orphanWorkerProcess            = $false
            loadBalancerCapabilities       = 'HttpLevel'
            rapidFailProtection            = $true
            rapidFailProtectionInterval    = (New-TimeSpan -Minutes 5).ToString()
            rapidFailProtectionMaxCrashes  = 5
            autoShutdownExe                = ''
            autoShutdownParams             = ''
            disallowOverlappingRotation    = $false
            disallowRotationOnConfigChange = $false
            logEventOnRecycle              = 'Time,Requests,Schedule,Memory,IsapiUnhealthy,OnDemand,ConfigChange,PrivateMemory'
            restartMemoryLimit             = 0
            restartPrivateMemoryLimit      = 0
            restartRequestsLimit           = 0
            restartTimeLimit               = (New-TimeSpan -Minutes 1440).ToString()
            restartSchedule                = @('00:00:00', '08:00:00', '16:00:00')
        }

       
        file "WebSiteFolder"
        {
            DestinationPath = $node.WebsajtRoot
            Ensure = 'Present'
            Force = $true
            Type = 'Directory'
            #DependsOn = "[xWebsite]DefaultSite"
        }
       
        #Nodspecifik website
        xWebsite WebSite
        {
            Name = $node.WebSiteName
            ApplicationPool = $node.WebAppPoolName
            AuthenticationInfo = MSFT_xWebAuthenticationInformation
            {
               Anonymous = $true
               Windows = $true
            }
            
            BindingInfo     = @(
                @(MSFT_xWebBindingInformation   
                    {  
                        Protocol              = "HTTP"
                        Port                  =  80 
                        HostName              = $node.Websitename
                    }
                );
                @(MSFT_xWebBindingInformation
                    {
                        Protocol              = "HTTP"
                        Port                  = 80
                        HostName              = $node.nodename
                    }
                )
            )
            DefaultPage = "Default.aspx"
            #DependsOn = "[WindowsFeature]web-webserver"
            EnabledProtocols = "http"
            Ensure = "Present"
            PhysicalPath = $node.WebsajtRoot
            State = 'Started'
        }
        
    }
}

IIS_WebSites -OutputPath "$env:TEMP\DSC_IIS\CreateWebsite" -ConfigurationData "C:\Users\thalm\OneDrive\powershell_work\DSC\IIS\IIS_ConfigurationData.psd1" 

<#


[string[]]$computers="S1","S2"

$Session = New-CimSession -ComputerName $computers -Credential (get-credential administrator)

Set-DscLocalConfigurationManager -Path "$env:TEMP\DSC_IIS\CreateWebsite" -Force -Verbose -cimsession $session
start-DscConfiguration -Wait -verbose -Path "$env:TEMP\DSC_IIS\CreateWebsite" -Force -cimsession $session

#>


