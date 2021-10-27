
function get-token {

   [cmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param(
        [Parameter(Mandatory=$true)][string]$LTMName,
        [Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$LTMCredentials
    )
    
    Begin
    {
        Set-LogMessage "Entering function Get-Token" -Type debug
    }

    process
    {
            $WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession

            $RestUri="/mgmt/shared/authn/login"
            try {
                $JSONBody = @{
                    username = $LTMCredentials.username;
                    password=$LTMCredentials.GetNetworkCredential().password;
                    loginProviderName='tmos'
                } | ConvertTo-Json

                $Result = Invoke-F5RestMethod -Method POST -Uri "https://$LTMName$RestUri" -Body $JSONBody -LTMCredentials $LTMCredentials -F5Session $WebSession
                $Token = $Result.token.token

                $TokenStartTime = $Result.token.startTime
                $websession.headers.Remove('X-F5-Auth-Token') | Out-Null
                $websession.Headers.Add('X-F5-Auth-Token', $Token)

                ##Verifiera token
                $RestUri = "/mgmt/shared/authz/tokens/$token"
                try
                {

                    $Result = Invoke-F5RestMethod -Method GET -Uri "https://$LTMName$RestUri" -F5Session $WebSession
              
                    ## Token Ok, utöka token timeouot
                    #NB: Max value is 36000 seconds (10 hours) so let's set it to 1 hour
                    $TokenLifespan = 3600
                    $Body = @{ timeout = $TokenLifespan } | ConvertTo-Json
                    $Headers = @{
                        'X-F5-Auth-Token' = $Token
                    }

                    $RestUri="/mgmt/shared/authz/tokens/$token"
                    try
                    {
                        Invoke-F5RestMethod -Method Patch -Uri "https://$LTMName$RestUri" -Headers $Headers -Body $Body -F5Session $websession  | Out-Null
              
                        #3600 = 1 timma
                        $ts = New-TimeSpan -Minutes (3600/60)
                        $date = Get-Date -Date $TokenStartTime 
                        $ExpirationTime = $date + $ts

                        #Set-LogMessage "New token ok valid until : $(get-date $ExpirationTime -Format "HH:mm")"  -Type info
                        Set-LogMessage "New token '$token' OK - Valid until : $(get-date $ExpirationTime -Format "HH:mm")"  -Type verbose

                        $newSession = [pscustomobject]@{
                            Credentials = $LTMCredentials
                            WebSession = $websession
                            Token      = $Token
                        }

                    }
                    catch
                    {
                        Set-LogMessage "Modification of token timeout failed. " -Type Error
                    }

                }
                catch
                {
                    Set-LogMessage "Verification of token '$token' did not match received token '$($result.token.token)' - [Avbryter]" -Type Error
                }

            }
            catch [System.Net.WebException]
            {
                Set-LogMessage "Error creating token: '$($_.Exception.Message)'..[Avbryter]" -Type Error
            }      

        $Script:F5Session = $newSession

    }#Slut process
    end
    {
        Get-FailoverState
        Set-LogMessage "Exiting function Get-Token" -Type debug
    }

}