
#$credz=(Get-Credential tal008adm)
$computername = "kraschobang" , "webtest02"

#$WantedLCMConfig=[ordered]@{
$WantedLCMConfig=@{
    ActionAfterReboot = "ContinueConfiguration"
    ConfigurationMode = "ApplyAndAutoCorrect"
    RebootNodeIfNeeded = $false
    LCMState = "Idle"
}

$rapport=@()
$computername.ForEach({

    $hash = [ordered]@{}
    $hash.add( "Computername", $_)
    try 
    {
        $cimsession = (New-CimSession -ComputerName $_ -Credential $credz)
    }
    catch{ "Gick inte att skapa cimsession till $_ " }

    try
    {
        Write-verbose "Getting LCM Configuration data from $($cimsession.computername.toUpper())"
        $RemoteLCMConfig =  Get-DscLocalConfigurationManager -CimSession $cimsession -ErrorAction Stop | select $WantedLCMConfig.foreach({ $_.keys })
    
        #$RemoteLCMConfigTemp=[ordered]@{}
        $RemoteLCMConfigTemp=@{}
        $RemoteLCMConfig.PSObject.Properties | % {
            $RemoteLCMConfigTemp.Add( $($_.name) , $($_.value) )
        }
        # Puts the result back in $RemoteLCMConfig so we can continue using it.
        $RemoteLCMConfig = $RemoteLCMConfigTemp
    }
    catch{
        write-output "LCM på '$($cimsession.computername)' svarade inte"
        return
    }
    $rapport += New-Object -TypeName psobject -Property $hash

    $mismatch=@()
    $WantedLCMConfig.GetEnumerator() | where Key -in $RemoteLCMConfig.Keys | % {

       # write-output "Testar om '$($_.Key )=$($_.value)'"
        if( -not ($_.value -eq $RemoteLCMConfig[$_.key]) )
        {
            $mismatch += New-Object -TypeName PSObject -Property @{ Nomatch = $RemoteLCMConfig[$_.key] } 
        }
        $rapport += $mismatch
    }
    
    $rapport

  return
    # Störigt med getenumerator()
    # Levererar både nyckel och värde i loopen så man måste använda properties key och value


<#
Try {
    Write-Host "Getting DSC Configuration data from $($cimsession.computername.toUpper())" -ForegroundColor Cyan
    Write-Verbose "[$this] Getting configuration details"
    $config = Get-DscConfiguration -CimSession $cimsession -ErrorAction stop
    } 
Catch {
    Write-Output "$($cimsession.computername) Inte konfad för dsc"
   #Throw "Fel $_"
   #exit if there was an error getting the configuration
   return
}
#>

if ($RemoteLCMConfig) {
    #Write-output "[$this] Getting Test results"


##################################################





##################################################
return "klar!"

    try{
        $status = Get-DscConfigurationStatus -CimSession $cimsession -ErrorAction Stop
    }
    catch { "No DSC config found on $($cimsession.ComputerName)" ; return}

    if($status)
    {
        try{
            $test = Test-DscConfiguration -CimSession $cimsession -Detailed -ErrorAction Stop
        }
        catch {"Fail or no DSC Config"}
    }

#    "Test" 
#    $test

#    "Status"
#    $status 

    $noncompliant = $test.ResourcesNotInDesiredState.ResourceID
    #$server = $RemoteLCMConfig.PSComputerName.ToUpper()
#    $server = $cimsession.ComputerName.ToUpper()
    $IP = ($status.IPV4Addresses).where({$_ -notmatch "^127"}) -join ","
    $mode = $status.MetaConfiguration.RefreshMode
   
    #parse the metadata property string and turn it into an object
    $a = $status.MetaData.split(";").trim() | where {$_}
    #$hash = [ordered]@{

    $hash.add( "IPAddress", $IP)
    $hash.add( "Mode",  $mode)
    $hash.add( "ConfigurationMode", $status.MetaConfiguration.ConfigurationMode)
    $hash.add( "ConfigurationFrequency", $status.MetaConfiguration.ConfigurationModeFrequencyMins)
    $hash.add( "RefreshFrequency", $status.MetaConfiguration.RefreshFrequencyMins)
    $hash.add( "InDesiredState", $test.InDesiredState)     
    $hash.add( "RemoteLCMConfig", $RemoteLCMConfig)     
     #}
    foreach ($line in $a) {
        $split = ($line -split ":").trim()
        $hash.add($split[0],$split[1])
    }
    $meta = New-Object -TypeName PSObject -Property $hash
    #>
    #$file = Join-Path -Path $Path -ChildPath "$server.html"
    $meta
    
    return


    $frag = @()
    
    $frag+= $meta | convertto-html -Fragment -as List
    
    #system properties to exclude from the output
    $exclude = "ResourceID","CIM*","PS*computername","ConfigurationName","ModuleName","ModuleVersion"
    Write-Verbose "[$this] Processing results"
    foreach ($setting in $config) {
      
      if ($noncompliant -contains $setting.ResourceId) {
        $frag += "<H3 class='alert'>$($setting.resourceID)</H3>"
      }
      else {
        $frag += "<H3>$($setting.resourceID)</H3>"
      }

      $defined = $setting.CimInstanceProperties.where({$_.value}) | Sort-Object -Property Name | Select-Object -ExpandProperty Name

      $obj = $defined | foreach-object -Begin { 
       #create a temporary hashtable
       $hash = [ordered]@{}
       } -process {
          #exclude properties
          if ($exclude -notcontains $_ ) {
            #get the corresponding value from the setting
            $val = $setting.$_
            #test if value is an array
            if ($val -is [array]) {
                $val = $val -join ","
            }
            #add it to the hashtable
            $hash.Add($_,$val)
         }
       } -end {
          #decide if output should be a table or list depending on 
          #the number of properties
          if ($hash.keys.count -gt 6) {
            $as = "list"
          }
          else {
            $as = "table"
          }
          #convert to an object and html
         $frag+= New-Object -TypeName PSObject -Property $hash |
          Convertto-HTML -as $as -Fragment
       }
  
     }

     $frag+=@"
<hr/><h5>
<i>
Items in red indicate non-compliant resources.<p/>
Report run: $(Get-Date) 
</i></h5>
"@

     Write-Verbose "[$this] Creating HTML file $file"
     Convertto-html -Head $head -Body $frag  |     
     Out-File -FilePath $file -Encoding ascii

     if ($passthru) {
        Get-Item -path $file
     }
 }





})
#$rapport

<#
$rapport=@()
$computername.ForEach({
    $entry = ($entry = " " | select-object HostName, WantedConfig, RemoteConfig) 

$entry.HostName = $_
$entry.wantedconfig = $expectedLocalDSCConfig
$entry.RemoteConfig =  Get-DscLocalConfigurationManager -CimSession $cimsession -ErrorAction Stop | select $expectedLocalDSCConfig.foreach({ $_.keys })
$rapport +=$entry
})
$rapport
#>
return


# LCM Config
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
break
#LCM -Computername $computername -OutputPath $env:TEMP -Verbose
#Set-DscLocalConfigurationManager -Path $env:TEMP -ComputerName $computername -Verbose -Credential $credz
#Get-DscLocalConfigurationManager -CimSession $cimsession -ErrorAction Stop | select $expectedLocalDSCConfig.foreach({ $_.keys })

# OM det inte funkar...
#
#Get-DscLocalConfigurationManager -CimSession (New-CimSession -ComputerName "web01a" -Credential $credz)
#Remove-DscConfigurationDocument -CimSession (New-CimSession -ComputerName "web01a" -Credential $credz) -Stage Pending -Force
