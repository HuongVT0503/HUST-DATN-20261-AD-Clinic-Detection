<#
.SYNOPSIS
    04_SRV02_Stage2_SetupHIS_SQL_SMB.ps1
    Chạy trên SRV02 SAU khi đã join miền và đăng nhập lại bằng CLINIC\Administrator.
    - Thêm service account vào Local Administrators.
    - Tạo SMB Share ẩn \\SRV02\BenhAn$ + SACL (gọi Setup_SMB_BenhAn_Share.ps1).
    - Cài MS SQL Server Express (Mixed Mode), nạp HIS_ClinicDB + SQL Audit 33205.
    - Cài Sysmon.
.NOTES
    Bản tách tay của PLAY 4 trong provisioning_clinic.yml.
    SQL cài ở Mixed Mode (/SECURITYMODE=SQL) vì Init_HIS_EMR_Schema.sql cần tạo SQL Login
    cho SVC_HIS_Sync. Nếu muốn full Server Audit chuẩn hơn thì cân nhắc SQL Developer Edition
    (miễn phí cho lab) thay cho Express, xem ghi chú trong keep.md.
#>

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
Write-Host "[*] [SRV02 - Stage 2] Repo root: $RepoRoot" -ForegroundColor Cyan

# 1. Thêm 2 service account và nhóm IT vào Local Administrators của SRV02
Add-LocalGroupMember -Group "Administrators" -Member "CLINIC\SVC_HIS_Database", "CLINIC\SVC_HIS_Sync", "CLINIC\GRP_IT_Admin" -ErrorAction SilentlyContinue

# 2. Cài Chocolatey nếu chưa có
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# 3. Tạo SMB Share BenhAn$ + 20 file XML BHYT mẫu + SACL (Event ID 5140/5145)
$SmbScript = Join-Path $RepoRoot "01_clinic_lab_and_noise\his_mssql_database\Setup_SMB_BenhAn_Share.ps1"
powershell.exe -ExecutionPolicy Bypass -File $SmbScript

# 4. Cài MS SQL Server Express ở chế độ Mixed Mode, bật TCP/IP cổng 1433
# Cai DEFAULT instance MSSQLSERVER tren cong 1433 de khop SPN MSSQLSvc/SRV02.clinic.local:1433.
choco install sql-server-express -y --params="'/SECURITYMODE=SQL /SAPWD=Password123! /TCPENABLED=1 /INSTANCENAME=MSSQLSERVER'"
choco install sqlserver-cmdlineutils -y
New-NetFirewallRule -DisplayName "Allow_MSSQL_1433" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow -ErrorAction SilentlyContinue

# 5. Nạp lược đồ CSDL và bật SQL Server Audit (dùng Windows auth -E, Administrator là sysadmin mặc định)
$SchemaScript = Join-Path $RepoRoot "01_clinic_lab_and_noise\his_mssql_database\Init_HIS_EMR_Schema.sql"
$AuditScript  = Join-Path $RepoRoot "01_clinic_lab_and_noise\his_mssql_database\Configure_SQL_Server_Audit_33205.sql"
sqlcmd -S localhost -E -i $SchemaScript
sqlcmd -S localhost -E -i $AuditScript
wevtutil sl Application /ms:536870912

# 6. Cài Sysmon
$SysmonConfig = Join-Path $RepoRoot "02_telemetry_and_scenarios\telemetry_configs\sysmon_clinic_config.xml"
New-Item -Path "C:\Tools" -ItemType Directory -Force | Out-Null
if (-not (Get-Service Sysmon64 -ErrorAction SilentlyContinue)) {
    Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "C:\Tools\Sysmon.zip"
    Expand-Archive -Path "C:\Tools\Sysmon.zip" -DestinationPath "C:\Tools\Sysmon" -Force
    if ((Test-Path $SysmonConfig) -and ((Get-Item $SysmonConfig).Length -gt 0)) {
        C:\Tools\Sysmon\Sysmon64.exe -accepteula -i $SysmonConfig
    } else {
        Write-Warning "sysmon_clinic_config.xml đang RỖNG. Cài Sysmon mặc định tạm thời, nhớ điền file này."
        C:\Tools\Sysmon\Sysmon64.exe -accepteula -i
    }
}

Write-Host "[+] [SRV02 - Stage 2] Hoàn tất HIS SQL + SMB + Audit." -ForegroundColor Green
