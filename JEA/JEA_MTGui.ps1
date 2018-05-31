# Det enda som kan behöva ändras är följande rad
$computers=@("Terrier","Papillon","En annan maskin","En tredje maskin")
$service="befregserv"
# Slut

#Peta inte på koden nedan!

if($PSVersionTable.PSVersion.Major -lt 5 ){Write-host "Detta script kräver Powershell version 5 eller senare!" -ForegroundColor Red ;break}

[xml]$xml=@"
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Hantera Tjänster" Height="330.424" Width="372.937" ScrollViewer.HorizontalScrollBarVisibility="Visible" ScrollViewer.CanContentScroll="True">
        <Grid Height="437" VerticalAlignment="Top" Margin="0,0,2,0">
        <TextBlock Name="textblock" TextWrapping="WrapWithOverflow" RenderTransformOrigin="-0.646,0.028" Margin="10,76,10,172" ScrollViewer.HorizontalScrollBarVisibility="Auto" ScrollViewer.VerticalScrollBarVisibility="Auto" ScrollViewer.CanContentScroll="True"/>
        <Button Name="starta" Content="Starta" HorizontalAlignment="Left" Margin="10,51,0,0" VerticalAlignment="Top" Width="66" />
        <Button Name="stoppa" Content="Stoppa" HorizontalAlignment="Left" Margin="95,51,0,0" VerticalAlignment="Top" Width="62"/>
        <Button Name="startaom" Content="Starta om" HorizontalAlignment="Left" Margin="175,51,0,0" VerticalAlignment="Top" Width="75"/>
        <ComboBox Name="comboBox" HorizontalAlignment="Left" VerticalAlignment="Top" Width="120" Margin="10,10,0,0" SelectedIndex="1" >
        <ComboBoxItem Content="- Välj miljö -" IsSelected="True" IsEnabled="False"/>$($computers | % { "<ComboBoxItem Content=`"$_`"/>"})</ComboBox>
        <Button Name="statuskoll" Content="Statuskoll" HorizontalAlignment="Left" Margin="175,12,0,0" VerticalAlignment="Top" Width="75"/>
    </Grid>
</Window>
"@

Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0)

try{ Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase,system.windows.forms } catch { Throw "Assemblies failed to load." }
#Create XAML reader
$xamGUI = [Windows.Markup.XamlReader]::Load((new-object System.Xml.XmlNodeReader $xml))
#Skapa variabler av namn-attributen i noderna ifrån xamljoxet
$xml.SelectNodes("//*[@Name]")|%{
    Set-Variable -Name ($_.Name) -Value $xamGUI.FindName($_.Name) -Scope Global
}

$starta.add_Click({
    if($comboBox.SelectedIndex -gt 0)
    {
        $servertotest = $comboBox.SelectedItem.content.ToString()
        $textblock.Text = "Startar '$service' på '$servertotest'`n"
        try{
            icm -ComputerName $servertotest -ConfigurationName MT_ServiceRestart -ErrorAction stop -Sc { try { Start-Service $using:service -Verbose -ErrorAction stop} catch { Throw $false } $true }
            $textblock.Text += "'$service' på '$servertotest' startad.`n"
        }
        catch {
            $textblock.Text = "[Misslyckades]`n" + $_ + "`n"
        }
    } else { $textblock.Text = "Du måste välja server först." }
})
$stoppa.add_Click({
    if($comboBox.SelectedIndex -gt 0)
    {
        $servertotest = $comboBox.SelectedItem.content.ToString()
        $textblock.Text = "Stoppar '$service' på '$servertotest'`n"
        try{
            icm -ComputerName $servertotest -ConfigurationName MT_ServiceRestart -ErrorAction stop -Sc { try { Stop-Service $using:service -Verbose -ErrorAction stop} catch { Throw $false } $true }
            $textblock.Text += "Tjänsten '$service' på '$servertotest' stoppad.`n"
        }
        catch {
            $textblock.Text = "[Misslyckades]`n" + $_ + "`n"
        }
    } else { $textblock.Text = "Du måste välja server först." }
})
$startaom.add_Click({
    if($comboBox.SelectedIndex -gt 0)
    {
        $servertotest = $comboBox.SelectedItem.content.ToString()
        $textblock.Text = "Startar om '$service' på '$servertotest'`n"
        try{
            icm -ComputerName $servertotest -ConfigurationName MT_ServiceRestart -ErrorAction stop -Sc { try { Restart-Service $using:service -Verbose -ErrorAction stop} catch { Throw $false } $true }
            $textblock.Text += "Tjänsten '$service' på '$servertotest' omstartad.`n"
        }
        catch {
            $textblock.Text = "[Misslyckades]`n" + $_ + "`n"
        }
    } else { $textblock.Text = "Du måste välja server först." }
})
$statuskoll.add_Click({
    if($comboBox.SelectedIndex -gt 0)
    {
        $servertotest = $comboBox.SelectedItem.content.ToString()
        try{
            $res = icm -ComputerName $servertotest -ConfigurationName MT_ServiceRestart -ErrorAction stop -Sc { try { Get-Service $using:service -Verbose -ErrorAction stop} catch { Throw $false } $true }
            #$res = icm -ComputerName "terrier" -ConfigurationName MT_ServiceRestart -ErrorAction stop -Sc { try { Get-Service "befregserv" -Verbose -ErrorAction stop} catch { Throw $false } $true }
           # write-verbose $res.status
           $textblock.Text = "Tjänsten på '$servertotest' är $($res.status)`n"
        }
        catch {
            $textblock.Text = "[Misslyckades]`n" + $_ + "`n"
        }
    } else { $textblock.Text = "Du måste välja server först." }
})
$xamGUI.ShowDialog() | out-null
