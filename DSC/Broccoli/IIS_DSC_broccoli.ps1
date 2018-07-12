cls

#Import-Certificate -FilePath "c:\dsc\DscPublicKey.cer" -CertStoreLocation Cert:\LocalMachine\My

if($PSVersionTable.PSVersion.Major -lt 5 ){Write-host "Detta script kräver Powershell version 5 eller senare!" -ForegroundColor Red ;break}
$VerbosePreference="SilentlyContinue"
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

#https://github.com/PowerShell/ComputerManagementDsc/wiki
#Find-Module -Name ComputerManagementDsc -Repository PSGallery | Install-Module -verbose

#Find-Module cNtfsAccessControl, PSDesiredStateConfiguration, xSMBShare, xWebAdministration | Install-Module -Force
#Get-DscResource -Module PSDesiredStateConfiguration
#Get-DscResource -Module xSMBShare
#Get-DscResource -Module xWebAdministration
#Get-DscResource -Module cNtfsAccessControl


$dscResources=@("PSDesiredStateConfiguration","xWebAdministration","xSMBShare","cNtfsAccessControl","ComputerManagementDsc")


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


$ConfigData= @{
    AllNodes = @(
            @{
                # The name of the node we are describing
                NodeName = "broccoli"

                # The path to the .cer file containing the
                # public key of the Encryption Certificate
                # used to encrypt credentials for this node
                CertificateFile = "C:\dsc\DscPublicKey.cer"


                # The thumbprint of the Encryption Certificate
                # used to decrypt the credentials on target node
                Thumbprint = "A8EE561020BB617834A2FDAF0AA00645610D79A9"
            };
        );
    }

