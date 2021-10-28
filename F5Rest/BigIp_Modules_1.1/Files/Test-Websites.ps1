<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>

function Test-WebSites
{

    [CmdletBinding(SupportsShouldProcess)] #adds WhatIf and Confirm parameters
    
    param(
        [Parameter(Mandatory=$false)][System.Management.Automation.PSCredential]$NTLMCredentials,
        [Parameter(Mandatory=$false)][System.Management.Automation.PSCredential]$MonaCredentials,
        [Parameter(Mandatory=$false)][System.Management.Automation.PSCredential]$InsamlingCredentials,
        $F5session=$script:F5session  
    )
    begin
    {
    
        Set-LogMEssage "Entering Function Test-WebSites" -Type debug
    
        try
        {
            if( [string]::IsNullOrEmpty($NTLMCredentials) )
            {
                $Creds = Get-Credential -ErrorAction stop -Message "Ange de credentials som ska användas för NTLM-Autentisering"
                $secpassword = ConvertTo-SecureString $Creds.GetNetworkCredential().password -AsPlainText -Force
                $NTLMCredentials = New-Object System.Management.Automation.PSCredential($Creds.UserName,$secpassword)
                Set-LogMessage "Using '$($NTLMCredentials.UserName)' from inputbox as username."
            }
            else
            {
                Set-LogMessage "Credentials found in parameter `$NTLMCredentials - Using '$($NTLMCredentials.UserName)' as username."
            }

        }
        catch
        {
            $NTLMCredentials = $F5session.Credentials
            Set-LogMessage "No NTLM-credentials found in parameter `$NTLMCredentials - Using '$($NTLMCredentials.UserName)' as username."
        }
        
        #"CREDZ = "
        #$NTLMCredentials.UserName
        #$NTLMCredentials.GetNetworkCredential().password
        #break
    }
    process
    {
        $websites = [ordered]@{
       
            
            
            #Start sidor med Anonym inloggning
            "Anonymous" = [ordered]@{
            
               "Hitta Statistik" = @{
                    URL = "https://www.scb.se/hitta-statistik/publiceringskalendern/"
                    WantedText = "N&#228;r publiceras statistiken?"
                }
                "api.scb.se" = @{
                    URL = "https://api.scb.se"
                    WantedText = "api.scb.se"
                }

                "www.scb.se" = @{
                    URL = "https://www.scb.se"
                    WantedText = "Statistikmyndigheten SCB"
                }

                "OWA" = @{
                    URL = "https://owa.scb.se/"
                   # WantedText = "Statistikmyndigheten SCB"
                }
            }
            #Slut sidor med Anonym inloggning
            
           
           
            #Start sidor med NTLM-inloggning utan bigip
             "NTLM" = [ordered]@{
                
                "Inblick" = @{
                    URL = "https://inblick.scb.intra"
                    WantedText = "Inblick - Startsida"
                }

                "Driftportalen" = @{
                    URL = "https://driftportalen/SitePages/Startsida.aspx"
                    WantedText = "Driftportalen - Startsida"
                }
            }
            #Slut Sidor med NTLM-inloggning
            
         

            
            #Start sidor med APM-Formsinloggning
            "Forms" = [ordered]@{

                "Horizon" = @{
                    URL = "https://horizon.scb.se"
                    UsernameField = "adusername"
                    PasswordField = "adpassword"
                    Username = $NTLMCredentials.UserName
                    Password = $NTLMCredentials.GetNetworkCredential().password
                    WantedText = "F5 Dynamic Webtop"
                    MFA = $true
                    MFAType = "SMS"
                    MFAValueInAPM = "session.otp.assigned.val"
                    MFAInputFieldName="OTPpassword"
                }
                
                "Insamling" = @{
                    URL = "https://www.insamling.scb.se"
                    Username = $InsamlingCredentials.UserName
                    Password = $InsamlingCredentials.GetNetworkCredential().Password
                    UsernameField = "username"
                    PasswordField = "password"
                    WantedText = "Val 1 - SCB"
                }

                "Inblick från internet" = @{
                    URL = "https://inblick.scb.se"
                    UsernameField = "username"
                    PasswordField = "password"
                    Username = $NTLMCredentials.UserName
                    Password = $NTLMCredentials.GetNetworkCredential().password
                    WantedText = "Inblick - Startsida"
                }
                

                
                "MONA" = @{
                    URL = "https://login.mona.scb.se"
                    MFA = $true
                    MFAType = "TOTP"
                    MFAValueInAPM = "session.custom.ga.decrypted_secret"
                    MFAInputFieldName="ga_code_attempt"
                    UsernameField = "username"
                    PasswordField = "password"
                    Username = $MonaCredentials.Username
                    Password = $MonaCredentials.GetNetworkCredential().Password
                    WantedText = "V\\u00e4lkommen till MONA" #Ä In unicode
                }

            }   #Slut sidor med Formsinloggning
            

        } | ConvertTo-Json





        $websites = ConvertFrom-Json $websites 

        $result = foreach( $LogonTypeProperty in @($websites.psobject.properties | where-object {$_.MemberType -eq "NoteProperty"}) )
        {

            foreach( $childProperty in @($LogonTypeProperty.Value.psobject.properties | where-object {$_.MemberType -eq "NoteProperty"}) )
            {

                $output = [ordered]@{
                    'Name'                  = $null
                    'LoginType'             = $null
                    'MFAType'               = $null
                    'UserName'              = $null
                    'Info'                  = $null
                    'TestResultat'          = $null
                    'TOTP'                  = $null
                }

                $output.Name = $childProperty.Name
                if( [string]::IsNullOrEmpty( $childProperty.value.UserName )) { $output.UserName = "None" } else { $output.UserName = $childProperty.value.UserName }
                $output.LoginType = $LogonTypeProperty.name
                if( [string]::IsNullOrEmpty( $childProperty.value.MFAType )) { $output.MFAType = "None" } else { $output.MFAType = $childProperty.value.MFAType }

    
                #Region Web requests
                if($LogonTypeProperty.name -eq "FORMS") #Först GET - följ redirect POST
                {

                    if( $childProperty.value.UsernameField -eq $null -or $childProperty.value.PasswordField -eq $null ) 
                    {
                        $output.UserName = " n/a "
                    }
                    elseif($childProperty.value.UserName -eq $null -or $childProperty.value.Password -eq $null)
                    {
                        $output.UserName = " n/a "
                    }
                    else
                    {
                        $body=@{
                            $($childProperty.value).UsernameField = "$($childProperty.value.UserName)"
                            $($childProperty.value).PasswordField = "$($childProperty.value.PassWord)"
                        }
                    }

                    try
                    {

                        $WebResponse = invoke-webrequest -uri $childProperty.value.URL -Method GET -SessionVariable 'FormsWebSession' -ErrorAction Ignore

                        #APM ger en 200 oavsett om det är fel el rätt user/pass
                        # Vi POST'ar username/password om de finns med i variablerna för denna sajt.
                        if($WebResponse.statuscode -eq 200)
                        {
                            try
                            {
                                $WebResponse = invoke-webrequest -uri $WebResponse.BaseResponse.responseuri.AbsoluteUri -Method Post -Body $body -websession $FormsWebSession -ErrorAction Ignore

                                #Plocka ut APM-cookies om det finns nån. För att användas i REST-anrop mot bigip
                                $Cookie = $null
                                foreach ($Cookie in $FormsWebSession.Cookies.GetCookies($childProperty.value.URL) ) { 

                                    if($cookie.name -eq "LastMRH_Session")
                                    {
                                        $LastMRH_Session = $cookie.value
                                    }

                                }
                    
                                if( $childProperty.value.MFA -eq $true )
                                {
                                    #################################################
                                    # Är MFA av typen TOTP kan vi läsa det i bigip. #
                                    #################################################

                                    # Anropa BigIp via REST för att hämta ut TOTP baserat på vilket sessionsID användaren har.
                                    $SharedSecret = Get-APMMultiFactorValue($LastMRH_Session)
                                    #write-debug "SharedSecret = $SharedSecret"

                                    # Vi har en Shared secret - Nu kan korrekt TOTP-Kod hämtas från funktionen GET-OTP
                                    # Därefter kan TOTP-koden POST'as till OTP-fältet i APM.
                                    if($childProperty.value.MFAType -eq "SMS")
                                    {
                                        # Anropa BigIp via REST för att hämta ut SMS-OTP baserat på vilket sessionsID användaren har.
                                        $OTPCode = Get-APMMultiFactorValue($LastMRH_Session)
                                    }
                                    if($childProperty.value.MFAType -eq "TOTP")
                                    {
                                        $OTPCode = Get-Otp -SECRET $SharedSecret -LENGTH 6 -WINDOW 30
                                    }
                                    #write-debug "TOTPCode = $TOTPCode"
                                    $output.TOTP = $OTPCode

                                    #POST till TOTP-fält i BigIp
                                    $body=@{
                                        $($childProperty.value.MFAInputFieldName) = $OTPCode
                                    }

                                    try
                                    {
                                        $WebResponse = invoke-webrequest -uri $WebResponse.BaseResponse.responseuri.AbsoluteUri -Method Post -Body $body -websession $FormsWebSession   -ErrorAction Ignore 
                                    
                                        if($childProperty.value.WantedText -ne $null)
                                        {
                                            if($WebResponse -match "$($childProperty.value.WantedText)")
                                            {
                                                #Texten fanns på websidan. Mer än så kan vi inte göra, utan flaggar sidan som OK.
                                                $output.Info  = "Wanted Text '$($childProperty.Value.WantedText)' found"
                                                $output.Testresultat = "[OK]"
                                            }
                                        }
                                        else
                                        {
                                            $output.Info = "Wanted Text '$($childProperty.Value.WantedText)' NOT found"
                                            $output.Testresultat = "[Unknown]"   
                                        }

                                    }
                                    catch
                                    {
                                        "Fel vid anrop till '$($WebResponse.BaseResponse.responseuri.AbsoluteUri)' "
                                    }

                                }
                                else
                                {
                                    if($WebResponse -match $($childProperty.Value.WantedText ))
                                    {
                                        #Texten fanns, så då är målet nått här.
                                        $output.Info = "Wanted Text '$($childProperty.Value.WantedText)' found"
                                        $output.Testresultat = "[OK]"
                                    }
                                    else
                                    {
                                        $output.Info = "Wanted Text '$($childProperty.Value.WantedText)' NOT found"
                                        $output.Testresultat = "[Unknown]"
                                    }
                                }
                            }#Slut try
                            catch
                            {
                                $output.Info = $error[0].Exception.Message
                            }
                        }
                    }
                    catch
                    {
                        $output.TestResultat = "[Fail]"
                        $output.Info = "Error - kontrollera att '$($childProperty.value.URL) är rättstavat' `n" +  $error[0].Exception.Message
                    }

               }
               else
               {
                    # Det var ingen APM-FORMS, utan vanliga websidor
                    try
                    {
                        $WebResponse = Invoke-WebRequest -Uri $childProperty.value.URL -ErrorAction Stop -Method GET -Credential $WebSiteCredentials
                        if($WebResponse.StatusCode -eq 200)
                        {

                            if($WebResponse -match "$($childProperty.value.WantedText)")
                            {
                                $output.Info = "Wanted Text '$($childProperty.Value.WantedText)' found"
                                $output.Testresultat = "[OK]"
                            }
                            else
                            {
                                $output.Info = "Wanted Text '$($childProperty.Value.WantedText)' NOT found"
                                $output.Testresultat = "[Unknown]"
                            }
                        }
                    }
                    catch
                    {
                        $output.Info = "$($WebResponse.StatusCode) $($WebResponse.StatusDescription)"
                        $output.Testresultat = "[FAIL] - $($_.Exception.Message)"
                    }

               } #endregion

            [pscustomobject]$output
            }
        }
        $result | ft -AutoSize


    }
    end
    {
        Set-LogMEssage "Exiting Function Test-WebSites" -Type debug
    }
}






















