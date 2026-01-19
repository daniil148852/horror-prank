# Horror Prank 2026 edition — только для VM, бро, не дури
Add-Type -AssemblyName System.Windows.Forms
Add-Type -MemberDefinition @"
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@ -Name Win32 -Namespace Native

# Скрываем окно PowerShell
$handle = (Get-Process -Id $PID).MainWindowHandle
[Native.Win32]::ShowWindowAsync($handle, 0) | Out-Null

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.WindowState = 'Maximized'
$form.BackColor = 'Black'
$form.TopMost = $true
$form.Opacity = 0.92

$label = New-Object System.Windows.Forms.Label
$label.AutoSize = $true
$label.ForeColor = 'Red'
$label.Font = New-Object System.Drawing.Font("Consolas", 48, [System.Drawing.FontStyle]::Bold)
$label.Text = "HUMANS ARE TASTY..."
$label.Location = New-Object System.Drawing.Point(($form.Width/2 - 300), ($form.Height/2 - 100))

$form.Controls.Add($label)

$form.Show()

# Скример через 8 сек
Start-Sleep -Seconds 8
$label.Text = "I SEE YOU, ДАНИИИИЛ..."
$label.ForeColor = 'DarkRed'
$form.BackColor = 'Maroon'
[System.Media.SystemSounds]::Hand.Play()

Start-Sleep -Seconds 4
$label.Text = "YOUR VM IS MINE NOW..."
$form.Opacity = 0.6

# Таймер для рандомных поп-апов
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2500
$timer.Add_Tick({
    $msg = @("Беги", "Она здесь", "Глаза везде", "Ты следующий", "Close me? LOL NO")[Get-Random -Maximum 5]
    [System.Windows.Forms.MessageBox]::Show($msg, "HorrorBob приветствует", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
})
$timer.Start()

# Держим скрипт живым
while ($form.Visible) { Start-Sleep -Milliseconds 100 }
