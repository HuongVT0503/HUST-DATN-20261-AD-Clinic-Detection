<#
.SYNOPSIS
    06_WS01_Stage2_InitWorkstation.ps1
    Chạy trên WS01 SAU khi đã join miền. Cho phép nhóm Y Bác sĩ/Lễ tân đăng nhập,
    cài sqlcmd và Sysmon. WS01 là nơi chạy bộ sinh nhiễu và là điểm xuất phát (Patient Zero).
.NOTES
    Bản tách tay của PLAY 5 trong provisioning_clinic.yml.
#>

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
Write-Host "[*] [WS01 - Stage 2] Repo root: $RepoRoot" -ForegroundColor Cyan

# 1. Cho các nhóm nghiệp vụ đăng nhập trên WS01 (máy trạm dùng chung giữa các ca trực)
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "CLINIC\GRP_BacSi", "CLINIC\GRP_YTa", "CLINIC\GRP_LeTan" -ErrorAction SilentlyContinue
Add-LocalGroupMember -Group "Users" -Member "CLINIC\GRP_BacSi", "CLINIC\GRP_YTa", "CLINIC\GRP_LeTan" -ErrorAction SilentlyContinue

# 2. Cài Chocolatey + sqlcmd
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
choco install sqlserver-cmdlineutils -y

# 3. Cài Sysmon
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

Write-Host "[+] [WS01 - Stage 2] Hoàn tất. Giờ có thể chạy bộ sinh nhiễu trong business_noise_generators\." -ForegroundColor Green
