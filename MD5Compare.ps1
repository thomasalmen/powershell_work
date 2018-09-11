
$filehash = (Get-FileHash -Path .\BIGIP-13.1.1-0.0.4.LTM-scsi.ova -Algorithm MD5 -Verbose).hash
$comparefile = (Get-Content .\BIGIP-13.1.1-0.0.4.LTM-scsi.ova.md5).Split(" ")[0].ToUpper()

if ($filehash -eq $comparefile) {
	"OK"
} else {
	"No match!"
}



#Räkna ut hash med certutil
certutil -hashfile .\BIGIP-13.1.1-0.0.4.LTM-scsi.ova SHA512