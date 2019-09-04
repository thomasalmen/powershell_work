#Setup kerberos för auth via bigip


#Skapa ADuser
New-ADUser -name "F5-SSO" -UserPrincipalName "F5-SSO@supercow.se" -SamAccountName "F5-SSO" -PasswordNeverExpires $true -Enabled $true -AccountPassword (ConvertTo-SecureString -AsPlainText "P@ssw0rd" -force) -KerberosEncryptionType AES256

#Skapa Keytab
ktpass -princ "HTTP/krbtest.supercow.se@SUPERCOW.SE" -mapuser F5-SSO@supercow.se -crypto AES256-SHA1  -ptype KRB5_NT_PRINCIPAL -pass P@ssw0rd -out c:\windows\temp\F5-SSO.keytab

# Sätt SPN serviceprincipalname...?
# Set-ADUser -Identity F5-SSO -ServicePrincipalNames @{add="HTTP/krbtest.supercow.se@SUPERCOW.SE"}
# PS C:\Users\Administrator> get-aduser f5-sso -Properties * | select servicePrincipalName,userPrincipalName,msDS-SupportedEncryptionTypes,sAMAccountName | fl

#Verifiera keytabfilen
ktpass /in C:\Windows\Temp\F5-SSO.keytab

#Ladda upp filen till BigIp
# Access  ››  Authentication  ››  testkrb_aaa
# Auth Realm: SUPERCOW.SE
# Service Name: HTTP

# Verifying the service account name configuration on the AD/KDC (På BigIp)
adtest -t query -h 10.1.10.246 -r "supercow.se" -A administrator -W P@ssw0rd -u F5-SSO -d 4


# Verifiera keytab på bigip
# Ta reda på var keytabfilen hamnat
grep kerberos_keytab /config/bigip.conf
# Output ungefär => cache-path /config/filestore/files_d/Common_d/kerberos_keytab_file_d/:Common:testkrb_aaa_key_file_119891_13
# Kör klist med parametrar nedan + filsökvägen
klist -Kket /config/filestore/files_d/Common_d/kerberos_keytab_file_d/:Common:testkrb_aaa_key_file_119891_13



<#Felsökning
https://support.f5.com/csp/article/K24065228

Kontrollera att browsern är inställd korrekt.
IE ska ha sajten i "Local Intranet" => Tools => Internet options > Security > Lägg till sajten till Local Intranet
Osäkert hur andra browser hanterar Kerberos

Enabla APM debuglogging om det inte redan är gjort.
tmsh modify sys db log.rba.level value debug


Verifiera att klienten skickar sin Kerberos service ticket till BIG-IP APM genom att titta på session.logon.last.authparam
session.logon.last.authparam ska börja med "YII" : info apmd[18913]: 01490007:6: /Common/example:Common:af26e8b5: Session variable 'session.logon.last.authparam' set to 'YII[...]
Om det står ex: 'TlRM[...]', så ha Kerberos authentication failat och försöker istället med NTLM

Verifiera klockan
På bigip: ntpstat
Windows: w32tm /stripchart /computer:thomasdc.supercow.se /dataonly /samples:5

Verifiera att klienten kan slå upp DNS-namne (krbtest.supercow.se)

Verifiera Kerberosbiljett på klienten
1 Rensa först alla biljetter: klist purge
2 Återskapa felet: 
3 klist
Ska visa minst två biljetter, en TGT-ticket och en ticket för access mot tjänsten (krbtest.supercow.se)

Verifiera att Kerberosauth  under authentication är korrekt.
Realm: SUPERCOW.SE
Service Name: HTTP


Verifiera AD-kontot
adtest -t query -h 10.1.10.246 -r "supercow.se" -A administrator -W P@ssw0rd -u F5-SSO -d 4
servicePrincipalName: | HTTP/krbtest.supercow.se@SUPERCOW.SE | HTTP/krbtest.supercow.se |
userPrincipalName: HTTP/krbtest.supercow.se@SUPERCOW.SE
msDS-SupportedEncryptionTypes: 16
sAMAccountName: F5-SSO
Observer att servicePrincipalName och userPrincipalName ska(?) vara samma.


Om kontot ändrats ex nytt lösen kan KVNO ha ändrats.
Verifiera att KVNO i AD är samma som i Keytabfilen
ldapsearch -xLLL -H ldap://supercow.se:389 -b 'dc=supercow,dc=se' -D 'CN=Administrator,CN=Users,DC=supercow,DC=se' -w 'P@ssw0rd' '(sAMAccountName=F5-SSO)' msDS-KeyVersionNumber
klist -Kket /config/filestore/files_d/Common_d/kerberos_keytab_file_d/:Common:testkrb_aaa_key_file_119891_13

#>


radera alla biljetter på klienten
klist purge
klist
