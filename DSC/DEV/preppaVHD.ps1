$VHDXFilePath = "C:\Virtuella Maskiner\S1\Virtual Hard Disks\S1.vhdx"
$computername = "DATORNAMN"
$AdministratorPassword = "Thomas123"

[ScriptBlock]$TestScript = {
    $UnattendFileExists = $false
    $exceptionCaught = $false
    $DriveLetter = [string]::Empty

    try {
        Mount-VHD -Path '$VHDXFilePath' -ReadOnly -Verbose -ErrorAction SilentlyContinue
        # Find out which drive letter the .vhdx file was mounted with
        $Disks = Get-CimInstance -ClassName Win32_DiskDrive | where Caption -eq "Microsoft Virtual Disk"
        foreach ($Disk in $Disks) {
            $Volumes = Get-CimAssociatedInstance -CimInstance $Disk -ResultClassName Win32_DiskPartition
            foreach ($Volume in $Volumes) {
                $LogicalDisk = Get-CimAssociatedInstance -CimInstance $Volume -ResultClassName Win32_LogicalDisk | where VolumeName -ne 'System Reserved'
                foreach ($prop in $LogicalDisk.CimInstanceProperties) {
                    if ($prop.Name -eq 'DeviceID') {
                        $DriveLetter = $prop.Value
                        Write-Verbose -Message "Mounted as drive $DriveLetter"
                        break
                    }
                }
            }
        }


        # Check if the Unattend.xml file exists
        if ($DriveLetter -ne [string]::Empty) {
            $UnattendFilePath = $DriveLetter + "\Unattend.xml"
            $UnattendFileExists = [System.IO.File]::Exists($UnattendFilePath)
            Write-Verbose -Message ([string]::Format("UnattendFilePath: {0}; UnattendFileExists: {1}", $UnattendFilePath, $UnattendFileExists))
        }
        else {
            $exceptionCaught = $true
        }
    }
    catch {
        $exceptionCaught = $true
    }
    finally {
        Dismount-VHD -Path '$VHDXFilePath' -ErrorAction SilentlyContinue -Verbose
    }

    if ($exceptionCaught) {
        Write-Verbose -Message ('An exception was caught during Test-TargetResource. No changes will be made.')
        return $true
    }
    if ($UnattendFileExists) {
        Write-Verbose -Message 'The Unattend.xml file already exists and no action is required.'
        return $true
    }
    else {
        Write-Verbose -Message 'The Unattend.xml file was not found and needs to be created.'
        return $false
    }
}




<# Unattendfil #>
$UnattendContents = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
<settings pass="windowsPE">
    <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <UserData>
        <AcceptEula>true</AcceptEula>
        <FullName>Atea</FullName>
        <Organization>Atea AB</Organization>
    </UserData>
    </component>
</settings>
<settings pass="offlineServicing">
    <component name="Microsoft-Windows-LUA-Settings" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <EnableLUA>true</EnableLUA>
    </component>
</settings>

<settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <ComputerName>$Computername</ComputerName>
        <RegisteredOrganization>$OrganizationName</RegisteredOrganization>
        <RegisteredOwner></RegisteredOwner>
    </component>
    <component name="Networking-MPSSVC-Svc" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <DomainProfile_EnableFirewall>true</DomainProfile_EnableFirewall>
        <PrivateProfile_EnableFirewall>true</PrivateProfile_EnableFirewall>
        <PublicProfile_EnableFirewall>true</PublicProfile_EnableFirewall>
    </component>
    <component name="Microsoft-Windows-TerminalServices-LocalSessionManager" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <fDenyTSConnections>false</fDenyTSConnections>
    </component>
    <component name="Microsoft-Windows-TerminalServices-RDP-WinStationExtensions" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <UserAuthentication>0</UserAuthentication>
    </component>
    <component name="Microsoft-Windows-SQMApi" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <CEIPEnabled>1</CEIPEnabled>
    </component>
    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <InputLocale>0409:00000409</InputLocale>
        <SystemLocale>en-US</SystemLocale>
        <UILanguage>en-US</UILanguage>
        <UILanguageFallback>en-US</UILanguageFallback>
        <UserLocale>en-US</UserLocale>
    </component>
