function Disable-Poolmember
{
write-output "INte klar!"
break

    Param
    (
        [parameter(Mandatory = $true,
        ValueFromPipeline = $true,Position=0)]
        $LogMessage,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Info','Information','Warning','Error','Verbose')]
        [string]$Type = 'Information'

    )
    Begin {}
    Process
    {



    
    #"TYP=$type"
        if($type -eq "Error")
        {
            Write-Output "*** Error: $LogMessage ***"
            break
        }
        if($type -in "Info")
        {
            Write-output "### Info: $LogMessage ###"
        }
        if($type -eq "Verbose")
        {
            Write-Verbose "Verbose: $LogMessage" -Verbose
        }
        if($type -eq "Warning")
        {
            Write-Warning "Warning: $LogMessage"
        }
    }
    end
    {}
}

