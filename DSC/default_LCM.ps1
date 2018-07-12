

function Get-LocalLCMProperties
{

    [cmdletbinding()]
    param(
        [parameter(mandatory=$true)]
        [string[]]$computername #,
        #[pscredential]$credz=(Get-Credential tal008adm)
    )

    Begin
    {
        Write-Verbose "[ BEGIN ] Startar function $($MyInvocation.Mycommand)"  
    }
    Process
    {
        $WantedLCMConfig=[ordered]@{
            ActionAfterReboot = "ContinueConfigurationx"
            ConfigurationMode = "ApplyAndAutoCorrecty"
            RebootNodeIfNeeded = $false
            LCMState = "Idle"
        }
        

    

    #Initerar tom array för att förvara varje pscustomobject i foreachloopen
    $rapport=@()
    foreach($c in $computername)
    {
    $entry = ($entry = " " | select-object HostName, OS, WantedConfig, RemoteConfig) 
    $entry.Hostname = "$c"
    $entry.WantedConfig = $WantedLCMConfig.GetEnumerator()
        try
        {
            $cimsession = (New-CimSession -ComputerName $c -Credential $credz -ErrorAction Stop)

            #TODO: Fixa till denna. Kräver en pssession och inte en cimsession.
            #invoke-command -session $psession { Set-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb -Value 2048 } | out-null
        
            try
            {
                
                $RemoteLCMConfig = Get-DscLocalConfigurationManager -CimSession $cimsession -ErrorAction Stop | select $ExpectedLCMConfig.foreach({ $_.keys })
                $entry.RemoteConfig = $RemoteLCMConfig
                $entry.os = Get-CimInstance Win32_OperatingSystem -CimSession $cimsession | Select-Object Caption
                #$entry.OS = $entry.OS.Replace("  "," ")
                #$entry.OS = $entry.OS.Replace("<%-accuracy>","") #Sometimes no osmatch.
			    #$entry.OS = $entry.OS.Trim()

                #Make a temp variable of $RemoteLCMConfig which now contains a cim-instance objekt and convert it into a hashtable
                $RemoteLCMConfigTemp=[ordered]@{}
                
                #https://stackoverflow.com/questions/27642169/looping-through-each-noteproperty-in-a-custom-object
                $RemoteLCMConfig.PSObject.Properties | % {
                    $RemoteLCMConfigTemp.Add( $($_.name) , $($_.value) )
                }

                # Puts the result back in $RemoteLCMConfig so we can continue using it.
                $RemoteLCMConfig = $RemoteLCMConfigTemp

                #Now, lets compare some stuff in the two hashtables
                $RemoteLCMConfig.GetEnumerator() | % { 
                
                    $compareKey = $_.key
                    $compareValue = $_.value
                    #Om en eller flera värden inte matchar mellan önskad och remote config så flaggar vi fel.
                    if( ! ( $compareValue -eq $WantedLCMConfig[$compareKey] ) )
                    {
                        #$mismatch += "$compareValue och $($ExpectedLCMConfig[$compareKey]) matchade inte"
                        #Write-Verbose "$compareValue och $($ExpectedLCMConfig[$compareKey]) matchade inte"
                        #$mismatch += [PSCustomObject]@{
                        #    Wanted = "$compareValue"
                        #    Remote = "$($ExpectedLCMConfig[$compareKey])"
                        #}
                            #$result.Add( @{Wanted= $($ExpectedLCMConfig[$compareKey])} ; @{ Received = $($compareValue) })
                        #}
                        $entry.mismatch += @( @{ Miss= "$compareValue och $($WantedLCMConfig[$compareKey]) matchade inte" } )
                    }
                    #$mismatch
                    #$action += $mismatch

                } 
            }
            catch
            {
                $result = "$($_.Exception.Message)"
                Write-verbose $result
            }
        }
        catch
        {
            $result="Could not connect to '$c'"
            #Write-verbose $result
            
        } 

        $rapport+=$entry
    }
    }
    End
    {
    #$entry
        $rapport #out | ft -AutoSize
        Write-Verbose "[  END  ] Ending: $($MyInvocation.Mycommand)"
    }
}



