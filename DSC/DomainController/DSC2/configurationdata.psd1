@{
	AllNodes = @(

        @{
            # NodeName "*" = apply this properties to all nodes that are members of AllNodes array.
            Nodename                    = "*"
            # Name of the remote domain. If no parent name is specified, this is the fully qualified domain name for the first domain in the forest.
            DomainName                  = "THOMAS.SE"
            # Maximum number of retries to check for the domain's existence.
            RetryCount                  = 20
            # Interval to check for the domain's existence.
            RetryIntervalSec            = 30
            # The path to the .cer file containing the public key of the Encryption Certificate used to encrypt credentials for this node.
            CertificateFile             = "$env:TEMP\DscPublicKey.cer"
            # The thumbprint of the Encryption Certificate used to decrypt the credentials on target node.
            Thumbprint                  = "ABD4777128C3AE137052529D117E504B1A1BE127"
        },

		@{
			NodeName = 's1'
            Purpose = 'Domain Controller'
            WindowsFeatures = 'AD-Domain-Services'
        }
    )
    NonNodeData = @{
        DomainName = 'thomas.se'
        AdGroups = 'Accounting','Information Systems','Executive Office','Janitorial Services'
        OrganizationalUnits = 'Accounting','Information Systems','Executive Office','Janitorial Services'
        AdUsers = @(
            @{
                FirstName = 'Katie'
                LastName = 'Green'
                Department = 'Accounting'
                Title = 'Manager of Accounting'
            }
            @{
                FirstName = 'Joe'
                LastName = 'Blow'
                Department = 'Information Systems'
                Title = 'System Administrator'
            }
            @{
                FirstName = 'Joe'
                LastName = 'Schmoe'
                Department = 'Information Systems'
                Title = 'Software Developer'
            }
            @{
                FirstName = 'Barack'
                LastName = 'Obama'
                Department = 'Executive Office'
                Title = 'CEO'
            }
            @{
                FirstName = 'Donald'
                LastName = 'Trump'
                Department = 'Janitorial Services'
                Title = 'Custodian'
            }
        )
    }
}