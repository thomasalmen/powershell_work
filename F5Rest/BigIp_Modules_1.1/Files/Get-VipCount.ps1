function Get-VipCount {

    [CmdletBinding(SupportsShouldProcess)] #adds WhatIf and Confirm parameters
    
    param(
        $F5session=$script:F5session  
    )
    begin
    {
        Set-LogMEssage "Entering Function Get-VipCount" -Type verbose
    }
    process
    {
        ### Kolla om vippen existerar.
        $Resturi = "/mgmt/tm/ltm/virtual/?`$select=name"
        try 
        {
            $Result = Invoke-F5RestMethod -Method GET -Uri "https://$LTMName$RestUri" -F5Session $F5Session.websession
            if($result)
            {
               # $result.count
                $result.Items.length
                #if($result.name -match $vip)
                #{
                #    #Set-LogMEssage "VIP '$($result.name)' OK" -Type Info
                #}
            }
        }
        catch
        {
            Set-LogMessage "Hittade inte VIP '$vip', kontrollera stavning. `nOccured At: '$($_.InvocationInfo.ScriptName)' `nLine $($_.InvocationInfo.ScriptLineNumber) - aborting" -Type Error
        }
    }
    end
    {
        Set-LogMEssage "Exiting Function Get-VipCount" -Type verbose
    }
}