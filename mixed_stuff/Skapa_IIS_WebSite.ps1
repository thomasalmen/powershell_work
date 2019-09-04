# TODO
# Kom ihåg att det även går att köra enter-pssession $s
# Då finns även driven IIS: tillgänglig

# Lägg till möjlighet att deploya fr git?
# $GitSource = @{
#    repoUrl = "repourl";
#    branch = "master";
# }

# Kolla om modulen IISAdministration finns
# Install-Module –Name IISAdministration -Force
# Gör en if-sats runt import-pssession ifall ex modulen inte finns

"Kom ihåg att ta bort break.."
break


$computer = "kraschobang"
$creds=Get-Credential domain\username

$s=New-PSSession $computer -Credential $creds

"Temp=" + $temp
try
{
    Import-PSSession -Session $s -module WebAdministrationx -ErrorAction stop # -module IISAdministration #-Prefix "prefix"
    Import-PSSession -Session $s -module WebAdministration -ErrorAction stop # -module IISAdministration #-Prefix "prefix"
    Import-PSSession -Session $s -module IISAdministration -ErrorAction stop # -module IISAdministration #-Prefix "prefix"

}
catch [Exception]
{
     Write-Warning $_.Exception.Message
}
#Remove-PSSession $s
"Temp efter = " + $temp

Enter-PSSession $s
#get-help *website* -full

<# Modifiera dessa #>
# POOL
$AppPoolnamn = "poolname.xxx.se"
$AppPoolNetVersion = "v4.0"

#SAJT
$SajtNamn = "sitename.xxx.se"
$SajtProtokoll = "http"
$SajtBinding = ""
$SajtIp = ""
$SajtPort = 80
$SajtPath = "d:\websites\sitename.xxx.se\CurrentVersion"
$SajtHostHeader = "sitename.xxx.se"

#CERTIFIKAT
#Använd maskinens cert - Export-PfxCertificate 
#$Certifikat = ""
#$CodeLocation ="" # Lämna blank om ingen kopiering ska göras.



<# Pilla inte på det nedanför denna rad #>
#$bindings = @{protocol="$SajtProtokoll"; bindingInformation=":"+$SajtPort+":"+$SajtNamn }

#Kollar om physical path existerar - annars skapa den
if(! (Test-Path -Path $SajtPath ))
{
    New-item -ItemType Directory -Path $SajtPath
}
else
{
    

#Kolla om app-pool finns - annars skapa den.
if (!(Test-Path $AppPoolnamn -pathType container))
{
    $appPool =  New-WebAppPool -Name $AppPoolnamn
    $appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $AppPoolNetVersion 
} 
else 
{
    Write-Host "Applikationspoolen finns redan"
}

Write-Host "Sökvägen finns redan"
}


#Kollar om sajten redan finns - annars skapa den.
if(!( Test-Path -Path $SajtPath -PathType Container ))
{
    New-Item -ItemType Directory -Path $SajtPath
    
    Start-IISCommitDelay
    $WebSite = New-IISSite -Name "$SajtNamn" -BindingInformation "$($SajtIp):$($SajtPort):$($SajtHostHeader)" -PhysicalPath $SajtPath -Passthru
    $WebSite.Applications["/"].ApplicationPoolName = "$AppPoolnamn"
    Stop-IISCommitDelay

    #New-website -Name $sajtnamn  -PhysicalPath $SajtPath -ApplicationPool $AppPoolnamn #-Port $SajtPort -HostHeader
    #if($SajtPort -eq 80)
    #{
    #    New-IISSiteBinding -Name "$SajtHostHeader" -BindingInformation "*:" + $SajtPort +":" + $SajtHostHeader -Protocol $SajtProtokoll
    #}
    #if($SajtPort -eq 443)
    #{
    #
    #}

}
else 
{
    Write-error "Sajten finns redan"
}
