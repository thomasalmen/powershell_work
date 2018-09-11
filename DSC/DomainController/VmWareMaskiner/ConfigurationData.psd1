# Configuration data file (ConfigurationData.psd1).

@{
    AllNodes = 
    @(

        @{
            PSDscAllowPlainTextPassword = $false;
            #PSDscAllowDomainUser = $true

            # NodeName "*" = apply this properties to all nodes that are members of AllNodes array.
            Nodename                    = "*"
            # Name of the remote domain. If no parent name is specified, this is the fully qualified domain name for the first domain in the forest.
            DomainName                  = "SUPERCOW.SE"
            # Maximum number of retries to check for the domain's existence.
            RetryCount                  = 20
            # Interval to check for the domain's existence.
            RetryIntervalSec            = 30
            # The path to the .cer file containing the public key of the Encryption Certificate used to encrypt credentials for this node.
            CertificateFile             = "$env:TEMP\DscPublicKey.cer"
            # The thumbprint of the Encryption Certificate used to decrypt the credentials on target node.
            Thumbprint                  = "5521B8F50C2236C80D66DF148E6F0A4F7151AEB4"
        },

        @{
            Nodename = "DC"
            Role = "DC01"
        }
        ,
       @{
            NodeName = @('S1','S2')
            Role = @('Web')
            #SourcePath = '\\client\WebSiteForDemo' # Content Source Location
            DestinationPath = 'd:\WebSites' # Content Destination Location
            WebAppPoolName = 'AppPool' # Name of the Application Pool to create
            WebSiteName = 'supercow.se' # Name of the website to create - this will also be hostname for DNS
            DomainName = 'supercow.se' # Remaining Domain name for Host Header i.e. Company.com and DNS
            DNSIPAddress = '*' # IP Address for DNS of the Website

        }
      #@{
      #      NodeName = 'S2'
      #      Role = @('Web')
      #      #SourcePath = '\\client\WebSiteForDemo' # Content Source Location
      #      DestinationPath = 'd:\WebSites' # Content Destination Location
      #      WebAppPoolName = 'AppPool' # Name of the Application Pool to create
      #      WebSiteName = 'supercow.se' # Name of the website to create - this will also be hostname for DNS
      #      DomainName = 'supercow.se' # Remaining Domain name for Host Header i.e. Company.com and DNS
      #  }

    )
}