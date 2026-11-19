<#
.SYNOPSIS
    Register-ClinicNoiseScheduledTasks.ps1
    Đăng ký 2 kịch bản sinh nhiễu nghiệp vụ phòng khám (Giao ca 4624/4625 và Đồng bộ XML BHYT)
    vào Windows Task Scheduler để tự động chạy ngầm định kỳ mỗi 5 phút.
.NOTES
    Đồ án Tốt nghiệp Kỳ 2026.1 - Sinh viên: Vũ Thúy Hường (MSSV: 20225135)
#>

$ErrorActionPreference = "Stop"
$ShiftScript = Join-Path $PSScriptRoot "Invoke-DoctorShiftChange_4624_4625.ps1"
$SyncScript  = Join-Path $PSScriptRoot "Invoke-HISXmlSync_QD130_QD4750.ps1"

Write-Host "[*] Đang đăng ký Scheduled Tasks cho Bộ sinh nhiễu Phòng khám..." -ForegroundColor Cyan

# 1. Task mô phỏng Giao ca trực Y Bác sĩ
$ActionShift  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ShiftScript`" -TotalAuthEvents 25"
$TriggerShift = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 1)
$Principal    = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "ClinicLab_DoctorShiftChange_Noise" `
                       -Action $ActionShift `
                       -Trigger $TriggerShift `
                       -Principal $Principal `
                       -Description "Mo phong Y Bac si dang nhap doi ca truc (Event ID 4624/4625)" `
                       -Force | Out-Null

# 2. Task mô phỏng Đồng bộ XML BHYT (QĐ 130/QĐ-BYT) & Tra cứu HIS lẻ
$ActionSync  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$SyncScript`" -SyncCycles 5"
$TriggerSync = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 1)

Register-ScheduledTask -TaskName "ClinicLab_HIS_XML_BHYT_Sync_Noise" `
                       -Action $ActionSync `
                       -Trigger $TriggerSync `
                       -Principal $Principal `
                       -Description "Mo phong dong bo XML BHYT QD130/4750 va truy van le HIS_ClinicDB" `
                       -Force | Out-Null

Write-Host "[+] Đã đăng ký thành công 2 Scheduled Tasks chạy ngầm định kỳ mỗi 5 phút!" -ForegroundColor Green