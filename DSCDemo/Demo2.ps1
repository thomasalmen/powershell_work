#install-module "xWebAdministration"
#Get-DscResource -Module  "xWebAdministration"
#Find-Module -Repository PSGallery -tag File



<#
[DscLocalConfigurationManager()]
Configuration FixaLCM {
Node kraschobang {
    Settings {
        RebootNodeIfNeeded = $true
        ActionAfterReboot = 'ContinueConfiguration'
        ConfigurationMode = 'ApplyAndAutoCorrect'
    }
}

}
FixaLCM -OutputPath C:\dsc\
Set-DscLocalConfigurationManager -Path C:\dsc\ -ComputerName kraschobang -Credential $credz
Get-DscLocalConfigurationManager -CimSession $cimsession
#>

configuration install_IIS_Kraschobang
{

    param
    (
        # Target nodes to apply the configuration
        [Parameter(Mandatory = $true)]
        [string[]]$computername,

        # Name of the website to create
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$WebSiteName,

        # Name of the website to create
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$WebAppPoolName,

        # Certificate ThumbPrint
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$CertThumbprint

        
    )


    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration
    #Import-DscResource -Module cWebAdministration
    ##Import-DscResource -module cNTFSPermission
    #Import-DscResource -Module cPSWAAuthorization #Mine

    Node $computername
    {
        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure = 'Present'
            Name            = "Web-Server"
        }

        WindowsFeature DefaultDoc
        {
            Ensure          = "Present"
            Name            = "Web-Default-Doc"
            DependsOn       = '[WindowsFeature]IIS'
        }
        WindowsFeature StaticContent
        {
            Ensure          = "Present"
            Name            = "Web-Static-Content"
            DependsOn       = '[WindowsFeature]IIS'
        }
        
        # Create the new Application Pool 
        xWebAppPool PSWAPool 
        {
            Ensure                = "Present"
            Name                  = $WebAppPoolName
            autoStart = $true
            managedRuntimeVersion = ""
            managedPipelineMode   = "Integrated"
            startMode             = "AlwaysRunning"
            identityType          = "ApplicationPoolIdentity"
            restartSchedule       = @("18:30:00","05:00:00")
            DependsOn             = @('[WindowsFeature]IIS') 

        }
        
        
        File StartpAGE
        {
            DestinationPath = "c:\inetpub\wwwroot\default.html"
            Ensure = "Present"
            Type = "File"
            Contents =  "<HTML><link rel='stylesheet' href='https://www.regionorebrolan.se/Style/global.css'><div><b>Välkommen till Region Örebro Läns fina websida!<div><img src='https://www.regionorebrolan.se/logo.png'></div><a href=''>En liten länk</a><br><a href=''>Två små länkar</a><br><br><button style='border:1px solid black;'>Logga in</button>&nbsp;<button style='border:1px solid black;'>Logga ut</button></div></HTML>"
        }

       
        xWebsite PSWASite #ResourceName
        {
            Name = $WebSiteName
            ApplicationPool = $WebAppPoolName

            BindingInfo = @(

                MSFT_xWebBindingInformation
                {
                    Protocol              = "HTTPS"
                    Port                  = 443
                    CertificateThumbprint = $CertThumbprint
                    CertificateStoreName  = "MY"
                }
            )
            DefaultPage = "Default.html"
            DependsOn = "[WindowsFeature]IIS"
            EnabledProtocols = "http"
            Ensure = "Present"
            PhysicalPath = "c:\inetpub\wwwroot\"
            State = 'Started'
        }

        Log Klar
        {
            # Microsoft-Windows-Desired State Configuration/Analytic log
            Message = "Installerade IIS :)"
            DependsOn = "[WindowsFeature]IIS"
        }

    }
}



configuration remove_IIS_Kraschobang
{

    param
    (
        # Target nodes to apply the configuration
        [Parameter(Mandatory = $true)]
        [string[]]$computername,

        # Name of the website to create
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$WebSiteName,

        # Name of the website to create
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$WebAppPoolName,

        # Certificate ThumbPrint
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$CertThumbprint

        
    )


    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration
    #Import-DscResource -Module cWebAdministration
    ##Import-DscResource -module cNTFSPermission
    #Import-DscResource -Module cPSWAAuthorization #Mine

    Node $computername
    {
        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure = 'Absent'
            Name            = "Web-Server"
        }

        File WebRoot
        {
            DestinationPath = "c:\inetpub\websites\testsitedsc"
            Ensure = "Absent"
            Type = "Directory"
        }
        Log Klar
        {

            # Microsoft-Windows-Desired State Configuration/Analytic log
            Message = "Avinstallerade IIS :)"
            DependsOn = "[WindowsFeature]IIS"
        }

    }
}



# Öppna webläsare mot https://kraschobang.orebroll.se
# $Berit=(Get-Credential orebroll\tal008adm)
$cimsession = (New-CimSession kraschobang -Credential $Berit)

icm -ComputerName kraschobang -Credential $Berit {get-service "w3svc"}
break
$cert=icm -Computername kraschobang -Credential  $Berit {Get-Childitem Cert:\LocalMachine\My | Where-Object {$_.Subject -match "cn=kraschobang.orebroll.se"} | Select-Object -ExpandProperty ThumbPrint}
icm -ComputerName kraschobang -Credential $Berit {install-module "xWebAdministration"}
install_IIS_Kraschobang -computername "Kraschobang" -WebSiteName "Websajt" -WebAppPoolName "ApplikationsPoolNamn" -CertThumbPrint $cert -OutputPath c:\dsc -Verbose
Start-DscConfiguration -CimSession $cimsession -Wait -Verbose -Path c:\dsc -force
Test-Connection kraschobang
break
icm -ComputerName kraschobang -Credential $Berit {get-service "w3svc"}
#get-winevent -logname "Microsoft-Windows-DSC/Operational" -ComputerName kraschobang -Credential $credz -MaxEvents 10


#Avinstallation
remove_IIS_Kraschobang -computername "Kraschobang" -WebSiteName "Websajt" -WebAppPoolName "ApplikationsPoolNamn" -CertThumbPrint $cert -OutputPath c:\dsc -Verbose
Start-DscConfiguration -CimSession $cimsession -Wait -Verbose -Path c:\dsc -Force
#Test-Connection kraschobang
#icm -ComputerName kraschobang -Credential $credz {get-service "w3svc"}

#Invoke-Command -ComputerName kraschobang -Credential tal008adm { Set-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb -Value 2048}
#Get-DscLocalConfigurationManager -CimSession (New-CimSession kraschobang -Credential tal008adm ) | select * -First 1