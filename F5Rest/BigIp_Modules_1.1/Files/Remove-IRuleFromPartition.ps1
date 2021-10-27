function Remove-IRuleFromPartition 
{
    param(
        [Parameter(Mandatory = $true)][string]$iRulename,
        $F5session=$script:F5session
    )
    begin
    {
        Set-LogMessage "Entering function Remove-IRuleFromPartition" -Type verbose
        Test-Token
    }
    process
    {
        $Resturi = "/mgmt/tm/ltm/rule/$iRulename"
        try 
        {
            $Result = Invoke-F5RestMethod -Method DELETE -Uri "https://$LTMName$RestUri" -Body $JSONBody -F5Session $F5session.WebSession
            Set-LogMessage "Deleted '$iRuleName' from Big-Ip" -Type Info
        }
        catch
        {
            Set-LogMessage "Fel när '$iRuleName' skulle tas bort - '$($_.Exception.Message)' `nOccured At: '$($_.InvocationInfo.ScriptName)' - Line $($_.InvocationInfo.ScriptLineNumber)" -Type warning
        }
    }
    end
    {
        Set-LogMessage "Exiting function Remove-IRuleFromPartition " -Type verbose
    }
}