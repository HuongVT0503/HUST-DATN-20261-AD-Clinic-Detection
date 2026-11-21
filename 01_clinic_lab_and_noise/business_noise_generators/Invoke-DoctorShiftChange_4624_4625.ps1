<#
.SYNOPSIS
    Invoke-DoctorShiftChange_4624_4625.ps1
    Mô phỏng lưu lượng nền nghiệp vụ y tế: Y bác sĩ và điều dưỡng đăng nhập/đăng xuất
    đổi ca trực liên tục trên máy trạm dùng chung WS01 (kèm tỷ lệ 5% gõ sai mật khẩu).
    Sinh sự kiện Windows Security Event ID 4624 (Success) và 4625 (Failure) trên DC01 & WS01.
.NOTES
    Đồ án Tốt nghiệp Kỳ 2026.1 - Sinh viên: Vũ Thúy Hường (MSSV: 20225135)
    Phương pháp luận: Synthetic Benign Activity Generation , .
#>

param(
    [int]$TotalAuthEvents = 60,
    [int]$TypoFailureRatePercent = 5,
    [string]$DomainName = "clinic.local",
    [string]$TargetServer = "SRV02.clinic.local"
)

$ErrorActionPreference = "SilentlyContinue"
Write-Host "[*] Khởi chạy Bộ sinh nhiễu Giao ca Y tế (Shift-Change Noise Generator)..." -ForegroundColor Cyan
Write-Host "    -> Tổng số phiên xác thực mô phỏng: $TotalAuthEvents (Tỷ lệ gõ nhầm mật khẩu: $TypoFailureRatePercent%)" -ForegroundColor Gray

# Định nghĩa P/Invoke gọi Win32 API LogonUser để kích hoạt xác thực Kerberos/NTLM thực sự
$LogonApiCode = @"
using System;
using System.Runtime.InteropServices;
public class Win32Auth {
    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool LogonUser(
        string lpszUsername,
        string lpszDomain,
        string lpszPassword,
        int dwLogonType,
        int dwLogonProvider,
        out IntPtr phToken
    );
    [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
    public static extern bool CloseHandle(IntPtr handle);
}
"@
Add-Type -TypeDefinition $LogonApiCode -ErrorAction SilentlyContinue

# Danh sách tài khoản Y Bác sĩ, Điều dưỡng, Lễ tân tham gia đổi ca
$ShiftUsers = @()
1..30 | ForEach-Object { $ShiftUsers += ("BS_BacSi{0:D3}" -f $_) }
1..40 | ForEach-Object { $ShiftUsers += ("YT_YTa{0:D3}" -f $_) }
1..15 | ForEach-Object { $ShiftUsers += ("LT_LeTan{0:D3}" -f $_) }

$CorrectPass = "Clinic@2026!"
$WrongPass   = "Clinic@2026_Typo!"

for ($i = 1; $i -le $TotalAuthEvents; $i++) {
    $SelectedUser = $ShiftUsers | Get-Random
    $RandomRoll   = Get-Random -Minimum 1 -Maximum 101

    if ($RandomRoll -le $TypoFailureRatePercent) {
        # Mô phỏng 5% nhân viên y tế gõ nhầm mật khẩu lúc vội giao ca -> Sinh Event ID 4625 / 4771
        $Token = [IntPtr]::Zero
        [Win32Auth]::LogonUser($SelectedUser, $DomainName, $WrongPass, 2, 0, [ref]$Token) | Out-Null
        net use "\\$TargetServer\IPC$" $WrongPass /user:"$DomainName\$SelectedUser" 2>$null | Out-Null
        Write-Host "[$i/$TotalAuthEvents] [4625 - GÕ NHẦM PASS] $DomainName\$SelectedUser đăng nhập thất bại do gõ sai phím." -ForegroundColor Yellow

        # Ngay sau khi gõ sai 1–2 giây, nhân viên gõ lại mật khẩu đúng -> Sinh Event ID 4624
        Start-Sleep -Milliseconds (Get-Random -Minimum 800 -Maximum 1800)
        [Win32Auth]::LogonUser($SelectedUser, $DomainName, $CorrectPass, 2, 0, [ref]$Token) | Out-Null
        if ($Token -ne [IntPtr]::Zero) { [Win32Auth]::CloseHandle($Token) | Out-Null }
    }
    else {
        # Mô phỏng 95% đăng nhập đổi ca hợp lệ -> Sinh Event ID 4624 & Kerberos TGS 4769 hợp lệ
        $Token = [IntPtr]::Zero
        $Result = [Win32Auth]::LogonUser($SelectedUser, $DomainName, $CorrectPass, 2, 0, [ref]$Token)
        if ($Token -ne [IntPtr]::Zero) { [Win32Auth]::CloseHandle($Token) | Out-Null }

        # Kết nối nhẹ sang SMB Share của SRV02 để sinh lưu lượng xác thực mạng ca trực
        net use "\\$TargetServer\BenhAn$" $CorrectPass /user:"$DomainName\$SelectedUser" 2>$null | Out-Null
        net use "\\$TargetServer\BenhAn$" /delete /y 2>$null | Out-Null

        Write-Host "[$i/$TotalAuthEvents] [4624 - HỢP LỆ] $DomainName\$SelectedUser đã đăng nhập nhận ca trực tại $env:COMPUTERNAME." -ForegroundColor Green
    }

    # Giãn cách ngẫu nhiên giữa các lượt đổi ca (0.5 - 2 giây)
    Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
}

Write-Host "[+] Hoàn tất mô phỏng lưu lượng giao ca trực (Event ID 4624 / 4625)!" -ForegroundColor Cyan