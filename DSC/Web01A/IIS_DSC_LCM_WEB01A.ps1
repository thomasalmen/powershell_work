function set-LocalDSCProperties()
{
    [cmdletbinding()]
    Param(
        [Parameter(Position = 0,Mandatory, ValueFromPipeline)]
        [ValidateNotNullorEmpty()]
        [string[]]$Computername,
        [pscredential]$credz

    )
    
    $cimsession = New-CimSession -ComputerName $computername -Credential $credz
    
Get-DscLocalConfigurationManager -CimSession $cimsession
Test-DscConfiguration -ComputerName kraschobang -Credential $credz

    $localdscconf = Get-DscLocalConfigurationManager -CimSession $cimsession  | select ActionAfterReboot,RebootNodeIfNeeded,ConfigurationMode

    break
    if( ($localdscconf.ActionAfterReboot -eq "ContinueConfiguration") -and ($localdscconf.RebootNodeIfNeeded -eq $false ) -and ($localdscconf.ConfigurationMode -eq "ApplyAndAutoCorrect" ) )
    {
        write-verbose "Local DSCconfiguration on '$($cimsession).computername' OK - skipping"
        return    
    }
    else
    {
        write-verbose "Modifying DSCconfig"
        invoke-command -session $PSsession { Set-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb -Value 2048 } | out-null
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
}
set-LocalDSCProperties -Computername kraschobang -credz (Get-Credential tal008adm)
