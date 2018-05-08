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


#Modul xWebAdministration kommer krävas
$dscResources=@("PSDesiredStateConfiguration","xWebAdministration","smbshare","PSDscResources")


$enabled_featurenames=@(
"Web-Server"
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
"Web-Net-Ext"
"Web-Net-Ext45",
"Web-ASP",
"Web-Asp-Net",
"Web-Asp-Net45",
"Web-ISAPI-Ext",
"Web-ISAPI-Filter",
"Web-Ftp-Server",
"Web-Ftp-Service",
"Web-Mgmt-Tools"

)


$disabled_featurenames=@(
"Server-Media-Foundation",
"WindowsPowerShellWebAccess",
"Containers",
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
"InkAndHandwritingService",
"PowerShellRoot",
"PowerShell",
"PowerShell-ISE"
)

Configuration Install_DSC_IIS
{
    param(
        [Parameter(Mandatory=$true)]
        $computername
    )
    
    #Av nån anledning går det inte att foreacha dessa resources utan de måste specas separat.

    #Get-DscResource -Module xSMBShare
    #Get-DscResource -Module xWebAdministration
    #Get-DscResource -Module PSDscResources
    #Find-DscResource -ModuleName PSDscResources | Install-Module -Force
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    #Import-DscResource -ModuleName PSDscResources -ModuleVersion 2.8.0.0
    
    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -ModuleName xSMBShare

    

    Get-DscResource -Module PSDscResources


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
            WindowsFeature $_ {
                Name = $_
                Ensure = 'Absent'
            }
        }) #foreach
        
        user CreateUser
        {
            UserName = ""
        }
<#
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
#>  
    
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
        #Flyttad till LCM-funktionen
        #invoke-command -session $PSsession { Set-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb -Value 2048 } | out-null
        
        #Flyttad till LCM-funktionen
        #set-LocalDSCProperties -Computername $computer -credz $credz
     
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

#        Test-DscConfiguration -ComputerName "kraschobang" -Credential orebroll\tal008adm

        if( (Test-DscConfiguration -ComputerName $computer -Credential $credz) -eq $true)
        {
            Write-Verbose "All steps performed OK"
        }

    }#foreach





    } #process
    End
    {
        Write-Verbose "[  END  ] Ending: $($MyInvocation.Mycommand)"
        "Ok"
        remove-PSSession $PSsession
    } #end

}

<#
function set-LocalDSCProperties()
{
    [cmdletbinding()]
    Param(
        [Parameter(Position = 0,Mandatory, ValueFromPipeline)]
        [ValidateNotNullorEmpty()]
        [string[]]$Computername,
        [pscredential]$credz

    )

    $cimsession = New-CimSession -ComputerName $computername -Credential $credz
    
    $localdscconf = Get-DscLocalConfigurationManager -CimSession $cimsession  | select ActionAfterReboot,RebootNodeIfNeeded,ConfigurationMode

    if( ($localdscconf.ActionAfterReboot -eq "ContinueConfiguration") -and ($localdscconf.RebootNodeIfNeeded -eq $false ) -and ($localdscconf.ConfigurationMode -eq "ApplyAndAutoCorrect" ) )
    {
        write-verbose "Local DSCconfiguration on '$($cimsession).computername' OK - skipping"
        return    
    }
    else
    {
        write-verbose "Modifying DSCconfig"
        [DscLocalConfigurationManager()]
        Configuration LCM {
    
            param([string[]]$Computername=($cimsession).computername)
    
            Node $Computername {
                Settings {
                    RebootNodeIfNeeded = $false
                    ActionAfterReboot = 'ContinueConfiguration'
                    ConfigurationMode = 'ApplyAndAutoCorrect'
                }
            }
        } 
        LCM -OutputPath $env:temp -Computername ($cimsession).computername
        Set-DscLocalConfigurationManager -Path $env:temp -CimSession $cimsession
        Get-DscLocalConfigurationManager -CimSession $cimsession
    }
}
#>



#Install-IISEnabledComputer -computername "web01a" -verbose -wait
Install-IISEnabledComputer -computername "kraschobang" -verbose