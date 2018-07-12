# READ FIRST!!
# Modulerna måste vara konstanter = måste finnas lokalt installerade innan scriptet körs
# * Antingen specas modulversionen "Import-DscResource -ModuleName xWebAdministration -ModuleVersion 1.20.0.0"
# * Eller så avinstalleras alla moduler som inte behövs
# Observera återigen att modulnamnen ska vara konstanter och inte variabler om paramteren -AllVersions ska användas.
# Uninstall-Module -Name xwebadministration -AllVersions
# Uninstall-Module -Name Xsmbshare -AllVersions
# Uninstall-Module -Name cNtfsAccessControl -AllVersions


# Foreach-satsen nedan måste först köras manuellt innan scriptet startas
# Kommentera sen bort foreach-satsen och kör scriptet som vanligt.
# # # # # 
$dscResources=@("xWebAdministration","xSMBShare","cNtfsAccessControl","testgrunka")
#foreach($d in $dscResources)
#{
#    find-module $d | install-module -Force
#}
# # # # # 


#Find-Module cNtfsAccessControl, PSDesiredStateConfiguration, xSMBShare, xWebAdministration | Install-Module -Force
#Get-DscResource -Module PSDesiredStateConfiguration
#Get-DscResource -Module xSMBShare
#Get-DscResource -Module xWebAdministration
#Get-DscResource -Module cNtfsAccessControl

#find-module xWebAdministration | Install-Module
#find-module cNTFSPermission | Install-Module

#Find-Module cNtfsAccessControl, PSDesiredStateConfiguration, xSMBShare, xWebAdministration | Install-Module -Force

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

Configuration Configuration_OLLWeb
{
    param(
        [Parameter(Mandatory=$true)]
        $computername
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -ModuleName xSMBShare
    Import-DscResource -ModuleName cNtfsAccessControl

    Node $computername
    {
        <#
        $enabled_featurenames.ForEach({
        #$node.Features.foreach({
            WindowsFeature $_ {
                Name = $_
                Ensure = 'Present'
            }
        }) #foreach
        
        #>
       
       <#
        $disabled_featurenames.ForEach({
        #$node.Features.foreach({
            WindowsFeature $_ {
                Name = $_
                Ensure = 'Absent'
            }
        }) #foreach
        #>


        #region filesanddirs
        
        File Folder1 {
            Ensure = 'Present'
            DestinationPath = 'd:\websites'
            Type = 'Directory'
        }

        <#
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
        #>

        <#
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
        #>
    
    }
}

Function Install-DSCEnabledComputer{

    [cmdletbinding()]
    Param(
        [Parameter(Position = 0,Mandatory=$false, ValueFromPipeline)]
        [ValidateNotNullorEmpty()]
        [string[]]$Computername,
        #[pscredential]$credz =(Get-Credential tal008adm),
        [string]$psrepository=(Get-PSRepository).name
    )
    Begin
    {
        Write-Verbose "[ BEGIN ] Starting: $($MyInvocation.Mycommand)"  
    } #begin
    Process
    {

    $rapport=@()
    $result = ""; $action = ""
    foreach($computer in $Computername)
    {
        Write-Verbose "Ansluter till '$computer'"  
        try
        {
            # Skitmuppigt :/
            # Invoke-command använder pssession och DSC använder cimsession
            # Därför både pssession och cimsession här.
            # TODO: Kanske finns nåt bättre sätt..?
            $PSsession = New-PSSession -ComputerName $computer -Credential $credz -ErrorAction stop
            $cimsession = new-cimsession -ComputerName $computer -credential $credz -ErrorAction Stop
            
        }
        catch
        {
            $result = "Kunde inte ansluta till '$computer' - skipping"
            Write-Verbose $result
            return
        }    

     
        Write-Verbose "Checking prerequisites.."
        foreach($r in $dscResources)
        {
            #Kollar om dsc-resursen finns
            if(! ( Invoke-Command -Session $PSsession  { get-DscResource -Module $using:r }  ) -eq $false )
            {
                $prerequisites += "'$r' Ok"
                #Write-Verbose "'$r' OK."
            }
            else
            {
                #Finns den inte kollar vi i $psrepository
                if(! (Invoke-Command -Session $PSsession { Find-DscResource -ModuleName $using:r -Repository $using:psrepository }  ) -eq $false)
                {
                    write-verbose "Hittade '$r' i '$psrepository' - installerar DSCmodul..."
                    if(! (Invoke-Command -Session $PSsession {install-module $using:r -Force -WhatIf } )  -eq $false)
                    {
                        write-verbose "Kontrollerar att DSCmodul installerats ok..."
                        if( !(Invoke-Command -Session $PSsession  { get-DscResource -Module $using:r } ) -eq $false )
                        {
                            $prerequisites +=  "Module '$r' installed OK."
                            #write-verbose "Module '$r' installed OK."
                        }
                    }                        
                }
                else
                {
                    $prerequisites += "Failed to install module '$r'!"
                    #write-verbose "Hittade inte '$r' i '$psrepository' - kan inte installera '$r'!"
                }

            }
        }

        #Kör DSC-konfen.
        Configuration_OLLWeb -OutputPath $env:TEMP -computername $Computer -verbose
        #ii $env:TEMP\$computername.mof
        Start-DscConfiguration -Path $env:TEMP -CimSession $cimsession -Wait -Force

#        if( (Test-DscConfiguration -ComputerName kraschobang -Credential (get-credential)) -eq $true)
#        {
#            Write-Verbose "All steps performed OK"
#        }
        $rapport+=[PSCustomObject]@{
            Computername     = $pssession.ComputerName
            Result = $result
            Action = $action
            PreRequisites = $prerequisites 
        }

        remove-PSSession $PSsession
        Remove-CimSession $cimsession
    }#foreach

    


    } #process
    End
    {
        $rapport

        Write-Verbose "[  END  ] Ending: $($MyInvocation.Mycommand)"
    } #end

}


Install-DSCEnabledComputer -computername "kraschobang","webtest02" -verbose
#Get-DscConfiguration -CimSession $cimsession
#Remove-DscConfigurationDocument -CimSession $cimsession -Stage Previous -Force
#icm -ComputerName kraschobang -Credential tal008adm { uninstall-Module "xWebAdministration" -Verbose -Force }