$enabled_featurenames=@(
"Web-Server", "Web-WebServer",
"Web-Common-Http", "Web-Default-Doc",
"Web-Http-Errors", "Web-Static-Content",
"Web-Net-Ext45", "Web-Health",
"Web-Log-Libraries", "Web-Custom-Logging",
"Web-Http-Logging", "Web-Request-Monitor",
"Web-Stat-Compression", "Web-Http-Tracing",
"Web-Security", "Web-Cert-Auth",
"Web-IP-Security", "Web-Windows-Auth",
"Web-Client-Auth", "Web-CertProvider",
"Web-Filtering", "Web-App-Dev",
"Web-ISAPI-Ext", "Web-ISAPI-Filter",
"Web-Mgmt-Tools", "Web-Mgmt-Console", "Web-Mgmt-Service",
"Web-Scripting-Tools", 
"NetExtens4", "AspNet45", "ISAPIExt", "ISAPIFilter",
"NET-Framework-45-Features", "NET-Framework-45-Core",
"NET-Framework-45-ASPNET", "NET-WCF-Services45", "NET-WCF-TCP-PortSharing45"
)

$disabled_featurenames=@(
"Containers", 
"Web-Basic-Auth", "Web-Digest-Auth", "Web-Dir-Browsing", "Web-Http-Redirect", "Web-Url-Auth",
"RSAT", "RSAT-Role-Tools", "RSAT-AD-Tools",  "RSAT-AD-PowerShell", "RSAT-ADDS", "RSAT-AD-AdminCenter", "RSAT-ADDS-Tools", "RSAT-ADLDS",  "RSAT-Hyper-V-Tools", "RSAT-RDS-Tools", "RSAT-DNS-Server",
"Hyper-V-Tools", "Hyper-V-PowerShell",
"UpdateServices-RSAT", "UpdateServices-API", "UpdateServices-UI",
"Web-Ftp-Server"
)

$ConfigData=@{
    # Node specific data
    AllNodes = @(

       # All Servers need following identical information 
       @{
            NodeName = '*'
            #PSDscAllowPlainTextPassword = $true;
            #PSDscAllowDomainUser = $true
       },
       # Unique Data for each Role
       @{
            NodeName = 'KRASCHOBANG'
            Role = @('Web', 'singleserver',"SecuredSite")
           
            SourcePath = '\\client\WebSiteForDemo' # Content Source Location
            DestinationPath = 'C:\WebSite' # Content Destination Location
            WebAppPoolName = 'ApplikationsPool' # Name of the Application Pool to create
            WebSiteName = 'MyWeb' # Name of the website to create - this will also be hostname for DNS
            DomainName = 'orebroll.se' # Remaining Domain name for Host Header i.e. Company.com and DNS
            DNSIPAddress = '*' # IP Address for DNS of the Website
            WebsitesRoot = "d:\websites"
            #ThumbPrint = Invoke-Command -Computername 's2.company.pri' {Get-Childitem Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -like "*wild*"} | Select-Object -ExpandProperty ThumbPrint}
        }

        @{
            NodeName = 'HOTELL'
            Role = @('Web', 'hotell')
            SourcePath = '\\client\WebSiteForDemo' # Content Source Location
            DestinationPath = 'C:\WebSite' # Content Destination Location
            WebAppPoolName = 'MyWebPool' # Name of the Application Pool to create
            WebSiteName = 'MyWeb' # Name of the website to create - this will also be hostname for DNS
            DomainName = 'Company.Pri' # Remaining Domain name for Host Header i.e. Company.com and DNS
            DNSIPAddress = '192.168.3.51' # IP Address for DNS of the Website
        } 
         @{
            NodeName = 's2.company.pri'
            Role = @('Web', 'SecuredSite','Application')
            SourcePath = '' # Content Source Location - not used for this app
            DestinationPath = 'C:\Windows\web\PowerShellWebAccess\wwwroot' # Empty Content Destination - to be filled with app install         
            WebAppPoolName = 'PSWAPool' # Name of the Application Pool to create
            WebSiteName = 'PSWA' # Name of the website to create - this will also be hostname for DNS           
            DomainName = 'Company.Pri' # Remaining Domain name for Host Header i.e. Company.com and DNS            
            DNSIPAddress = '192.168.3.52' # IP Address for DNS of the Website
            #ThumbPrint = Invoke-Command -Computername 's2.company.pri' {Get-Childitem Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -like "*wild*"} | Select-Object -ExpandProperty ThumbPrint}
            
        }

    );
} 