#https://gist.github.com/jonfriesen/234c7471c3e3199f97d5
#requires -version 2
<#
.SYNOPSIS
  Time-base One-Time Password Algorithm (RFC 6238)
.DESCRIPTION
  This is an implementation of the RFC 6238 Time-Based One-Time Password Algorithm draft based upon the HMAC-based One-Time Password (HOTP) algorithm (RFC 4226). This is a time based variant of the HOTP algorithm providing short-lived OTP values. 
.NOTES
  Version:        1.0
  Author:         Jon Friesen
  Creation Date:  May 7, 2015
  Purpose/Change: Provide an easy way of generating OTPs
  
#>
 
function Get-Otp($SECRET, $LENGTH, $WINDOW){

    $enc = [System.Text.Encoding]::UTF8
    $hmac = New-Object -TypeName System.Security.Cryptography.HMACSHA1
    $hmac.key = Convert-HexToByteArray(Convert-Base32ToHex(($SECRET.ToUpper())))
    $timeBytes = Get-TimeByteArray $WINDOW
    $randHash = $hmac.ComputeHash($timeBytes)
    
    $offset = $randhash[($randHash.Length-1)] -band 0xf
    $fullOTP = ($randhash[$offset] -band 0x7f) * [math]::pow(2, 24)
    $fullOTP += ($randHash[$offset + 1] -band 0xff) * [math]::pow(2, 16)
    $fullOTP += ($randHash[$offset + 2] -band 0xff) * [math]::pow(2, 8)
    $fullOTP += ($randHash[$offset + 3] -band 0xff)

    $modNumber = [math]::pow(10, $LENGTH)
    $otp = $fullOTP % $modNumber
    $otp = $otp.ToString("0" * $LENGTH)
    return $otp
}

