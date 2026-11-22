<#
.SYNOPSIS
    02_DC01_Stage2_ConfigureAD_Audit.ps1
    Chạy trên DC01 SAU khi đã reboot và đăng nhập lại bằng CLINIC\Administrator.
    - Nạp 6 OU, 5 Group, 200 định danh + 3 service account (gọi Import-ClinicADUsers.ps1).
    - Bật telemetry phía phòng thủ: Registry 1644, auditpol 4769/4624/4625, nới .evtx.
    - Cài Sysmon trên DC01.
.NOTES
    Bản tách tay của PLAY 2 trong provisioning_clinic.yml.
#>

$ErrorActionPreference = "Stop"
# Thư mục gốc repo = lùi 3 cấp từ thư mục chứa script này (aws_powershell_bootstrap)
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
Write-Host "[*] [DC01 - Stage 2] Repo root: $RepoRoot" -ForegroundColor Cyan

# 1. Nạp định danh phòng khám (script tự sinh đủ 200 user vào CSV nếu CSV chưa đủ)
$ImportScript = Join-Path $RepoRoot "01_clinic_lab_and_noise\ad_identity_200_users\Import-ClinicADUsers.ps1"
powershell.exe -ExecutionPolicy Bypass -File $ImportScript

# 2. Bật log truy vấn LDAP expensive/inefficient (Event ID 1644) và hạ ngưỡng để bắt mọi truy vấn ADSI
#    Nguồn registry key: Microsoft - How to find expensive/inefficient LDAP queries (xem keep.md)
$RegFile = Join-Path $RepoRoot "02_telemetry_and_scenarios\telemetry_configs\Enable-LDAP-1644-Diagnostics.reg"
reg import $RegFile
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics" -Name "15 Field Engineering" -Value 5 -Type DWord
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "Expensive Search Results Threshold" -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "Inefficient Search Results Threshold" -Value 1 -PropertyType DWord -Force | Out-Null

# 3. Bật Advanced Audit Policy cho Kerberos (4769) và Logon/Logoff (4624/4625) + nới dung lượng .evtx lên 512MB
auditpol /set /subcategory:"Kerberos Service Ticket Operations" /success:enable /failure:enable | Out-Null
auditpol /set /subcategory:"Kerberos Authentication Service" /success:enable /failure:enable | Out-Null
auditpol /set /subcategory:"Logon" /success:enable /failure:enable | Out-Null
auditpol /set /subcategory:"Logoff" /success:enable | Out-Null
wevtutil sl Security /ms:536870912
wevtutil sl "Directory Service" /ms:536870912

# 4. Cài Sysmon trên DC01
$SysmonConfig = Join-Path $RepoRoot "02_telemetry_and_scenarios\telemetry_configs\sysmon_clinic_config.xml"
New-Item -Path "C:\Tools" -ItemType Directory -Force | Out-Null
if (-not (Get-Service Sysmon64 -ErrorAction SilentlyContinue)) {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "C:\Tools\Sysmon.zip"
    Expand-Archive -Path "C:\Tools\Sysmon.zip" -DestinationPath "C:\Tools\Sysmon" -Force
    if ((Test-Path $SysmonConfig) -and ((Get-Item $SysmonConfig).Length -gt 0)) {
        C:\Tools\Sysmon\Sysmon64.exe -accepteula -i $SysmonConfig
    } else {
        Write-Warning "sysmon_clinic_config.xml đang RỖNG. Cài Sysmon với cấu hình mặc định tạm thời."
        Write-Warning "Hãy điền file này trước khi chạy thật, nếu không sẽ thiếu Event ID 1 (ProcessCreate) cho 3 kịch bản."
        C:\Tools\Sysmon\Sysmon64.exe -accepteula -i
    }
}

Write-Host "[+] [DC01 - Stage 2] Hoàn tất. Kiểm tra: (Get-ADUser -Filter *).Count phải > 200." -ForegroundColor Green
