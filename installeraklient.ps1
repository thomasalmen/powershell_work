#hyper-v
# chrome + IE inkognito
# startsida intra
# animeringsgrejjer GUI - computer
# F5 editor
# vscode
# installera chrome
# F5 irule editor
# 7zip
# winscp
# notepad++
# beyond compare: L:\Serverdrift\Tools\Beyond Compare 3.1.11.12204
# Veracrypt
# cygwin

<# Installera PowerShellGet Module (https://docs.microsoft.com/en-us/powershell/gallery/psget/get_psget_module)
Get-Module -Name PowerShellGet 
Install-PackageProvider Nuget –Force
Install-Module –Name PowerShellGet –Force
Update-Module -Name PowerShellGet
Install-Module –Name IISAdministration -Force
## Importera modul: Import-Module IISAdministration
#>


break

#Installera prylar

"Glöm inte att starta om datorn!"


<# Avinstallera jox  #>
    "Avinstallerar skräp"
    # Get-AppxPackage  | where { $_.PackageFullName -match "bing" }
    # Remove-AppxPackage Vill ha PackageFullName som parameter
    Remove-AppxPackage Microsoft.BingWeather_4.21.2212.0_x64__8wekyb3d8bbwe -ErrorAction SilentlyContinue | out-null
<# Slut avinstallera #>




<# WSL #>
    "Installerar WSL..."
    #Disable-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online
    $status = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    if($status.State -eq "Enabled")
    {
        return "WSL redan enablat..avbryter"
    }
    #https://docs.microsoft.com/en-us/windows/uwp/get-started/enable-your-device-for-development
    New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock -Name AllowDevelopmentWithoutDevLicense -PropertyType DWord -Value 1 -Force
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart

    Start-Process -FilePath C:\Windows\System32\cmd.exe -ArgumentList "/c `"lxrun /install /y`"" -NoNewWindow -Wait
    ## initially set default user as root
    Start-Process -FilePath C:\Windows\System32\cmd.exe -ArgumentList "/c `"lxrun /setdefaultuser root /y`"" -NoNewWindow -Wait
    # Launch Windows Store för andra distar (disablat inom oll)
    # Start-Process -FilePath "ms-windows-store://collection/?CollectionId=LinuxDistros"
<# Slut WSL #>

<# RSAT #>

	#Requires -RunAsAdministrator

	$web = Invoke-WebRequest https://www.microsoft.com/en-us/download/confirmation.aspx?id=45520

	$MachineOS= (Get-WmiObject Win32_OperatingSystem).Name

	#Check for Windows Server 2012 R2
	IF($MachineOS -like "*Microsoft Windows Server*")
	{
	    Add-WindowsFeature RSAT-AD-PowerShell
	    Break
	}
	IF ($ENV:PROCESSOR_ARCHITECTURE -eq "AMD64"){
	    Write-host "x64 Detected" -foregroundcolor yellow
	    $Link=(($web.AllElements |where class -eq "multifile-failover-url").innerhtml[0].split(" ")|select-string href).tostring().replace("href=","").trim('"')
	    }ELSE{
	    Write-host "x86 Detected" -forgroundcolor yellow
	    $Link=(($web.AllElements |where class -eq "multifile-failover-url").innerhtml[1].split(" ")|select-string href).tostring().replace("href=","").trim('"')
	}

	$DLPath= ($ENV:USERPROFILE) + "\Downloads\" + ($link.split("/")[8])

	Write-Host "Downloading RSAT MSU file" -foregroundcolor yellow
	Start-BitsTransfer -Source $Link -Destination $DLPath

	$Authenticatefile=Get-AuthenticodeSignature $DLPath
	
	$WusaArguments = $DLPath + " /quiet"
	if($Authenticatefile.status -ne "valid") {write-host "Can't confirm download, exiting";break}
	Write-host "Installing RSAT for Windows 10 - please wait" -foregroundcolor yellow
	Start-Process -FilePath "C:\Windows\System32\wusa.exe" -ArgumentList $WusaArguments -Wait

<# Slut RSAT #>




<# Kolla o ev ta bort Powershell V2 #>

"Tar bort PSv2"
    try 
    {
        if ( (Get-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2).State -match  "Enabled")
        {
            try {
                disable-windowsoptionalfeature -online -featureName MicrosoftWindowsPowerShellV2
            }catch [Exception]{
                write-host "[Fail]`n$_.Exception.Message"
            }
	        write-host "Powershell v2 disablades"
        }
    }
    catch [Exception] {
        Write-Warning $_.Exception.Message
    }

<# Slut Powershell V2 #>



