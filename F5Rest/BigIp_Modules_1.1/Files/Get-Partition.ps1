function get-partition {
    
    [cmdletbinding()]
    [CmdletBinding(SupportsShouldProcess)] #adds WhatIf and Confirm parameters
    
    param(
        # Partitionsnamn
        [Parameter(Mandatory = $true)][string]$partition,
        $F5session=$script:F5session  
    )

    begin 
    {
        Set-LogMEssage "Entering Function Get-Partition" -Type debug
        Test-token
    }

    process
    {
        $Resturi = "/mgmt/tm/auth/partition/$partition"
        try 
        {
            $Result = Invoke-F5RestMethod -Method GET -Uri "https://$LTMName$RestUri" -F5Session $F5Session.websession
            #Set-LogMEssage "Partition '$($partition)' OK" -Type Info
        }
        catch
        {
            Set-LogMessage "Hittade inte partition med namn '$partition' - '$($_.Exception.Message)'`nOccured At: '$($_.InvocationInfo.ScriptName)' Line $($_.InvocationInfo.ScriptLineNumber) - aborting" -Type Error
        }
    }
    end
    {
        Set-LogMEssage "Exiting Function Get-Partition" -Type debug
    }

}
