$VerbosePreference="Continue"
# Det enda som kan behöva ändras är följande rad
$computers=@("Terrier","Papillon")
$service="bits","is_DMS_Orders","is_DMS_Results"
# Slut

# Peta inte på koden nedan!
# !
if($PSVersionTable.PSVersion.Major -lt 5 ){Write-host "Detta script kräver Powershell version 5 eller senare!" -ForegroundColor Red ;break}
[xml]$xml=@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Hantera Tjänster" Height="330.424" Width="372.937" ScrollViewer.HorizontalScrollBarVisibility="Visible" ScrollViewer.CanContentScroll="True">
    <Grid Height="437" VerticalAlignment="Top" Margin="0,0,2,0">
        <TextBlock Name="textblock" TextWrapping="WrapWithOverflow" RenderTransformOrigin="-0.646,0.028" Margin="25,110,0,10" ScrollViewer.HorizontalScrollBarVisibility="Auto" ScrollViewer.VerticalScrollBarVisibility="Auto" ScrollViewer.CanContentScroll="True"/>
        <GroupBox Header="Tjänster" HorizontalAlignment="Left" Margin="25,0,0,0" VerticalAlignment="Top" Height="110" Width="297">
            <Grid HorizontalAlignment="Left" Height="219" VerticalAlignment="Top">
                <StackPanel Name="Radioknappar" Orientation="Vertical" Margin="140,5,0,0">$($dist=5;$service | % { "<RadioButton Name=`"service_$($_)`" Content=`"$($_)`" GroupName=`"knappar`" />" ;$dist+=15 })</StackPanel>
                <ComboBox Name="comboBox" HorizontalAlignment="Left" VerticalAlignment="Top" Width="120" Margin="10,8,0,0" SelectedIndex="1" ><ComboBoxItem Content="- Välj server -" IsSelected="false" IsEnabled="False"/>$($computers | % { "<ComboBoxItem Content=`"$_`"/>"})</ComboBox>
                <Button Name="starta" Content="Starta" HorizontalAlignment="Left" Margin="10,54,0,0" VerticalAlignment="Top" Width="59" />
                <Button Name="stoppa" Content="Stoppa" HorizontalAlignment="Left" Margin="77,54,0,0" VerticalAlignment="Top" Width="59"/>
                <Button Name="startaom" Content="Starta om" HorizontalAlignment="Left" Margin="145,54,0,0" VerticalAlignment="Top" Width="59"/>
                <Button Name="statuskoll" Content="Statuskoll" HorizontalAlignment="Left" Margin="212,54,0,0" VerticalAlignment="Top" Width="59"/>
                <Label Name="label" Content="Tillverkad av Thomas Almén, Regionservice IT Serverdrift 2018" HorizontalAlignment="Left" Margin="7,70,0,0" VerticalAlignment="Top" Height="25" FontSize="9"/>
            </Grid>
        </GroupBox>
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
[Console.Window]::ShowWindow($consolePtr, 0) | Out-Null


try{ Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase,system.windows.forms } catch { Throw "Assemblies failed to load." }
#Create XAML reader
$xamGUI = [Windows.Markup.XamlReader]::Load((new-object System.Xml.XmlNodeReader $xml))
#Skapa variabler av namn-attributen i noderna ifrån xamljoxet
$xml.SelectNodes("//*[@Name]")|%{
    Set-Variable -Name ($_.Name) -Value $xamGUI.FindName($_.Name) -Scope Global
}
$servicetorestart = ""
[System.Windows.RoutedEventHandler]$ChoosedRadioHandler = {
    $Script:servicetorestart = $_.source.Content
}
$Radioknappar.AddHandler([System.Windows.Controls.RadioButton]::CheckedEvent, $ChoosedRadioHandler)

$statuskoll.add_Click({
    if($comboBox.SelectedIndex -gt 0)
    {
        $servertotest = $comboBox.SelectedItem.content.ToString()
        if($servicetorestart -ne "")
        {
            try{
                $res = icm -ComputerName $servertotest -ConfigurationName dms_services -ErrorAction stop -Sc { try { Get-Service $($using:servicetorestart) -ErrorAction stop} catch { Throw  } $true }
                $textblock.Text = "Tjänsten '$servicetorestart' på '$servertotest' är [$($res.status)]`n"
            }
            catch {
                $textblock.Text = "[Misslyckades]`n" + $_ + "`n"
            }
        }
        else { $textblock.Text = "Du måste välja tjänst." }
    } else { $textblock.Text = "Du måste välja server." }
})
$starta.add_Click({
    if($comboBox.SelectedIndex -gt 0)
    {
        $servertotest = $comboBox.SelectedItem.content.ToString()
        if($servicetorestart -ne "")
        {
            try{
                $res = icm -ComputerName $servertotest -ConfigurationName dms_services -ErrorAction stop -Sc { try { Start-Service $($using:servicetorestart) -ErrorAction stop} catch { Throw  } $true }
                $check = icm -ComputerName $servertotest -ConfigurationName dms_services -ErrorAction stop -Sc { try { Get-Service $($using:servicetorestart) -ErrorAction stop} catch { Throw  } $true }
                $textblock.Text = "Tjänsten '$servicetorestart' på '$servertotest' är [$($check.status)]"
            }
            catch {
                $textblock.Text = "[Misslyckades]`n" + $_ + "`n"
            }
        }
        else { $textblock.Text = "Du måste välja tjänst." }
    } else { $textblock.Text = "Du måste välja server." }
})
$stoppa.add_Click({
    if($comboBox.SelectedIndex -gt 0)
    {
        $servertotest = $comboBox.SelectedItem.content.ToString()
        if($servicetorestart -ne "")
        {
            try{
                $res = icm -ComputerName $servertotest -ConfigurationName dms_services -ErrorAction stop -Sc { try { Stop-Service $($using:servicetorestart) -ErrorAction stop} catch { Throw  } $true }
                $check = icm -ComputerName $servertotest -ConfigurationName dms_services -ErrorAction stop -Sc { try { Get-Service $($using:servicetorestart) -ErrorAction stop} catch { Throw  } $true }
                $textblock.Text = "Tjänsten '$servicetorestart' på '$servertotest' är [$($check.status)]"
            }
            catch {
                $textblock.Text = "[Misslyckades]`n" + $_ + "`n"
            }
        }
        else { $textblock.Text = "Du måste välja tjänst." }
    } else { $textblock.Text = "Du måste välja server." }
})
$startaom.add_Click({
    if($comboBox.SelectedIndex -gt 0)
    {
        $servertotest = $comboBox.SelectedItem.content.ToString()
        if($servicetorestart -ne "")
        {
            try{
                $res = icm -ComputerName $servertotest -ConfigurationName dms_services -ErrorAction stop -Sc { try { Restart-Service $($using:servicetorestart) -ErrorAction stop} catch { Throw  } $true }
                $check = icm -ComputerName $servertotest -ConfigurationName dms_services -ErrorAction stop -Sc { try { Get-Service $($using:servicetorestart) -ErrorAction stop} catch { Throw  } $true }
                $textblock.Text = "Tjänsten '$servicetorestart' på '$servertotest' är [$($check.status)]"
            }
            catch {
                $textblock.Text = "[Misslyckades]`n" + $_ + "`n"
            }
        }
        else { $textblock.Text = "Du måste välja tjänst." }
    } else { $textblock.Text = "Du måste välja server." }
})
$xamGUI.ShowDialog() | out-null
