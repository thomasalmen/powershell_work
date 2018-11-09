# https://docs.microsoft.com/en-us/powershell/dsc/bootstrapdsc
# Mounta VHDn som ska autostarta med DSC-conf
mount-vhd -Path "c:\virtuella maskiner\kurt\virtual hard disks\kurt-OSDisk.vhdx"

#Sample DSC-conf
Configuration Injectad_DSC
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    node ('localhost')
    {
        Service BITS
        {
            name = "BITS"
            Ensure = 'present'
            State = 'Stopped'
            Description = "Service modifierad av DSC i pending.mof"
        }
        service Spooler {
            Name = "Spooler"
            Ensure='Present'
            State = 'Stopped'
            Description = "Service modifierad av DSC i pending.mof"
        }
    }
}
#Skapa mof-fil = localhost.mof
Injectad_DSC -OutputPath $env:temp\Injectad_DSC

#Flytta el kopiera mof-filen till virtuella disken och avmounta den.
copy-Item C:\Users\thalm\AppData\Local\Temp\skapadc\DC.meta.mof -Destination "e:\Windows\System32\Configuration\metaconfig.mof" -Force
copy-Item C:\Users\thalm\AppData\Local\Temp\skapadc\DC.mof -Destination "e:\Windows\System32\Configuration\Pending.mof" -Force

#Move-Item $env:temp\Injectad_DSC\localhost.mof -Destination "e:\Windows\System32\Configuration\Pending.mof" -Force
Dismount-VHD -Path "c:\virtuella maskiner\kurt\virtual hard disks\kurt-OSDisk.vhdx"

#Boota sen maskinen som vanligt.