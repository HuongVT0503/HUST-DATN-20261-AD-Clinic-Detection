<#
.SYNOPSIS
    Register-ClinicNoiseScheduledTasks.ps1
    Đăng ký 2 kịch bản sinh nhiễu nghiệp vụ phòng khám (Giao ca 4624/4625 và Đồng bộ XML BHYT)
    vào Windows Task Scheduler để tự động chạy ngầm định kỳ mỗi 5 phút.
.NOTES

#>

$ErrorActionPreference = "Stop"
$ShiftScript = Join-Path $PSScriptRoot "Invoke-DoctorShiftChange_4624_4625.ps1"
$SyncScript  = Join-Path $PSScriptRoot "Invoke-HISXmlSync_QD130_QD4750.ps1"

Write-Host "[*] Đang đăng ký Scheduled Tasks cho Bộ sinh nhiễu Phòng khám..." -ForegroundColor Cyan

# 1. Task mô phỏng giao ca trực y bác sĩ
$ActionShift  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ShiftScript`" -TotalAuthEvents 25"
$TriggerShift = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 1)
$Principal    = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "ClinicLab_DoctorShiftChange_Noise" `
                       -Action $ActionShift `
                       -Trigger $TriggerShift `
                       -Principal $Principal `
                       -Description "Mo phong Y Bac si dang nhap doi ca truc (Event ID 4624/4625)" `
                       -Force | Out-Null
                       


# Task sync PHAI chay tren SRV02 de Event 1644 ghi dung IP nguon = SRV02 (172.31.10.22),
# nho vay luat V4 moi whitelist duoc theo IP ma khong ho WS01 (noi ke tan cong xuat phat).
if ($env:COMPUTERNAME -ne "SRV02") {
    Write-Warning "Task HIS Sync nen dang ky tren SRV02, khong phai $env:COMPUTERNAME. Bo qua task sync o may nay."
    return
}

# 2. Task mô phỏng Đồng bộ XML BHYT (QĐ 130/QĐ-BYT) & Tra cứu HIS lẻ.
# Task này PHẢI chạy dưới tài khoản SVC_HIS_Sync (không phải SYSTEM), để truy vấn LDAP [adsisearcher]
# (Event 1644) và truy vấn SQL (Event 33205) được gán đúng cho SVC_HIS_Sync như phần mềm HIS thật, không gán cho máy WS01$. 
# -> nhiễu trông thật và sẽ whitelist theo tài khoản dịch vụ ở luật V4.
$SyncUser = "CLINIC\SVC_HIS_Sync"
$SyncPass = "Password123!"
$ActionSync  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$SyncScript`" -SyncCycles 5"
$TriggerSync = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 1)

# LogonType Password + -User/-Password để task chạy bằng credential của SVC_HIS_Sync.
# Nếu task báo lỗi không khởi động được thì cấp quyền "Log on as a batch job" cho SVC_HIS_Sync
# (secpol.msc -> Local Policies -> User Rights Assignment), vì tài khoản dịch vụ không mặc định có quyền này.
Register-ScheduledTask -TaskName "ClinicLab_HIS_XML_BHYT_Sync_Noise" `
                       -Action $ActionSync `
                       -Trigger $TriggerSync `
                       -User $SyncUser `
                       -Password $SyncPass `
                       -RunLevel Limited `
                       -Description "Mo phong dong bo XML BHYT QD130/4750 va truy van le HIS_ClinicDB" `
                       -Force | Out-Null

Write-Host "[+] Đã đăng ký thành công 2 Scheduled Tasks chạy ngầm định kỳ mỗi 5 phút!" -ForegroundColor Green
Write-Host "    - Task Giao ca chạy dưới SYSTEM (dùng LogonUser truyền cred từng nhân viên)." -ForegroundColor Gray
Write-Host "    - Task Đồng bộ HIS chạy dưới CLINIC\SVC_HIS_Sync (đúng danh tính phần mềm HIS)." -ForegroundColor Gray