Configuration WebNodes
{

    # Import the module that defines custom resources
    try
    {
        Import-DscResource -Module PSDesiredStateConfiguration, xWebAdministration, cNTFSPermission, PSWAAuthorization
    }
    catch
    {
        "Module fail"
    }

    # Dynamically find the applicable nodes from configuration data
    Node $AllNodes.where{$_.Role -eq 'Web'}.NodeName {

#       # Installera  IIS default-grunkor
        $enabled_featurenames.ForEach({
                WindowsFeature $_ {
                    Name = $_
                    Ensure = 'Present'
                }
            }) #foreach

        # Se till att dessa är disablade
        $disabled_featurenames.ForEach({
            WindowsFeature $_ {
                Name = $_
                Ensure = 'Absent'
            }
        }) #foreach

#       # Disable the Default Web Site
        xWebsite DefaultSite {

            Name            = "Default Web Site"
            State           = "Stopped"
            PhysicalPath    = "C:\inetpub\wwwroot"
            DependsOn       = "[WindowsFeature]IIS"
        }
        file DefaultSite
        {
                DestinationPath = "c:\intepub\wwwroot"
                Ensure = 'Absent'
        }
        File WebContent {
            Ensure = 'Present'
            SourcePath = $Node.SourcePath
            DestinationPath = $Node.DestinationPath
            Recurse = $true
            Type = 'Directory'
            #DependsOn = '[WindowsFeature]AspNet45'
        } 
        #WMSVC-service ska vara avinstallerad
       Service StartWMSVC {
            ensure = 'Absent'
            Name = 'WMSVC'
            StartupType = 'Manual'
            State = 'Stopped'
       }

    # Setting permissions for the application
    cNTFSPermission AppPoolPermission {
        Ensure          = "Present"
        Account         = "users"
        Access          = "Allow"
        Path            = "C:\Windows\web\PowerShellWebAccess\data\AuthorizationRules.xml"
        Rights          = 'ReadAndExecute'
        NoInherit       = $true
        DependsOn       = '[xWebAppPool]WebAppPool'
    } 

 

    #      # Config application pool
    xWebAppPool WebAppPool { 
        Ensure = "Present"
        Name = $Node.WebAppPoolName
        autoStart = "true"  
        managedRuntimeVersion = "v4.0"
        managedPipelineMode = "Integrated"
        startMode = "AlwaysRunning"
        identityType = "ApplicationPoolIdentity"
        restartSchedule = @("18:30:00","05:00:00")
        DependsOn = @('[WindowsFeature]IIS','[WindowsFeature]AspNet45') 
    }

    # Configure web site
    xWebsite WebSite
    {
    Ensure = "Present"
    Name = $Node.WebSiteName
    State = "Started"
    PhysicalPath = $Node.DestinationPath
    ApplicationPool = $Node.WebAppPoolName
    BindingInfo = MSFT_xWebBindingInformation { 
                        
                        Protocol = "HTTP" 
                        Port = 80
                        Hostname = "$($Node.WebSiteName).$($Node.DomainName)"
                        } 
    DependsOn       = '[xWebAppPool]WebAppPool'
    
    }

    } #End Node Role Web


    Node $AllNodes.where{$_.Role -eq 'SecuredSite'}.NodeName {

        
        # Create an empty directory for the application install
        File WebContent {
        
            Ensure = 'Present'
            #SourcePath = $Node.SourcePath
            DestinationPath = $Node.DestinationPath
            #Recurse = $true
            Type = 'Directory'
            DependsOn = '[WindowsFeature]AspNet45'
        }

#      # Config application pool
        xWebAppPool WebAppPool { 
        
            Ensure = "Present"
            Name = $Node.WebAppPoolName
            autoStart = "true"  
            managedRuntimeVersion = "v4.0"
            managedPipelineMode = "Integrated"
            startMode = "AlwaysRunning"
            identityType = "ApplicationPoolIdentity"
            restartSchedule = @("18:30:00","05:00:00")
            DependsOn = @('[WindowsFeature]IIS','[WindowsFeature]AspNet45') 
 
        }

        xWebsite SecuredSite
        {
            Ensure          = "Present"
            Name            = $Node.WebSiteName
            State           = "Started"
            PhysicalPath    = $Node.DestinationPath
            ApplicationPool = $Node.WebAppPoolName
            BindingInfo     =  MSFT_xWebBindingInformation {  
                             
                               Protocol              = "HTTPS" 
                               Port                  = 443 
                               Hostname              = "$($Node.WebSiteName).$($Node.DomainName)"
                               CertificateThumbprint = $Node.ThumbPrint
                               CertificateStoreName  = "MY" 
                             } 
            DependsOn       = @('[xWebAppPool]WebAppPool', '[File]WebContent')

        }

          
    } #End Node SecuredSite
    ####################################################

} # End Config

