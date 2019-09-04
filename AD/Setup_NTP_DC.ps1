# Disabla timesync fr�n vmware VM settings-> Management-> Integration Services and uncheck Time Synchronization.
# UDP port 123 m�ste vara �ppnad f�r inkommande NTP-trafik
# Observera att eventuella w32time-policies m�ste st�ngas av
# Remove-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\W32Time -Recurse 
# gpupdate

<#
# Regv�rden f�r w32time-service
# https://support.microsoft.com/en-us/help/816042/how-to-configure-an-authoritative-time-server-in-windows-server
# HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time
# F�r Local Policy gpedit.msc
# HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\W32Time

# Reghack f�r att konfa servern att fr�ga extern ntp-k�lla
# 1 �ndra servertypen till NTP.
# HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters
# Type = NTP
# 
# 2 St�ll in AnnounceFlags p� 5.
# HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Config\
# AnnounceFlags = 5 (DWORD)
# 
# 3. Aktivera NTPServer.
# HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer
# Enabled = 1(DWORD)
# 
# 4. Tidsk�llor
# HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters
# NtpServer = "0.pool.ntp.org,0x1 1.pool.ntp.org,0x1 2.pool.ntp.org,0x1 3.pool.ntp.org,0x1,8
# 
# 5.Time Correction
# HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Config\MaxPosPhaseCorrection
# MaxPosPhaseCorrection = E10 (E10 = 3600 i Hex) alternativt 300# In Edit DWORD Value, click to select Decimal in the Base box.
# The default value of MaxPosPhaseCorrection is 48 hours in Windows Server 2008 R2 or later.
# HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Config\MaxNegPhaseCorrection
# MaxNegPhaseCorrection  = E10 (E10 = 3600 i HEX) The default value of MaxNegPhaseCorrection is 48 hours in Windows Server 2008 R2 or later.


# Hela delen blir#>
$ntpservers = "0.pool.ntp.org,0x8","1.pool.ntp.org,0x8","2.pool.ntp.org,0x8","3.pool.ntp.org,0x8"
#Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters\ -Name Type
Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters\ -Name Type -Value "NTP" -Type String

#Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config\ -Name AnnounceFlags
Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config\ -Name AnnounceFlags -Value 5 -Type DWord

#Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer -Name Enabled
Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer -Name Enabled -Value 1 -Type DWord

#Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters -Name NtpServer
Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters -Name NtpServer -Value "$ntpservers" -Type String

#Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config -Name MaxPosPhaseCorrection
Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config -Name MaxPosPhaseCorrection -Value 3600 -Type DWord

#Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config -Name MaxNegPhaseCorrection
Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config -Name MaxNegPhaseCorrection -Value 3600 -Type DWord

restart-service w32time
w32tm /resync /rediscover /nowait
w32tm /query /configuration
w32tm /query /status
w32tm /query /peers

# Konfa windows att anv�nda intern maskinvaruklocka (CMOS, BIOS el fr�n ex vmware)
#Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config -Name AnnounceFlags
#Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config -Name AnnounceFlags -Value 10 -Type DWord
#restart-service w32time

#>

<#
# Denna del k�rs p� DC med kommando w32Time


#Stop-Service w32time
#0x01 � use special poll interval SpecialInterval
#0x02 � UseAsFallbackOnly
#0x04 � send request as SymmetricActive mode
#0x08 � send request as Client mode

w32tm /config /update /manualpeerlist:"0.pool.ntp.org,0x8 1.pool.ntp.org,0x8 2.pool.ntp.org,0x8 3.pool.ntp.org,0x8" /syncfromflags:MANUAL /reliable:yes
Restart-Service w32time -verbose


# Detta k�rs p� den dom�nanslutna klienten
w32tm /config /syncfromflags:domhier /update
# Kontrollera inst�llningar
# Current configuration
w32tm /query /configuration
w32tm /query /status
w32tm /query /peers
#Current running source
w32tm /query /source
# Force the service to try to resync with its configured source.
w32tm /resync 


# Testa att NTP-servern svarar
w32tm /stripchart /computer:0.pool.ntp.org /dataonly /samples:5

w32tm /stripchart /computer:thomasdc.supercow.se /dataonly /samples:5



# Backa och l�gg tillbaka default W32time configuration
Stop-Service w32time
w32tm /unregister
w32tm /register
Start-Service w32Time

#>


