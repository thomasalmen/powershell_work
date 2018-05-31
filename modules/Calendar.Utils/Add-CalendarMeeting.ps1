<#
	.SYNOPSIS
		Just a small Powershell Function to create Outlook Calendar Meeting on the fly.
        From http://newdelhipowershellusergroup.blogspot.se/2013/08/powershell-and-outlook-create-calendar.html

	.DESCRIPTION
		If you are a Powershell Scripter or Programmer, then most of your time is spent
		On the Powershell Console. I want to write a small function which helps me to
		Create a calendar invites from the Powershell console. So that I can add calendar
		Invites on the fly and add them as reminder.

	.PARAMETER  Subject
		Using -Subject parameter please provide the subject of the calendar meeting.

	.PARAMETER  Body
		Using -Body, you can add a more information in to the calendar invite.

	.PARAMETER  Location
		The location of your Meeting, for example can be meeting room1 or any country.

	.PARAMETER  Importance
		By Default the importance is set to 2 which is normal
		You can set to -Importance high by providing 2 as an argument
    	0 = Low
    	1 = Normal
    	2 = High.


	.PARAMETER  AllDayEvent
		If you want to create an all day event mart it as $true.

    .PARAMETER BusyStatus
        To set your status to Busy, Free Tenative, or out of office, By default it is set to Busy
        0 = Free
        1 = Tentative
        2 = Busy
        3 = Out of Office


	.PARAMETER  DisableReminder
		By Default reminders are enabled. If you don’t want a reminder, specify parameter DisableReminder

	.PARAMETER  MeetingStart
		Provide the Date and time of meeting to start from.

	.PARAMETER  MeetingDuration
		By default meeting duration is set to 30 Minutes. You can change the duration Of the meeting using -MeetingDuration Parameter.

	.PARAMETER  Reminder
		'By default you got reminder before 15 minutes of meting starts. 
         You can use -Reminder to set the reminder duration. The value is in Minutes.'

	.EXAMPLE
		PS C:\>Add-CalendarMeeting -Subject "Powershell" -Body "Show how to use Powershell with Outlook" -Location "Conf Room 1" -AllDayEvent -DisableReminder
		
	.EXAMPLE
		PS C:\>Add-CalendarMeeting -Subject "Powershell" -Body "Show how to use Powershell with Outlook" -Location "Conf Room 1" -MeetingStart "08/08/2013 22:30" -Reminder 30 
	

	.EXAMPLE
		PS C:\>Add-CalendarMeeting -Subject "Powershell" -Body "Show how to use Powershell with Outlook" -Location "Conf Room 1" -Importance 'High'


	.NOTES
        I worte this function for adding a quick calender meeting.
        in this fucntion you can't add anyone and sent invites to someone.
        In next version of the same function , i will add these functionality.
        Thanks : Aman Dhally {amandhally@gmail.com}

	.LINK
		www.amandhally.net

	.LINK
		www.
