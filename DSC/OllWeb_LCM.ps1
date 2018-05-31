function Set-LocalLCMProperties
{
    [cmdletbinding()]
    param(
        [parameter(mandatory=$true)]
        [string[]]$computername #,
        #[pscredential]$credz=(Get-Credential tal008adm)
    )

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
                $result = "[Error] $($_.Exception.Message)"
            }

        }
        catch
        {
            $result="[Fail] could not connect to '$c'"
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

Set-LocalLCMProperties -computername webutv02 ,webtest03 -verbose #,kraschobang,web01a,web01b -verbose # ,web01a,web01b -verbose

# OM det inte funkar...
#
#Get-DscLocalConfigurationManager -CimSession (New-CimSession -ComputerName "web01a" -Credential $credz)
#Remove-DscConfigurationDocument -CimSession (New-CimSession -ComputerName "web01a" -Credential $credz) -Stage Pending -Force
