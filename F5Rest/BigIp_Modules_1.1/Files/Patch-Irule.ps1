function Patch-Irule {
Write-Output "Funktion ej klar!"
break

    get-token

    #Visa gammal regel
    $Resturi = "/mgmt/tm/ltm/rule/~yDMZ~bigipdemo.scb.intra_sorrypage_iRule"
    try 
    {
        [SSLValidator]::OverrideValidation()
        $Result = Invoke-RestMethod -Method GET -Uri "https://$LTMName$RestUri" -WebSession $session -ErrorAction stop
        [SSLValidator]::RestoreValidation()

        #$printOldRule = [pscustomobject]@{
        #    Name = $result.name
        #    apiAnonymous = $result.apiAnonymous
        #} 
        Write-Output "Existerande regel:`n`n "
        $result.apiAnonymous
    }
    catch
    {
        $error[0].Exception
    }
    #Slut Visa gammal regel

  # Patcha existerande regel
    $Resturi = "/mgmt/tm/ltm/rule/~yDMZ~bigipdemo.scb.intra_sorrypage_iRule"    

$sorrypage_HTML=@"
when HTTP_REQUEST {
    #Parametrar:Startdatum_tid Enddatum_tid nuvarande_tid Felmeddelande
    set sorrypage_HTML {
        <b>Detta &auml;r ett testmeddelande</b><br><a href="https://www.scb.se">L&auml;nk till scb.se</a><br><img src="https://scitechdaily.com/images/Cat-COVID-19-Mask-777x518.jpg">
    }
    
    call /yDMZ/proc_sorrypage::sorrypage "2020-08-18 11:00" "2020-08-21 16:36" [clock seconds] "`$sorrypage_HTML"
}
"@
    $JSONBody = @{
        apiAnonymous = "$sorrypage_HTML";
            
    } | ConvertTo-Json

    # Fix för teckenencoding
    # Caused by a bug in ConvertTo-Json https://windowsserver.uservoice.com/forums/301869-powershell/suggestions/11088243-provide-option-to-not-encode-html-special-characte
    # '<', '>', ''' and '&' are replaced by ConvertTo-Json to \\u003c, \\u003e, \\u0027, and \\u0026. The F5 API doesn't understand this. Change them back.
    $ReplaceChars = @{
        '\\u003c' = '<'
        '\\u003e' = '>'
        '\\u0027' = "'"
        '\\u0026' = "&"
    }

    foreach ($Char in $ReplaceChars.GetEnumerator()) 
    {
        $JSONBody = $JSONBody -replace $Char.Key, $Char.Value
    }

    try 
    {
        
        [SSLValidator]::OverrideValidation()
        $Result = Invoke-RestMethod -Method PATCH -Uri "https://$LTMName$RestUri" -Body $JSONBody -WebSession $session -ContentType 'application/json' -ErrorAction Stop
        [SSLValidator]::RestoreValidation()
        "Uppdaterade regel: "
        $result.apiAnonymous
    }
    catch
    {
        write-warning "Fel när iRule skulle läggas till, kontrollera syntax!"
        $error[0].Exception
        break
    }

    #visa ny regel

}