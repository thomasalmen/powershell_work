#Failover-state
function Get-FailoverState
{
    Param
    (
        $F5Session  = $script:F5Session
    )

    Begin
    {
        Set-LogMessage "Entering function Get-FailoverState" -type debug
        Test-Token
    }
    Process
    {

        $Resturi = "/mgmt/tm/cm/device"
        try
        {
            $Result = Invoke-F5RestMethod -Method GET -Uri "https://$LTMName$RestUri" -F5Session $F5session.websession
            
            if( ! ($result.items.failoverState).tolower() -match "active" ) 
            {
              Set-LogMessage "Bigipdevice '$($result.items.hostname) ($($result.items.managementIp))' är inte aktiv enhet. `nÄndra värdet på '`$Ltmname' från '$($LTMName)' till korrekt ip för aktiv enhet - [Avbryter]" -Type Error
            }
        }
        catch
        {
            $($_.Exception.Message)
        }
    }
    end
    {
        Set-LogMessage "Exiting function Get-FailoverState" -Type debug
    }
}