function Get-TimeByteArray($WINDOW) {
    $span = (New-TimeSpan -Start (Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0) -End (Get-Date).ToUniversalTime()).TotalSeconds
    $unixTime = [Convert]::ToInt64([Math]::Floor($span/$WINDOW))
    $byteArray = [BitConverter]::GetBytes($unixTime)
    [array]::Reverse($byteArray)
    return $byteArray
}

function Convert-HexToByteArray($hexString) {
    $byteArray = $hexString -replace '^0x', '' -split "(?<=\G\w{2})(?=\w{2})" | %{ [Convert]::ToByte( $_, 16 ) }
    return $byteArray
}

function Convert-Base32ToHex($base32) {
    $base32chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    $bits = "";
    $hex = "";

    for ($i = 0; $i -lt $base32.Length; $i++) {
        $val = $base32chars.IndexOf($base32.Chars($i));
        $binary = [Convert]::ToString($val, 2)
        $staticLen = 5
        $padder = '0'
            # Write-Host $binary
        $bits += Add-LeftPad $binary.ToString()  $staticLen  $padder
    }


    for ($i = 0; $i+4 -le $bits.Length; $i+=4) {
        $chunk = $bits.Substring($i, 4)
        # Write-Host $chunk
        $intChunk = [Convert]::ToInt32($chunk, 2)
        $hexChunk = Convert-IntToHex($intChunk)
        # Write-Host $hexChunk
        $hex = $hex + $hexChunk
    }
    return $hex;

}

