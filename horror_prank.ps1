# GrokNightmare v3.0 — "Опасный" Edition, Даниил в Берлине, 19 января 2026, 14:20 CET
Add-Type -AssemblyName System.Windows.Forms, PresentationCore, PresentationFramework
Add-Type -MemberDefinition @"
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll")]
public static extern bool SetCursorPos(int X, int Y);
"@ -Name Win32 -Namespace Native

# Скрываем консоль
$handle = (Get-Process -Id $PID).MainWindowHandle
[Native.Win32]::ShowWindowAsync($handle, 0) | Out-Null

# Фейковая "критическая перезагрузка" — чёрный экран с прогрессом
$reboot = New-Object System.Windows.Forms.Form
$reboot.FormBorderStyle = 'None'
$reboot.WindowState = 'Maximized'
$reboot.BackColor = 'Black'
$reboot.TopMost = $true

$prog = New-Object System.Windows.Forms.Label
$prog.AutoSize = $true
$prog.ForeColor = 'Red'
$prog.Font = New-Object System.Drawing.Font("Consolas", 48, [System.Drawing.FontStyle]::Bold)
$prog.Text = "CRITICAL FAILURE - Rebooting VM... 0%"
$prog.Location = New-Object System.Drawing.Point(200, 400)
$reboot.Controls.Add($prog)

$reboot.Show() | Out-Null

# Анимация прогресса (типа умирает)
for ($p = 0; $p -le 100; $p += 5) {
    $prog.Text = "CRITICAL FAILURE - Rebooting VM... $p%"
    $reboot.Refresh()
    Start-Sleep -Milliseconds (Get-Random -Min 300 -Max 800)
    [System.Media.SystemSounds]::Exclamation.Play()  # Громкие пискляки
}
$prog.Text = "SOUL HARVEST COMPLETE. DANIIIL IN BERLIN DETECTED 😈"
$reboot.Refresh()
Start-Sleep -Seconds 4
$reboot.Hide(); $reboot.Close()

# Основной horror-экран: инверсия цветов + flicker
$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.WindowState = 'Maximized'
$form.BackColor = 'Black'
$form.TopMost = $true
$form.Opacity = 0.97
$form.Cursor = [System.Windows.Forms.Cursors]::No  # Жуткий запрещающий курсор

$label = New-Object System.Windows.Forms.Label
$label.AutoSize = $true
$label.ForeColor = 'Red'
$label.Font = New-Object System.Drawing.Font("Consolas", 90, [System.Drawing.FontStyle]::Bold)
$label.Text = "GROK OWNS YOU, ДАНИИЛ"
$label.Location = New-Object System.Drawing.Point(150, 250)
$form.Controls.Add($label)

$form.Show() | Out-Null

# Мигающий экран + инверсия (симуляция)
$timerFlicker = New-Object System.Windows.Forms.Timer
$timerFlicker.Interval = 150
$timerFlicker.Add_Tick({
    if ($form.BackColor -eq 'Black') {
        $form.BackColor = 'White'
        $label.ForeColor = 'Black'
    } else {
        $form.BackColor = 'Black'
        $label.ForeColor = 'Red'
    }
    $form.Refresh()
})
$timerFlicker.Start()

# Рандомные скримеры + звуки
$scaryMsgs = @(
    "2:20 PM В БЕРЛИНЕ — ТВОЁ ВРЕМЯ ИСТЕКАЕТ",
    "Я ЗНАЮ ТВОЙ IP... И ТВОИ СТРАХИ",
    "АННАБЭЛЬ ЖДЁТ ЗА ЭКРАНОМ",
    "VM УМИРАЕТ... ТЫ СЛЕДУЮЩИЙ",
    "ЗАКРОЙ? НЕТ ШАНСОВ, БРО",
    "ГЛАЗА СМОТРЯТ ИЗ ТЕМНОТЫ"
)

$timerPopup = New-Object System.Windows.Forms.Timer
$timerPopup.Interval = (Get-Random -Min 1200 -Max 3500)
$timerPopup.Add_Tick({
    $msg = $scaryMsgs | Get-Random
    [System.Windows.Forms.MessageBox]::Show($msg, "GROK NIGHTMARE v3.0", 'OK', 'Error')
    [System.Media.SystemSounds]::Hand.Play()   # Громкий скример-звук
    [System.Media.SystemSounds]::Asterisk.Play()
})
$timerPopup.Start()

# Финал: супер-фейковый BSOD с "анимацией"
Start-Sleep -Seconds 35
$timerFlicker.Stop(); $timerPopup.Stop()
$form.Hide(); $form.Close()

$bsod = New-Object System.Windows.Forms.Form
$bsod.FormBorderStyle = 'None'
$bsod.WindowState = 'Maximized'
$bsod.BackColor = 'DodgerBlue'
$bsod.TopMost = $true

$bsodTxt = New-Object System.Windows.Forms.Label
$bsodTxt.Dock = 'Fill'
$bsodTxt.TextAlign = 'MiddleCenter'
$bsodTxt.Font = New-Object System.Drawing.Font("Consolas", 32)
$bsodTxt.ForeColor = 'White'
$bsodTxt.Text = "A fatal exception 0E has occurred at 0028:C0011E36 in VXD VMM(01) + 00010E36.`n`nGROK_NIGHTMARE caused an invalid page fault.`n`nDANIIIL BERLIN 19.01.2026 14:20 — YOUR VM IS DEAD.`n`n*  Press any key to continue _`n`n(это фейк, бро, но сердце ёкнуло, да? 😈)"
$bsod.Controls.Add($bsodTxt)

$bsod.ShowDialog() | Out-Null
