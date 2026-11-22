<#
.SYNOPSIS
    05_WS01_Stage1_JoinDomain.ps1
    Chạy trên máy WS01 (Windows Server 2022 trắng, đóng vai máy trạm phòng khám).
    Trỏ DNS về DC01, đổi tên -> WS01, gia nhập miền clinic.local rồi tự Reboot.
.PARAMETER DC01PrivateIP
    Private IP của DC01 (ví dụ 172.31.10.10). BẮT BUỘC truyền vào.
.NOTES
    Giống hệt 03_SRV02_Stage1 nhưng đổi tên máy thành WS01.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$DC01PrivateIP
)

$ErrorActionPreference = "Stop"
$DomainName = "clinic.local"
$AdminPass  = "P@ssw0rd123!"

Write-Host "[*] [WS01 - Stage 1] Trỏ DNS về DC01 ($DC01PrivateIP) và gia nhập miền $DomainName..." -ForegroundColor Cyan

Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Set-DnsClientServerAddress -ServerAddresses $DC01PrivateIP

$SecurePass = ConvertTo-SecureString $AdminPass -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential("CLINIC\Administrator", $SecurePass)

Add-Computer -DomainName $DomainName `
             -NewName "WS01" `
             -Credential $Cred `
             -OUPath "OU=ClinicComputers,DC=clinic,DC=local" `
             -Options JoinWithNewName, AccountCreate `
             -Restart -Force

# Reboot xong, đăng nhập CLINIC\Administrator rồi chạy 06_WS01_Stage2_InitWorkstation.ps1
