# Förberedelse för att skapa och ladda upp ett self-signed cert för att kryptera mof-filerna.
# Self-signed givetvis bara i testmiljöer
# Scriptet skapar ett self-signed cert på lokala datorn och laddar upp det till respektive klientdator.
# Använder New-SelfSignedCertificateEx.ps1
# https://gallery.technet.microsoft.com/scriptcenter/Self-signed-certificate-5920a7c6


# Executionpolicy måste vara bortkopplat
# Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
# Gå till rätt katalog
# cd C:\Users\thalm\OneDrive\powershell_work\dsc\DomainController

# Sourca New-SelfSignedCertificateEx.ps1
#. .\New-SelfSignedCertificateEx.ps1

# Alla datorer som ska ha certet
$computers="s1","s2"
# Lösenord till pfx'en
$pfxpassword= "P@ssw0rd"


$thumbprint=New-SelfsignedCertificateEx `
    -Subject "CN=${ENV:ComputerName}" `
    -EKU 'Document Encryption' `
    -KeyUsage 'KeyEncipherment, DataEncipherment' `
    -SAN ${ENV:ComputerName} `
    -FriendlyName 'DSC Credential Encryption certificate' `
    -Exportable `
    -StoreLocation 'LocalMachine' `
    -KeyLength 2048 `
    -ProviderName 'Microsoft Enhanced Cryptographic Provider v1.0' `
    -AlgorithmName 'RSA' `
    -SignatureAlgorithm 'SHA256'

# Locate the newly created certificate
$Cert = Get-ChildItem -Path cert:\LocalMachine\My | Where-Object {
        ($_.FriendlyName -eq 'DSC Credential Encryption certificate') -and ($_.Subject -eq "CN=${ENV:ComputerName}")
    } | Select-Object -First 1

# export the public key certificate
$mypwd = ConvertTo-SecureString -String $pfxpassword -Force -AsPlainText
$cert | Export-PfxCertificate -FilePath "$env:temp\DscPrivateKey.pfx" -Password $mypwd -Force

# remove the private key certificate from the node but keep the public key certificate
$cert | Export-Certificate -FilePath "$env:temp\DscPublicKey.cer" -Force
$cert | Remove-Item -Force
Import-Certificate -FilePath "$env:temp\DscPublicKey.cer" -CertStoreLocation Cert:\LocalMachine\My


# Kopiera cert och nyckel remote via pssession:
$computers | % {
    $sess = New-PSSession -ComputerName $_ -Credential (Get-Credential -Message "Lösen för $_" -UserName administrator)
    Copy-Item "$env:temp\DscPrivateKey.pfx" -Destination "c:\windows\temp\DscPrivateKey.pfx" -ToSession $sess -Force

    # Import to the root store so that it is trusted
    $mypwd = ConvertTo-SecureString -String $pfxpassword -Force -AsPlainText
    Invoke-Command -Session $sess { Import-PfxCertificate -FilePath "c:\windows\temp\DscPrivateKey.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $using:mypwd -Verbose }
    Remove-PSSession -Session $sess
}

$thumbprint.Thumbprint
$thumbprint.Thumbprint | clip
write-output "Thumbprint kopierat till clipboard. Du kan nu klistra in den i din DSC ConfigurationData"
