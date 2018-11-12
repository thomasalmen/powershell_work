# VHD'n måste vara syspreppad innan unattend funkar.
# Annars går det bra att använda pending.mof (DSC)


$CpuCores=1 #Cpu Cores in the VM
$RAMSize=512MB #Ram Size
$Name="Ivantest" #VMName , will also become the Computer Name
$IPDomain="10.10.30.16" #IP Address
$DefaultGW="10.10.30.1" #Default Gateway to be used
$DNSServer="10.10.30.15" #DNS Server
$DNSDomain="test.com" #DNS Domain Name
$SwitchNameDomain="Server_Vlan" #Hyper V Switch Name
$NetworkAdapterName="NIC" #Set the VM Domain access NIC name
$AdminAccount="Administrator" #User name and Password
$AdminPassword="Thomas123"


$Organization="Test Organization"
$ProductID="TMJ3Y-NTRTM-FJYXT-T22BY-CWG3J"

#Where's the VM Default location? (Asså c:\virtuella maskiner)
$Path= Get-VMHost |select VirtualMachinePath -ExpandProperty VirtualMachinePath

#Where should I store the VM VHD?, you actually have nothing to do here unless you want a custom name on the VHD
$VHDPath=$Path +"\$Name\$Name.vhdx"
$StartupFolder="C:\Virtuella Maskiner\HDS" #Where are the folders with prereq software ?
$TemplateLocation="C:\Virtuella Maskiner\HDS\TESTUnattend.vhdx" #Syspreppade VHD'n
$UnattendLocation="C:\Users\thalm\OneDrive\powershell_work\DSC\DEV\Unattend_mall.xml" #Var finns unattendfilen - templaten?
 
#Start the Party!
#Let's see if there are any VM's with the same name if you actually find any simply inform the user
$VMS=Get-VM
Foreach($VM in $VMS)
{
    if ($Name -match $VM.Name)
    {
        write-host -ForegroundColor Red "Found VM With the same name! ($vm.name)"
        return
    }
}
 
#Create the VM
#New-VM -Name $Name -Path $Path -MemoryStartupBytes $RAMSize -Generation 1 -NoVHD
New-VM -Name $Name -Path $Path -MemoryStartupBytes $RAMSize -Generation 2 -NoVHD
 
#Remove any auto generated adapters and add new ones with correct names for Consistent Device Naming
Get-VMNetworkAdapter -VMName $Name | Remove-VMNetworkAdapter
Add-VMNetworkAdapter -VMName $Name -SwitchName $SwitchNameDomain -Name $NetworkAdapterName -DeviceNaming On
 
#Start and stop VM to get mac address, then arm the new MAC address on the NIC itself
start-vm $Name; sleep 5; stop-vm $Name -Force;
sleep 5
$MACAddress=get-VMNetworkAdapter -VMName $Name -Name $NetworkAdapterName|select MacAddress -ExpandProperty MacAddress
$MACAddress=($MACAddress -replace '(..)','$1-').trim('-')
get-VMNetworkAdapter -VMName $Name -Name $NetworkAdapterName|Set-VMNetworkAdapter -StaticMacAddress $MACAddress
 
#Copy the template and add the disk on the VM. Also configure CPU and start - stop settings
Copy-item $TemplateLocation -Destination  $VHDPath -Force
Set-VM -Name $Name -ProcessorCount $CpuCores  -AutomaticStartAction Start -AutomaticStopAction ShutDown -AutomaticStartDelay 5 
# GEN 2
Add-VMHardDiskDrive -VMName $Name -ControllerType SCSI -Path $VHDPath
#Add-VMHardDiskDrive -VMName $Name -ControllerType IDE -Path $VHDPath

#Set first boot device to the disk we attached
$Drive=Get-VMHardDiskDrive -VMName $Name | where {$_.Path -eq "$VHDPath"}
# GEN2
Get-VMFirmware -VMName $Name | Set-VMFirmware -FirstBootDevice $Drive
 
#Prepare the unattend.xml file to send out, simply copy to a new file and replace values
Copy-Item $UnattendLocation $StartupFolder\"unattend_"$Name".xml"
$DefaultXML=$StartupFolder+ "\unattend_$Name.xml"
$NewXML=$StartupFolder + "\unattend_$Name.xml"
$DefaultXML=Get-Content $DefaultXML
$DefaultXML  | Foreach-Object {
 $_ -replace '1AdminAccount', $AdminAccount `
 -replace '1Organization', $Organization `
 -replace '1Name', $Name `
 -replace '1ProductID', $ProductID`
 -replace '1MacAddressDomain',$MACAddress `
 -replace '1DefaultGW', $DefaultGW `
 -replace '1DNSServer', $DNSServer `
 -replace '1DNSDomain', $DNSDomain `
 -replace '1AdminPassword', $AdminPassword `
 -replace '1IPDomain', $IPDomain `
 } | Set-Content $NewXML
 
#Mount the new virtual machine VHD
mount-vhd -Path $VHDPath

#Find the drive letter of the mounted VHD
$VolumeDriveLetter=GET-DISKIMAGE $VHDPath | GET-DISK | GET-PARTITION |get-volume |?{$_.FileSystemLabel -ne "Recovery"}|select DriveLetter -ExpandProperty DriveLetter

#Construct the drive letter of the mounted VHD Drive
# Om 2 partitioner så hamnar partitionen oftast på F:
$DriveLetter="F:" #"$VolumeDriveLetter"+":"
#Copy the unattend.xml to the drive
Copy-Item $NewXML $DriveLetter\unattend.xml
#Dismount the VHD
Dismount-Vhd -Path $VHDPath

#Fixa boot order GEN2
#$old_boot_order = Get-VMFirmware -VMName $name -ComputerName . | Select-Object -ExpandProperty BootOrder
#$new_boot_order = $old_boot_order | Where-Object { $_.BootType -ne "Network" }
#Set-VMFirmware -VMName $name -ComputerName . -BootOrder $new_boot_order

#Fire up the VM
Start-VM $Name
#Part 2 Complete---------------------------------------------------------------------#


