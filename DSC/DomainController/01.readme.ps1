    # Installera en DC Med DSC

#Installera modul på server och klient
#Install-Module -Name xActiveDirectory

#save-module xActiveDirectory
#$x=new-pssession S1 -Credential s1\administrator
#Copy-Item "C:\Users\thalm\AppData\Local\Temp\xActiveDirectory" -ToSession $x -Destination c:\temp -Recurse
#Skapa cert för att säkra upp MOF givetvis bara i testmiljöer

# Metod 1
#Skapa self-signed cert på lokala datorn.
# Använd New-SelfSignedCertificateEx.ps1
# https://gallery.technet.microsoft.com/scriptcenter/Self-signed-certificate-5920a7c6
#Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
#. C:\Users\thalm\Desktop\WorkCode\powershell_work\DSC\DomainController\New-SelfSignedCertificateEx.ps1
#$computers="S1","S2"
$computers="S2"

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

# Kopiera certet remote via pssession:
$computers | % {
    $sess = New-PSSession -ComputerName $_ -Credential $_\administrator
    Copy-Item "$env:temp\DscPrivateKey.pfx" -Destination "c:\windows\temp\DscPrivateKey.pfx" -ToSession $sess -Force

    # Import to the root store so that it is trusted
    $mypwd = ConvertTo-SecureString -String "YOUR_PFX_PASSWD" -Force -AsPlainText
    Invoke-Command -Session $sess { Import-PfxCertificate -FilePath "c:\temp\DscPrivateKey.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $using:mypwd > $null }
    $sess.close()    
}


