function Set-Sorrypage
{
    
    [CmdletBinding(SupportsShouldProcess)] #adds WhatIf and Confirm parameters
    
    param(

        # Case-sensitive namn på partition där den virtuella servern finns
        [Parameter(Mandatory=$true)]
        [string]$partition,

        # Case-sensitive namn på den virtuella servern som ska ha iRulen
        [Parameter(Mandatory=$true)]
        [string]$vip,

        #Namnet på iRulen som ska skapas
        [Parameter(Mandatory=$true)]
        [string]$iRuleName,

        #Datum/tid då sidan ska stängas (YYY-mm-dd HH:MM)
        [Parameter(Mandatory=$true)]
        [string]$startDate,

        #Datum/tid då sidan ska öppnas igen (YYY-mm-dd HH:MM)
        [Parameter(Mandatory=$true)]
        [string]$endDate,

        $F5Session=$Script:F5Session
    )

    BEGIN
    {
    "Använd funktionen New-Sorrypage istället."
    break

      Test-Token
    }
    PROCESS
    {
        #get-token -LTMName $LTMName -LTMUser $LTMUser -LTMPassword $LTMPassword
        get-partition -partition $partition
        get-vip -partition $partition -vip $vip
        Get-irule -partition $partition -iRulename $irulename #-session $session
        #new-irule -partition $partition -iRulename $iRuleName  -iRuleKod $iRuleKod
        
        #Variabeln $irulenamn kan ev ändras i funktionen new-irule.
        #Därför anropas funktionen inte add-irule med -irulename $irulename
        
        Set-LogMessage "Lägger till regel på '$vip'"
        add-irule -partition $partition -vip $vip -iRulename $iRulename
    }

} #Slut function