function Set-LogMessage
{

    Param
    (
        [parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
        $LogMessage,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Info','Information','Warning','Error','Verbose','debug')]
        [string]$Type = 'Information'

    )
    Begin {}
    Process
    {
    #$type
            Switch($type.ToLower())
            {
                "error"
                {
                    Write-Output "`n!Error!`n$LogMessage`n"
                    break
                }
                "info"
                {
                    Write-output "$LogMessage" -Verbose
                }
                "information"
                {
                    Write-output "$LogMessage" -Verbose
                }
                "verbose"
                {
                    Write-Verbose "$LogMessage" 
                }
                "warning"
                {
                    Write-Warning "$LogMessage"
                }
                "debug"
                {
                    if($DebugPreference -eq "Continue")
                    {
                        Write-Debug $LogMessage
                    }
                }
            }
       
    }
    end {}
}