Configuration Configuration_Broccoli
{
    #param(
    #    [Parameter(Mandatory=$true)]
    #    $computername
    #)
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration -ModuleVersion 1.20.0.0
    Import-DscResource -ModuleName xSMBShare -ModuleVersion 2.1.0.0
    Import-DscResource -ModuleName cNtfsAccessControl
    Import-DscResource -ModuleName ComputerManagementDsc -ModuleVersion 5.0.0.0

    

    Node $AllNodes.NodeName
    {
    
        LocalConfigurationManager
        {
             CertificateId = $node.Thumbprint
        }

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



        #region filesanddirs
        File Folder1 {
            Ensure = 'Present'
            DestinationPath = 'D:\Easit'
            Type = 'Directory'
        }

        File Folder2 {
            Ensure = 'Present'
            DependsOn = "[File]Folder1"
            DestinationPath = 'D:\Easit\wwwroot'
            Type = 'Directory'
        }
        File Folder3 {
            Ensure = 'Present'
            DestinationPath = 'D:\orebroll_scheduled_jobs'
            Type = 'Directory'
        }
        #endregion

    
        #region Filesharing
        xSMBShare FileShare {
            DependsOn = '[file]Folder1'
            Ensure = 'Present'
            Name = "Easit$"
            Description = 'Share som ger Jenny Karlsson och Easit access'
            Path = 'D:\Easit'
            FullAccess = "authenticated users"
        }
        #endregion


        #region sharepermissons
        cNtfsPermissionEntry localusers
        {
            Ensure = 'Present'
            DependsOn = "[file]Folder1"
            Path = "d:\Easit"
            Principal = 'BUILTIN\Users'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'ReadAndExecute'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }

        cNtfsPermissionEntry jka091 {
            Ensure = 'Present'
            DependsOn = "[file]Folder1"
            Principal = "$($env:userdomain)\jka091"
            Path = 'd:\Easit'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'FullControl'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                })
        }

        #Permissions for admins
        cNtfsPermissionEntry AdminPermissions
        {
            Ensure = 'Present'
            Path = "d:\Easit"
            DependsOn = '[File]folder1'
            Principal = 'BUILTIN\Administrators'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                    Inheritance = 'ThisFolderOnly'
                    NoPropagateInherit = $false
                }
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'ReadAndExecute'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'AppendData', 'CreateFiles'
                    Inheritance = 'SubfoldersAndFilesOnly'
                    NoPropagateInherit = $false
                }
            )
        
        }
        #Grupp dl_cayenne_easit_l read and execute
        cNtfsPermissionEntry dl_cayenne_easit_l
        {
            Ensure = 'Present'
            Path = "d:\Easit"
            DependsOn = '[File]folder1'
            Principal = 'dl_cayenne_easit_l'
            AccessControlInformation = @(

                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'ReadAndExecute'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        
        }

        #Servicekonto srvacc_easit
        cNtfsPermissionEntry srvacc_easit
        {
            Ensure = 'Present'
            Path = "d:\Easit"
            DependsOn = '[File]folder1'
            Principal = 'srvacc_easit'
            AccessControlInformation = @(

                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }
        #endregion


        #Region Scheduled_tasks

        ScheduledTask ScheduledTaskDailyAdd
        {
            TaskName                  = 'Test task '
            TaskPath                  = '\'
            ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType              = 'Daily'
            DaysInterval              = 1
            RepeatInterval            = '00:15:00'
            RepetitionDuration        = '08:00:00'
            RestartCount              = 2
            RestartInterval           = '00:05:00'
            RunOnlyIfNetworkAvailable = $true
            WakeToRun                 = $true
            Ensure = "Absent"
        }
ScheduledTask AdExport1
{
    TaskName = "TEST-AdExport 1 - Magnus Karlsson"
    #[ActionArguments = [string]]
    ActionExecutable = "D:\orebroll_scheduled_jobs\AdExport\StartaAdExport1.bat"
    ActionWorkingPath = "D:\orebroll_scheduled_jobs\AdExport"
    AllowStartIfOnBatteries = $false
    DaysInterval = 1
    #[DaysOfWeek = [string[]]]
    #[DependsOn = [string[]]]
    Description = "AdExport 1"
    DisallowDemandStart = $false
    DisallowHardTerminate = $false
    #[DisallowStartOnRemoteAppSession = [bool]]
    #[DontStopIfGoingOnBatteries = [bool]]
    #[DontStopOnIdleEnd = [bool]]
    Enable = $true
    Ensure = "Present"
    ExecuteAsCredential = (get-credential "orebroll\srvacc_easit_test")
    #[ExecutionTimeLimit = [string]]
    Hidden = $false
    #[IdleDuration = [string]]
    #[IdleWaitTimeout = [string]]
    #[LogonType = [string]{ Group | Interactive | InteractiveOrPassword | None | Password | S4U | ServiceAccount }]
    #[MultipleInstances = [string]{ IgnoreNew | Parallel | Queue }]
    #[NetworkName = [string]]
    #[Priority = [UInt32]]
    #[PsDscRunAsCredential = [PSCredential]]
    #[RandomDelay = [string]]
    #[RepeatInterval = [string]]
    RepetitionDuration = "Indefinitely"
    #[RestartCount = [UInt32]]
    #[RestartInterval = [string]]
    #[RestartOnIdle = [bool]]
    #[RunLevel = [string]{ Highest | Limited }]
    RunOnlyIfIdle = $false
    RunOnlyIfNetworkAvailable = $true
    ScheduleType = "Daily"
    StartTime = "01:00:00" 
    #[StartWhenAvailable = [bool]]
    TaskPath = "\"
    #[User = [string]]
    WakeToRun = $false
    #[WeeksInterval = [UInt32]]
}
        <#
State                 : Ready
Actions               : {MSFT_TaskExecAction}
Author                : OREBROLL\easit
Date                  : 2018-04-19T17:18:20.9914487
Description           : 
Documentation         : 
Principal             : MSFT_TaskPrincipal2
SecurityDescriptor    : 
Settings              : MSFT_TaskSettings3
Source                : 
#TaskName              : AdExport 1 - Magnus Karlsson
#TaskPath              : \
Triggers              : {MSFT_TaskDailyTrigger}
URI                   : \AdExport 1 - Magnus Karlsson
Version               : 
PSComputerName        : 
CimClass              : Root/Microsoft/Windows/TaskScheduler:MSFT_ScheduledTask
CimInstanceProperties : {Actions, Author, Date, Description...}
CimSystemProperties   : Microsoft.Management.Infrastructure.CimSystemProperties







State                 : Ready
Actions               : {MSFT_TaskExecAction}
Author                : OREBROLL\easit
Date                  : 2018-04-19T17:20:27.23315
Description           : 
Documentation         : 
Principal             : MSFT_TaskPrincipal2
SecurityDescriptor    : 
Settings              : MSFT_TaskSettings3
Source                : 
TaskName              : AdExport 2 - Magnus Karlsson
TaskPath              : \
Triggers              : {MSFT_TaskDailyTrigger}
URI                   : \AdExport 2 - Magnus Karlsson
Version               : 
PSComputerName        : 
CimClass              : Root/Microsoft/Windows/TaskScheduler:MSFT_ScheduledTask
CimInstanceProperties : {Actions, Author, Date, Description...}
CimSystemProperties   : Microsoft.Management.Infrastructure.CimSystemProperties

State                 : Ready
Actions               : {MSFT_TaskExecAction}
Author                : OREBROLL\easit
Date                  : 2018-04-19T17:22:23.5863519
Description           : 
Documentation         : 
Principal             : MSFT_TaskPrincipal2
SecurityDescriptor    : 
Settings              : MSFT_TaskSettings3
Source                : 
TaskName              : Artikelimport
TaskPath              : \
Triggers              : {MSFT_TaskDailyTrigger}
URI                   : \Artikelimport
Version               : 
PSComputerName        : 
CimClass              : Root/Microsoft/Windows/TaskScheduler:MSFT_ScheduledTask
CimInstanceProperties : {Actions, Author, Date, Description...}
CimSystemProperties   : Microsoft.Management.Infrastructure.CimSystemProperties

State                 : Ready
Actions               : {MSFT_TaskExecAction}
Author                : OREBROLL\easit
Date                  : 2018-04-19T16:14:08.1218781
Description           : 
Documentation         : 
Principal             : MSFT_TaskPrincipal2
SecurityDescriptor    : 
Settings              : MSFT_TaskSettings3
Source                : 
TaskName              : Easit EmailRequest
TaskPath              : \
Triggers              : {MSFT_TaskDailyTrigger}
URI                   : \Easit EmailRequest
Version               : 
PSComputerName        : 
CimClass              : Root/Microsoft/Windows/TaskScheduler:MSFT_ScheduledTask
CimInstanceProperties : {Actions, Author, Date, Description...}
CimSystemProperties   : Microsoft.Management.Infrastructure.CimSystemProperties

State                 : Ready
Actions               : {MSFT_TaskExecAction}
Author                : OREBROLL\easit
Date                  : 2018-04-19T16:17:08.3086876
Description           : 
Documentation         : 
Principal             : MSFT_TaskPrincipal2
SecurityDescriptor    : 
Settings              : MSFT_TaskSettings3
Source                : 
TaskName              : Easit ImportClient
TaskPath              : \
Triggers              : {MSFT_TaskDailyTrigger}
URI                   : \Easit ImportClient
Version               : 
PSComputerName        : 
CimClass              : Root/Microsoft/Windows/TaskScheduler:MSFT_ScheduledTask
CimInstanceProperties : {Actions, Author, Date, Description...}
CimSystemProperties   : Microsoft.Management.Infrastructure.CimSystemProperties

State                 : Ready
Actions               : {MSFT_TaskExecAction}
Author                : OREBROLL\easit
Date                  : 2018-04-19T17:27:08.0771989
Description           : 
Documentation         : 
Principal             : MSFT_TaskPrincipal2
SecurityDescriptor    : 
Settings              : MSFT_TaskSettings3
Source                : 
TaskName              : Easit Synk av Anknytningar
TaskPath              : \
Triggers              : {MSFT_TaskDailyTrigger}
URI                   : \Easit Synk av Anknytningar
Version               : 
PSComputerName        : 
CimClass              : Root/Microsoft/Windows/TaskScheduler:MSFT_ScheduledTask
CimInstanceProperties : {Actions, Author, Date, Description...}
CimSystemProperties   : Microsoft.Management.Infrastructure.CimSystemProperties

State                 : Disabled
Actions               : {MSFT_TaskExecAction}
Author                : OREBROLL\easit
Date                  : 2018-04-19T17:30:04.2958021
Description           : 
Documentation         : 
Principal             : MSFT_TaskPrincipal2
SecurityDescriptor    : 
Settings              : MSFT_TaskSettings3
Source                : 
TaskName              : EasitInvoice
TaskPath              : \
Triggers              : {MSFT_TaskTrigger}
URI                   : \EasitInvoice
Version               : 
PSComputerName        : 
CimClass              : Root/Microsoft/Windows/TaskScheduler:MSFT_ScheduledTask
CimInstanceProperties : {Actions, Author, Date, Description...}
CimSystemProperties   : Microsoft.Management.Infrastructure.CimSystemProperties

State                 : Ready
Actions               : {MSFT_TaskExecAction}
Author                : OREBROLL\easit
Date                  : 2018-04-19T17:32:35.6285477
Description           : 
Documentation         : 
Principal             : MSFT_TaskPrincipal2
SecurityDescriptor    : 
Settings              : MSFT_TaskSettings3
Source                : 
TaskName              : Klientimporter
TaskPath              : \
Triggers              : {MSFT_TaskDailyTrigger}
URI                   : \Klientimporter
Version               : 
PSComputerName        : 
CimClass              : Root/Microsoft/Windows/TaskScheduler:MSFT_ScheduledTask
CimInstanceProperties : {Actions, Author, Date, Description...}
CimSystemProperties   : Microsoft.Management.Infrastructure.CimSystemProperties

State                 : Ready
Actions               : {MSFT_TaskExecAction}
Author                : OREBROLL\easit
Date                  : 2018-04-19T17:35:12.0944311
Description           : 
Documentation         : 
Principal             : MSFT_TaskPrincipal2
SecurityDescriptor    : 
Settings              : MSFT_TaskSettings3
Source                : 
TaskName              : Skärmimporter
TaskPath              : \
Triggers              : {MSFT_TaskDailyTrigger}
URI                   : \Skärmimporter
Version               : 
PSComputerName        : 
CimClass              : Root/Microsoft/Windows/TaskScheduler:MSFT_ScheduledTask
CimInstanceProperties : {Actions, Author, Date, Description...}
CimSystemProperties   : Microsoft.Management.Infrastructure.CimSystemProperties


        #>
        #endregion
    
    }
}



