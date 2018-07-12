$ConfigData=@{
    # Node specific data
    AllNodes = @(
       # All Servers need following identical information 
       @{
            NodeName           = '*'
            #PSDscAllowPlainTextPassword = $true;
            #PSDscAllowDomainUser = $true

            Role = @('DefaultWebSettings')
          
       } ,

       # Unique Data for each Role
       

       @{
       
            NodeName = 'kraschobang.orebroll.se'
            Role = @('DefaultWebSettings')
            SourcePath = '\\client\WebSiteForDemo' # Content Source Location
            DestinationPath = 'd:\WebSites' # Content Destination Location
            WebAppPoolName = 'MyWebPool' # Name of the Application Pool to create
            WebSiteName = @('MyWeb','Myweb2') # Name of the website to create - this will also be hostname for DNS
            DomainName = 'Company.Pri' # Remaining Domain name for Host Header i.e. Company.com and DNS
            DNSIPAddress = '192.168.3.51' # IP Address for DNS of the Website
            managedPipelineMode = "Integrated"
            Testvariabel = "Testar"        
        }

       @{
       
            NodeName = 'win2016temp.orebroll.se'
            Role = @('DefaultWebSettings')
            SourcePath = '\\client\WebSiteForDemo' # Content Source Location
            DestinationPath = 'd:\WebSites' # Content Destination Location
            WebAppPoolName = 'MyWebPool' # Name of the Application Pool to create
            WebSiteName = @('MyWeb','Myweb2') # Name of the website to create - this will also be hostname for DNS
            DomainName = 'Company.Pri' # Remaining Domain name for Host Header i.e. Company.com and DNS
            DNSIPAddress = '192.168.3.51' # IP Address for DNS of the Website
            managedPipelineMode = "Integrated"
            Testvariabel = "Testar"        
        }

        
       @{
            NodeName = 'kraschobang'
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
            NodeName = 'win2016temp'
            Role = @('Web', 'SecuredSite','Application')
           
            #SourcePath = '' # Content Source Location - not used for this app
            #DestinationPath = 'C:\Windows\web\PowerShellWebAccess\wwwroot' # Empty Content Destination - to be filled with app install         
            #WebAppPoolName = 'PSWAPool' # Name of the Application Pool to create
            #WebSiteName = 'PSWA' # Name of the website to create - this will also be hostname for DNS           
            #DomainName = 'Company.Pri' # Remaining Domain name for Host Header i.e. Company.com and DNS            
            #DNSIPAddress = '192.168.3.52' # IP Address for DNS of the Website
            #ThumbPrint = Invoke-Command -Computername 's2.company.pri' {Get-Childitem Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -like "*wild*"} | Select-Object -ExpandProperty ThumbPrint}
            
        }
        #>
    );
} 


Configuration WebNodes
{
    # Import the module that defines custom resources
    #Get-Module -ListAvailable xDNSserver
    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module xWebAdministration -ModuleVersion 2.0.0.0
    #Import-DscResource -Module xDNSserver
    #Import-DscResource -Module cNTFSPermission
    Import-DscResource -ModuleName cNtfsAccessControl
    #Import-DscResource -Module PSWAAuthorization

    # Dynamically find the applicable nodes from configuration data
    Node $AllNodes.where{$_.Role -eq 'DefaultWebSettings'}.NodeName {
    
    #Standardfeatures
    
        # Install the IIS role
        WindowsFeature IIS {
            Ensure          = "Present"
            Name            = "Web-Server"
        }
        # Disable the Default Web Site
        xWebsite DefaultSite {
            Name            = "Default Web Site"
            State           = "Stopped"
            Ensure = "Absent"
            PhysicalPath    = "C:\inetpub\wwwroot"
            DependsOn       = "[WindowsFeature]IIS"
        }
    
    <#
        xWebAppPool WebAppPool { 
        
            Ensure = "Present"
            Name = $Node.WebAppPoolName
            autoStart = $true
            managedRuntimeVersion = "v4.0"
            managedPipelineMode = "Integrated"
            startMode = "AlwaysRunning"
            identityType = "ApplicationPoolIdentity"
            restartSchedule = @("18:30:00","05:00:00")
            #DependsOn = @('[WindowsFeature]IIS','[WindowsFeature]AspNet45') 
            DependsOn = @('[WindowsFeature]IIS') 
 
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
       #>


    } #End Node Role Web

    <#

###############################################################################

    Node $AllNodes.where{$_.Role -eq 'OpenSite'}.NodeName {

        File WebContent {
        
            Ensure = 'Present'
            SourcePath = $Node.SourcePath
            DestinationPath = $Node.DestinationPath
            Recurse = $true
            Type = 'Directory'
            DependsOn = '[WindowsFeature]AspNet45'
        }  
        
 #      # Config application pool
        xWebAppPool WebAppPool { 
        
            Ensure = "Present"
            Name = $Node.WebAppPoolName
            autoStart = $true
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
       
    } # End Node OpenSite

    ###############################################################################

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

    Node $AllNodes.where{$_.Role -eq 'Application'}.NodeName {

#       # Installing the Application
        WindowsFeature PSWA {
            Ensure          = "Present"
            Name            = "WindowsPowerShellWebAccess"
            DependsOn       = @('[WindowsFeature]IIS','[WindowsFeature]AspNet45')
        }

#       # Setting permissions for the application
        cNTFSPermission AppPoolPermission {
        
            Ensure          = "Present"
            Account         = "users"
            Access          = "Allow"
            Path            = "C:\Windows\web\PowerShellWebAccess\data\AuthorizationRules.xml"
            Rights          = 'ReadAndExecute'
            NoInherit       = $true
            DependsOn       = '[xWebAppPool]WebAppPool'
        } 



    } # End of Node
#>
} # End Config


WebNodes -ConfigurationData $ConfigData -OutputPath C:\Users\tal008\Desktop\DSC-tester
#cat .\kraschobang.orebroll.se.mof
break
#$creds = Get-Credential win2016temp\administrator
Start-DscConfiguration -ComputerName "win2016temp.orebroll.se" -Wait -Verbose -Path C:\Users\tal008\Desktop\DSC-tester -Credential $creds -Force