<# Sysinternals #>

    #Funktionen förutsätter att det är en tom dator där inte sysinternals borde finnas installerat från början.
    # Därför laddas filen ner först och sen sker kontrollerna + ev installation
    $sysinternals_url = "http://live.sysinternals.com/Files/SysinternalsSuite.zip"
    $sysinternals_tempmapp = "$env:temp\sysinternals_temp"
    $sysinternals_installmapp = "c:\SysinternalsSuite"
    $sysinternals_replace_taskmanager_regpath="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe"
    try 
    { 
        Write-Host "Installerar Sysinternals Tools"
        # Ladda ner tools fr sysinternals
        Invoke-WebRequest -UseBasicParsing -Uri $sysinternals_url -OutFile $env:temp\SysinternalsSuite.zip -Verbose 
        Expand-Archive -LiteralPath $env:temp\SysinternalsSuite.zip -DestinationPath $sysinternals_tempmapp -Force

        if(Test-Path $sysinternals_installmapp){

            Get-ChildItem -path $sysinternals_tempmapp | foreach 
            {

                if(Test-Path "$sysinternals_installmapp\$psitem")
                {

                    $new_filehash = Get-FileHash "$sysinternals_installmapp\$psitem" -Algorithm MD5
                    $old_filehash = Get-FileHash "$sysinternals_tempmapp\$psitem" -Algorithm MD5

                    #Returnerar objektet som matchar
                    If (Compare-Object -ReferenceObject ($old_filehash) -DifferenceObject ($new_filehash) -Property Hash) 
                    {
                        "$sysinternals_tempmapp\$psitem Inte samma som målfilen $sysinternals_installmapp\$psitem --> kopierar."
                        Copy-Item -Path "$sysinternals_tempmapp\$psitem" -Destination "$sysinternals_installmapp"
                    }
                }
                else 
                {
                    Copy-Item -Path "$sysinternals_tempmapp\$psitem" -Destination "$sysinternals_installmapp" -Verbose
                }
            }
        }
        else
        {
            #Sysinternals inte installerat (iaf inte i "standardmappen", så då kopierar vi bara dit mappen.)
            Copy-Item -Path $sysinternals_tempmapp -Destination "$sysinternals_installmapp" -Recurse
            Unblock-File -Path $sysinternals_installmapp\*.*
        }
 
        #Byter ut taskmanager mot sysinternals process explorer via reghack.
        if(Test-Path $sysinternals_replace_taskmanager_regpath)
        {
            $temp=(Get-ItemProperty -Path $sysinternals_replace_taskmanager_regpath -Name "Debugger" -ErrorAction SilentlyContinue).Debugger

            if($temp -ne "$sysinternals_installmapp\procexp.exe")
            {
                New-ItemProperty -Path $sysinternals_replace_taskmanager_regpath -Name "Debugger" -Value "$sysinternals_installmapp\procexp.exe" -PropertyType String -Force | Out-Null
            }
        } 
        else
        {
            #Nyckeln finns inte (Skapas av procexp) så därför skapar vi den och lägger till strängvärdet.
            New-Item -Path $sysinternals_replace_taskmanager_regpath -Force | Out-Null
            New-ItemProperty -Path $sysinternals_replace_taskmanager_regpath -Name "Debugger" -Value "$sysinternals_installmapp\procexp.exe" -PropertyType String -Force | Out-Null
        }
        $temp=$null

        #Installerar sysmon
        # Konfigfil snodd från: https://github.com/SwiftOnSecurity/sysmon-config
        try
        {
            Invoke-WebRequest "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" -UseBasicParsing -OutFile "$sysinternals_installmapp\sysmonconfig-export.xml" -Verbose
            Start-Process "$sysinternals_installmapp\sysmon.exe" -ArgumentList "-accepteula -i $sysinternals_installmapp\sysmonconfig-export.xml" -Verbose -Wait
        }
        catch [Exception] 
        {
            Write-Warning $_.Exception.Message
        }
    #Sätter PATH till sysinternalsmappen
    Set-Item -path env:PATH -value ($env:PATH + "$sysinternals_installmapp")
    $env:path

    #Uppdaterar PATH
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Environment" -Name PATH –Value ( (Get-ItemProperty -Path "$Reg" -Name PATH).Path + ";$sysinternals_installmapp")


    }
    catch [Exception] 
    {
        Write-Warning $_.Exception.Message
    }
<# slut sysinternals #>

<# Enabla hyper-v #>

    "Enablar Hyper-V"
    $status = Get-WindowsOptionalFeature -Online -FeatureName  Microsoft-Hyper-V
    if($status.State -eq "Enabled")
    {
        return "Hyper-V redan enablat"
    }
    Enable-WindowsOptionalFeature -NoRestart -Online -FeatureName:Microsoft-Hyper-V -All

<# Slut hyper-v #>

<# show "Run as user"#>
# https://superuser.com/questions/1045158/how-do-you-run-as-a-different-user-from-the-start-menu-in-windows-10
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name ShowRunasDifferentuserinStart -Value 1 -type DWORD
Stop-Process -processname explorer
<# Slut "Run as user"#>


