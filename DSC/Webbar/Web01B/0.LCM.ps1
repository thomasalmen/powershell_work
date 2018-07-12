if($PSVersionTable.PSVersion.Major -lt 5 ){Write-host "Detta script kräver Powershell version 5 eller senare!" -ForegroundColor Red ;break}
#$VerbosePreference="SilentlyContinue"
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

#$credz=(Get-Credential tal008adm)
$computername = "web01a"

$WantedLCMConfig=[ordered]@{
#$WantedLCMConfig=@{
    ActionAfterReboot = "ContinueConfiguration"
    ConfigurationMode = "ApplyAndAutoCorrect"
    RebootNodeIfNeeded = $false
    LCMState = "Idle"
}

$computername.ForEach({
    try 
    {
        $cimsession = (New-CimSession -ComputerName $_ -Credential $credz)
    }
    catch{ "Gick inte att skapa cimsession till $_ " }

    try
    {

        # TODO: Fixa till denna. Kräver en pssession och inte en cimsession.
        # invoke-command -ComputerName $computername -Credential $credz { Set-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb -Value 2048 } | out-null

        Write-verbose "Getting LCM Configuration data from $($cimsession.computername.toUpper())"
        $RemoteLCMConfig =  Get-DscLocalConfigurationManager -CimSession $cimsession -ErrorAction Stop | select $WantedLCMConfig.foreach({ $_.keys })
        $RemoteLCMConfigTemp=[ordered]@{}
        $RemoteLCMConfig.PSObject.Properties | % {
            $RemoteLCMConfigTemp.Add( $($_.name) , $($_.value) )
        }
        # Puts the result back in $RemoteLCMConfig so we can continue using it.
        $RemoteLCMConfig = $RemoteLCMConfigTemp

    }
    catch {}
    
    #Gör om hastables till custom objects
    $obj = [pscustomobject]@{}
    $obj | Add-Member -MemberType NoteProperty -Name "Computername" -Value $cimsession.ComputerName
    #$obj | Add-Member -MemberType 
    $obj.to


    $obj1 = [pscustomobject]$WantedLCMConfig
    $obj2 = [pscustomobject]$RemoteLCMConfig
    $obj3 = [pscustomobject]$obj1
    #$obj2
    #$obj1 = New-Object -TypeName PSCustomObject -Property $WantedLCMConfig
    #$obj2 = New-Object -TypeName PSCustomObject -Property 


    

    

            #Skriv ett objekt till pipeline
            
            #[pscustomobject]@{
            #     WantedConf = {
            #     
            #        $WantedLCMConfig.GetEnumerator() | ForEach-Object {$CustomObject = "" | Select-Object Name,ID
            #            $CustomObject.Name = $_.key
            #            $CustomObject.ID = $_.value
            #            $CustomObject
            #        }
            #     }
            #     RemoteConf = $WantedLCMConfig
            #}  | ft -AutoSize
             
    #Write-Output "Remoteconf: $($RemoteLCMConfig | out-string)"
    #Write-Output "WantedLCMConfig: $($WantedLCMConfig | out-string)"

})

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
