
#Observera att denna inte är klar.
#TODO: Exportera nyckel + pinkod för pkcs12.

#Snodda rader för att kolla om user är administrator
if (-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    #Write-error "Du måste vara administratör för att exekvera detta script!"
    Throw "Du måste vara administratör för att exekvera detta script!"
    Pause
    break
}

$noNeedToCchangeTheseParameters = 'O=RegionService IT,OU=Region Orebro Lan,L=Orebro,S=Narke,C=SE'

function new-csr {

    param (
    [CmdletBinding()]
        [Parameter(Mandatory = $false)]
        [string]$CN,

        #[Parameter(Mandatory = $true, HelpMessage="Skriv in namnet på ditt cert, ex 'certifikat.orebroll.se'")]
        #[ValidateNotNullorEmpty()]
        #[string]$CN,

        [Parameter(Mandatory=$false)][string]$OutDir,
        [Parameter(Mandatory=$false)][switch]$OpenExplorer,
        #[switch]$VerifyWithOpenssl=$false,

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
        [string]$CAName="CA4.orebroll.se\Orebroll CA4"
        #[string]$CAName="CA2.orebroll.se\Orebroll CA2"

    )

    if($CN -eq "" )
    {
        Do
        { 
            $cn=Read-Host("Ange namn (CN) på certifikatet")
        } 
        Until($cn -ne '')
    }

    #Ta bort ev skräp-requests
    Remove-PendingRequestsFromCertStore -CN $CN

    if($OutDir -eq "")
    {
        $outdir = "$($env:TEMP)\$($CN)"
    }

    $InfFil = "$($OutDir)\$($CN).inf";
    $CSRFil = "$($OutDir)\$($CN).csr"

    #Kolla om outdir finns, annars skapa det.
    if(!(Test-Path $OutDir))
    {
        New-Item -Path $OutDir -ItemType Directory |Out-Null
    }

# settings.inf
#Funktionen get-san anropas inuti here-stringen med $(get-san)
$settingsFil = @"
[Version] 
Signature=`"`$Windows NT`$`"

[NewRequest] 
Subject = "CN=$CN,$($noNeedToCchangeTheseParameters)"
    
Exportable = TRUE 
HashAlgorithm = sha256
KeySpec = 1          ; Key Exchange - Required for encryption
KeyUsage = 0xA0      ; Digital Signature, Key Encipherment
KeyLength =  2048
MachineKeySet = TRUE 
;SMIME = FALSE
ProviderName = `"Microsoft RSA SChannel Cryptographic Provider`" 
ProviderType =  12
RequestType =  PKCS10 
    
;[EnhancedKeyUsageExtension]
;OID=1.3.6.1.5.5.7.3.1 ; Server Authentication
;OID=1.3.6.1.5.5.7.3.2 ; Client Authentication

[Extensions]
$(get-san)

[RequestAttributes]
CertificateTemplate="WebServer"
"@
    
    $settingsFil | Out-File -FilePath $InfFil -Encoding ascii

    Write-verbose "Detta är innehållet i inf-filen:`r`n $(Get-Content $InfFil)"

    certreq -new $InfFil $CSRFil | Out-Null
	if(!($LastExitCode -eq 0))
	{
		write-output "certreq -new fail!"
        break
	}   

    # Hämta tillbaka CSR från filen på disk
    Get-Content $CSRFil | clip
    Get-Clipboard
    write-Host "Din CSR finns nu på $CSRFIL samt kopierades till ditt clipboard (ctrl+v för att klistra in)"
    # Radera inf-filen som nu inte behövs längre
    
    Remove-Item $InfFil -Force

    $OpenExplorer = $true #Temp för testning
    if($OpenExplorer -eq $true)
    {
        start-process -FilePath $OutDir -WindowStyle Normal
    }

    if( (Read-Host ("Vill du skicka din request till CA? (j/n)")) -eq "j"  )
    {
        send-requestToCA
    }

    ## Verifera CSR med openssl.. Förutsätter att openssl finns installerat.
    #if($VerifyWithOpenssl -eq $true)
    #{
    #    openssl req -text -noout -verify -in $CSRFil
    #}

}

function get-san {

    # Fråga efter SAN-namn
    $SANnamn=[ordered]@{}
    $i=0
    Do{ 
        $i++
        if( ($santemp = read-host "Vill du ange extra SAN-namn $i (Enter=inget)") -ne '')
        {
            $SANnamn.add( $i, $santemp )
            
        }
    } 
    Until($santemp -eq '')

    # https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/ff625722(v=ws.10)
    $san = '2.5.29.17 = "{text}"' + "`r`n"
    $san += '_continue_ = "dns=' + $CN + '&"' + "`r`n"
    if ($SANnamn.Count -gt 0) {
  
        $SANnamn.Values | % {
            $san += '_continue_ = "dns=' + $_ + '&"' + "`r`n"
        }
    }
    return $san
}



