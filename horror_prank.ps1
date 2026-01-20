Write-Host "=== SUPER ANTI-MALWARE CLEANER ===" -ForegroundColor Cyan

# 1. Остановка подозрительных PowerShell
Get-Process powershell -ErrorAction SilentlyContinue | 
Where-Object { $_.MainWindowTitle -eq "" } | 
Stop-Process -Force

# 2. Очистка автозапуска (реестр)
$runPaths = @(
 "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
 "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
)

foreach ($path in $runPaths) {
    if (Test-Path $path) {
        Get-ItemProperty $path | Get-Member -MemberType NoteProperty | ForEach-Object {
            Remove-ItemProperty -Path $path -Name $_.Name -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "[OK] Реестр очищен" -ForegroundColor Green

# 3. Очистка Startup
$startup = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
Get-ChildItem $startup -ErrorAction SilentlyContinue | Remove-Item -Force

Write-Host "[OK] Startup очищен" -ForegroundColor Green

# 4. Удаление задач планировщика
Get-ScheduledTask | 
Where-Object { $_.TaskName -like "*Defender*" -or $_.TaskName -like "*Update*" } |
Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

Write-Host "[OK] Планировщик очищен" -ForegroundColor Green

# 5. Очистка WMI Persistence
$wmiNS = "root\subscription"
Get-WmiObject -Namespace $wmiNS -Class __EventFilter -ErrorAction SilentlyContinue | Remove-WmiObject
Get-WmiObject -Namespace $wmiNS -Class CommandLineEventConsumer -ErrorAction SilentlyContinue | Remove-WmiObject
Get-WmiObject -Namespace $wmiNS -Class __FilterToConsumerBinding -ErrorAction SilentlyContinue | Remove-WmiObject

Write-Host "[OK] WMI очищен" -ForegroundColor Green

# 6. Удаление копий вируса
$paths = @(
 $env:TEMP,
 $env:APPDATA,
 $env:LOCALAPPDATA,
 "C:\Users\Public"
)

foreach ($p in $paths) {
    Get-ChildItem $p -Recurse -Include *.ps1,*.vbs -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt 1000 } |
    Remove-Item -Force
}

Write-Host "[OK] Файлы удалены" -ForegroundColor Green

# 7. Блокировка PowerShell-вирусов
Set-ExecutionPolicy Restricted -Scope LocalMachine -Force
Set-ExecutionPolicy Restricted -Scope CurrentUser -Force

Write-Host "[OK] PowerShell заблокирован" -ForegroundColor Green

# 8. Восстановление обоев
$wall = "C:\Windows\Web\Wallpaper\Windows\img0.jpg"
Add-Type @"
using System.Runtime.InteropServices;
public class WP {
[DllImport("user32.dll")]
public static extern int SystemParametersInfo(int a,int b,string c,int d);
}
"@
[WP]::SystemParametersInfo(20,0,$wall,3)

Write-Host "[OK] Обои восстановлены" -ForegroundColor Green

Write-Host "=== ОЧИСТКА ЗАВЕРШЕНА ===" -ForegroundColor Cyan
