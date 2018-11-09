Configuration Configuration_IIS_Files
{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PsCredential] $ShareCreds
     )

    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module xWebAdministration -ModuleVersion 2.3.0.0
    Import-DscResource -Module NetworkingDsc

    Node $AllNodes.where{$_.Role -eq 'httpweb'}.NodeName 
    {
        LocalConfigurationManager
        {
            CertificateId = $node.Thumbprint
        }

        #Skapa sajtroot och KOPIERA FILER  - Kräver access från switchen VM står i mot localhost
        File "StartPage"
        {
            #Måste ha credentials eftersom DSC körs som system och därmed inte har rätt att läsa shaeres.
            #Alternativt lägg till computername$ om det är domän
            Credential = $ShareCreds# (Get-Credential -Message "Ange lösen för share $($node.sourcepath)")
            Ensure = "Present"
            Type = 'Directory'
            Recurse = $true # Ensure presence of subdirectories, too
            SourcePath = $node.sourcepath
            DestinationPath = $node.WebsajtRoot
            Force = $true
            MatchSource = $true
        }
    }
}
$params=@{
    OutputPath="$env:TEMP\DSC_IIS\WebsajtFiles"
    ShareCreds = (Get-Credential -UserName "$env:USERDOMAIN\$env:USERNAME" -Message "Enter credentials for configuration")
    ConfigurationData = "C:\Users\thalm\OneDrive\powershell_work\DSC\IIS\IIS_ConfigurationData.psd1"
}
Configuration_IIS_Files @params

<#

[string[]]$computers="S1","S2"
$Session = New-CimSession -ComputerName $computers -Credential (get-credential administrator)

Set-DscLocalConfigurationManager "$env:TEMP\DSC_IIS\WebsajtFiles" -Verbose -CimSession $session
Start-DscConfiguration -Path "$env:TEMP\DSC_IIS\WebsajtFiles" -Wait -Verbose -Force -CimSession $Session

#>