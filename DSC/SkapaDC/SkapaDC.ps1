# Om allt misslyckas så går det eventuellt att avinstallera DCn: Uninstall-ADDSDomainController -IgnoreLastDCInDomainMismatch -Force -IgnoreLastDnsServerForZone -RemoveApplicationPartitions

# Configuration data file (ConfigurationData.psd1).

$configurationdata=@{
    AllNodes = 
    @(
        @{
            # NodeName "*" = apply this properties to all nodes that are members of AllNodes array.
            Nodename = "*"

            # Domännamn
            DomainName = "supercow.se"

            # Maximum number of retries to check for the domain's existence.
            RetryCount = 20

            # Interval to check for the domain's existence.
            RetryIntervalSec = 30

            # The path to the .cer file containing the public key of the Encryption Certificate used to encrypt credentials for this node.
            CertificateFile = "$(get-location)\DscPublicKey.cer"

            # The thumbprint of the Encryption Certificate used to decrypt the credentials on target node.
            Thumbprint = "AD6AED2F3421473AAD817D8A4458252609031BE5"
        
        },

        @{
            Nodename = "thomasdc"
            Role = "DC01"
            #Skapa vanlig user för test
            TestADUserName = "testuser"
            ADUserPassword = $node.TestADUserPassword

            #Variabler för skapandet av test-adgrupp (under users)
            ADGroupName = "TestGrupp"   
            ADGroupScope = "Global" #('DomainLocal','Global','Universal')]   
            ADGroupCatgory = "Security" #('Security','Distribution')]   
            ADGroupDescription = "Beskrivning av gruppen"

            #Variabler för OU 
            OUName = "Exempel OU"  
            OUPath = "dc=supercow,dc=se" 
            OUProtectedFromAccidentalDeletion = $true  
            OUDescription = "Ett test OU"

            #Variabler för passwordpolicy 
            PWPolicyComplexityEnabled = $true 
            PWPolicyMinPasswordLength = 8

            #Variabler för att skapa datorkonto 
            CreateComputerAccount_DomainController = $Node.NodeName  
            CreateComputerAccount_DomainAdministratorCredential = $DomainAdministratorCred  
            CreateComputerAccount_ComputerName = "thomasweb" #, "S1","S2"
            CreateComputerAccount_Path = "dc=supercow,dc=se"

            #Variabler för att skapa CA
            CA_enabled_featurenames=@("RSAT-ADCS","RSAT-ADCS-mgmt", "ADCS-Web-Enrollment","ADCS-Cert-Authority")

        },
        @{
            Nodename = "<DC_NUMMER_TVÅ>"
            Role = "Replica DC"
        }
    )

        # Globala features = Inte nodspecifika
        IIS_enabled_featurenames=@("Web-Mgmt-Tools","Web-Mgmt-Console","Web-Server","Web-WebServer", "Web-Common-Http", "Web-Default-Doc", "Web-Dir-Browsing", "Web-Http-Errors","Web-Static-Content","Web-Http-Redirect","Web-Health", "Web-Http-Logging","Web-Log-Libraries","Web-Request-Monitor", "Web-Http-Tracing","Web-Performance","Web-Stat-Compression","Web-Security", "Web-Filtering","Web-Basic-Auth","Web-Windows-Auth","Web-App-Dev", "Web-ISAPI-Ext", "Web-Mgmt-Compat", "Web-Metabase","Web-WHC","Web-Net-Ext", "Web-Net-Ext45", "Web-ASP", "Web-Asp-Net", "Web-Asp-Net45")

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
        [pscredential]$DNSDelegationCred,

        [Parameter(Mandatory)] 
        [pscredential]$TestADUserPassword

    )

    # Import DSC Resources
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -Module ActiveDirectoryCSDsc
    Import-DscResource -Module xWebAdministration

    Node $AllNodes.Where{$_.Role -eq "DC01"}.Nodename
    {

        # LCM
        # 
        LocalConfigurationManager
        {
            # Går att ha satt till $true men enbart för testmiljö
            RebootNodeIfNeeded = $true
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyAndAutoCorrect'
            # The thumbprint of a certificate used to secure credentials passed in a configuration.
            CertificateId = $node.Thumbprint
        }


        #
        # Installera Windows Feature "Active Directory Domain Services".
        #
        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name   = "AD-Domain-Services"
        }

        #
        # Installera RSAT - för guiadmin
        #
        WindowsFeature InstallTools
        {
            name = "RSAT-ADDS"
            ensure='Present'
        }

        #
        # Skapa AD-domänen som specifierat i configurationdata
        #
        xADDomain FirstDC
        {
            DomainName = $Node.DomainName
            DomainAdministratorCredential = $DomainAdministratorCred
            SafemodeAdministratorPassword = $SafemodeAdministratorCred
            #DnsDelegationCredential = $DNSDelegationCred
            DependsOn = "[WindowsFeature]ADDSInstall"

        }

        #
        # Vänta tills domänen skapats
        #
        xWaitForADDomain DomainWait
        {
            DomainName = $Node.DomainName
            DomainUserCredential = $DomainAdministratorCred
            RetryCount = $Node.RetryCount
            RetryIntervalSec = $Node.RetryIntervalSec
            DependsOn = "[xADDomain]FirstDC"
        }

        #
        # Enabla Recycle Bin.
        #
        xADRecycleBin RecycleBin
        {
            # Credential with Enterprise Administrator rights to the forest.
            EnterpriseAdministratorCredential = $DomainAdministratorCred
            # Fully qualified domain name of forest to enable Active Directory Recycle Bin.
            ForestFQDN = $Node.DomainName
            DependsOn = "[xWaitForADDomain]DomainWait"
        }
        
        
        #
        #Skapa exempelgrupp
        #
        #xADGroup ExampleGroup
        #{
        #    GroupName = $Node.ADGroupName
        #    GroupScope = $Node.ADGroupScope
        #    Category = $Node.ADGroupCatgory
        #    Description = $Node.ADGroupDescription
        #    Ensure = 'Present'
        #}

        #
        #Skapa test-ou
        #
        #xADOrganizationalUnit ExampleOU 
        #{
        #    Name = $Node.OUName      
        #    Path = $Node.OUPath   
        #    ProtectedFromAccidentalDeletion = $Node.OUProtectedFromAccidentalDeletion   
        #    Description = $Node.OUDescription
        #    Ensure = 'Present'
        #}

        #
        #Password policy  
        #
        xADDomainDefaultPasswordPolicy 'DefaultPasswordPolicy'     
        {
            DomainName = $Node.DomainName       
            ComplexityEnabled = $Node.PWPolicyComplexityEnabled   
            MinPasswordLength = $Node.PWPolicyMinPasswordLength       
        }
           

        #
        # Skapa AD Test-User "TestUser".
        #
        xADUser SkapaTestUser
        {
            #skapar en testuser
            DomainName = $Node.DomainName
            
            #DomainAdministratorCredential is only required if not executing the task on a domain controller or using the -DomainController parameter
            #DomainAdministratorCredential = $DomainAdministratorCred 
            UserName = $Node.TestADUserName
            Password = $TestADUserPassword
            Ensure = "Present"
            DependsOn = "[xWaitForADDomain]DomainWait"
            #Denna behövs pga att vi samtidigt installerar CA-Rollen
            PasswordAuthentication = 'Negotiate'
            
        }
        xADUser SkapaBigIpServiceAccount
        {
            #skapar ett servicekonto för bigip 
            DomainName = $Node.DomainName
            
            #DomainAdministratorCredential is only required if not executing the task on a domain controller or using the -DomainController parameter
            #DomainAdministratorCredential = $DomainAdministratorCred 
            UserName = "svc_bigip"
            Password = $TestADUserPassword
            Ensure = "Present"
            DependsOn = "[xWaitForADDomain]DomainWait"
            #Denna behövs pga att vi samtidigt installerar CA-Rollen
            PasswordAuthentication = 'Negotiate'
            #Path = "CN=svc_bigip,CN=Managed Service Accounts,DC=supercow,DC=se"
            
        }

        #                                                     
        #Skapa datorkonto
        #
        $Node.CreateComputerAccount_ComputerName | % {
            xADComputer "$_"      
            {        
                DomainController = $Node.CreateComputerAccount_DomainController      
                DomainAdministratorCredential = $Node.CreateComputerAccount_DomainAdministratorCredential 
                ComputerName = $_ # $Node.CreateComputerAccount_ComputerName         
                Path = $Path  
            }  
        }

        ############################################
        #Installera CA
        # Enbart via powershell och CA PowerShell module
        # Get-Command -Module AdcsAdministration
        # Add-WindowsFeature adcs-cert-authority
        # Install-AdcsCertificationAuthority -CAType EnterpriseRootCa -CryptoProviderName "ECDSA_P256#Microsoft Software Key Storage Provider" -KeyLength 256 -HashAlgorithmName SHA256
        # Management tools
        # Add-WindowsFeature RSAT-ADCS,RSAT-ADCS-mgmt, ADCS-Cert-Authority
        ############################################

        #IIS Installeras under ADCS-installationen, men inte alla features vi vill ha, ex mgmt-guit
        # Observera att default website måste finnas.
        # Om den inte finns så återskapa den.
        # Namn: "Default Website" Path c:\inetpub\wwwroot
        # Därefter kör "Certutil -v -vroot" så skapas certsrv upp
        $configurationdata.IIS_enabled_featurenames.ForEach({
            WindowsFeature $_ {
                Name = $_
                Ensure = 'Present'
            }
        }) #foreach

        #Säkerställ att default web site finns
        xWebsite DefaultSite
        {
            Ensure          = "Present"
            Name            = "Default Web Site"
            State           = "Started"
            PhysicalPath    = "C:\inetpub\wwwroot"
            DependsOn       = "[WindowsFeature]Web-WebServer"
        }

        # Nod-features som ska vara present
        $node.CA_enabled_featurenames.ForEach({
            WindowsFeature $_ {
                Name = $_
                Ensure = 'Present'
                DependsOn = '[WindowsFeature]Web-Server'
                
            }
        }) #foreach

        AdcsCertificationAuthority CertificateAuthority
        {
            IsSingleInstance = 'Yes'
            Ensure           = 'Present'
            Credential       = $DomainAdministratorCred
            CAType = 'EnterpriseRootCA'
            DependsOn        = '[WindowsFeature]ADCS-Cert-Authority'
            CACommonName = 'Supercow ROOT CA'
            CADistinguishedNameSuffix = $node.CreateComputerAccount_Path #'DC=supercow,DC=se'
            ValidityPeriod = 'Years'
            ValidityPeriodUnits = 10
            CryptoProviderName = "RSA#Microsoft Software Key Storage Provider"
            KeyLength = 2048
            HashAlgorithmName = "SHA256"
            DatabaseDirectory = "C:\Windows\system32\CertLog"
            LogDirectory = "C:\Windows\system32\CertLog"
            OverwriteExistingCAinDS = $true
            OverwriteExistingDatabase = $true
            OverwriteExistingKey = $true

        }

        AdcsWebEnrollment WebEnrollment
        {
            Ensure           = 'Present'
            IsSingleInstance = 'Yes'
            Credential       = $DomainAdministratorCred
            #IIS måste installeras före ADCS
            DependsOn        = @('[WindowsFeature]ADCS-Web-Enrollment', '[WindowsFeature]Web-Server') 
        }





    }
    <#
    Node $AllNodes.Where{$_.Role -eq "Replica DC"}.Nodename
    {
        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
        }
        xWaitForADDomain DscForestWait
        {
            DomainName = $Node.DomainName
            DomainUserCredential = $domainCred
            RetryCount = $Node.RetryCount
            RetryIntervalSec = $Node.RetryIntervalSec
            DependsOn = "[WindowsFeature]ADDSInstall"
        }
        xADDomainController SecondDC
        {
            DomainName = $Node.DomainName
            DomainAdministratorCredential = $domainCred
            SafemodeAdministratorPassword = $safemodeAdministratorCred
            DnsDelegationCredential = $DNSDelegationCred
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }
    }
    #>
}
$PW = ConvertTo-SecureString -String "P@ssw0rd" -AsPlainText -Force

SkapaDC -ConfigurationData $configurationdata `
    -SafemodeAdministratorCred (New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList "administrator", $PW) `
    -DomainAdministratorCred (New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList "administrator", $PW) `
    -DNSDelegationCred (New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList "administrator", $PW) `
    -TestADUserPassword (New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList "TestADUserName", $PW) `
    -OutputPath "$(get-location)\SkapaDC_MOF"

break

# LCM Först
Set-DSCLocalConfigurationManager -Path "$(get-location)\SkapaDC_MOF" -force -verbose #-Credential administrator
break

#Starta DSC
Start-DscConfiguration -Path "$(get-location)\SkapaDC_MOF" -Wait -Verbose -force #-Credential administrator 
break

get-dscconfigurationstatus
Get-DscLocalConfigurationManager
# remove-dscconfigurationdocument -Stage Current
#>
 
 