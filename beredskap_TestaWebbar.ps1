if($PSVersionTable.PSVersion.Major -lt 5 ){Write-Host "Detta script kräver Powershell version 5 eller senare!"}

cls
$portsToTestForCertificates=@(22,443,8443)

$system=[ordered]@{

    "www.regionorebrolan.se" = [ordered]@{

        #"DEAD_WebServices" = [ordered]@{
        #    "DEAD" = @(1433)
        #};


        "WebServers" = [ordered]@{
            "www.orebroll.se" = @(80,443)
            "www.ojebjoll.se" = @(80,443)
        #    "www.regionorebrolan.se" = @(80,443)
            "webext01a" = @(80,808)
        #    "webext01b" = @(80,808)
        #    "www-noda.orebroll.se" = @(80,443)
        #    "www-nodb.orebroll.se" = @(80,443)
        #    "filin.orebroll.se" = @(21,22)
        };

        #"Databases" = [ordered]@{
        #    "HOMER" = @(1433,3389)
        #};

        #"WebServices" = [ordered]@{
        #    "DEAD" = @(1433)
        #    "WS2" = @(1433)
        #    "WS3" = @(1433)
        #};
    };
    
    #"www.kurt.se" = @{}
    #"www.sune.se" = @{}
    #"www.berit.se" = @{}
}
$Rapport = @()

#Plocka ut systemets namn
$system.GetEnumerator() | % {

    # Skapar ett objekt att lagra meddelanden i 
    

    "Behandlar system '$($_.key)' *"

    #Plocka ut serverobjekten, ex webserver el databas.
    $_.value.GetEnumerator() | % {
$statusMess = ($statusMess = " " | Select-Object Server, Test, Port, Resultat, Diagnos)    
$statusMess.Resultat = " Första loopen"

        "`nTestar objekt i '$($_.key)'"
        
        #Plocka ut värdena server och port ur objektet
        # Först server
        $server=$_
        $server.value.GetEnumerator() | % {
#$statusMess += ($statusMess = " " | Select-Object Server, Test, Port, Resultat, Diagnos)
            $serverNamn = $_.key
            "`nGenomför test av '$($servernamn)'"

            $statusmess.Server = $serverNamn
            $statusmess.Test = "DNS"
            $statusmess.Port = "n/a"            

            # Fråga DNS #
            try
            {
                $dnsname = [system.Net.Dns]::GetHostByName($ServerNamn) 
                $statusmess.Resultat = $dnsname.addresslist.IPAddressToString
                $statusMess.Diagnos = "[OK]"
                $dnsname=$dnsname.addresslist.IPAddressToString
            }
            catch [Exception]
            {
                $statusmess.Resultat = "'$($ServerNamn)' not found in DNS"
                $statusMess.Diagnos = "[FAIL]"
                $dnsname=$ServerNamn
            }


            
            

            ###############
            #Slut Fråga DNS
            ###############

            # Start ping #
            <#
            try{
                $pingtest=Test-Connection -ComputerName $dnsname -ErrorAction stop -ErrorVariable e -Verbose #-quiet
                if($pingtest.IPV4Address.IPAddressToString -ne $null)
                {
                    #Write-Verbose "ping $($dnsname) `t[OK]"
                    #Write-Host "Ping [OK]"
                }
            }
            catch [exception]
            {
                #write-warning "Server '$($dnsname)' does not respond to ping"
            }
            # Slut ping #
            #>

            #Plocka ut porten
            <#
            $tempport = $_
            $tempport.value.GetEnumerator() | % {
                $port=$_

                # connecta till server:port *
                try 
                {
                    $TcpClient = new-object "System.Net.Sockets.TcpClient" -ErrorAction Stop
                    $TcpClient.Connect($serverNamn, $port)
                    if($TcpClient.Connected -eq $true)
                    {
                        write-host "TcpConnect $($servernamn):$($port) `t[OK]"
                        #Jämför portar här
                        if( $port -eq 443)
                        {
                            ChkCert -ip $servernamn -Port $port
                        }
                        # port 80 = kolla om det finns en webserver som svarar.
                        if( $port -eq 80) 
                        {
                            try{
                                $websajt=Invoke-WebRequest $serverNamn -Headers ${"GET"="/";"HTTP"="/1.1";"Connection"="Close";"HOST"="$($servernamn)"} -Method Get -ErrorAction SilentlyContinue -UseBasicParsing -MaximumRedirection 0
                                "`tWebserver svarar $($servernamn):$($port) '" + $websajt.StatusCode + " " + $WEBSAJT.StatusDescription + "'" 
                            }
                            catch [Exception]
                            {
                                "`tNo HTTP response from $($servernamn):$($port)"
                            }
                        }
                    }
                }
                catch 
                {
                    Write-warning "$($servernamn) svarar inte på port $port"
                    #Write-Debug $_
                }

                #######################
                # Slut Testa port-connection
                #######################
                #tcpjox -servernamn $server -port $port
            }
            #>
            
            #"Avslutar test av '$($_.key)'"
        
         
        }
    }

   # "Avslutar test av system '$($_.key)' *"
  # $i
    #$Rapport | ft -AutoSize
              $Rapport+=$statusmess
}
$Rapport

