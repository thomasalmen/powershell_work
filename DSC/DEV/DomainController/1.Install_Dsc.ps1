<#

#Om servern inte har internet (ex hyper-v internal) så måste modulen sparas lokalt och sen kopieras till servern.
$requiredDSCModules=@("xActiveDirectory","NuGet")

$requiredDSCModules.foreach({
    #Find-Module $_ | 
    Save-Module $_ -Path $env:temp\$_ -Force -Verbose
})
$creds = get-credential administrator
"DC" | % {
    $tempsess = new-pssession $_ -Credential $creds
    $requiredDSCModules.ForEach({
       Copy-Item $env:temp\$_\$_ -ToSession $tempsess  -Destination "C:\Program Files\WindowsPowerShell\Modules" -Recurse -Force -Verbose
       Invoke-Command -Session $tempsess { Install-Module $using:_ -Force -verbose }
    })
}
#>
# Om allt misslyckas så går det att avinstallera DCn: Uninstall-ADDSDomainController -IgnoreLastDCInDomainMismatch -Force -IgnoreLastDnsServerForZone -RemoveApplicationPartitions

# Configuration data file (ConfigurationData.psd1).

$configurationdata=@{
    AllNodes = 
    @(
        @{
            # NodeName "*" = apply this properties to all nodes that are members of AllNodes array.
            Nodename = "*"

            # Name of the remote domain. If no parent name is specified, this is the fully qualified domain name for the first domain in the forest.
            DomainName = "supercow.se"

            # Maximum number of retries to check for the domain's existence.
            RetryCount = 20

            # Interval to check for the domain's existence.
            RetryIntervalSec = 30

            # The path to the .cer file containing the public key of the Encryption Certificate used to encrypt credentials for this node.
            CertificateFile = "$env:TEMP\DscPublicKey.cer"

            # The thumbprint of the Encryption Certificate used to decrypt the credentials on target node.
            Thumbprint = "A6C4D4CB47D7430FDC01F262A995F8FDA76E0D4B"
        },

        @{
            Nodename = "DC"
            Role = "DC01"
        }
    )
}


Configuration SkapaDC
{
    param
    (
        [Parameter(Mandatory)] 
        [pscredential]$SafemodeAdministratorCred, 

        [Parameter(Mandatory)] 
        [pscredential]$DomainAdministratorCred, 

        [Parameter(Mandatory)] 
        [pscredential]$ADUserCred
    )

    # Import DSC Resources
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $AllNodes.Where{$_.Role -eq "DC01"}.Nodename
    {
        LocalConfigurationManager
        {
            # Går att ha satt till $true men enbart för testmiljö
            RebootNodeIfNeeded = $true
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyAndAutoCorrect'
            # The thumbprint of a certificate used to secure credentials passed in a configuration.
            CertificateId = $node.Thumbprint
        }

        # Install Windows Feature "Active Directory Domain Services".
        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name   = "AD-Domain-Services"
        }
        WindowsFeature InstallTools
        {
            name = "RSAT-ADDS"
            ensure='Present'
        }
        # Create AD Domain specified in HADCServerConfigData.
        xADDomain FirstDC
        {
            # Name of the remote domain. If no parent name is specified, this is the fully qualified domain name for the first domain in the forest.
            DomainName                    = $Node.DomainName
            # Credentials used to query for domain existence.
            DomainAdministratorCredential = $DomainAdministratorCred
            # Password for the administrator account when the computer is started in Safe Mode.
            SafemodeAdministratorPassword = $SafemodeAdministratorCred
            # Specifies the fully qualified, non-Universal Naming Convention (UNC) path to a directory on a fixed disk of the local computer that contains the domain database (optional).
            DatabasePath                  = "C:\NTDS"
            # Specifies the fully qualified, non-UNC path to a directory on a fixed disk of the local computer where the log file for this operation will be written (optional).
            LogPath                       = "C:\NTDS"
            # Specifies the fully qualified, non-UNC path to a directory on a fixed disk of the local computer where the Sysvol file will be written. (optional)
            SysvolPath                    = "C:\SYSVOL"
            # DependsOn specifies which resources depend on other resources, and the LCM ensures that they are applied in the correct order, regardless of the order in which resource instances are defined.
            DependsOn                     = "[WindowsFeature]ADDSInstall"
        }

        # Wait until AD Domain is created.
        xWaitForADDomain DomainWait
        {
            DomainName           = $Node.DomainName
            DomainUserCredential = $DomainAdministratorCred
            # Maximum number of retries to check for the domain's existence.
            RetryCount           = $Node.RetryCount
            # Interval to check for the domain's existence.
            RetryIntervalSec     = $Node.RetryIntervalSec
            DependsOn            = "[xADDomain]FirstDC"
        }

        # Enable Recycle Bin.
        xADRecycleBin RecycleBin
        {
            # Credential with Enterprise Administrator rights to the forest.
            EnterpriseAdministratorCredential = $DomainAdministratorCred
            # Fully qualified domain name of forest to enable Active Directory Recycle Bin.
            ForestFQDN                        = $Node.DomainName
            DependsOn                         = "[xWaitForADDomain]DomainWait"
        }
        
        # Create AD User "Test.User".
        xADUser ADUser
        {
            DomainName                    = $Node.DomainName
            UserName                      = "Test.User"
            Ensure = 'Present'
            Password                      = $ADUserCred
            #DomainAdministratorCredential = $DomainAdministratorCred
            #DependsOn                     = "[xWaitForADDomain]DomainWait"
        }
    }
}

#Testlösen: ABC.123/abc.123
$PW = ConvertTo-SecureString -String "ABC.123/abc.123" -AsPlainText -Force

SkapaDC -ConfigurationData $configurationdata `
    -SafemodeAdministratorCred (New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList "administrator", $PW) `
    -DomainAdministratorCred (New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList "supercow.se\administrator", $PW) `
    -ADUserCred (New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList "supercow\test.user", $PW) -OutputPath "$env:temp\SkapaDC"
    
# Make sure that LCM is set to continue configuration after reboot.
<#

Set-DSCLocalConfigurationManager -Path "$env:temp\SkapaDC" -Credential administrator -Force -verbose
Start-DscConfiguration -Path "$env:temp\SkapaDC" -Wait -Verbose -force -Credential administrator 

#>
