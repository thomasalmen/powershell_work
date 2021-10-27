function Test-Token {
#return
    param (
            $F5Session=$Script:F5Session
        )


    Begin {
        Set-LogMEssage "Entering Function test-Token" -Type debug

    }
    process
    {
        if($F5Session)
        {
            if($F5Session.token)
            {
                ##Verifiera token
                $RestUri = "/mgmt/shared/authz/tokens/$($f5session.token)"
                try
                {
                    $Result = Invoke-F5RestMethod -Method GET -Uri "https://$LTMName$RestUri" -F5Session $F5session.websession
                    Set-LogMessage "Token '$($Result.token)' matched '$($f5session.token)'" -Type debug
                }
                catch
                {
                    Set-LogMessage "Token '$($F5Session.token)' did not match received token '$($result.token)' Occured At: '$($_.InvocationInfo.ScriptName)' Line $($_.InvocationInfo.ScriptLineNumber) - aborting" -Type Error
                }
            }
            else
            {
                Set-LogMessage "Token '$($F5Session.token)' did not match received token '$($result.token)' Occured At: '$($_.InvocationInfo.ScriptName)' Line $($_.InvocationInfo.ScriptLineNumber) - aborting" -Type Error
            }
        } 
        else
        {
            Set-LogMessage "Token '$($F5Session.token)' did not match received token '$($result.token)' Occured At: '$($_.InvocationInfo.ScriptName)' Line $($_.InvocationInfo.ScriptLineNumber) - aborting" -Type Error
        }
    }#Slut process
    end
    {
        Set-LogMessage "Exiting function Test-Token" -Type debug
    }
}