function tcpjox()
{
param(
[parameter(Mandatory=$false)][string]$servernamn,
[Parameter(Mandatory=$false)][string]$port
)
#write-host "TcpConnect --> $($servernamn):$($port) `t[OK]"

        $TcpClient = new-object "System.Net.Sockets.TcpClient" -ErrorAction Stop -ErrorVariable e
        try 
        {
            $TcpClient.Connect( "www.regionorebrolan.se", 443)
            if($TcpClient.Connected -eq $true)
            {
                write-host "TcpConnect --> $($servernamn):$($port) `t[OK]"
                if( $port -eq 443)
                {
                    ChkCert -ip $servernamn -Port $port
                }
                if( $port -eq 80) 
                {
                    kollaWebserver
                }
            }
        }
        catch 
        {
            Write-warning "$($servernamn) svarar inte på port $port"
            #Write-Debug $_
        }


}




#CERT
#https://newspaint.wordpress.com/2017/04/05/checking-ssl-certificate-expiry-on-remote-server-using-powershell/
#PING CLASS
#https://msdn.microsoft.com/en-us/library/system.net.networkinformation.ping(v=vs.110).aspx

# Script som ska köras för att testa att servrar, noder, bigip och databas fungerar inifrån orebroll.
#Write-Host "Detta script testar åtkomst till www och dess servermiljöer inifrån."


function ChkCert
{
    Param ([string]$ip="kraschobang",[int]$Port=80)

    $CertInfo = [Ordered]@{}

    $TCPClient = New-Object -TypeName System.Net.Sockets.TCPClient
    try
    {
        $TcpSocket = New-Object Net.Sockets.TcpClient($ip,$port)

        $tcpstream = $TcpSocket.GetStream()
        $Callback = {param($sender,$cert,$chain,$errors) return $true}
        $SSLStream = New-Object -TypeName System.Net.Security.SSLStream -ArgumentList @($tcpstream, $True, $Callback)
        try
        {
        $SSLStream.AuthenticateAsClient($IP)
        $Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($SSLStream.RemoteCertificate)
                
        $CertInfo["KeyLength"] = $Certificate.PublicKey.Key.KeySize
        $CertInfo["SignatureAlgorithm"] = $Certificate.SignatureAlgorithm.FriendlyName
        $certinfo["NotAfter"] = $certificate.NotAfter
        $certinfo["Certificate"] = $Certificate
        }
        finally
        {
        $SSLStream.Dispose()
        }
    }
    finally
    {
        $TCPClient.Dispose()
    }
    if($CertInfo.count -ne $null)
    {
    #return [PSCustomObject]$certinfo
    return "HITTADE " + $CertInfo.certificate.subject
    #return $Certificate
    }
}
#ChkCert
