function Get-Irule {

    param(
        # Partitionsnamn
        [Parameter(Mandatory = $true)][string]$partition,
        [Parameter(Mandatory = $true)][string]$iRulename,
        $F5session=$script:F5session  
    )

    begin
    {
        Set-LogMessage "Entering function Get-Irule" -Type debug
        Test-token
    }
    process
    {



        ###########################################################
        # Kolla om iRule med $iRulename redan finns i partitionen #
        ###########################################################
        $Resturi = "/mgmt/tm/ltm/rule/~$partition~$irulename"
        try 
        {
            $Result = Invoke-F5RestMethod -Method GET -Uri "https://$LTMName$RestUri" -F5Session $F5Session.Websession
            if($result.name -match "$iRuleName" )
            {
                $result
            }
        }
        catch
        {
            #Om ett fel inträffar så är det en 404 - Requested rule not found = inget fel utan Helt OK, för då finns inte regeln
            #Set-LogMessage "'$iRulename' gick inte att hitta i partition '$partition' - '$($_.Exception.Message)' `nOccured At: '$($_.InvocationInfo.ScriptName)' - Line $($_.InvocationInfo.ScriptLineNumber)" -Type Info
            $false
        }
    }
    end
    {
        Set-LogMessage "Exiting function Get-Irule" -Type debug
    }

}