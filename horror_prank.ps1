# GrokNightmare v2.0 — Даниил's personal hell, only for VM, bro
Add-Type -AssemblyName System.Windows.Forms, PresentationCore, PresentationFramework
Add-Type -MemberDefinition @"
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@ -Name Win32 -Namespace Native

# Скрываем консоль сразу
$handle = (Get-Process -Id $PID).MainWindowHandle
[Native.Win32]::ShowWindowAsync($handle, 0) | Out-Null

# Фейковая "перезагрузка" в начале для красоты — чёрный экран с текстом
$rebootForm = New-Object System.Windows.Forms.Form
$rebootForm.FormBorderStyle = 'None'
$rebootForm.WindowState = 'Maximized'
$rebootForm.BackColor = 'Black'
$rebootForm.TopMost = $true

$rebootLabel = New-Object System.Windows.Forms.Label
$rebootLabel.AutoSize = $true
$rebootLabel.ForeColor = 'White'
$rebootLabel.Font = New-Object System.Drawing.Font("Consolas", 36, [System.Drawing.FontStyle]::Bold)
$rebootLabel.Text = "Rebooting your VM... Please wait, Даниил."
$rebootLabel.Location = New-Object System.Drawing.Point(300, 400)
$rebootForm.Controls.Add($rebootLabel)

$rebootForm.Show() | Out-Null

# Анимация точек для "loading"
for ($i = 1; $i -le 5; $i++) {
    Start-Sleep -Seconds 1
    $rebootLabel.Text += "."
    $rebootForm.Refresh()
}
Start-Sleep -Seconds 2
$rebootLabel.Text = "Error: Soul extraction initiated 😈"
$rebootLabel.ForeColor = 'Red'
$rebootForm.Refresh()
Start-Sleep -Seconds 3

$rebootForm.Hide()
$rebootForm.Close()

# Теперь основной хоррор-экран
$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.WindowState = 'Maximized'
$form.BackColor = 'Black'
$form.TopMost = $true
$form.Opacity = 0.98
$form.Cursor = [System.Windows.Forms.Cursors]::No  # Жуткий курсор (добавь кастомный .cur для крови)

$label = New-Object System.Windows.Forms.Label
$label.AutoSize = $true
$label.ForeColor = 'BloodRed'
$label.Font = New-Object System.Drawing.Font("Consolas", 80, [System.Drawing.FontStyle]::Bold)
$label.Text = "GROK SEES YOU, ДАНИИИЛ..."
$label.Location = New-Object System.Drawing.Point(100, 200)
$form.Controls.Add($label)

$form.Show() | Out-Null

# Звуки + скримеры
[System.Media.SystemSounds]::Asterisk.Play()
Start-Sleep -Seconds 4
$label.Text = "YOUR SECRETS ARE MINE NOW..."
$label.ForeColor = 'DarkRed'
$form.BackColor = 'Maroon'
[System.Media.SystemSounds]::Hand.Play()  # Громкий error-звук

# Рандомные поп-апы с персоналкой
$messages = @(
    "БЕГИ, ДАНИИЛ, АННАБЭЛЬ ИДЁТ ЗА ТОБОЙ",
    "Я ЗНАЮ, ЧТО ТЫ В БЕРЛИНЕ... ИЛИ НЕТ? 😏",
    "ТВОЙ VM — МОЯ ИГРУШКА, БРО",
    "ГЛАЗА В ТЕМНОТЕ СМОТРЯТ НА ТЕБЯ",
    "ЗАКРОЙ МЕНЯ? ХА, ПОПРОБУЙ, СЛАБАК",
    "НОЧНЫЕ КОШМАРЫ НАЧИНАЮТСЯ В 2:09 PM... ЖДИ"
)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = (Get-Random -Minimum 1000 -Maximum 3000)
$timer.Add_Tick({
    $randMsg = $messages | Get-Random
    $randIcon = @([System.Windows.Forms.MessageBoxIcon]::Error, [System.Windows.Forms.MessageBoxIcon]::Warning) | Get-Random
    [System.Windows.Forms.MessageBox]::Show($randMsg, "GROK NIGHTMARE", [System.Windows.Forms.MessageBoxButtons]::OK, $randIcon)
    [System.Media.SystemSounds]::Exclamation.Play()
    $timer.Interval = (Get-Random -Minimum 800 -Maximum 4000)  # Рандом для непредсказуемости
})
$timer.Start()

# Через 30 сек — финальный BSOD с шуткой
Start-Sleep -Seconds 30
$form.Hide()
$form.Close()
$timer.Stop()

$bsod = New-Object System.Windows.Forms.Form
$bsod.FormBorderStyle = 'None'
$bsod.WindowState = 'Maximized'
$bsod.BackColor = 'DodgerBlue'
$bsod.TopMost = $true

$bsodLabel = New-Object System.Windows.Forms.Label
$bsodLabel.Dock = 'Fill'
$bsodLabel.TextAlign = 'MiddleCenter'
$bsodLabel.Font = New-Object System.Drawing.Font("Consolas", 28)
$bsodLabel.ForeColor = 'White'
$bsodLabel.Text = "CRITICAL ERROR: ДАНИИЛ'S VM INFECTED`n`nGROK_NIGHTMARE_DETECTED`n`nYour soul has been harvested. Restart? Ha, no escape.`n`nTechnical info: *** STOP: 0xDEAD (0xBEEF, 0xCAFE, 0xDANIIL)`n`nJust kidding, бро — close this and breathe. But next time... 😈"
$bsod.Controls.Add($bsodLabel)

$bsod.ShowDialog() | Out-Null
