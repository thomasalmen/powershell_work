function New-Backup
{
    Param
    (
        [Parameter(Mandatory=$false)]
        [string]$UCSName = "BigIp_$($LTMname)_" + $(get-date -Format "yyyyMMdd_HH.mm") +".ucs",

        $F5Session  = $script:F5Session
    )

    Begin
    {
        Set-LogMessage "Entering function New-Backup" -Type Debug
        Test-Token
    }
    Process
    {
        New-Transaction

        #Lägg till backuppen till transaction-ID't
        $Resturi = "/mgmt/tm/sys/ucs"
        $JSONBody = @{
            command = "save"
            name = "$UCSName"
        } | ConvertTo-Json

        try
        {
            $Result = Invoke-F5RestMethod -Method POST -Uri "https://$LTMName$RestUri" -Body $JSONBody -F5Session $F5session.websession
            Set-Logmessage "Lade till UCS till transaction" -Type Info
        }
        catch
        {
            Set-LogMessage "Error adding to backup-transaction: '$($_.Exception.Message)'" -Type Error
        }



        ######################
        # Starta transaction #
        ######################
        $RestUri = "/mgmt/tm/transaction/$($F5Session.WebSession.Headers."X-F5-REST-Coordination-Id")"

        $JSONBody = @{
            state = "VALIDATING"
        } | ConvertTo-Json

        try
        {
            #Till denna PATCH skickas inte transactionId med i headern, så den headern tas nu bort.
            Set-LogMessage "Startar transaction" -Type Info
            $F5Session.Websession.Headers.Remove('X-F5-REST-Coordination-Id') | Out-Null
            $result = Invoke-F5RestMethod -Method PATCH -Uri "https://$LTMName$RestUri" -Body $JSONBody -F5Session $F5session.websession
        }
        catch
        {
            Set-LogMessage "Kunde inte starta transaction: '$($_.Exception.Message)'" -Type Error
        }

        ######################
        # Verifiera resultat #
        ######################
        $RestUri = "/mgmt/tm/transaction/$($F5Session.WebSession.Headers."X-F5-REST-Coordination-Id")"
        try
        {
            $Result = Invoke-F5RestMethod -Method GET -Uri "https://$LTMName$RestUri" -F5Session $F5session.websession
            if($result.items.state -eq "COMPLETED")
            {
                Set-LogMessage "Backup '$($UCSName)' completed Successfully!" -Type Info
            }
        }
        catch
        {
            Set-LogMessage "Could not verify backup. Please perform a manual backup - '$($_.Exception.Message)'" -Type Error
        }

    }
    End
    {
        Set-LogMessage "Leaving function New-Backup" -Type debug
    }
}