function Set-LocalLCMProperties
{

    [cmdletbinding()]
    param(
        [parameter(mandatory=$true)]
        [string[]]$computername #,
        #[pscredential]$credz=(Get-Credential tal008adm)
    )
"oops.."
break
    Begin
    {
        if($PSVersionTable.PSVersion.Major -lt 5 ){Write-host "Detta script kräver Powershell version 5 eller senare!" -ForegroundColor Red ;break}
        try
        {
            $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = New-Object Security.Principal.WindowsPrincipal -ArgumentList $identity
            if(! ($principal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator ) ) -eq $true) { return "Detta script måste köras som administrator!"}
        }
        catch
        {
            throw "Failed to determine if the current user has elevated privileges. The error was: '{0}'." -f $_
        }

        $ExpectedLCMConfig=@{
            ActionAfterReboot = "ContinueConfiguration"
            ConfigurationMode = "ApplyAndAutoCorrect"
            RebootNodeIfNeeded = $false
            LCMState = "Idle"
        }
        Write-Verbose "[ BEGIN ] Startar function $($MyInvocation.Mycommand)"  
    } #begin

    Process
    {
    #Initerar tom array för att förvara varje pscustomobject i foreachloopen
    $rapport=@()

    #[string[]]$sune="berit","kurt" ; $sune.foreach({ $_ })

    #$Computername.foreach({
    foreach($c in $computername)
    {
        [DscLocalConfigurationManager()]
        Configuration LCM {
            param([string[]]$computername)
            Node $computername {
                Settings {
                    ActionAfterReboot = $LCMExpectedConfig.ActionAfterReboot
                    ConfigurationMode = $LCMExpectedConfig.ConfigurationMode
                    RebootNodeIfNeeded =$LCMExpectedConfig.RebootNodeIfNeeded
                }
            }
        }
        #End Configuration
        
        try
        {
            $cimsession = (New-CimSession -ComputerName $c -Credential $credz -ErrorAction Stop)

            #TODO: Fixa till denna. Kräver en pssession och inte en cimsession.
            #invoke-command -session $psession { Set-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb -Value 2048 } | out-null
        
            try
            {
                $RemoteLCMConfig = Get-DscLocalConfigurationManager -CimSession $cimsession -ErrorAction Stop | select $ExpectedLCMConfig.foreach({ $_.keys })
                $osInfo = Get-CimInstance Win32_OperatingSystem -CimSession $cimsession | Select-Object Caption, Version
                
                $computername=$c
                $action = ""
                $result = "Ok"

                #Kollar om värdena i $localdscconf som kommer från servern och värdena i $expectedLocalDSCConfig överensstämmer.
                # Annars fråga användaren vad den vill göra
                #https://stackoverflow.com/questions/27642169/looping-through-each-noteproperty-in-a-custom-object
                $RemoteLCMConfig.PSObject.Properties | % {
                "S_ = $($_.name) = $($_.value)"

                "P"
                #$ExpectedLCMConfig[$_.name] #Värdet i nyckeln. Inte nyckelnamnet

                #$ExpectedLCMConfig.containskey($_.name)
                #$ExpectedLCMConfig.item($_.name)
                $ExpectedLCMConfig.keys[$_.name]
                # |  select keys,values
                break
                    <#
                    if( -not ($ExpectedLCMConfig[$_.Name] -eq $_.value) )
                    {
                        write-warning "LCM-Config on '$computername' does not match expected config: '$($ExpectedLCMConfig[$_.Name]) = $($_.value)'"
                        
                        #"LCMExpectedConfig.keys"
                        #$LCMExpectedConfig.keys
                        #"OO"
                        #$LCMExpectedConfig.keys[$_.name]
                        #$_.name
                        #$_.value

                        #"LCMExpectedConfig.values"
                        #$LCMExpectedConfig.values


                        #$LCMExpectedConfig.keys[$_]
                        #"Z"
#                        $LCMExpectedConfig[$_.name].values
                        

                        if( (Read-Host "Would you like to change '$($ExpectedLCMConfig[$_.Name]) =  ' to '$($ExpectedLCMConfig[$_.Name])=$($_.value)'  (j/n)") -eq "j")
                        {
                            write-verbose "Modifying DSCconfig"
                            LCM -OutputPath $env:temp -Computername ($cimsession.computername) | out-null
                            Set-DscLocalConfigurationManager -Path $env:temp -CimSession $cimsession -Force
                            $action = "No action needed"
                            $result = "Updated by user"
                        }
                        else
                        {
                            $action = "Action needed - Local LCM-Config does not match expected config"
                            $result="LCMconfig aborted"
                        }
                    }
                    #>
                }
                $lcmconfigafter = Get-DscLocalConfigurationManager -CimSession $cimsession | select $ExpectedLCMConfig.foreach({ $_.keys })
               # Remove-CimSession -CimSession $cimsession
            }
            catch
            {
                $result = "$($_.Exception.Message)"
            }

        }
        catch
        {
            $result="Could not connect to '$c'"
            Write-verbose $result
        } 
        
        $rapport+=[PSCustomObject]@{
            Name     = $cimsession.ComputerName
            Result = $result
            OS = $osinfo
            Action = $action
            ExpectedLCMConfig = $ExpectedLCMConfig 
            RemoteLCMConfig = $RemoteLCMConfig
            LCMConfigAfter = $lcmconfigafter
        }

    }
    
    }
    End
    {
        $rapport
        Write-Verbose "[  END  ] Ending: $($MyInvocation.Mycommand)"
    } #end




}

Get-LocalLCMProperties -computername kraschobang,webtest03,webtest02,webint05 -verbose #,kraschobang,web01a,web01b -verbose # ,web01a,web01b -verbose
#Set-LocalLCMProperties -computername webutv02 ,webtest03 -verbose #,kraschobang,web01a,web01b -verbose # ,web01a,web01b -verbose

# OM det inte funkar...
#
#Get-DscLocalConfigurationManager -CimSession (New-CimSession -ComputerName "web01a" -Credential $credz)
#Remove-DscConfigurationDocument -CimSession (New-CimSession -ComputerName "web01a" -Credential $credz) -Stage Pending -Force
