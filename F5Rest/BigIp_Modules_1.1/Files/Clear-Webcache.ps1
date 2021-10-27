#region clear-webcache
function Clear-WebCache {

    param (
        
        # Case-sensitive namn på partition där den virtuella servern finns
        [Parameter(Mandatory=$true)]
        [string]$partition,

        #Namn på webaccelerations-profilen
        [Parameter(Mandatory=$true)]
        [string]$webaccelerationProfileName,
        
        [bool]$checkonly,
        
        $F5Session=$Script:F5Session

    )

    Process
    {
        Test-Token

        Set-LogMessage "Entering function Clear-WebCache" -Type debug

        #Start kolla och radera webacceleration
        $Resturi = "/mgmt/tm/ltm/profile/ramcache/~$partition~$webaccelerationProfileName/stats"
        try 
        {
            [SSLValidator]::OverrideValidation()
            $Result = Invoke-RestMethod -Method GET -Uri "https://$LTMName$RestUri" -WebSession $F5session.websession -ErrorAction stop
            [SSLValidator]::RestoreValidation()
        
            $num_results = ($result.entries.PSObject.Properties | Measure-Object).Count

            if([bool]$checkonly -eq $true) {
                Set-LogMessage "[INFO] There are '$($num_results)' cached entries in '$partition~$webaccelerationProfileName'" -Type Info
                #Returnera enbart antalet entries i cachen
            }

            if( $num_results -gt 0 )
            {
                $Resturi = "/mgmt/tm/ltm/profile/ramcache/~$partition~$webaccelerationProfileName"
                try
                {
                    [SSLValidator]::OverrideValidation()
                    $Result = Invoke-RestMethod -Method DELETE -Uri "https://$LTMName$RestUri" -WebSession $F5session.websession -ErrorAction stop
                    [SSLValidator]::RestoreValidation()

                    Set-LogMessage "Deleted $($num_results) cached entries from '$partition~$webaccelerationProfileName'." -Type Info

                    # Ev kolla att cachen blev tömd genom att anropa Clear-WebCache igen
                    # Clear-WebCache -partition $partition -webaccelerationProfileName $webaccelerationProfileName
                }
                catch
                {
                    Set-LogMessage "Error when deleting ramcache from profile '$partition~$webaccelerationProfileName' '$($_.Exception.Message)' [Avbryter]" -Type Error
                }
             }
             else
             {
                Set-LogMessage "Profile '$webaccelerationProfileName' contains $($result.items.count) entries...nothing to do" -Type Info
             }
        }
        catch
        {
            Set-LogMessage "Could not find profile '/$partition/$webaccelerationProfileName' - '$($_.Exception.Message)' `nOccured At: '$($_.InvocationInfo.ScriptName)' - Line $($_.InvocationInfo.ScriptLineNumber)" -Type Error
        }
        #Slut kolla och radera webacceleration
    }
    end
    {
        Set-LogMessage "Exiting function Clear-WebCache" -Type debug
    }
}
#endregion