function Remove-PendingRequestsFromCertStore()
{
	param(
		[String[]]$CN
	)
	    
	#Ta bort en skräp-pending requests
	$certstore = new-object system.security.cryptography.x509certificates.x509Store('REQUEST', 'LocalMachine')
	$certstore.Open('ReadWrite')
	foreach($certreq in $($certstore.Certificates))
	{
		if($certreq.Subject -match "CN=$CN")
		{
			$certstore.Remove($certreq)
		}
	}
	$certstore.close()

}

function export-pendingcert()
{
		#if($export)
		#{
		    Write-Debug "export parameter is set. => export certificate"
		    Write-Verbose "exporting certificate and private key"
		    $cert = Get-Childitem "cert:\LocalMachine\My" | where-object {$_.Thumbprint -eq (New-Object System.Security.Cryptography.X509Certificates.X509Certificate2((Get-Item "$CN.cer").FullName,"")).Thumbprint}
		    Write-Debug "Certificate found in computerstore: $cert"

		    #create a pfx export as a byte array
		    $certbytes = $cert.export([System.Security.Cryptography.X509Certificates.X509ContentType]::pfx)

		    #write pfx file
		    $certbytes | Set-Content -Encoding Byte  -Path "$CN.pfx" -ea Stop
		    Write-Host "Certificate successfully exportert to $CN.pfx !" -ForegroundColor Green
		    
		    Write-Verbose "deleting exported certificat from computer store"
		    # delete certificate from computer store
		    $certstore = new-object system.security.cryptography.x509certificates.x509Store('My', 'LocalMachine')
		    $certstore.Open('ReadWrite')
		    $certstore.Remove($cert)
		    $certstore.close() 
		    
		#}
		#else
		#{
		#    Write-Debug "export parameter is not set. => script finished"
		#    Write-Host "The certificate with the subject $CN is now installed in the computer store !" -ForegroundColor Green
		#}
}

function send-requestToCA()

{



#"Variabler:" 
#$CAName
#$csrfil
#"$($outdir)\$($CN).cer"
#"certreq -submit -config `"$CAName`" `"$csrfil`" `"$($outdir)\$($CN).cer`" " 
#break



    try {
       # KORREKT Invoke-Expression -Command  "certreq -submit -config `"$CAName`" $csrfil $($outdir)\$($CN).cer"
       Invoke-Expression -Command  "certreq -submit -config `"$CAName`" `"$csrfil`" `"$($outdir)\$($CN).cer`" " 
    }
    catch
    {
		if(!($LastExitCode -eq 0))
		{
		    throw "certreq -submit command failed"
		}
		Write-verbose "request was successful. Result was saved to $CN.cer"
    }

    
write-verbose "retreive and install the certifice"
		$x=Invoke-Expression -Command "certreq -accept `"$($outdir)\$($CN).cer`" " | Out-Null

		if(!($LastExitCode -eq 0))
		{
		    Write-Verbose "certreq -accept `"$($outdir)\$($CN).cer`" - [Fail]"
		}

		if(($LastExitCode -eq 0) -and ($? -eq $true))
		{
			Write-verbose "Certificate request successfully finished!" #-ForegroundColor Green
		    	
		}
		else
		{
			write-verbose "Request failed with unkown error."
		}


		#if($export)
		#{
		#    Write-Debug "export parameter is set. => export certificate"
		    Write-Verbose "exporting certificate and private key"
		    $cert = Get-Childitem "cert:\LocalMachine\My" | where-object {$_.Thumbprint -eq (New-Object System.Security.Cryptography.X509Certificates.X509Certificate2((Get-Item "$($outdir)\$($CN).cer").FullName,"")).Thumbprint}
		    Write-verbose "Certificate found in computerstore: $cert"

		    #create a pfx export as a byte array
		    $certbytes = $cert.export([System.Security.Cryptography.X509Certificates.X509ContentType]::pfx)

		    #write pfx file
		    $certbytes | Set-Content -Encoding Byte  -Path "$($outdir)\$($CN).pfx" -ErrorAction Stop
		    Write-verbose "Certificate successfully exportert to $($outdir)\$($CN).pfx"
		    
		    Write-Verbose "deleting exported certificate from computer store"
		    # delete certificate from computer store
		    $certstore = new-object system.security.cryptography.x509certificates.x509Store('My', 'LocalMachine')
		    $certstore.Open('ReadWrite')
		    $certstore.Remove($cert)
		    $certstore.close() 
		    
		#}
		#else
		#{
		#    Write-Debug "export parameter is not set. => script finished"
		#    Write-Host "The certificate with the subject $CN is now installed in the computer store !" -ForegroundColor Green
		#}


}
new-csr #-CN "testcertifikat.orebroll.se"




<#
$cert = Get-Childitem "cert:\LocalMachine\My" | where-object {$_.Thumbprint -eq (New-Object System.Security.Cryptography.X509Certificates.X509Certificate2((Get-Item "C:\Users\tal008\AppData\Local\Temp\intratest.orebroll.se\intratest.orebroll.se.csr").FullName,"")).Thumbprint}
Write-output "Certificate found in computerstore: $cert"

#create a pfx export as a byte array
$certbytes = $cert.export([System.Security.Cryptography.X509Certificates.X509ContentType]::pfx)

#write pfx file
$certbytes | Set-Content -Encoding Byte  -Path "$CN.pfx" -ea Stop
#>