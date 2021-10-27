#Create-CSR

function New-Csr {
    [CmdletBinding()]

    param(

    # Case-sensitive namn pÃ¥ partition
    [Parameter(Mandatory=$true)]
    [ValidateSet("yDMZ", "Common", "SCB-LAN", "iDMZ")]
    $Partition,

    #Common Name pÃ¥ certifikatet
    [Parameter(Mandatory = $true)]
    [string]$commonName,
    
    #[string]$subjectAlternativeName="",
    [Parameter(Mandatory=$false)]
    [string]$emailAddress="",
    
    [Parameter(Mandatory=$false)]
    [string]$adminEmailAddress=""

    )
    Begin
    {
        Set-LogMessage "Entering Function New-CSR"
    }
    Process
    {

        $Resturi = "/mgmt/tm/sys/crypto/key"
        #"challengePassword": "1234",
        $JSONBody = @{
            "name" = "/$partition/$commonName"
            "commonName" = "$commonName"
            "subjectAlternativeName" = "DNS:$commonName"
            "emailAddress" = $emailAddress
            "adminEmailAddress" = $adminEmailAddress
            "keySize" = "2048"
            "publicKeyType" = "RSA"
            "country" = "SE"
            "state" = "Nerike"
            "city" = "Orebro"
            "organization" = "Statistiska Centralbyran"
            "ou" = "ITDS"
            "options" = @(
                @{
                    "gen-csr" = "$commonName"
                 }
             )
        
        } | ConvertTo-Json #-Compress



        try 
        {
            Set-LogMessage "Skickar CSR till '$LTMName'..." -Type Info
            [SSLValidator]::OverrideValidation()
            $Result = Invoke-RestMethod -Method POST -Uri "https://$LTMName$RestUri" -Body $JSONBody -WebSession $F5session.websession -ContentType 'application/json' -ErrorAction Stop
            [SSLValidator]::RestoreValidation()
            
            Set-LogMessage "New CSR created OK"
            #Write-QALogMessage -Message $okMessage -Source "Catch-block in get-token" -TYPE INFO
            #Write-verbose $okMessage -Verbose

                try 
                {

                    $Resturi = "/mgmt/tm/util/bash/"

                    $JSONBody = @{
                        "command"  = "run"
                        "utilCmdArgs" = "-c 'tmsh list sys crypto csr /yDMZ/$commonName'"
                    } | ConvertTo-Json -Compress

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

  
                    [SSLValidator]::OverrideValidation()
                    $Result = Invoke-RestMethod -Method POST -Uri "https://$LTMName$RestUri" -Body $JSONBody -WebSession $F5session.websession -ContentType 'application/json' -ErrorAction Stop
                    [SSLValidator]::RestoreValidation()
                    $CSR = $result.commandResult.Substring(0, $result.commandResult.IndexOf('-----END CERTIFICATE REQUEST-----') +32)
                    $CSR | Set-Clipboard
                    $CSR
                    Set-LogMessage "CSR ovan har också kopierats till ditt clipboard - använd ctrl+v för att klistra in det till din CA." -Type Info 

                }
                catch
                {
                    Set-LogMessage "Fel vid läsning av CSR '$($_.Exception.Message)'" -Type Error
                }

        }
        catch
        {
            Set-LogMessage "$($_.errordetails | ConvertFrom-Json).message" -type Error
        }

    }
    End
    {
        Set-LogMessage "Exiting function NEW-CSR"
    }

}
#Slut New CSR

