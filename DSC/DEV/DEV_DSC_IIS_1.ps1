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

#$credz=(Get-Credential tal008adm)
$computername = "kraschobang"

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
            NodeName = 'basis.orebroll.se'
            Role = @('Web', 'OpenSite')
           
            SourcePath = '\\client\WebSiteForDemo' # Content Source Location
            DestinationPath = 'C:\WebSite' # Content Destination Location
            WebAppPoolName = 'MyWebPool' # Name of the Application Pool to create
            WebSiteName = 'MyWeb' # Name of the website to create - this will also be hostname for DNS
            DomainName = 'Company.Pri' # Remaining Domain name for Host Header i.e. Company.com and DNS
            DNSIPAddress = '192.168.3.51' # IP Address for DNS of the Website
        }

        <#
        @{
            NodeName = 's2.company.pri'
            Role = @('Web', 'SecuredSite','Application')

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


$computername.ForEach({

    try 
    {
        $cimsession = (New-CimSession -ComputerName $_ -Credential $credz)
    }
    catch{ "Gick inte att skapa cimsession till $_ " }




#region IIS Pools
$IIS_applicationPools=@(
"basis.orebroll.se",
"behorighetsportalen.orebroll.se",
"efoto.orebroll.se",
"jourlistan.orebroll.se",
"labmed.orebroll.se",
"loggwebb.orebroll.se",
"lokalbokning.orebroll.se",
"matilda.orebroll.se",
"netasset.orebroll.se",
"sp.orebroll.se",
"transporter.orebroll.se",
"webapp.orebroll.se",
"webapp_vardrapp",
"webapp-aduser",
"webapp-datorregistrering",
"webapp-lfkalksok",
"webapp-mvkchangedbookings",
"webapp-primkassarapport",
"webapp-screen"
"webapp-skvader",
"webprog.orebroll.se",
"webprog-ImxPersoSok"
)

#endregion

Configuration Configuration_IIS
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

        #region websites

        # Stoppa default website
        xWebsite DefaultSite
        {
            Ensure          = "Absent"
            Name            = "Default Web Site"
            State           = "Stopped"
            PhysicalPath    = "C:\inetpub\wwwroot"
            #DependsOn       = "[WindowsFeature]IIS"
        }

        xWebsite NewWebsite
        {
            Ensure          = "Present"
            Name            = "basis.orebroll.se"
            State           = "Started"
            PhysicalPath    = "D:\websites\basis.orebroll.se\CurrentVersion"
            BindingInfo     = @(
                MSFT_xWebBindingInformation
                {
                    Protocol              = "HTTP"
                    Port                  = 80
                    #CertificateSubject    = "CN=kraschobang.orebroll.se"
                    #CertificateThumbprint = "E405C9C0196E3681C32A2BD6F7BB644A3D9B9626"
                    #CertificateStoreName  = "MY"
                    IPAddress = "10.10.23.33"
                }
            )
            #DependsOn       = "[File]newpath"
        }

        $IIS_applicationPools.ForEach({
        

        #xWebAppPool $_
        #{
            #Name                           = $_
            #Ensure                         = 'Present'
            #State                          = 'Started'
            #autoStart                      = $true
            #CLRConfigFile                  = ''
            #enable32BitAppOnWin64          = $true
            #enableConfigurationOverride    = $true
            #managedPipelineMode            = 'Integrated'
            #managedRuntimeLoader           = 'webengine4.dll'
            #managedRuntimeVersion          = 'v4.0'
            #passAnonymousToken             = $true
            #startMode                      = 'OnDemand'
            #queueLength                    = 1000
            #cpuAction                      = 'NoAction'
            #cpuLimit                       = 90000
            #cpuResetInterval               = (New-TimeSpan -Minutes 5).ToString()
            #cpuSmpAffinitized              = $false
            #cpuSmpProcessorAffinityMask    = 4294967295
            #cpuSmpProcessorAffinityMask2   = 4294967295
            #identityType                   = 'ApplicationPoolIdentity'
            #idleTimeout                    = (New-TimeSpan -Minutes 20).ToString()
            #idleTimeoutAction              = 'Terminate'
            #loadUserProfile                = $true
            #logEventOnProcessModel         = 'IdleTimeout'
            #logonType                      = 'LogonBatch'
            #manualGroupMembership          = $false
            #maxProcesses                   = 1
            #pingingEnabled                 = $true
            #pingInterval                   = (New-TimeSpan -Seconds 30).ToString()
            #pingResponseTime               = (New-TimeSpan -Seconds 90).ToString()
            #setProfileEnvironment          = $false
            #shutdownTimeLimit              = (New-TimeSpan -Seconds 90).ToString()
            #startupTimeLimit               = (New-TimeSpan -Seconds 90).ToString()
            #orphanActionExe                = ''
            #orphanActionParams             = ''
            #orphanWorkerProcess            = $false
            #loadBalancerCapabilities       = 'HttpLevel'
            #rapidFailProtection            = $true
            #rapidFailProtectionInterval    = (New-TimeSpan -Minutes 5).ToString()
            #rapidFailProtectionMaxCrashes  = 5
            #autoShutdownExe                = ''
            #autoShutdownParams             = ''
            #disallowOverlappingRotation    = $false
            #disallowRotationOnConfigChange = $false
            #logEventOnRecycle              = 'Time,Requests,Schedule,Memory,IsapiUnhealthy,OnDemand,ConfigChange,PrivateMemory'
            #restartMemoryLimit             = 0
            #restartPrivateMemoryLimit      = 0
            #restartRequestsLimit           = 0
            #restartTimeLimit               = (New-TimeSpan -Minutes 1440).ToString()
            #restartSchedule                = @('00:00:00', '08:00:00', '16:00:00')
        #}


        
        })

        #path för virtual dir
        #File vDirPath
        #{
        #    DestinationPath = "d:\labsite\PhysicalPathWebApplication"
        #    Ensure = 'Present'
        #    Type = "Directory"
        #    DependsOn = "[File]newpath"
        #}
        
         # region website defaults #> 
         #xWebSiteDefaults SiteDefaults
         #{
         #   ApplyTo = 'Machine'
         #   LogFormat = 'W3C'
         #   AllowSubDirConfig = 'true'
         #}
         #endregion

         # region pool defaults
         #xWebAppPoolDefaults PoolDefaults
         #{
         #   ApplyTo = 'Machine'
         #   ManagedRuntimeVersion = 'v4.0'
         #   IdentityType = 'ApplicationPoolIdentity'
         #}
         # endregion

         #region pool





        #Add an appSetting key1
        #xWebConfigKeyValue ModifyWebConfig
        #{
        #    Ensure = "Present"
        #    ConfigSection = "AppSettings"
        #    Key = "key1"
        #    Value = "value1"
        #    IsAttribute = $false
        #    WebsitePath = "IIS:\sites\" + $Node.WebsiteName
        #    DependsOn = @("[File]CreateWebConfig")
        #}

        #Add an appSetting key1
        #xWebConfigKeyValue ModifyWebConfig
        #{
        #    Ensure = "Present"
        #    ConfigSection = "AppSettings"
        #    Key = "key1"
        #    Value = "value1"
        #    IsAttribute = $false
        #    WebsitePath = "IIS:\sites\" + $Node.WebsiteName
        #    DependsOn = @("[File]CreateWebConfig")
        #}


         #endregion
        #xWebsite NewWebsite
        #{
        #    Ensure          = "Absent"
        #    Name            = "LabSite"
        #    State           = "Started"
        #    PhysicalPath    = "d:\labsite"
        #    BindingInfo     = @(
        #        MSFT_xWebBindingInformation
        #        {
        #            Protocol              = "HTTPS"
        #            Port                  = 8444
        #            CertificateSubject    = "CN=kraschobang.orebroll.se"
        #            CertificateThumbprint = "E405C9C0196E3681C32A2BD6F7BB644A3D9B9626"
        #            CertificateStoreName  = "MY"
        #        }
        #    )
        #    DependsOn       = "[File]newpath"
        #}

        #Create a new Web Application
        #xWebApplication NewWebApplication
        #{
        #    Name = "WebApplicationName"
        #    Website = "LabSite"
        #    WebAppPool =  "SampleAppPool"
        #    PhysicalPath = "d:\labsite\PhysicalPathWebApplication"
        #    Ensure = "Absent"
        #    DependsOn = @("[xWebSite]NewWebSite","[File]newpath")
        #}

        #endregion



    }
}

})

Configuration_IIS -OutputPath $env:TEMP -Computername $computername -verbose
Start-DscConfiguration -ComputerName $computername -Path $env:TEMP -Wait -Verbose -Credential $credz -Force
# Test-DscConfiguration -ComputerName $computername -Credential $credz
# Get-DscConfiguration -CimSession $cimsession
# Remove-DscConfigurationDocument -CimSession $cimsession -Stage pending -Force
# Get-DscConfigurationStatus -CimSession (New-CimSession $computername -Credential tal008adm)