function Convert-IntToHex([int]$num) {
    return ('{0:x}' -f $num)
}

function Add-LeftPad($str, $len, $pad) {
    if(($len + 1) -ge $str.Length) {
        while (($len - 1) -ge $str.Length) {
            $str = ($pad + $str)
        }
    }
    return $str;
}


#Get-Otp -SECRET "VGY4D7OC6IRNMAQT" -LENGTH 6 -WINDOW 30




function Get-APMMultiFactorValue($APMSession)
{
$F5session=$script:F5session  
    $Resturi = "/mgmt/tm/util/bash/"

    $JSONBody = @{
        "command"  = "run"
        "utilCmdArgs" = "-c ' sessiondump --sid $APMSession | grep -i $($childproperty.Value.MFAValueInAPM) | awk \'{print `$3}\' '"
    } | ConvertTo-Json -Compress

    # Caused by a bug in ConvertTo-Json https://windowsserver.uservoice.com/forums/301869-powershell/suggestions/11088243-provide-option-to-not-encode-html-special-characte
    # '<', '>', ''' and '&' are replaced by ConvertTo-Json to  , \\u003e, \\u0027, and \\u0026. The F5 API doesn't understand this. Change them back.
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
    #Slut jsonbugg.

    $Resturi = "/mgmt/tm/util/bash/"
    try
    {
        $result = Invoke-F5RestMethod -Method POST  -Body $JSONBody -Uri "https://$LTMName$RestUri" -F5Session $F5session.WebSession
        $SharedSecret = $result.commandResult -replace "`n" #AWK lägger till ett enterslag som måste tas bort.

        if( (($SharedSecret).Length -eq 16) -or (($SharedSecret).Length -eq 6) )
        {
            $SharedSecret
        } 
    }
    catch

    {
      $output.TestResultat = "[Fail]"
      $output.Info = "Fel - " + $_.Exception.Response
    }
}

#endregion

