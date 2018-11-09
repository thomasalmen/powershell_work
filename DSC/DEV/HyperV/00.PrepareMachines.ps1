#Glöm inte sysprep
#C:\windows\System32\Sysprep\sysprep.exe

# Kopiera moduler till servern
#Meta mof till: C:\Windows\System32\Configuration\metaconfig.mof
# "mof till X:\Windows\System32\Configuration\Pending.mof

#$mount[1] = Mount-VHD -Path "c:\virtuella maskiner\kurt\virtual hard disks\kurt-OSDisk.vhdx" -PassThru | Get-Disk | Get-Partition | Get-Volume
#Dismount-VHD -Path "c:\virtuella maskiner\kurt\virtual hard disks\kurt-OSDisk.vhdx" 

#$tempcomputers.ForEach({
#mount-vhd -Path "c:\virtuella maskiner\kurt\virtual hard disks\kurt-OSDisk.vhdx"
#    #$tempsess = new-pssession $_ -Credential $creds #(Get-Credential -Message "Ange user/pass för $_" administrator)
#    $requiredDSCModules.ForEach({
#       Copy-Item $env:temp\$_\$_ -ToSession $tempsess  -Destination "C:\Program Files\WindowsPowerShell\Modules" -Recurse -Force -Verbose
#       Invoke-Command -Session $tempsess { Install-Module $using:_ -Force }
#    })
#})