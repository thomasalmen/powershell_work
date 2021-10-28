<#
.Synopsis
   Skapar en ny sorrypage. Dˆper om ifall det redan finns en med samma namn som skickas med i variablen $iRuleName
.DESCRIPTION
   Long description
.EXAMPLE
    [string]$partition = "yDMZ"
    [string]$vip = "bigipdemo.scb.intra_https_vs"
    [string]$iRuleName = "bigipdemo.scb.intra_DEMO_1.0_sorrypage"
    [string]$startDate = "2020-09-22 13:00"
    [string]$endDate = "2029-01-22 19:00"
    $irulekod = @"
    when HTTP_REQUEST { ... }
    "@

    New-Sorrypage -partition $partition -vip $vip -iRuleName $iRuleName -startDate $startDate -endDate $endDate

.EXAMPLE
   New-Sorrypage -partition "yDMZ"  -vip "bigipdemo.scb.intra_https_vs" -iRuleName "bigipdemo.scb.intra_DEMO_1.0_sorrypage" -startDate "2021-01-01 14:00" -endDate "2021-01-01 19:00"
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>


function New-Sorrypage 
{
    ## Funktionen skapar och l‰gger till en NY Sorrypage som definieras i $iRulekod pÂ $vip
    [CmdletBinding(SupportsShouldProcess)] #adds WhatIf and Confirm parameters
    
    param(

        # Case-sensitive namn p√ partition d√§r den virtuella servern finns
       # [Parameter(Mandatory=$true, ValueFromPipeline=$true )]
        [ValidateSet('yDMZ','SCB-LAN','iDMZ')]
        [ValidateNotNullOrEmpty()]
        [string]$partition,

        # Case-sensitive namn p√ den virtuella servern som ska ha iRulen
        [Parameter(Mandatory=$true)]
        [string]$vip,

        #Namnet p√• iRulen som ska skapas
        [Parameter(Mandatory=$true)]
        [string]$iRuleName,

        #Datum/tid d√• sidan ska st√§ngas (YYY-mm-dd HH:MM)
        [Parameter(Mandatory=$true)]
        [string]$startDate,

        #Datum/tid d√• sidan ska √∂ppnas igen (YYY-mm-dd HH:MM)
        [Parameter(Mandatory=$true)]
        [string]$endDate,

        [Parameter(Mandatory=$false)]
        [string]$iRulekod,

        $F5Session=$Script:F5Session
    )

    BEGIN
    {

    if(!$partition)
    {
        set-logmessage "Partition is mandatory, please provide a value." -Type Error
    }
    if(!$iRulekod)
    {
        Set-LogMessage "'`$irulecode' not detected, using default iRulecode defined in '$PSCommandPath'." -Type Warning
    }
    # Om inte iRulkekoden ‰r medskickad sÂ skapas en default Sorrypage.
    # Startdate och EndDate l‰ggs in via de medskickade variablerna $startDate och $endDate
    if([string]::IsNullOrEmpty($iRulekod))
    {
    $tempNamnForVariablesInIrules = ($vip).Replace(".","_")

    #$tempNamnForVariablesInIrules 
    #break


$irulekod = @"
# ################################################################### #
# Important stuff:                                                    #
# Only modify the two variables below.                                #
# They need to be specified exactly as this: "YYYY-mm-dd<SPACE>HH:MM" #
# Example: set static::close_start_date "2020-09-20 15:00"            #
# /Thomas                                                             #
# ################################################################### #

priority 1
when RULE_INIT {
    #Start maintenance window in YYYY-mm-dd HH:MM format
    set static::$($tempNamnForVariablesInIrules)_close_start_date "$startDate"

    #End maintenance window in YYYY-mm-dd HH:MM format
    set static::$($tempNamnForVariablesInIrules)_close_end_date "$endDate"

    # ################################################################# #
    # Do not modiy anything below if you don't know what you are doing! #
    # ################################################################# #

    #Convert start/end times to seconds
    set static::$($tempNamnForVariablesInIrules)_close_start [clock scan `$static::$($tempNamnForVariablesInIrules)_close_start_date]
    set static::$($tempNamnForVariablesInIrules)_close_end [clock scan `$static::$($tempNamnForVariablesInIrules)_close_end_date]


    set static::scblogo { iVBORw0KGgoAAAANSUhEUgAAADUAAAA8CAYAAADG6fK4AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA/9pVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1wTU06T3JpZ2luYWxEb2N1bWVudElEPSJ1dWlkOjVEMjA4OTI0OTNCRkRCMTE5MTRBODU5MEQzMTUwOEM4IiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOkZFRUQ1NUI4RDY2QjExRTdCMUZDRDY5QjQ4QTk3OTMzIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOkZFRUQ1NUI3RDY2QjExRTdCMUZDRDY5QjQ4QTk3OTMzIiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIElsbHVzdHJhdG9yIENDIDIwMTcgKE1hY2ludG9zaCkiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDpBQzMzODE5NTZCRDZFNzExOEQ5REZBMjYzRUM0QUIzRSIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpB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 }


    set static::sorrypageHTML {<!doctype html>
    <html lang="sv" xmlns="http://www.w3.org/1999/xhtml" xml:lang="sv">
    <Head>
        <title>Statistikmyndigheten SCB - Meddelande om underh&aring;ll, Statistics Sweden - Notice of maintenance</title>
        <meta charset="UTF-8">
		<style type="text/css">
    	    body { background:#e8e8e8; font-family:arial;} 
    	    h1,p { text-align:left; } 
    	    p { font-size: 20px; } 
    	    img { margin:auto; display:block;} 
    	    .content { background:#ffffff; border:1px solid #ccc; border-radius:4px; box-shadow:0 1px 0 rgba(0,0,0,0.2);margin:60px auto 0; padding:20px;width:840px; } 

	    </style>
	</head>
	<body>
	
	
    <a href="https://[HTTP::host]" title="Statistikmyndigheten SCB - ladda om sidan, Statistics Sweden - reload page"><img src="data:image/png;base64,`$static::scblogo" alt="Ladda om sidan - Reload page"></a>
	<div class="content">
        
	    <h1>Meddelande om underh&aring;ll</h1>
	    <p>

                <p>SCB st&auml;nger samtliga system f&ouml;r underh&aring;ll [clock format `$static::$($tempNamnForVariablesInIrules)_close_start -format {%Y-%m-%d, kl %H:%M} ].
                <br>
                Vi &ouml;ppnar igen [clock format `$static::$($tempNamnForVariablesInIrules)_close_end -format {%Y-%m-%d, kl %H:%M} ].
                </p>
                <p>Det inneb&auml;r att du under denna tid varken kan h&auml;mta eller l&auml;mna information hos oss.
                <br>
                V&auml;lkommen tillbaka!
                </p>

	    </p>
        <p>
                <h1>Maintenance notice</h1>
                <p>Statistics Sweden will carry out systems-wide maintenance starting [clock format `$static::$($tempNamnForVariablesInIrules)_close_start -format {%Y-%m-%d, at %H:%M} ]. 
                <br>
                The website will be available again [clock format `$static::$($tempNamnForVariablesInIrules)_close_end -format {%Y-%m-%d, at %H:%M} ].
                </p>
                <p>During this period, it will not be possible to retrieve information from or submit data digitally to Statistics Sweden.
                <br>
                Welcome back!
                </p>


	</div>
	</body>
	</html>
    }

    
}

when HTTP_REQUEST priority 1 {
    #Kolla klockan och ev trigga sorrypage
    if { [clock seconds] > `$static::$($tempNamnForVariablesInIrules)_close_start  and [clock seconds] < `$static::$($tempNamnForVariablesInIrules)_close_end } {
        HTTP::respond 200 content [subst `$static::sorrypageHTML] Connection close
        event disable all
        #HTTP::disable
        #ACCESS::disable
        #TCP::close
        return ok
    }

}
"@
}

        Set-LogMessage "Entering function New-Sorrypage" -Type debug
        Test-Token
    }
    PROCESS
    {
        Get-Partition -partition $partition
        Get-vip -partition $partition -vip $vip
       
       #"kod"
       # $irulekod
       # break


        #Skapar den nya regeln
        New-Irule -partition $partition -iRulename $iRuleName -iRuleKod $iRuleKod
        
        #L‰gger till nya regeln pÂ vippen
        Add-irule -partition $partition -vip $vip -iRulename $iRulename
    }
    end
    {
        Set-LogMessage "Exiting function New-Sorrypage" -Type debug
    }
} #Slut function