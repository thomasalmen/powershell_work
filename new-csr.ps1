#Snodda rader för att kolla om user är administrator
if (-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-error "Du måste vara administratör för att exekvera detta script!"
    Pause
    #Throw "Du måste vara administratör för att exekvera detta script!"
    break
}


$O = "RegionService IT" #Read-Host "Organisation (e.g. Company Ltd)"
$OU = "Region Orebro Lan" #Read-Host "Organisational Unit (e.g. IT)"
$L = "Orebro" #Read-Host "City (e.g. Amsterdam)"
$S = "Narke" #Read-Host "State (e.g. Noord-Holland)"
$C = "SE" #Read-Host "Country (e.g. NL)"

# settings.inf
#########################
$settingsFil = @"
[Version] 
Signature=`"`$Windows NT`$`"

[NewRequest] 
KeyLength =  2048
Exportable = TRUE 
MachineKeySet = TRUE 
SMIME = FALSE
RequestType =  PKCS10 
ProviderName = `"Microsoft RSA SChannel Cryptographic Provider`" 
ProviderType =  12
HashAlgorithm = sha256

;Variables
Subject = "CN=#CN#,OU=$OU,O=$O,L=$L,S=$S,C=$C"

[Extensions]
#SAN#

[RequestAttributes]
CertificateTemplate="WebServer"

"@

function new-csr {

    param (
        [Parameter(Mandatory=$true)][string]$CN,
        [Parameter(Mandatory=$false)][string]$OutDir="$($env:TEMP)\$($CN)",
        [Parameter(Mandatory=$false)][switch]$OpenExplorer
    )


    if(!(Test-Path $OutDir))
    {
        New-Item -Path $OutDir -ItemType Directory |Out-Null
    }

    $InfFil = "$($OutDir)\$($CN).inf";
    $CSRFil = "$($OutDir)\$($CN).csr"

    #Fråga om eventuella SAN-namn
    

    # Spara till inf-filen.
    $settingsFil.Replace("#SAN#" , (get-san) ).Replace("#CN#",$cn) | Out-File -FilePath $InfFil -Encoding ascii


    certreq -new $InfFil $CSRFil | Out-Null
	if(!($LastExitCode -eq 0))
	{
		write-output "certreq -new fail!"
        break
	}   

    # Radera inf-filen som nu inte behövs längre
    #Remove-Item $InfFil -Force

    # Hämta tillbaka CSR från filen på disk
    Get-Content $CSRFil | clip
    Get-Clipboard
    write-Host "Din CSR finns nu på $CSRFIL samt kopierades till ditt clipboard (ctrl+v för att klistra in)"

    #if($OpenExplorer -eq $true)
    #{
        start-process -FilePath $OutDir -WindowStyle Normal
    #}


}

function get-san {

    # Fråga efter SAN-namn
    $SANnamn=[ordered]@{}
    $i=0
    Do{ 
        $i++
        if( ($santemp = read-host "SAN-namn $i (Enter=inget)") -ne '')
        {
            $SANnamn.add( $i, $santemp )
            
        }
    } 
    Until($santemp -eq '')

    # https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/ff625722(v=ws.10)
    if ($SANnamn.Count -gt 0) {
	    $san = '2.5.29.17 = "{text}"' + "`r`n"
    
        $SANnamn.Values | % {
            $san += '_continue_ = "dns=' + $_ + '&"' + "`r`n"
    #"Lägger till " + $san
        }
    }

    return $san
}

new-csr (Read-Host("Ange namn (CN) på certifikatet "))



