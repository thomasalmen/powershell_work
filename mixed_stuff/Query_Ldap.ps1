cls

$kollprops = @{

    "Prod" = [ordered]@{
        Computers=@("ldapserver1","ldapserver2","ldapserver3")
        ldapObject="/C=SE"
        SokFilter="mail=homer.simpson@xxx.se"
        propertyToLookfor = "hsaidentity"
    };

    #"Test" = [ordered]@{
    #    Computers=@("ldapservertest1","ldapservertest2","ldapservertest3","ldapservertest4")
    #    ldapObject="/C=SE"
    #    SokFilter="mail=homer.simpson@xxx.se"
    #    propertyToLookfor = "hsaidentity"
    #};

    "History" = [ordered]@{
        Computers=@("ldapservertest5")
        ldapObject="/o=EDIRAroot"
        SokFilter="sn=some_username"
        propertyToLookfor = "description"
    };
}





#$computers = "kollmaster","kollslave1"
#$ldapobjekt = "/C=SE"
#$sokfilter="sn=almén"
#$sokfilter="mail=homer.simpson@xxx.se"
#$propertyToLookfor = "hsaidentity"


<# 
    Remember:
    Sök på ett attribut som inte returnerar för många träffar
    Ex "sn=andersson" returnerar massor av träffar, medans "mail=homer.simpson@xxx.se" inte alls returnerar lika många
#>
<#
allows you to provide an array of keys to get multiple values.
$environments = @{
    Prod = 'SrvProd05'
    QA   = 'SrvQA02'
    Dev  = 'SrvDev12'
}

$environments[@('QA','DEV')]
$environments[('QA','DEV')]
$environments['QA','DEV']
#>

function kollaKoll()
{
    
    param(
        [Parameter(Mandatory=$true)]$properties,
        [Parameter(Mandatory=$false)][switch]$includeKollHist
    )
    
   # if( (read-host "Inkludera kollhist? Enter=Avbryt"," j/n") -eq 'j') # -or $includeKollHist)
   # {
   #     $computers += "kollhist"    
   #     $ldapobjekt = "/o=EDIRAroot"
   #     $sokfilter = "sn=kollmonitor_user"
   #     $propertyToLookfor = "description"
   # }

    $Rapport = @()

    # Skickar $properties till foreach
    $properties.GetEnumerator() | % {

        $message = New-Object psobject | select Server, Antal, Resultat, Status
        "Går igenom objektet " + $_.key
        #$message.Server = $_.key
        #$message.Status = "Fail"
        #$message.antal = 0

        # Tilldela $_ till tempvariabel och loopa ut nästa nivå.
        # $_ innehåller nu ex key="prod" 
        
        $temp = $_
     
       # Skickar värdet i "value", d.v.s en annan hashtable till foreach

        $temp.value.GetEnumerator() | % {
            #"Letar igenom objektet " + $_.key
            
            
            if($_.value.count -gt 1)
            {
                $temp2 = $_
                $temp2.value.GetEnumerator() | % {
                "blah " + $_
                   $ldapstring = $_

                }
            }
            else
            {
                "blah2 = " + $_.value
                $ldapstring += $_.value
               # "Inte fler än 1..fortsätt"
            }


              
    
    
        }
                   "String = " + $ldapstring
    
        #$Rapport+=$message
    } 
#    $Rapport | ft -AutoSize

    
    
    
    
    
    
    
    
    <#
    $computers | % {

    #$message = ($message = " " | select Server, Antal, Resultat, Status)
    $message = New-Object psobject | select Server, Antal, Resultat, Status
    $message.Server = $_  
    $message.Status = "Fail"
    $message.antal = 0

    $katalogroot = [System.DirectoryServices.DirectoryEntry]::new("LDAP://$($_)$($ldapobjekt)", "", "", "none")
    if($katalogroot.path -ne $null)
    {
        $sokobject = [DirectoryServices.DirectorySearcher]::new($katalogroot,$sokfilter)
        $objresult=$sokobject.FindAll()
        $message.Antal = $objresult.Count

        #Loopar igenom de träffar som returnerades om de är fler än noll.
        if ($objresult.path.Count -gt 0 )
        {
            $objresult.properties | % {
                $message.Resultat+=@("$($_[$propertyToLookfor])")
            }
            $message.Status = "OK"
        }
        else 
        { 
            $message.Resultat = "Inga träffar på '$($sokfilter)'"
        }  
    }
    else
    {
        $message.Resultat = "Kunde inte ansluta till '$($_)'"
    }

    $Rapport+=$message
    } 
    $Rapport | ft -AutoSize
    #>

}


kollakoll -properties $kollprops
