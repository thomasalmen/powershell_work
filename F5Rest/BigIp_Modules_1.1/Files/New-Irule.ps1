
function New-Irule {
    param(
        # Partitionsnamn
        [Parameter(Mandatory = $true)][string]$partition,
        [Parameter(Mandatory = $true)][string]$iRulename,
        [Parameter(Mandatory = $false)][string]$iRuleKod,
        $F5session=$script:F5session  
    )
    begin
    {

        if(!$iRuleKod)
        {
            $iRuleKod = "when HTTP_REQUEST { # No Code }"
        }

        Test-token
    }
    
    process
    {
        ##############################################################
        # Kolla om iRule med samma namn redan finns i partitionen    #
        ##############################################################

        $iRuleFinnsRedan = get-irule -partition $partition -iRulename $irulename
        

        if($iRuleFinnsRedan)
        {
        
            if(![string]::IsNullOrEmpty($iRuleFinnsRedan.apiAnonymous))
            {
                $ExistingIruleCode = $iRuleFinnsRedan.apiAnonymous.Trim()
            }
            if( ($ExistingIruleCode) -eq ($iRuleKod.Trim()) )
            {
                Set-LogMessage "iRule '$($iRuleFinnsRedan.name)' already exist in partition '$partition' and is the same as `$iRuleKod - Nothing to do." -Type warning
                return
            }
            else
            {
                #Set-LogMessage "'$($iRuleFinnsRedan.name)' already exists in '$partition' but is not equal to `$iRuleKod - Backing up.." -Type Info
                #Regeln kan vara bunden till en vip och måste isf tas bort därifrån och därefter döpas om.
                #Därför skapas en ny regel med namn $BackupiRuleName  dit existerande kod kopieras.
                #Därefter PATCH'as original-iRUle med bifogad kod.
                
                $BackupiRuleName = $($iRuleFinnsRedan.name) + "_backup_" + (Get-Date -Format "yyyy-MM-dd_HH.mm.ss")
                
                $JSONBody = @{
                    partition = "$partition";
                    name = "$BackupiRuleName" ;
                    apiAnonymous = "$($iRuleFinnsRedan.apiAnonymous)";
                } | ConvertTo-Json -Compress

                # Start jsonbugg-fix.
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


                # Döp om den gamla regeln.
                # OM det fastnar i catch kan regeln redan vara attached till en vip
                $Resturi = "/mgmt/tm/ltm/rule"
                try 
                {
                    $Result = Invoke-F5RestMethod -Method POST -Uri "https://$LTMName$RestUri" -Body $JSONBody -F5Session $F5session.WebSession
                    Set-LogMessage "Existing '$($iRuleFinnsRedan.name)' renamed to '$BackupiRuleName'" -Type Info
                }
                catch
                {
                    Set-LogMessage "Fel vid skapande av iRule: '$($_.Exception.Message)' `nOccured At: '$($_.InvocationInfo.ScriptName)' - Line $($_.InvocationInfo.ScriptLineNumber)" -Type Error
                }



                #############################################
                # PATCHAR Existerande regel med ny irulekod #
                #############################################

                $JSONBody = @{
                    partition = "$partition";
                    apiAnonymous = "$irulekod";
                } | ConvertTo-Json -Compress


                # Start jsonbugg-fix.
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

                # Döp om den gamla regeln.
                # OM det fastnar i catch kan regeln redan vara attached till en vip
                $Resturi = "/mgmt/tm/ltm/rule/$iRuleName"
                try 
                {
                    $Result = Invoke-F5RestMethod -Method PATCH -Uri "https://$LTMName$RestUri" -Body $JSONBody -F5Session $F5session.WebSession
                    Set-LogMessage "Patched existing iRule '$iRuleName' with attached irulecode in '`$iRuleKod'" -Type Info
                }
                catch
                {
                    Set-LogMessage "Fel vid skapande av iRule: '$($_.Exception.Message)' `nOccured At: '$($_.InvocationInfo.ScriptName)' - Line $($_.InvocationInfo.ScriptLineNumber)" -Type Error
                }

                ##################################################
                # Slut PATCHAR Existerande regel med ny irulekod #
                ##################################################
            }
        } 
        else
        {
            ###############################################
            # Skapa den nya iRulen i partition $partition #
            ###############################################
            $Resturi = "/mgmt/tm/ltm/rule"    
        
            if( [string]::IsNullOrEmpty( $iRuleKod ))
            {
                $JSONBody = @{
                    partition = "$partition";
                    name = $iRuleName;
                } | ConvertTo-Json -Compress
            }
            else #Kod bifogas i variablen = ska skrivas in i iRulen
            {
                $JSONBody = @{
                    partition = "$partition";
                    name = $iRuleName;
                    apiAnonymous = $irulekod;
                } | ConvertTo-Json -Compress
            }

            # Start jsonbugg-fix.
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
            # Slut jsonbugg-fix.


            try 
            {
                $Result = Invoke-F5RestMethod -Method POST -Uri "https://$LTMName$RestUri" -Body $JSONBody -F5Session $F5session.WebSession
                Set-LogMessage "Created iRule '$iRuleName' in partition '/$partition' [OK]" -Type Info

                $script:iRulename = $iRulename
            }
            catch
            {
                Set-LogMessage "Fel vid skapande av iRule: '$($_.Exception.Message)' `nOccured At: '$($_.InvocationInfo.ScriptName)' - Line $($_.InvocationInfo.ScriptLineNumber)" -Type Error
            }
        }

    } # Slut Process
    end
    {
    }
}
