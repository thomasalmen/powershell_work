
#Set-ExecutionPolicy Unrestricted
$TomcatVersion = "9.0.4"
$ServiceName = "Katalogadmin" # Måste vara unikt.
$Catalina_Home = "D:\websites\katalogadmin.orebroll.se\apache-tomcat-9.0.4"
$Catalina_Base = "" # Kan lämnas tom
$Java_home = "D:\websites\katalogadmin.orebroll.se\jre1.8.0_151"
$jvm = "$($java_home)\bin\server"
$PathToTomcatExe = "$($Catalina_Home)\bin\tomcat9.exe"


if($Catalina_Base -eq "" ) {$Catalina_base = $Catalina_Home}
$params = @"
    --Description "Apache Tomcat $($TomcatVersion) Server - http://tomcat.apache.org/"
    --JavaHome "$Java_home"
    --DisplayName "Apache Tomcat $($TomcatVersion) - $($ServiceName)"
    --Install "$PathToTomcatExe"
    --LogPath "$($catalina_base)\logs"
    --Classpath "$($catalina_home)\bin\bootstrap.jar;$($catalina_home)\bin\tomcat-juli.jar"
    --Jvm "$($jvm)\jvm.dll"
    --StartMode "jvm"
    --StopMode "jvm"
    --StartPath "$Catalina_Home"
    --StopPath "$Catalina_Home"
    --StartClass "org.apache.catalina.startup.Bootstrap"
    --StopClass "org.apache.catalina.startup.Bootstrap"
    --StartParams "start"
    --StopParams "stop"
    --JvmOptions "-Dcatalina.home=$Catalina_Home;-Dcatalina.base=$catalina_Base;-Dignore.endorsed.dirs;-Djava.io.tmpdir=$Catalina_Base\temp;-Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager;-Djava.util.logging.config.file=$Catalina_Base\conf\logging.properties" 
    --JvmOptions9 "--add-opens=java.base/java.lang=ALL-UNNAMED#--add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED"
    --Startup "Manual"
    --JvmMs "128"
    --JvmMx "256"
"@

$params= $params.replace("`r`n","")

$temp = "//IS//$($ServiceName) $($params)"

Start-Process -FilePath "$PathToTomcatExe" -ArgumentList "//IS//$($ServiceName) $($params)" -NoNewWindow
break

if(Get-service -Name $ServiceName)
{
    Set-Service -Name $ServiceName -StartupType Automatic   
    Start-Service $ServiceName
    Rename-Item -Path "$($Catalina_Home)\bin\tomcat9w.exe" -NewName $ServiceName |Out-Null
}

 

