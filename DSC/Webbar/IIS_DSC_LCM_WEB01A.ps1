function Set-LocalLCMProperties
{
    [cmdletbinding()]
    param(
        [parameter(mandatory=$true)]
        [string[]]$computername,
        [pscredential]$credz=(Get-Credential)
    )

    Begin
    {
        $expectedLocalDSCConfig=[ordered]@{
            ActionAfterReboot = "ContinueConfiguration"
            ConfigurationMode = "ApplyAndAutoCorrect"
            RebootNodeIfNeeded = $false
        }
        Write-Verbose "[ BEGIN ] Startar function $($MyInvocation.Mycommand)"  
    } #begin

    Process
    {
    #Initerar tom array för att förvara varje pscustomobject i foreachloopen
    $rapport=@()
    $Computername.foreach({
        
        [DscLocalConfigurationManager()]
        Configuration LCM {
            param([string[]]$Computername)
            Node $Computername {
                Settings {
                    ActionAfterReboot = $expectedLocalDSCConfig.ActionAfterReboot
                    ConfigurationMode = $expectedLocalDSCConfig.ConfigurationMode
                    RebootNodeIfNeeded =$expectedLocalDSCConfig.RebootNodeIfNeeded
                }
            }
        }
        #End Configuration

        try
        {
            $cimsession = (New-CimSession -ComputerName $_ -Credential $credz -ErrorAction Stop)
        }
        catch
        {
            $result="[Fail] $($_.Exception.Message)"
            return
        } 
        
        #TODO: Fixa till denna. Kräver en pssession och inte en cimsession.
        #invoke-command -session $psession { Set-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb -Value 2048 } | out-null
        
        try
        {
            $localdscconf = Get-DscLocalConfigurationManager -CimSession $cimsession -ErrorAction Stop | select $expectedLocalDSCConfig.foreach({ $_.keys })
            $computername=$_
            $action = "No action needed"
            $result = "Ok"

            #Kollar om värdena i $localdscconf som kommer från servern och värdena i $expectedLocalDSCConfig överensstämmer.
            # Annars fråga användaren vad den vill göra
            #https://stackoverflow.com/questions/27642169/looping-through-each-noteproperty-in-a-custom-object
            $localdscconf.PSObject.Properties | % {
                if( -not ($expectedLocalDSCConfig[$_.Name] -eq $_.value) )
                {
                    #$result = "LCM-Config on '$computername' does not match expected config"

                    if( (Read-Host "[Note] LCM-Config on '$computername' does not match expected config.`nWould you like me to change them for you (j/n)") -eq "j")
                    {
                        write-verbose "Modifying DSCconfig"
                        LCM -OutputPath $env:temp -Computername ($cimsession.computername) | out-null
                        Set-DscLocalConfigurationManager -Path $env:temp -CimSession $cimsession -Force
                        $result = "Updated by user"
                    }
                    else
                    {
                        $action = "Action needed - Local LCM-Config does not match expected config"
                        $result="LCMconfig aborted"
                    }
                }
            }
        }
        catch
        {
            $result = "[Error] $($_.Exception.Message)"
        }

        
        $rapport+=[PSCustomObject]@{
            Name     = $cimsession.ComputerName
            Result = $result
            Action = $action
        }
      
        Remove-CimSession -CimSession $cimsession
    })
    
    }
    End
    {
        $rapport
        Write-Verbose "[  END  ] Ending: $($MyInvocation.Mycommand)"
    } #end




}

Set-LocalLCMProperties -computername "kraschobang" ,web01a,web01b -verbose

# OM det inte funkar...
#
#Get-DscLocalConfigurationManager -CimSession (New-CimSession -ComputerName "web01a" -Credential $credz)
#Remove-DscConfigurationDocument -CimSession (New-CimSession -ComputerName "web01a" -Credential $credz) -Stage Pending -Force
