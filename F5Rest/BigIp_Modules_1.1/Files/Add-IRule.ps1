<#
.Synopsis
   L�gger till iRule p� vip
   Funktionen m�ste anropas efter Get-Token d� $F5Session skapats.
   Alternativt m�ste en F5Session skickas med.

.EXAMPLE

#>

function Add-Irule  {
# Detta �r en help-function och �r inte gjord f�r att anropas direkt.

    param(
        # Partitionsnamn
        [Parameter(Mandatory=$true)]
        [ValidateSet("yDMZ", "Common", "SCB-LAN", "iDMZ")]
        $Partition,
        [Parameter(Mandatory = $true)][string]$vip,
        [Parameter(Mandatory = $true)][string]$iRulename,

        $F5session=$script:F5session

    )
    begin
    {
        Test-token
    }
    process
    {

        #Kolla om det finns flera regler p� vippen och kom ihåg dem i s� fall.
        $Resturi = "/mgmt/tm/ltm/virtual/~$partition~$vip"
        try 
        {
            $Result = Invoke-F5RestMethod -Method GET -Uri "https://$LTMName$RestUri" -F5Session $F5session.WebSession -ErrorAction stop 

    
            # Finns det fler �n 1 regel p� vippen?
            if($result.rules.Count -gt 0)
            {
                $ant_rules = " + " + $($result.rules.Count) + " existerande regler" # Enbart f�r r�knaren nedan

                foreach($rule in $result.rules)
                {
                    if( $rule -eq "/" + $partition + "/" + $iRulename)
                    {
                        Set-LogMessage "iRule '$iRulename' already attached to '$vip' - Nothing to do" -Type warning
                        return
                    }
                }

                # L�gger till ev redan existerande regler + nya regeln p� vippen
                $JSONBody = @{
                    partition = "$partition";
                    rules = @(
                        "/$partition/$iRuleName"
                        $result.rules
                    )
            
                } | ConvertTo-Json

            }
            else
            {
                # Annars, l�gg bara till den nya regeln
                $JSONBody = @{
                    partition = "$partition";
                    rules = @(
                        "/$partition/$iRuleName"
                    )
            
                } | ConvertTo-Json
            }

            #L�gg till nya och eventuellt redan existerande reglerna p� vippen
            $Resturi = "/mgmt/tm/ltm/virtual/$vip"
            try 
            {
                $Result = Invoke-F5RestMethod -Method PATCH -Uri "https://$LTMName$RestUri" -Body $JSONBody -F5Session $F5session.WebSession -ErrorAction Stop
                Set-LogMessage "Lade till '$iRuleName'$($ant_rules) p� virtuell server '$vip'" -Type Info
            }
            catch
            {
                Set-LogMessage "Fel n�r '$iRuleName' skulle l�ggas till - '$($_.Exception.Message)' `nOccured At: '$($_.InvocationInfo.ScriptName)' - Line $($_.InvocationInfo.ScriptLineNumber)" -Type Error
            }
            # Slut L�gg till existerande plus nya regeln på vippen

        }
        catch
        {
            Set-LogMessage "Det gick inte att kontrollera om det redan finns iRules p� '$vip' - '$($_.Exception.Message)' `nOccured At: '$($_.InvocationInfo.ScriptName)' - Line $($_.InvocationInfo.ScriptLineNumber)" -Type Error
        }
        #Slut Kolla om det finns flera regler p� vippen
    } #Slut process
    end
    {
    }
}