#>
Function Add-CalendarMeeting {
# AÖ 2016-10-10. Byggt från http://newdelhipowershellusergroup.blogspot.se/2013/08/powershell-and-outlook-create-calendar.html
# AÖ 2017-04-20. Rättat verbose logging
[cmdletBinding(SupportsShouldProcess=$true,
               ConfirmImpact='Medium')]
Param(
    [Parameter(
        Mandatory = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage="Please provide a subject of your calendar item.")]
    [Alias('sub')]
    [string]$Subject,

    [Parameter(
        ValueFromPipelineByPropertyName = $True,
        HelpMessage="Please provide a description of your calendar item.")]
    [Alias('bod')]
    [string]$Body,

    [Parameter(
        ValueFromPipelineByPropertyName = $True,
        HelpMessage="Please provide the location of your meeting.")]
    [Alias('loc')]
    [string]$Location,

	[Parameter(
        Mandatory=$True,
        ValueFromPipelineByPropertyName = $True)]
	[datetime]$MeetingStart,

	[Parameter(
        ValueFromPipelineByPropertyName = $True)]
	[datetime]$MeetingEnd,

	[Parameter(
        ValueFromPipelineByPropertyName = $True)]
	[int]$MeetingDuration = 30, 

    [Parameter(
        ValueFromPipelineByPropertyName = $True,
        HelpMessage="Please provide the importance of your meeting.")]
	[ValidateSet('Normal','Low','High')]
	[string]$Importance = 'Normal',

	[Parameter(
        ValueFromPipelineByPropertyName = $True)]
	[ValidateSet('Free','Tentative','Busy','OutOfOffice')]
	[string]$BusyStatus = 'Busy',

    # Parameter to be able to tell function to add an all day event by pipeline.
    # Switch AllDayEvent is tricky to send over pipeline.
	[Parameter(
        ValueFromPipelineByPropertyName = $True)]
    [ValidateSet('AllDay','Normal')]
    [string]$EventType = 'Normal',

	[Parameter()]
	[switch]$AllDayEvent = $false,

	[switch]$DisableReminder = $False,

	[Parameter(
        ValueFromPipelineByPropertyName = $True)]
	[int]$Reminder = 15

#    [Parameter(
#        HelpMessage="Rounds the specified MeetingStart and MeetingEnd to nearest Hour, half hour or quarter")]
#    [ValidateSet('Hour','HalfHour','Quarter')]
#    [string]$RoundToNearest
)
    BEGIN {
		# Om -debug är satt, ändra $DebugPreference så att output blir lite mindre irriterande.
		#	http://learn-powershell.net/2014/06/01/prevent-write-debug-from-bugging-you/
		If ($PSBoundParameters['Debug']) {
			$DebugPreference = 'Continue'
		}

        # https://msdn.microsoft.com/en-us/library/office/aa171432(v=office.11).aspx
        $ImportanceHash = @{
                            'Low' = 0;
                            'Normal' = 1;
                            'High' = 2;
                            }

        $BusyStatusHash = @{
                            'Free' = 0;
                            'Tentative' = 1;
                            'Busy' = 2;
                            'OutofOffice' = 3
                        }

        $outlookProcess = Get-process | ? { $_.Path -like "*outlook.exe"}
        if(-Not $outlookProcess) {
            Throw "Outlook needs to be started. Could not find a process matching '*outlook.exe'"
        }
    }

    PROCESS {
        Write-Debug $($pscmdlet.MyInvocation.BoundParameters | out-string)

        # följande kontroller kan göras med ParamSets
        # Läggs i PROCESS eftersom kontroller även skall köras på in-pipe'at data
	    if ( ($AllDayEvent -or $EventType -eq 'AllDay') -And -Not $MeetingEnd) {
		    Throw "If an all day event is specified MeeintEnd must also be set!"
	    }
        # här kollas med BoundParameters eftersom MeetingDuration har ett default-värde satt.
        # $pscmdlet.MyInvocation.BoundParameters används istället för $PSBoundParameters['MeetingDuration'] eftersom parametrar
        # även kan komma via pipeline
        if ($($pscmdlet.MyInvocation.BoundParameters['MeetingDuration']) -And $MeetingEnd) {
            Throw "Both MeetingDuration and MeetingEnd cannot be specified at the same time!"
        }

        # För tillfället kan både -AllDayEvent spec'as samt -EventType 'Normal', vilket inte är en ok kombination.
        # Att utesluta det med Parameter sets verkar inte funka ifall data skall skickas över pipe.
        # Orkar inte koda för det. 



        # Create a new appointments using Powershell
        $outlookApplication = New-Object -ComObject 'Outlook.Application' -Verbose:$False
        # Creating a instatance of Calenders
        $newCalenderItem = $outlookApplication.CreateItem('olAppointmentItem')

        $newCalenderItem.Subject = $Subject
        $newCalenderItem.Body = $Body
        $newCalenderItem.Location  = $Location

        if ($Reminder -ge 0) {
            # krånglig logik kanske. .ReminderSet skall vara $True om inte $DisableReminder är spec'ad. $DisableReminder är $False som default.
            # därför blir ($DisableReminder -eq $False) = $True när inte $DisableReminder spec'as och reminderSet sätts till $True
            $newCalenderItem.ReminderSet = ($DisableReminder -eq $False) 
            $newCalenderItem.ReminderMinutesBeforeStart = $Reminder
        } else {
            # Om $Reminder är minddre än 0 (-1) så slås reminder av.
            # Snabbhack för att support'a att Reminder kan skickas in via pipe
            $newCalenderItem.ReminderSet = $False
            $newCalenderItem.ReminderMinutesBeforeStart = 0
        }
        $newCalenderItem.Importance = $ImportanceHash[$Importance]
        $newCalenderItem.BusyStatus = $BusyStatusHash[$BusyStatus]        

        $newCalenderItem.Start = $MeetingStart
    

        # Normalize end timestamp of meeting
        # Här tar vi inte hänsyn till om MeetingDuration och MeetingEnd är satta samtidigt, det ska ha kollats tidigare
        # $MeetingEnd kollas om det är satt, om inte så beräkas MeetingEnd från MeetingDuration.
        # Anledningen att inte använda $MeetingDuration i kontroll här beror på att $MeetingDuration alltid är satt pga att det har ett default-värde
        if ( -Not $MeetingEnd ) {            
            # MeetingEnd beräkas här mha MeetingDuration, så att bara MeetingEnd används hädanefter.
            $MeetingEnd = $MeetingStart.AddMinutes($MeetingDuration)
        }

        if($AllDayEvent -or ($EventType -eq 'AllDay') ) {
            # if AllDayEvent is specified it seems that end date must be one day further.
            $newCalenderItem.AllDayEvent = $True
            $newCalenderItem.End = $meetingend.AddDays(1)
        } else {
            $newCalenderItem.End = $MeetingEnd
        }

        Write-Verbose "Add Meeting. Subject: `"$Subject`". Body: `"$Body`". Location: `"$Location`". AllDayEvent = $($AllDayEvent -or ($EventType -eq 'AllDay')). Meeting start: $MeetingStart. Meeting end: $MeetingEnd. Reminder: $Reminder"

        if($pscmdlet.ShouldProcess("Calendar","Add Meeting. `"$Subject`". $MeetingStart to $MeetingEnd") ) {
            $newCalenderItem.Save()
        }        
    }
}


Function _Test_Add-CalendarMeeting {
    
    $MeetingParams = @{
                    Subject = "Meeting created with Add-CalendarMeeting";
                    Body = "Content";
                    MeetingStart = (Get-date).AddDays(1);
                    MeetingDuration = 120;
                    }
    #New-Object -TypeName PSObject -Property $MeetingParams | Add-CalendarMeeting -Verbose
    New-Object -TypeName PSObject -Property $MeetingParams | Add-CalendarMeeting -Verbose -WhatIf

    <#
    Add-CalendarMeeting -Subject "Meeting created with Add-CalendarMeeting" -Body "Content" -MeetingStart (Get-date).AddDays(1) -MeetingDuration 120



    $MeetingParams = @{
                        Subject = "Meeting created with Add-CalendarMeeting";
                        Body = "Content";
                        MeetingStart = (Get-date).AddDays(1);
                        MeetingEnd = (Get-date).AddDays(4);
                        EventType = 'AllDay'
                    }
    New-Object -TypeName PSObject -Property $MeetingParams | Add-CalendarMeeting -Verbose


    Add-CalendarMeeting -Subject "Servicefönster 2017-01-19. Fokus applikation" -MeetingStart "2017-01-19 00:00" -MeetingEnd "2017-01-19 00:00" -EventType AllDay -BusyStatus Free -Verbose
    #>

}
