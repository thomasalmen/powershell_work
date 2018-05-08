# Det enda som kan behöva ändras är följande rad
$computers=@("Terrier","Produktionsmaskinen","En annan maskin")
# Slut

[xml]$xml=@"
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Starta om tjänst" Height="330.424" Width="372.937" ScrollViewer.HorizontalScrollBarVisibility="Visible" ScrollViewer.CanContentScroll="True">
        <Grid Height="437" VerticalAlignment="Top" Margin="0,0,2,0">
        <TextBlock Name="textblock" TextWrapping="WrapWithOverflow" RenderTransformOrigin="-0.646,0.028" Margin="10,90,10,158" ScrollViewer.HorizontalScrollBarVisibility="Auto" ScrollViewer.VerticalScrollBarVisibility="Auto" ScrollViewer.CanContentScroll="True"/>
        <Button Name="starta" Content="Starta" HorizontalAlignment="Left" Margin="10,51,0,0" VerticalAlignment="Top" Width="66" />
        <Button Name="stoppa" Content="Stoppa" HorizontalAlignment="Left" Margin="95,51,0,0" VerticalAlignment="Top" Width="62"/>
        <Button Name="startaom" Content="Starta om" HorizontalAlignment="Left" Margin="175,51,0,0" VerticalAlignment="Top" Width="75"/>
        <ComboBox Name="comboBox" HorizontalAlignment="Left" VerticalAlignment="Top" Width="120" Margin="10,10,0,0" SelectedIndex="1" >
        <ComboBoxItem Content="- Välj miljö -" IsSelected="True" IsEnabled="False"/>
        $($computers | % { "<ComboBoxItem Content=`"$_`"/>"})
        </ComboBox>
        <Button Name="statuskoll" Content="Statuskoll" HorizontalAlignment="Left" Margin="175,12,0,0" VerticalAlignment="Top" Width="75"/>
    </Grid>
</Window>
"@
$service="befregserv"
try{ Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase,system.windows.forms } catch { Throw "Assemblies failed to load." }
#Create XAML reader
$xamGUI = [Windows.Markup.XamlReader]::Load((new-object System.Xml.XmlNodeReader $xml))
#Skapa variabler av namn-attributen i noderna ifrån xamljoxet
$xml.SelectNodes("//*[@Name]") | %{
    Set-Variable -Name ($_.Name) -Value $xamGUI.FindName($_.Name) -Scope Global
}
$starta.add_Click({
    $servertotest = $comboBox.SelectedItem.content.ToString()
    try{
        icm -ComputerName $servertotest -ConfigurationName MT_ServiceRestart -ErrorAction stop -Sc { try { Start-Service $using:service -Verbose -ErrorAction stop} catch { Throw $false } $true }
        $textblock.Text = "'$service' på '$servertotest' startad [OK]`n"
    }
    catch {
        $textblock.Text = "[Misslyckades]`n" + $_ + "`n"
    }
})
$stoppa.add_Click({
    $servertotest = $comboBox.SelectedItem.content.ToString()
    try{
        icm -ComputerName $servertotest -ConfigurationName MT_ServiceRestart -ErrorAction stop -Sc { try { Stop-Service befregserv -Verbose -ErrorAction stop} catch { Throw $false } $true }
        $textblock.Text = "'$service' på '$servertotest' stoppad [OK]`n"
    }
    catch {
        $textblock.Text = "[Misslyckades]`n" + $_ + "`n"
    }
})
$startaom.add_Click({
    $servertotest = $comboBox.SelectedItem.content.ToString()
    try{
        icm -ComputerName $servertotest -ConfigurationName MT_ServiceRestart -ErrorAction stop -Sc { try { Restart-Service befregserv -Verbose -ErrorAction stop} catch { Throw $false } $true }
        $textblock.Text = "'$service' på '$servertotest' omstartad [OK]`n"
    }
    catch {
        $textblock.Text = "[Misslyckades]`n" + $_ + "`n"
    }
})
$statuskoll.add_Click({
    $servertotest = $comboBox.SelectedItem.content.ToString()
    try{
        $res = icm -ComputerName $servertotest -ConfigurationName MT_ServiceRestart -ErrorAction stop -Sc { try { (get-Service befregserv -Verbose -ErrorAction stop).status } catch { Throw $false }  }
        $textblock.Text = "Tjänsten på '$servertotest' är $($res.value)`n"
    }
    catch {
        $textblock.Text = "[Misslyckades]`n" + $_ + "`n"
    }
})
$xamGUI.ShowDialog() | out-null