Write-Host "=== Anti-BSOD Cleaner started ===" -ForegroundColor Cyan

# 1. Проверка и удаление автозапуска
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$badName = "WindowsDefenderHelper"

if (Get-ItemProperty -Path $regPath -Name $badName -ErrorAction SilentlyContinue) {
    Remove-ItemProperty -Path $regPath -Name $badName -Force
    Write-Host "[OK] Автозапуск удалён" -ForegroundColor Green
} else {
    Write-Host "[OK] Автозапуск не найден" -ForegroundColor Green
}

# 2. Удаление файлов вредоноса
$files = @(
    "$env:TEMP\svchost_helper.exe",
    "$env:TEMP\payload.bin"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Remove-Item $file -Force
        Write-Host "[OK] Удалён файл: $file" -ForegroundColor Green
    } else {
        Write-Host "[OK] Файл не найден: $file" -ForegroundColor Gray
    }
}

# 3. Сброс обоев на стандартные
$defaultWallpaper = "C:\Windows\Web\Wallpaper\Windows\img0.jpg"

Add-Type @"
using System.Runtime.InteropServices;
public class Wallpaper {
  [DllImport("user32.dll", CharSet=CharSet.Auto)]
  public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

[Wallpaper]::SystemParametersInfo(20, 0, $defaultWallpaper, 3)
Write-Host "[OK] Обои восстановлены" -ForegroundColor Green

# 4. Блокировка опасных PowerShell-скриптов
Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope CurrentUser -Force
Write-Host "[OK] Выполнение подозрительных скриптов заблокировано" -ForegroundColor Green

Write-Host "=== Очистка завершена ===" -ForegroundColor Cyan
