#Namn på backup
[string]$endDate = "Backuptest_2021-01-22_19.00_backup"

#Var ska backupfilen överföras?
#ftp://

function New-Transaction
{

    Param
    (
        $F5Session  = $script:F5Session
    )

    Begin
    {
        Set-LogMessage "Entering function New-Transaction" -type debug
        Test-Token
    }
    Process
    {
        #Skapa transaction ID genom att skicka en tom JSON-body

        $Resturi = "/mgmt/tm/transaction"
        $JSONBody = @{
        
        } | ConvertTo-Json #-Compress

        try
        {
            $Result = Invoke-F5RestMethod -Method POST -Uri "https://$LTMName$RestUri" -Body $JSONBody -F5Session $F5session.websession
            $TransactionID = $result.transID
          
            $F5Session.Websession.Headers.Remove('X-F5-REST-Coordination-Id') | Out-Null
            $F5Session.Websession.Headers.Add('X-F5-REST-Coordination-Id',$TransactionID)
            Set-LogMessage "Skapade transactionId '$TransactionID'" -Type Info
        }
        catch [System.Net.WebException] 
        {
            Set-LogMessage "Error creating transaction - $($_.Exception.Message)" -Type Error
        }
    }
    End
    {
        Set-LogMessage "Leaving function New-Transaction" -Type debug
    }
}