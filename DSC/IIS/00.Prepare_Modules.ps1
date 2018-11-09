<#

    Tankar ner och installerar moduler som behövs till DSC-Konfen
    Laddar först ner och installerar dem lokalt.
    Kopierar sen till respektive maskin och importerar dem där.

#>

$creds = get-credential administrator
$VerbosePreference="Silentlycontinue"

$computers="S1","S2"
$requiredDSCModules=@(
    @{"ModuleName" = "xWebAdministration";"Version"=""}
    @{"ModuleName" = "NetworkingDsc";"Version"=""}
)
$requiredDSCModules.ForEach({
    $localmodule = Find-Module -repository psgallery $($_.ModuleName)
    $localmodule | install-module #Installerar modulen lokalt
    $localmodule | Save-Module $($_.ModuleName) -Path $env:temp\DSC_IIS_Modules\ -Force
})

$requiredPackageManagers=@(
    "Nuget"
)
$requiredPackageManagers.ForEach({
    # Installerar nuget package manager lokalt
    $nugetinstall = Install-PackageProvider -Name $_ -Force -scope AllUsers
    $nugetpath = (Get-PackageProvider -Name $nugetinstall.Name).ProviderPath 
    $nugetpath = Split-Path $nugetpath
})

$computers.ForEach({
    $sess = new-pssession $_ -Credential $creds 
    $requiredDSCModules.ForEach({
       #"Kopierar och importerar $($_.modulename)  "
       Copy-Item $env:temp\DSC_IIS_Modules\$($_.ModuleName)\ -ToSession $sess  -Destination "C:\Program Files\WindowsPowerShell\Modules" -Recurse -Force
       Invoke-Command -Session $sess { import-module $using:_.ModuleName }
    })
    #"Kopierar och importerar $($nugetinstall.name)  "
    copy-item $nugetpath -tosession $sess -destination $nugetpath -recurse -force
    invoke-command -session $sess { Import-PackageProvider -Name $($using:nugetinstall.name) -Force}
    remove-pssession $sess
})
