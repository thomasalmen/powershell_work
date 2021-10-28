<#
.Synopsis
   Lägger till iRule på vip
   Funktionen måste anropas efter Get-Token då $F5Session skapats.
   Alternativt måste en F5Session skickas med.

.EXAMPLE

#>

function Add-Irule  {
# Detta är en help-function och är inte gjord för att anropas direkt.

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

        #Kolla om det finns flera regler pÃ vippen och kom ihÃ¥g dem i sÃ fall.
        $Resturi = "/mgmt/tm/ltm/virtual/~$partition~$vip"
        try 
        {
            $Result = Invoke-F5RestMethod -Method GET -Uri "https://$LTMName$RestUri" -F5Session $F5session.WebSession -ErrorAction stop 

    
            # Finns det fler än 1 regel på vippen?
            if($result.rules.Count -gt 0)
            {
                $ant_rules = " + " + $($result.rules.Count) + " existerande regler" # Enbart för räknaren nedan

                foreach($rule in $result.rules)
                {
                    if( $rule -eq "/" + $partition + "/" + $iRulename)
                    {
                        Set-LogMessage "iRule '$iRulename' already attached to '$vip' - Nothing to do" -Type warning
                        return
                    }
                }

                # Lägger till ev redan existerande regler + nya regeln på vippen
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
                # Annars, lägg bara till den nya regeln
                $JSONBody = @{
                    partition = "$partition";
                    rules = @(
                        "/$partition/$iRuleName"
                    )
            
                } | ConvertTo-Json
            }

            #Lägg till nya och eventuellt redan existerande reglerna på vippen
            $Resturi = "/mgmt/tm/ltm/virtual/$vip"
            try 
            {
                $Result = Invoke-F5RestMethod -Method PATCH -Uri "https://$LTMName$RestUri" -Body $JSONBody -F5Session $F5session.WebSession -ErrorAction Stop
                Set-LogMessage "Lade till '$iRuleName'$($ant_rules) på virtuell server '$vip'" -Type Info
            }
            catch
            {
                Set-LogMessage "Fel när '$iRuleName' skulle läggas till - '$($_.Exception.Message)' `nOccured At: '$($_.InvocationInfo.ScriptName)' - Line $($_.InvocationInfo.ScriptLineNumber)" -Type Error
            }
            # Slut Lägg till existerande plus nya regeln pÃ¥ vippen

        }
        catch
        {
            Set-LogMessage "Det gick inte att kontrollera om det redan finns iRules pÃ '$vip' - '$($_.Exception.Message)' `nOccured At: '$($_.InvocationInfo.ScriptName)' - Line $($_.InvocationInfo.ScriptLineNumber)" -Type Error
        }
        #Slut Kolla om det finns flera regler pÃ vippen
    } #Slut process
    end
    {
    }
}
