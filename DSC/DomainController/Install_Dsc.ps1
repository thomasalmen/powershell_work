# DSC Configuration Script (HADC.ps1)
# Install and configure Highly Available Domain Controllers in a new forest.
Configuration HADC
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
            RebootNodeIfNeeded = $false
            # The thumbprint of a certificate used to secure credentials passed in a configuration.
            CertificateId = $node.Thumbprint
        }

        # Install Windows Feature "Active Directory Domain Services".
        WindowsFeature ADDSInstall
        {
            Ensure = "present"
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
            DomainAdministratorCredential = $DomainAdministratorCred
            UserName                      = "Test.User"
            Password                      = $ADUserCred
            Ensure                        = "present"
            DependsOn                     = "[xWaitForADDomain]DomainWait"
        }
    }

    Node $AllNodes.Where{$_.Role -eq "DC02"}.Nodename
    {
        # Configure LCM to allow Windows to automatically reboot if needed. Note: NOT recommended for production!
        LocalConfigurationManager
        {
		    # Set this to $true to automatically reboot the node after a configuration that requires reboot is applied. Otherwise, you will have to manually reboot the node for any configuration that requires it. The default (recommended for PRODUCTION servers) value is $false.
            RebootNodeIfNeeded = $false
		    # The thumbprint of a certificate used to secure credentials passed in a configuration.
            CertificateId = $node.Thumbprint
        }

        # Install Windows Feature AD Domain Services.
        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name   = "AD-Domain-Services"
        }

        # Ensure that the Active Directory Domain Services feature is installed.
        xWaitForADDomain DomainWait
        {
            DomainName           = $Node.DomainName
            DomainUserCredential = $DomainAdministratorCred
            RetryCount           = $Node.RetryCount
            RetryIntervalSec     = $Node.RetryIntervalSec
            DependsOn            = "[WindowsFeature]ADDSInstall"
        }

        # Ensure that the AD Domain is present before the second domain controller is added.
        xADDomainController SecondDC
        {
            DomainName                    = $Node.DomainName
            DomainAdministratorCredential = $DomainAdministratorCred
            SafemodeAdministratorPassword = $SafemodeAdministratorCred
            DependsOn                     = "[xWaitForADDomain]DomainWait"
        }
    }
}

#Testlösen: ABC.123/abc.123
HADC -ConfigurationData .\ConfigurationData.psd1 `
    -SafemodeAdministratorCred (Get-Credential -UserName Administrator -Message "Enter Domain Safe Mode Administrator Password") `
    -DomainAdministratorCred (Get-Credential -UserName thomas.se\administrator -Message "Enter Domain Administrator Credential") `
    -ADUserCred (Get-Credential -UserName Test.User -Message "Enter AD User Credential")

# Make sure that LCM is set to continue configuration after reboot.
Set-DSCLocalConfigurationManager -Path .\HADC –Verbose -Credential s1\administrator

Start-DscConfiguration -Path ".\HADC" -Wait -Verbose -force -Credential administrator