Function Install-DSCEnabledComputer{

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
        
        Write-Verbose "Checking DSC-resource prerequisites.."
        foreach($r in $dscResources)
        {
        
            #Kollar om dsc-resursen finns
            if(! ( Invoke-Command -Session $PSsession  { Get-DscResource -Module $args[0] } -ArgumentList "$r" ) -eq $false )
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

        #Kör DSC-konfen - här exekveras förändringarna
        Write-Verbose "Alles ok..Running DSC-Config."
        Configuration_Broccoli -OutputPath $env:TEMP -computername $Computer -verbose
        Start-DscConfiguration -Path $env:TEMP -ComputerName $Computer -Wait -Verbose -Credential $credz -Force
        #Slut dsc-conf


    }#foreach


    #Test-DscConfiguration -ComputerName kraschobang -Credential tal008adm


    } #process
    End
    {
        Write-Verbose "[  END  ] Ending: $($MyInvocation.Mycommand)"
        remove-PSSession $PSsession
    } #end

}




Install-DSCEnabledComputer -computername "broccoli" -verbose
# Get-DscConfiguration -CimSession (new-cimsession broccoli -credential tal008adm)
#Remove-DscConfigurationDocument -CimSession $cimsession -Stage Previous -Force
#Get-DscLocalConfigurationManager -CimSession (new-cimsession kraschobang -credential tal008adm)
#Test-DscConfiguration -ComputerName kraschobang -Credential tal008adm
#Get-DscConfigurationStatus -CimSession (new-cimsession broccoli -credential tal008adm) #-all
#Get-DscResource -Name ScheduledTask -Syntax