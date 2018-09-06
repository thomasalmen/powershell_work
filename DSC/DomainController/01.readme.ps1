    # Installera en DC Med DSC

#Installera modul på server och klient
Install-Module -Name xActiveDirectory

#Skapa cert för att säkra upp MOF givetvis bara i testmiljöer

# Metod 1
#Skapa self-signed cert på lokala datorn.
# Använd New-SelfSignedCertificateEx.ps1
# https://gallery.technet.microsoft.com/scriptcenter/Self-signed-certificate-5920a7c6

New-SelfsignedCertificateEx `
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
$mypwd = ConvertTo-SecureString -String "YOUR_PFX_PASSWD" -Force -AsPlainText
$cert | Export-PfxCertificate -FilePath "$env:temp\DscPrivateKey.pfx" -Password $mypwd -Force

# remove the private key certificate from the node but keep the public key certificate
$cert | Export-Certificate -FilePath "$env:temp\DscPublicKey.cer" -Force
$cert | Remove-Item -Force
Import-Certificate -FilePath "$env:temp\DscPublicKey.cer" -CertStoreLocation Cert:\LocalMachine\My

# Ko+piera certet remote via psdrive:
New-PSDrive -Name S1 -PSProvider FileSystem -Root \\s1\c$ -Description "Remote S1" -Credential administrator
Copy-Item C:\Users\tal008\AppData\Local\Temp\DscPrivateKey.pfx -Destination '\\s1.lan\c$\'


# Import to the root store so that it is trusted
$mypwd = ConvertTo-SecureString -String "YOUR_PFX_PASSWD" -Force -AsPlainText
Invoke-Command -ComputerName s1 -Credential administrator { Import-PfxCertificate -FilePath "c:\DscPrivateKey.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $using:mypwd > $null }