<# Fiddler #> 
        $fiddlerurl="https://telerik-fiddler.s3.amazonaws.com/fiddler/FiddlerSetup.exe"
        Invoke-WebRequest $fiddlerurl -OutFile "$env:temp\fiddlersetup.exe" -Verbose -UseBasicParsing
        Start-Process -FilePath "$env:temp\fiddlersetup.exe" -ArgumentList "/s" -Wait
<# Slut fiddler #>

<# Chrome #>
    $chromeurl="https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B6351D934-E40D-0C49-3472-3F482871B5AF%7D%26lang%3Den%26browser%3D4%26usagestats%3D1%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers%26ap%3Dx64-stable-statsdef_1%26installdataindex%3Ddefaultbrowser/chrome/install/ChromeStandaloneSetup64.exe"
    $chromeExecute="$env:temp\ChromeStandaloneSetup64.exe"
    invoke-webrequest $chromeurl -OutFile $chromeExecute -UseBasicParsing -Verbose
    Start-Process $chromeExecute -Wait
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\http\shell\open\command" -Name "(default)" -Value "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -type String -Force

    #Chrome policies
     Set-ItemProperty -path HKLM:\SOFTWARE\Policies\Google\Chrome -name 'IncognitoModeAvailability' -Value 0
     Set-ItemProperty -path HKLM:\SOFTWARE\Policies\Google\Chrome -name 'RestoreOnStartupURLs' -Value ""

<# Chrome #>



<# Lite reghacks #>
#Reghacks .net:
#$Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
#$RegistryKey = $Registry.OpenSubKey("SOFTWARE\\Classes\\http\\shell\\open\\command")
#$Value = $RegistryKey.GetValue("")

    "Fixar onödiga registerposter"


    # Enabla Windows update
    New-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate -Name "DisableWindowsUpdateAccess" -PropertyType dword -Value 0 -Force| Out-Null
    New-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate -Name "AcceptTrustedPublisherCerts" -PropertyType dword -value 1 -Force| Out-Null
    New-ItemProperty -path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -name "NoAutoUpdate" -PropertyType dword -Value 0 -Force | Out-Null
    get-service -Name wuauserv | Restart-Service

    # IE startpage
    new-itemproperty -Path "HKCU:\Software\Microsoft\Internet Explorer\Main" -name "Start page" -PropertyType String -Value "About:blank" -Force
    new-itemproperty -Path "HKCU:\Software\Microsoft\Internet Explorer\Main" -name "Search page" -PropertyType String -Value "http://www.google.com" -Force

    
    # Tillåt inprivate i IE (Group policy)
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Group Policy Objects\{A635290A-87DF-4C6F-AA22-CF72B072559A}User\Software\Policies\Microsoft\Internet Explorer\Privacy" -Name "EnableInPrivateBrowsing" -Value 1 -PropertyType DWORD -Force
    

    # HKEY_USERS mountas efter att anv loggar in med dess SID.
    # Måste alltså hitta min SID först. (Note to self: vet att den för tillfället är:S-1-5-21-57989841-796845957-725345543-58060 )
    # https://stackoverflow.com/questions/20186778/read-hkey-users-and-hkey-current-users
    # http://www.checkyourlogs.net/?p=24811
    $SID = (Get-WmiObject -Class Win32_UserAccount  -Filter "Domain = 'orebroll' AND Name = 'tal008'").SID 
    New-ItemProperty -Path "Registry::HKEY_USERS\$SID\Software\Policies\Microsoft\Internet Explorer\Main" -Name "Start Page" -Value "about:blank" -PropertyType STRING -Force | Out-Null

    # Edge startpage - stydr av policy och ligger inte i HKEY_classes_root som default
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Internet Settings" -Name "ProvisionedHomePages" -Value "About:blank" -PropertyType String -force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" -Name "AllowInPrivate" -Value 1 -PropertyType dword -force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" -Name "PreventAccessToAboutFlagsInMicrosoftEdge" -Value 0 -PropertyType dword -force | Out-Null

    # Ta bort Driftinformation.exe från startup
    if(Test-Path "HKLM:\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run")
    {
        if( (Get-ItemProperty -Path "HKLM:\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "Driftinfo" -ErrorAction SilentlyContinue ).driftinfo )
        {
            Remove-ItemProperty -Path "HKLM:\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "Driftinfo" | Out-Null
        }
        get-process -Name "Driftinformation" -ErrorAction SilentlyContinue | Stop-Process | Out-Null
    }
<# Slut reghacks #>


<# Windows #>
#cd hkcu:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects
#gi *


#$visualfxregpath = Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 
#$visualfxregpath | Foreach-Object { 
#    New-ItemProperty -Path $_.pspath -Name "DefaultApplied" -Value 0 -PropertyType DWORD -Force
#}



<# Slut windows #>
 
#New-ItemProperty -path "HKCU:\Software\Microsoft\Internet Explorer\Safety\PrivacIE" -Name "StartMode" -PropertyType DWORD -Value 1 -Force
