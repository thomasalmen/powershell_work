# Skapa mapp för maskin och HD
# Kopiera dit VHD
# Kopiera in moffar till VHD'n
# skapa maskiner och attacha VHD
# - maskiner ska ha default switch först och sen moddas till rätt switch

# Skapa mapp där alla moffar och tempfiler förvaras.
<#
    $outpath="$env:temp\DSC_INSTALL"
    New-Item $outpath -ItemType Directory -Force
    cd $outpath

    @("xWebAdministration","NetworkingDsc","Xactivedirectory","xHyper-V") | % {
        Find-Module $_ -repository PsGallery -Verbose | Install-Module -force -Verbose | Save-Module $_ -Path $outpath\DSC_Downloaded_Modules\$_ -Force -Verbose -repository PsGallery
    }
#>

Configuration HyperV_VMS
{
    param
    (
        [string[]]$NodeName = 'localhost',

        #Var finns VHD-filen med windows grundinstallation?
        [string]$OriginalVHD = 'c:\virtuella maskiner\HDS\win2016.vhdx',

        #[Parameter(Mandatory)]
        [string[]]$VMNames = @("SUNE"),

        [parameter(mandatory=$false)]
        [string]$VMpath = "c:\virtuella maskiner",

        # Bra om det går att använda default switch så att maskinerna kommer ut på internet
        #[Parameter(Mandatory)]
        [string[]]$SwitchName = "Default Switch",

        #[Parameter(Mandatory)]
        #[validatescript({Test-Path $_})]
        $MofToCopy = "C:\Users\thalm\Desktop\Presentation.docx"
        
        #[Parameter()]
        #[string[]]$MACAddress
    )

    Import-DscResource -module xHyper-V,PSDesiredStateConfiguration

    Node $NodeName
    {

        foreach ($vmName in $VMNames)
        {

            <# Skapar mapp för maskin o disk, samt kopierar ut originaldisk med windows i samma veva
            file "$vmname-Dir" {
                SourcePath = $OriginalVHD
                DestinationPath = "$VMpath\$vmName\virtual hard disks\$VMName-OSDisk.vhdx"
                Type = 'File'
                Force = $true
                Ensure = "Present"
                #MatchSource = $true
            }
            #>
            
            Get-DscResource  xVhdFile -Syntax
            xVhdFile "$vmname-CopyUnattendxml"
            {
                VhdPath =  "$VMpath\$vmName\virtual hard disks\$VMName-OSDisk.vhdx"

                FileDirectory =  MSFT_xFileDirectory {
                    SourcePath = "C:\Users\thalm\Desktop\Presentation.docx"
                    DestinationPath = "CopiedFile"

                }
            }
            
            <# Ensures a VM with all the properties
            xVMHyperV "$vmName-NewVM"
            {
                Ensure     = 'Present'
                Name       = $VMName
                VhdPath    = "$vmpath\$vmname\virtual hard disks\$VMName-OSDisk.vhdx"
                SwitchName = $switchname
                #MACAddress = 
                State           = "Off"
                Path            = $Path
                Generation      = 1
                StartupMemory   = 512MB 
                MinimumMemory   = 512MB
                MaximumMemory   = 512MB
                ProcessorCount  = 1
                #MACAddress      = 
                RestartIfNeeded = $false
                WaitForIP       = $false
                AutomaticCheckpointsEnabled = $true
                DependsOn  = "[file]$vmname-Dir"
            }
            #>
        }
    }
}

HyperV_VMS -OutputPath $outpath\HyperV_VMS
#Start-DscConfiguration -Path $outpath\HyperV_VMS -Wait -Verbose -Force


