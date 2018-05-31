


Import-Module S:\Scripting\powershell\modules\Calendar.Utils -Verbose

Get-Command -Module Calendar.Utils

Add-CalendarMeeting -Subject "Förändringsstopp 2017. 19/6 - 20/8" -Body "Förändringsstopp" -MeetingStart '2017-06-19' -MeetingEnd '2017-08-20' -BusyStatus Free -AllDayEvent -DisableReminder -Verbose


