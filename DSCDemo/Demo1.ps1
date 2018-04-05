
# Öppna c$ på kraschobang
#$Sune = Get-Credential orebroll\tal008adm

Configuration TestKonf {

    Node kraschobang.orebroll.se {
        Service ConfigureService {
            Name = ’BITS’
            State = 'Running’
        } 
        File WorkDir {
            Type = 'Directory’	
            Ensure = 'Present’	
            DestinationPath = 'C:\MappNamn’
        }
    }
}

TestKonf -OutputPath C:\dsc
Start-DscConfiguration -ComputerName kraschobang.orebroll.se -Path C:\dsc -Wait -Verbose -Credential $sune -Force
