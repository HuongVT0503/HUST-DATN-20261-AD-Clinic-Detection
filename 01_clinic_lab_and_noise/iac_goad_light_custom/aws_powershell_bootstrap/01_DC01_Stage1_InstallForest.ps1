<#
.SYNOPSIS
    01_DC01_Stage1_InstallForest.ps1
    Chạy trên máy DC01 (Windows Server 2022 trắng trên AWS EC2).
    Đổi hostname -> DC01, cài AD-Domain-Services, dựng Forest clinic.local (NetBIOS CLINIC).
    Máy sẽ tự Reboot sau khi promote xong.
.NOTES
    Đây là bản tách tay (standalone) của PLAY 1 trong provisioning_clinic.yml để chạy
    thủ công qua RDP trên AWS, cho máy cá nhân ~8GB RAM không dựng được 3 VM VirtualBox.
    Tôi cố tình đặt lại mật khẩu Administrator = P@ssw0rd123! để các script join domain
    sau này dùng chung 1 mật khẩu miền đã biết trước (CLINIC\Administrator / P@ssw0rd123!).
#>

$ErrorActionPreference = "Stop"
$DomainName   = "clinic.local"
$NetbiosName  = "CLINIC"
$AdminPass    = "P@ssw0rd123!"

Write-Host "[*] [DC01 - Stage 1] Bắt đầu dựng Domain Controller cho miền $DomainName..." -ForegroundColor Cyan

# 1. Đặt lại mật khẩu Administrator để thống nhất mật khẩu miền (dùng cho bước join domain)
net user Administrator $AdminPass | Out-Null

# 2. Đổi hostname thành DC01 (nếu chưa đúng thì đổi, lần chạy này chưa reboot ngay, nhưng Install-ADDSForest sẽ reboot máy sau khi xong)
if ($env:COMPUTERNAME -ne "DC01") {
    Rename-Computer -NewName "DC01" -Force
    Write-Host "[+] Đã đổi hostname thành DC01." -ForegroundColor Green
}

# 3. Cài feature AD DS kèm công cụ quản trị
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools | Out-Null
Write-Host "[+] Đã cài AD-Domain-Services." -ForegroundColor Green

# 4. Dựng Forest clinic.local. Install-ADDSForest sẽ tự reboot máy khi xong (~3-4 phút)
$SecurePass = ConvertTo-SecureString $AdminPass -AsPlainText -Force
Import-Module ADDSDeployment
Install-ADDSForest `
    -DomainName $DomainName `
    -DomainNetbiosName $NetbiosName `
    -SafeModeAdministratorPassword $SecurePass `
    -ForestMode "WinThreshold" `
    -DomainMode "WinThreshold" `
    -InstallDns `
    -Force

# (Không có dòng nào chạy sau đây vì máy đã Reboot. Sau khi lên lại, đăng nhập
#  CLINIC\Administrator / P@ssw0rd123! rồi chạy tiếp 02_DC01_Stage2_ConfigureAD_Audit.ps1)
