function Remove-Sorrypage 
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("yDMZ", "Common", "SCB-LAN", "iDMZ")]
        $Partition,
        [Parameter(Mandatory = $true)][string]$vip,
        [Parameter(Mandatory = $true)][string]$iRulename,
        $F5session=$script:F5session
    )

    Begin
    {
        Test-token
    }
    Process
    {
        #Kolla att partition och vipp finns
        Get-Partition -partition $partition
        Get-Vip -partition $partition -vip $vip
        
        #Kolla att regeln existerar i partitionen
        $iRuleToDelete = Get-irule -partition $partition -iRulename $irulename
        
        #Kolla om det finns flera regler på vippen
        $Resturi = "/mgmt/tm/ltm/virtual/~$partition~$vip"
        try 
        {
            $Result = Invoke-F5RestMethod -Method GET -Uri "https://$LTMName$RestUri" -F5Session $F5session.WebSession -ErrorAction stop 

            # Finns det fler än 1 regel på vippen?
            if($result.rules.Count -gt 0 -and $result.rules -match "/$partition/$irulename")
            {
                $iRules = @() 
                foreach($rule in $result.rules)
                {
                    if($rule -ne "/$partition/$irulename" )
                    {
                        $iRules += $rule             
                    }
                }

                # Tar bort önskad regel från JSONBODY, men behåller övriga regler om det finns några.
                $JSONBody = @{
                    partition = "$partition";
                    rules = @(
                        $iRules
                    )
                } | ConvertTo-Json

                
                # D.v.s PATCH'a rules{} med de existerande reglerna, men lämna regeln som ska tas bort utanför arrayen.
                $Resturi = "/mgmt/tm/ltm/virtual/$vip"
                try 
                {
                    $Result = Invoke-F5RestMethod -Method PATCH -Uri "https://$LTMName$RestUri" -Body $JSONBody -F5Session $F5session.WebSession
                    Set-LogMessage "Tog bort '$iRuleName' från virtuell server '$vip'" -Type Info
                }
                catch
                {
                    Set-LogMessage "Fel när '$iRuleName' skulle tas bort från '$vip' - '$($_.Exception.Message)' `nOccured At: '$($_.InvocationInfo.ScriptName)' - Line $($_.InvocationInfo.ScriptLineNumber)" -Type Error
                }

                # ~~~~~~~~~~~~~~~~~~ OBS ~~~~~~~~~~~~~~~~~~~~ #
                #    Raderar iRule PERMANENT från systemet    #
                # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
                Remove-IruleFromPartition -iRulename $irulename
            }
            else
            {
                Set-LogMessage "Hittade inte '$iRulename' på '$vip' - Nothing to do" -Type Warning
            }

        } #Slut try
        catch
        {
            $_.Exception.Message
        }

    }#Slut process

}##Slut function