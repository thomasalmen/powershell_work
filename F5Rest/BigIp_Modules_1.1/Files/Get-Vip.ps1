function get-vip {

    [cmdletbinding()]
    [CmdletBinding(SupportsShouldProcess)] #adds WhatIf and Confirm parameters
    
    param(
        # Partitionsnamn
        [Parameter(Mandatory = $true)][string]$partition,
        [Parameter(Mandatory = $true)][string]$vip,
        $F5session=$script:F5session  
    )
    begin
    {
        Set-LogMEssage "Entering Function Get-Vip" -Type debug
    }
    process
    {
        ### Kolla om vippen existerar.
        $Resturi = "/mgmt/tm/ltm/virtual/~$partition~$vip"
        try 
        {
            $Result = Invoke-F5RestMethod -Method GET -Uri "https://$LTMName$RestUri" -F5Session $F5Session.websession
            if($result)
            {
                if($result.name -match $vip)
                {
                    #Set-LogMEssage "VIP '$($result.name)' OK" -Type Info
                }
            }
        }
        catch
        {
            Set-LogMessage "Hittade inte VIP '$vip', kontrollera stavning. `nOccured At: '$($_.InvocationInfo.ScriptName)' `nLine $($_.InvocationInfo.ScriptLineNumber) - aborting" -Type Error
        }
    }
    end
    {
        Set-LogMEssage "Exiting Function Get-Vip" -Type debug
    }
}