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
            Thumbprint = "EEE0629D3F72666C93D1367FDFF9F3BF0913B638"
        
        },

        @{
            Nodename = "thomasdc"
            Role = "DC01"
            #Skapa vanlig user
            ADUserName = "testuser"
            #ADUserPassword = 

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
            CreateComputerAccount_ComputerName = "S1","S2"
            CreateComputerAccount_Path = "dc=supercow,dc=se"

        },
        @{
            Nodename = "<DC_NUMMER_TVÅ>"
            Role = "Replica DC"
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
        [pscredential]$DNSDelegationCred,

        [Parameter(Mandatory)] 
        [pscredential]$ADUserPassword
    )

    # Import DSC Resources
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $AllNodes.Where{$_.Role -eq "DC01"}.Nodename
    {
        #
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
            DomainUserCredential = $domainCred
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
        # Skapa AD User "TestUser".
        #
        xADUser SkapaUser
        {
            DomainName = $Node.DomainName
            DomainAdministratorCredential = $domainCred
            UserName = $Node.ADUserName
            Password = $ADUserPassword
            Ensure = "Present"
            DependsOn = "[xWaitForADDomain]DomainWait"
        }

        #
        #Skapa exempelgrupp
        #
        xADGroup ExampleGroup
        {
            GroupName = $Node.ADGroupName
            GroupScope = $Node.ADGroupScope
            Category = $Node.ADGroupCatgory
            Description = $Node.ADGroupDescription
            Ensure = 'Present'
        }

        #
        #Skapa test-ou
        #
        xADOrganizationalUnit ExampleOU 
        {
            Name = $Node.OUName      
            Path = $Node.OUPath   
            ProtectedFromAccidentalDeletion = $Node.OUProtectedFromAccidentalDeletion   
            Description = $Node.OUDescription
            Ensure = 'Present'
        }

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
$PW = ConvertTo-SecureString -String "Password1!" -AsPlainText -Force

SkapaDC -ConfigurationData $configurationdata `
    -SafemodeAdministratorCred (New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList "administrator", $PW) `
    -DomainAdministratorCred (New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList "administrator", $PW) `
    -DNSDelegationCred (New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList "administrator", $PW) `    -ADUserPassword (New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList "testuser", $PW) `
    -OutputPath "$(get-location)\SkapaDC"

# LCM Först
# Set-DSCLocalConfigurationManager -Path "$(get-location)\SkapaDC" -Credential administrator -Force -verbose

#Starta DSC
# Start-DscConfiguration -Path "$(get-location)\SkapaDC" -Wait -Verbose -force -Credential administrator 

#remove-dscconfigurationdocument -Stage Current
#>
 
 