#break
#WebNodes -ConfigurationData $ConfigData -OutputPath .\


Function Install-IISEnabledComputer{

    [cmdletbinding()]
    Param(
        [Parameter(Position = 0,Mandatory, ValueFromPipeline)]
        [ValidateNotNullorEmpty()]
        [string[]]$Computername,
        [pscredential]$credz=(Get-Credential tal008adm),
        [string]$psrepository=(Get-PSRepository).name
    )

    Begin
    {
        Write-Verbose "[ BEGIN ] Starting: $($MyInvocation.Mycommand)"  
    } #begin
    Process
    {

    foreach($computer in $Computername)
    {
        Write-Verbose "Ansluter till '$computer'"  
        try
        {
            $PSsession = New-PSSession -ComputerName $computer -Credential $credz
        }
        catch
        {
            write-verbose "Kunde inte ansluta till '$computer' - skipping"
            return
        }    
        #Ifsats runt denna!
        #invoke-command -session $PSsession { Set-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb -Value 2048 } | out-null
        
        #Anropar funktion
        ####set-LocalDSCProperties -Computername $computer -credz $credz
     
        Write-Verbose "Checking prerequisites.."
        foreach($r in $dscResources)
        {
            #Kollar om dsc-resursen finns
            if(! ( Invoke-Command -Session $PSsession  { get-DscResource -Module $args[0] } -ArgumentList "$r" ) -eq $false )
            {
                Write-Verbose "'$r' OK."
            }
            else
            {
                #Finns den inte kollar vi i $psrepository
                if(! (Invoke-Command -Session $PSsession { Find-DscResource -ModuleName $args[0] -Repository $args[1] } -ArgumentList $r,$psrepository ) -eq $false)
                {
                    write-verbose "Hittade '$r' i '$psrepository' - installerar DSCmodul..."
                    if(! (Invoke-Command -Session $PSsession {install-module $args[0] -Force  } -ArgumentList "$r" )  -eq $false)
                    {
                        write-verbose "Kontrollerar att DSCmodul installerats ok..."
                        if( !(Invoke-Command -Session $PSsession  { get-DscResource -Module $args[0] } -ArgumentList "$r" ) -eq $false )
                        {
                            write-verbose "Module '$r' installed OK."
                        }
                    }                        
                }
                else
                {
                    write-verbose "Hittade inte '$r' i '$psrepository' - kan inte installera '$r'!"
                }

            }
        }

        #Kör DSC-konfen.
        Install_DSC_IIS -OutputPath $env:TEMP -computername $Computer -verbose
        Start-DscConfiguration -Path $env:TEMP -ComputerName $Computer -Wait -Verbose -Credential $credz -Force

#        if( (Test-DscConfiguration -ComputerName $computer -Credential $credz) -eq $true)
#        {
#            Write-Verbose "All steps performed OK"
#        }

    }#foreach


    #Test-DscConfiguration -ComputerName kraschobang -Credential tal008adm


    } #process
    End
    {
        Write-Verbose "[  END  ] Ending: $($MyInvocation.Mycommand)"
        remove-PSSession $PSsession
    } #end

}