</settings>

<settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <UserAccounts>
            <AdministratorPassword>
            <Value>$AdministratorPassword</Value>
            <PlainText>true</PlainText>
            </AdministratorPassword>
        </UserAccounts>
        <RegisteredOrganization>Atea AB</RegisteredOrganization>
        <RegisteredOwner>Atea Ab</RegisteredOwner>
        <OOBE>
            <HideEULAPage>true</HideEULAPage>
            <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
            <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
            <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
            <NetworkLocation>Work</NetworkLocation>
            <ProtectYourPC>1</ProtectYourPC>
            <SkipUserOOBE>true</SkipUserOOBE>
            <SkipMachineOOBE>true</SkipMachineOOBE>
        </OOBE>
        <TimeZone>UTC</TimeZone>
        <VisualEffects>
            <SystemDefaultBackgroundColor>4</SystemDefaultBackgroundColor>
        </VisualEffects>
    </component>
</settings>
</unattend>
"@









[ScriptBlock]$SetScript = {
    try {
        # Mount the .vhdx file, and identify the drive letter it's using
        Mount-VHD -Path '$VHDXFilePath' -Verbose
        $Disks = Get-CimInstance -ClassName Win32_DiskDrive | where Caption -eq "Microsoft Virtual Disk"
        foreach ($Disk in $Disks) {
            $Volumes = Get-CimAssociatedInstance -CimInstance $Disk -ResultClassName Win32_DiskPartition
            foreach ($Volume in $Volumes) {
                $LogicalDisk = Get-CimAssociatedInstance -CimInstance $Volume -ResultClassName Win32_LogicalDisk | where VolumeName -ne 'System Reserved'
                foreach ($prop in $LogicalDisk.CimInstanceProperties) {
                    if ($prop.Name -eq 'DeviceID') {
                        $DriveLetter = $prop.Value
                        Write-Verbose -Message "Mounted as drive $DriveLetter"
                        break
                    }
                }
            }
        }
        # Tell PowerShell that it has a new drive to know about... without this, it can't see the drive
        New-PSDrive -Name $DriveLetter.Substring(0, 1) -PSProvider FileSystem -Root "$($DriveLetter)\"
        $UnattendFilePath = $DriveLetter + "\Unattend.xml"
        # Create a local variable to hold the contents of the Unattend.xml file... we'll use String.Replace to insert the contents below
        $LocalUnattendContents = '$UnattendContents'
        # Write the Unattend.xml file to the mounted .vhdx file
        $LocalUnattendContents | Out-File $UnattendFilePath -Force -Encoding Default
        Write-Verbose -Message ('Unattend.xml file written to ' + $UnattendFilePath)
    }
    catch {
        Write-Verbose -Message ([string]::Format('Exception: {0}; {1}', $_.Exception.Message, $_.Exception.StackTrace))
    }
    finally {
        Dismount-VHD -Path '$VHDXFilePath' -ErrorAction SilentlyContinue -Verbose
    }
}


Configuration ScriptTest
{
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'

    Node localhost
    {
        Script VMUnattendScript {
            GetScript = "NADA" #$GetScript.ToString().Replace('$VHDXFilePath', $VHDXFilePath)
            SetScript = $SetScript.ToString().Replace('$VHDXFilePath', $VHDXFilePath).Replace('$UnattendContents', $UnattendContents)
            TestScript = $TestScript.ToString().Replace('$VHDXFilePath', $VHDXFilePath)
            #DependsOn = '[File]' + $BaseFileResourceName
        }
    }
}
ScriptTest
Start-DscConfiguration -Path C:\WINDOWS\system32\ScriptTest -ComputerName localhost -Wait -Verbose -force