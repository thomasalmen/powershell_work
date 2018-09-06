﻿# Configuration data file (ConfigurationData.psd1).

@{
    AllNodes = 
    @(
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
            Thumbprint                  = "A90242C09B766D92E17983DF936CACB2C9E31BB0"
        },

        @{
            Nodename = "s1"
            Role = "DC01"
        }
        #,
        #@{
        #    Nodename = "192.168.1.3"
        #    Role = "DC02"
        #}
    )
}