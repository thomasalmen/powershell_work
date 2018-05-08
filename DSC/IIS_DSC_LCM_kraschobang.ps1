#function set-LocalDSCProperties()
#{

    [cmdletbinding()]
    Param(
        [Parameter(Position = 0,Mandatory, ValueFromPipeline)]
        [ValidateNotNullorEmpty()]
        [string[]]$Computername,
        [pscredential]$credz

    )


    $VerbosePreference ="verbose"


    #$cimsession = New-CimSession -ComputerName $computername -Credential $credz
    #$cimsession = New-CimSession -ComputerName "kraschobang" -Credential (Get-Credential tal008adm)
    
    $localdscconf = Get-DscLocalConfigurationManager -CimSession $cimsession  | select ActionAfterReboot,RebootNodeIfNeeded,ConfigurationMode

    if( ($localdscconf.ActionAfterReboot -eq "ContinueConfiguration") -and ($localdscconf.RebootNodeIfNeeded -eq $false ) -and ($localdscconf.ConfigurationMode -eq "ApplyAndAutoCorrect" ) )
    {
        write-verbose "Local DSCconfiguration on '$($cimsession).computername' OK - skipping"
        return    
    }
    else
    {
        write-verbose "Modifying DSCconfig"
        [DscLocalConfigurationManager()]
        Configuration LCM {
    
            param([string[]]$Computername=($cimsession).computername)
    
            Node $Computername {
                Settings {
                    RebootNodeIfNeeded = $false
                    ActionAfterReboot = 'ContinueConfiguration'
                    ConfigurationMode = 'ApplyAndAutoCorrect'
                }
            }
        } 

        LCM -OutputPath $env:temp -Computername ($cimsession).computername
        Set-DscLocalConfigurationManager -Path $env:temp -CimSession $cimsession
        Get-DscLocalConfigurationManager -CimSession $cimsession
    }
#}