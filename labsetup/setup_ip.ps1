
$hostip="10.1.20.251"
New-NetIPAddress -IPAddress $hostip -InterfaceAlias "Web" -AddressFamily IPv4 -PrefixLength 24 -defaultgateway 10.1.20.240
#10.1.20.252

$ip="10.1.20.30","10.1.20.31", "10.1.20.32", "10.1.20.33", "10.1.20.41", "10.1.20.42", "10.1.20.43", "10.1.20.44", "10.1.20.45"
$ip | % { New-NetIPAddress -IPAddress $_ -InterfaceAlias "Web" -AddressFamily IPv4 -PrefixLength 24 }

$ip | % {
    netsh http delete iplisten ipadd=$($_):80
    netsh http add iplisten ipadd=$($_):80
}

$lampip="10.1.20.252", "10.1.20.11", "10.1.20.12", "10.1.20.13", "10.1.20.14", "10.1.20.15", "10.1.20.16", "10.1.20.17", "10.1.20.18", "10.1.20.19", "10.1.20.20", "10.1.20.50"
$lampip | % { New-NetIPAddress -IPAddress $_ -InterfaceAlias "Web" -AddressFamily IPv4 -PrefixLength 24 }

$lampip | % {
    netsh http delete iplisten ipadd=$($_):80
   # netsh http add iplisten ipadd=$($_):80
}

#https://stackoverflow.com/questions/7285310/confusing-powershell-behavior
netsh http add iplisten 127.0.0.1

#New-NetIPAddress -IPAddress 10.1.20.15 -InterfaceAlias "Web" -AddressFamily IPv4 -PrefixLength 24


#netsh http delete iplisten ipadd=10.1.20.42:80
#netsh http add iplisten ipadd=10.1.20.42:80