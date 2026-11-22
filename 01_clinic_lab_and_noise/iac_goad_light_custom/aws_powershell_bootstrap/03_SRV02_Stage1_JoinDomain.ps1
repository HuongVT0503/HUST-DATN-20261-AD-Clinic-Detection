<#
.SYNOPSIS
    03_SRV02_Stage1_JoinDomain.ps1
    Chạy trên máy SRV02 (Windows Server 2022 trắng). Trỏ DNS về DC01, đổi tên -> SRV02,
    gia nhập miền clinic.local rồi tự Reboot.
.PARAMETER DC01PrivateIP
    Địa chỉ Private IP của DC01 trong VPC (ví dụ 172.31.10.10). BẮT BUỘC truyền vào.
.NOTES
    Bản tách tay của PLAY 3 (phần member server) trong provisioning_clinic.yml.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$DC01PrivateIP
)

$ErrorActionPreference = "Stop"
$DomainName = "clinic.local"
$AdminPass  = "P@ssw0rd123!"

Write-Host "[*] [SRV02 - Stage 1] Trỏ DNS về DC01 ($DC01PrivateIP) và gia nhập miền $DomainName..." -ForegroundColor Cyan

# 1. Trỏ DNS Client về DC01 (bắt buộc để phân giải được clinic.local)
Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Set-DnsClientServerAddress -ServerAddresses $DC01PrivateIP

# 2. Đổi tên máy + gia nhập miền trong 1 bước, dùng tài khoản miền đã biết trước
$SecurePass = ConvertTo-SecureString $AdminPass -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential("CLINIC\Administrator", $SecurePass)

Add-Computer -DomainName $DomainName `
             -NewName "SRV02" `
             -Credential $Cred `
             -OUPath "OU=ClinicComputers,DC=clinic,DC=local" `
             -Options JoinWithNewName, AccountCreate `
             -Restart -Force

# Máy sẽ Reboot. Sau đó đăng nhập CLINIC\Administrator rồi chạy 04_SRV02_Stage2_SetupHIS_SQL_SMB.ps1
