cls
#$ErrorActionPreference = "Silentlycontinue"

#OBS TESTA INTE KOLLHIST!
#$computers = "kollslave1", "kollslave2","kollmaster" #"kollmaster","kollslave1", "kollslave2"#,"kollhist"

$computers="kollhist"
$sokfilter="hsaIdentity=SE2321000164-tal008"

#ldap://kollhist.orebroll.se/o=Region Örebro län,l=Örebro län,c=SE,dc=history,c=SE och med ett sökfilter ”hsaIdentity=SE2321000164-tal008”
#$sokfilter="sn=almén"

foreach ($c in $computers) 
{

    $katalogroot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$($c)/c=se","","","none")
    $object=new-object DirectoryServices.DirectorySearcher($katalogroot,$sokfilter)
    write-host -nonewline "Testar $c..."
    
    try{
        $objresult=$object.FindAll()
        
        if ($objresult.path.Count -gt 0 )
        {
            write-output ("$($objresult.path.Count) träff(-ar)")
            $traffar=""
            $objresult.path | % { 
                #Visar de träffar som returnerades
                $traffar+="[$($psitem)]`n"
            }
            write-output $traffar`n
        }
        else { Write-output "[Inga träffar på '$($sokfilter)']" }  
    }
    Catch {
        Write-output "[Fail: $($psitem.Exception.Message.replace("`n",''))]"
    }
$error.Clear()
} 


