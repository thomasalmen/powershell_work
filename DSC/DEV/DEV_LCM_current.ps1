if($PSVersionTable.PSVersion.Major -lt 5 ){Write-host "Detta script kräver Powershell version 5 eller senare!" -ForegroundColor Red ;break}
$VerbosePreference="SilentlyContinue"

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

#$credz=(Get-Credential win2016temp\administrator)
#$credz=(Get-Credential tal008adm)
$computername = "kraschobang","win2016temp.orebroll.se"

$WantedLCMConfig=[ordered]@{
    ActionAfterReboot = "ContinueConfiguration"
    ConfigurationMode = "ApplyAndAutoCorrect"
    RebootNodeIfNeeded = $false
    LCMState = "Idle"
}

$rapport=@()
$computername.ForEach({
$status = "OK"
    try 
    {
        $cimsession = (New-CimSession -ComputerName $_ -Credential $credz -ErrorAction Stop -ev e )
    }
    catch{ 
        if($e)
        {
            $status = "Gick inte att skapa cimsession  " ;
        }
    }

    try
    {
        
        if($cimsession)
        {
            # TODO: Fixa till denna. Kräver en pssession och inte en cimsession.
            # invoke-command -ComputerName $computername -Credential $credz { Set-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb -Value 2048 } | out-null

            Write-verbose "Getting LCM Configuration data from $($cimsession.computername.toUpper())"
            $RemoteLCMConfig =  Get-DscLocalConfigurationManager -CimSession $cimsession -ErrorAction Stop -EV E | select $WantedLCMConfig.foreach({ $_.keys })
            if($RemoteLCMConfig)
            {
                $RemoteLCMConfigTemp=[ordered]@{}
                $RemoteLCMConfig.PSObject.Properties | % {
                    $RemoteLCMConfigTemp.Add( $($_.name) , $($_.value) )
                }
                # Puts the result back in $RemoteLCMConfig so we can continue using it.
                $RemoteLCMConfig = $RemoteLCMConfigTemp
                #$temp = New-Object -TypeName PSCustomObject -Property $RemoteLCMConfig 
            }
        }

    }
    catch { 
        if($e)
        {
            $status = "Nåt gick fel";
        }
    }
    
   
    $rapport+=(
        @([pscustomobject]@{
         #TEMP = $temp
         Computername = $_
         Status = $status
         Konfiguration = "WantedConf"
         ActionAfterReboot = $WantedLCMConfig.ActionAfterReboot
         ConfigurationMode = $WantedLCMConfig.ConfigurationMode
         RebootNodeIfNeeded = $WantedLCMConfig.RebootNodeIfNeeded
         LCMState = $WantedLCMConfig.LCMState
         
        },
        [pscustomobject]@{
         Konfiguration = "Remoteconf"
         ActionAfterReboot = $RemoteLCMConfig.ActionAfterReboot
         ConfigurationMode = $RemoteLCMConfig.ConfigurationMode
         RebootNodeIfNeeded = $RemoteLCMConfig.RebootNodeIfNeeded
         LCMState = $RemoteLCMConfig.LCMState     
        })
    )
    try { Remove-CimSession -CimSession $cimsession -ErrorAction SilentlyContinue } catch {}
    $RemoteLCMConfig = ""
})

$rapport | ft -AutoSize
break






<#
if( (Read-Host "Vill du fortsätta?","(j)" ) -eq "j".ToLower() )
{

# LCM Configuration
[DscLocalConfigurationManager()]
Configuration LCM {
    param([string[]]$Computername)
    Node $Computername {
        Settings {
            ActionAfterReboot = $WantedLCMConfig.ActionAfterReboot
            ConfigurationMode = $WantedLCMConfig.ConfigurationMode
            RebootNodeIfNeeded =$WantedLCMConfig.RebootNodeIfNeeded
        }
    }
}
#End LCM Configuration
if(LCM -Computername $computername -OutputPath $env:TEMP -Verbose)
{
    Set-DscLocalConfigurationManager -Path $env:TEMP -ComputerName $computername -Verbose -Credential $credz
}
else
{
    "Nåt gick fel. Gör och och gör rätt!"
}
#Get-DscConfigurationStatus -CimSession $cimsession -ErrorAction Stop
#Test-DscConfiguration -CimSession $cimsession -Detailed -ErrorAction Stop



}
#>
