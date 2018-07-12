cls
if($PSVersionTable.PSVersion.Major -lt 5 ){Write-host "Detta script kräver Powershell version 5 eller senare!" -ForegroundColor Red ;break}

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

#install-module -Name PSDesiredStateConfiguration
#install-module -Name xWebAdministration
#install-module -Name xSMBShare

$dscResources=@("PSDesiredStateConfiguration","xWebAdministration","xSMBShare")


$enabled_featurenames=@(
"FileAndStorage-Services",
"File-Services",
"FS-FileServer",
"Storage-Services",
"Web-Server",
"Web-WebServer",
"Web-Common-Http",
"Web-Default-Doc",

"Web-Http-Errors",
"Web-Static-Content",
"Web-Net-Ext45",
"Web-Health",
"Web-Log-Libraries",
"Web-Custom-Logging",
"Web-Http-Logging",
"Web-Request-Monitor",
"Web-Stat-Compression",
"Web-Http-Tracing",
"Web-Security",
"Web-Cert-Auth",
"Web-IP-Security",
"Web-Windows-Auth",
"Web-Client-Auth",
"Web-CertProvider",
"Web-Filtering",
"Web-App-Dev",
"Web-ISAPI-Ext",
"Web-ISAPI-Filter",
"Web-Mgmt-Tools",
"Web-Mgmt-Console",
"Web-Scripting-Tools",
"Web-Mgmt-Service",
"NET-Framework-45-Features",
"NET-Framework-45-Core",
"NET-Framework-45-ASPNET",
"NET-WCF-Services45",
"NET-WCF-TCP-PortSharing45")


$disabled_featurenames=@(
"Containers",
"Web-Basic-Auth",
"Web-Digest-Auth",
"Web-Dir-Browsing",
"Web-Http-Redirect",
"Web-Url-Auth",
"RSAT",
"RSAT-Role-Tools",
"RSAT-AD-Tools", 
"RSAT-AD-PowerShell",
"RSAT-ADDS",
"RSAT-AD-AdminCenter",
"RSAT-ADDS-Tools",
"RSAT-ADLDS", 
"RSAT-Hyper-V-Tools",
"Hyper-V-Tools",
"Hyper-V-PowerShell",
"RSAT-RDS-Tools",
"UpdateServices-RSAT",
"UpdateServices-API",
"UpdateServices-UI",
"RSAT-DNS-Server",
"Web-Ftp-Server"
)

Configuration Install_DSC_IIS
{
    param(
        [Parameter(Mandatory=$true)]
        $computername
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -ModuleName xSMBShare
    #install-module "xWebAdministration"
    #install-module "xSMBShare"
    #Get-DscResource -Module  xSMBShare "xWebAdministration"
    #Find-Module -Repository PSGallery -tag File



    Node $computername
    {
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

    File ReportFolder1 {
        Ensure = 'Present'
        DestinationPath = 'D:\Easit\wwwroot'
        Type = 'Directory'
    }
    File ReportFolder2 {
        Ensure = 'Present'
        DestinationPath = 'D:\orebroll_scheduled_jobs'
        Type = 'Directory'
    }
    
    
    #xSMBShare ReportShare {
    #    DependsOn = '[file]ReportFolder'
    #    Ensure = 'Present'
    #    Name = 'Reports$'
    #    Description = 'admin report share'
    #    Path = 'C:\Reports'
    #    FullAccess = "$env:USERDOMAIN\domain admins"
    #    NoAccess = "$env:USERDOMAIN\domain users"
    #}
    
    }
}



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



Install-IISEnabledComputer -computername "kraschobang" -verbose