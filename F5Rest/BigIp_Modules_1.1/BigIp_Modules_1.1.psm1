$Script:F5Session=$null

#region allowSelfsignedCerts
function allowSelfsignedCerts
{

# Kod som tillåter self-signed certs
$definition = @"
using System.Collections.Generic;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

public static class SSLValidator
{
    private static Stack<RemoteCertificateValidationCallback> funcs = new Stack<RemoteCertificateValidationCallback>();

    private static bool OnValidateCertificate(object sender, X509Certificate certificate, X509Chain chain, SslPolicyErrors sslPolicyErrors)
    {
        return true;
    }

    public static void OverrideValidation()
    {
        funcs.Push(ServicePointManager.ServerCertificateValidationCallback);
        ServicePointManager.ServerCertificateValidationCallback = OnValidateCertificate;
    }

    public static void RestoreValidation()
    {
        if (funcs.Count > 0) {
            ServicePointManager.ServerCertificateValidationCallback = funcs.Pop();
        }
    }
}
"@

    try {
        Add-Type -TypeDefinition $definition
    }
    catch {
        "Did not add '$definition'"
    }
}
#endregion

$ErrorActionPreference = "stop"

allowSelfsignedCerts

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path
#Restrict .NET Framework to TLS v 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#region Load Public Functions

    Get-ChildItem "$ScriptPath\Files" -Filter *.ps1 -Recurse| Select-Object -Expand FullName | ForEach-Object {
        $Function = Split-Path $_ -Leaf
        try {
            . $_
        } catch {
            Write-Warning ("{0}: {1}" -f $Function,$_.Exception.Message)
        }
   }

#endregion

Export-ModuleMember -Function Add-Irule, Clear-WebCache,Disable-Poolmember, Get-FailoverState, Get-Irule, Get-Otp, Get-Partition, Get-Token, Get-Vip, Get-VipCount, New-Backup, New-Csr, New-Irule, New-Sorrypage,New-Transaction,Patch-Irule,Remove-IRuleFromPartition, Remove-Sorrypage,Set-Sorrypage,Test-WebSites


<#
$manifest = @{

    Path              = '\\scb\script\Repository\Scripts\Nätverk\BigIp_Modules_1.1\BigIp_Modules_1.1.psd1'
    RootModule        = 'BigIp_Modules_1.1.psm1' 
    Author            = 'Thomas Almén'
}
New-ModuleManifest @manifest
#>

