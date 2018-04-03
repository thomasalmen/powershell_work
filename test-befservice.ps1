cls

[string]$url = @(
"http://befservice2.orebroll.se")

$requestHeaders = @{"SOAPAction" = "http://befservice2.org/GetPerson"; "Accept-Charset" ="utf-8";"Accept-Encoding" = "gzip,deflate"}
$contenttype="text/xml;charset=UTF-8"
#$contenttype="text/plain;charset=UTF-8"

$SOAPRequest=@"
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:bef="http://befservice2.org/">
   <soapenv:Header/>
   <soapenv:Body>
      <bef:GetPerson>
         <bef:pPnr12>PERSONNUMMER</bef:pPnr12>
         <bef:pTransTyp>[INT]TRANSTYP</bef:pTransTyp>
         <bef:pInklAvreg>[STRING]j/n</bef:pInklAvreg>
         <bef:pInklSkyddad>[STRING]J/N</bef:pInklSkyddad>
         <bef:pKundId>[INT]ID</bef:pKundId>
         <bef:pApp>[STRING]heck</bef:pApp>
         <bef:pAnvaendare>[STRING]j/n</bef:pAnvaendare>
         <bef:pHost>[STRING]j/n</bef:pHost>
      </bef:GetPerson>
   </soapenv:Body>
</soapenv:Envelope>
"@


#$utf8 = [System.Text.Encoding]::GetEncoding(65001)

$Rapport = @()
$url | ForEach-Object { 

    $statusMess = " " | Select-Object Svar, Diagnos
    $statusmess.Svar = "N/A"
    $statusmess.Diagnos = "FAIL!"
    try
    {
        
        $out = Invoke-RestMethod $_ -Method POST -ContentType $contenttype -Body $SOAPRequest -Headers $requestHeaders

        if( (select-Xml -xml $out -XPath "//StatusKod" | select -ExpandProperty Node ).innertext -eq "okok" )
        {
            $statusmess.Diagnos = "OkOk"
            $out.SelectSingleNode("//PersonPost") | select Namn, Adresser | foreach { $statusmess.Svar = $_.Namn.ForNamn + " " + $_.Namn.EfterNamn + "`n" + $_.Adresser.FolkbokforingsAdress.UtdelningsAdress1 }
        }
    }
    catch { 
        $statusMess.Svar = "Request failed " + $out.RawContent
    }
    $Rapport+=$statusmess
}

$Rapport | ft -Wrap