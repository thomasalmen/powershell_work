function Invoke-F5Restmethod
{
    param(
        [Parameter(Mandatory = $false)][string]$method="GET",
        [Parameter(Mandatory = $true)][string]$uri,
        [Parameter(Mandatory = $false)][System.Management.Automation.PSCredential]$LTMCredentials,
        [Parameter(Mandatory)]$F5Session,
        [Parameter(Mandatory = $false)][string]$ErrorActionOverride = "Stop",
        $Body,
        $Headers
    )
    begin
    {
        Set-LogMessage "Entering function Invoke-F5Restmethod" -Type verbose
    }
    process
    {
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $Result = Invoke-RestMethod -Method $method -Uri $uri -Headers $headers -WebSession $F5Session -ErrorAction "$ErrorActionOverride" -ContentType 'application/json' -Body $body -Credential $LTMCredentials
        }
        else
        {
            try
            {
                [SSLValidator]::OverrideValidation()
                $Result = Invoke-RestMethod -Method $method -Uri $uri -Headers $headers -WebSession $F5Session -ErrorAction "$ErrorActionOverride" -ContentType 'application/json' -Body $body -Credential $F5Session.Credential
                [SSLValidator]::RestoreValidation()
            }
            catch
            {
                $_.Exception.Message
            }
        }
        $result
    } # End process
    end
    {
        Set-LogMessage "Exiting function Invoke-F5Restmethod" -Type verbose
    }
} #End function