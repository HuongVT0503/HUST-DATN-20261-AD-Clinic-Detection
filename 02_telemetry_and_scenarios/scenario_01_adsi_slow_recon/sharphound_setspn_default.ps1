<#
.SYNOPSIS
    sharphound_setspn_default.ps1
    Kich ban 1A (DEFAULT / loud): do quet Active Directory bang CHU KY cong cu mac dinh
    de luat V1 (SC1-V1) bat trung. Day la "giai phap hien co" de so sanh.
.DESCRIPTION
    Co 3 cach sinh chu ky ma SC1-V1 bat. Toi dung Cach 1 lam mac dinh vi no KHONG
    can tai binary ngoai (tranh canh bao Defender, de tai hien):

      Cach 1 (MAC DINH, native): setspn.exe -Q */*  -> liet ke toan bo SPN trong rung.
              setspn.exe nam trong RSAT AD Tools, la tinh nang co san cua Windows
              (khong phai tool bên thu ba). Script tu cai RSAT neu WS01 chua co.
              SC1-V1 bat chuoi 'setspn.exe -Q */*'.

      Cach 2 (TUY CHON, day du nhat): SharpHound.exe thu thap do thi BloodHound.
              SharpHound.exe la binary NGOAI (GhostPack/SpecterOps), KHONG nam trong
              repo va bootstrap KHONG tai ve. Chi chay neu ban tu dat file vao C:\Tools.

      Cach 3: Invoke-BloodHound (ban PowerShell cua SharpHound) - cung la tool ngoai.

.NOTES
    CHAY TRONG LAB CO LAP (clinic.local)
    MITRE ATT&CK: T1087.002 (Account Discovery: Domain Account), T1069.002, T1018.

    Provenance luat SC1-V1 va cach lay SharpHound: xem docs/PROVENANCE_detection_rules.md.
#>

$ErrorActionPreference = "SilentlyContinue"

# Ghi moc ground truth ra CSV de gan nhan .evtx
$GtFile = "C:\ground_truth.csv"
if (-not (Test-Path $GtFile)) { "timestamp,scenario,phase" | Set-Content -Path $GtFile -Encoding UTF8 }
"$(Get-Date -Format 'o'),SC1-1A,START" | Add-Content -Path $GtFile

Write-Host "[*] [SC1-1A DEFAULT] Do quet AD bang chu ky mac dinh (muc tieu: V1 bat trung)." -ForegroundColor Cyan
Write-Host "    BAT DAU (ghi lai lam ground truth): $(Get-Date -Format 'o')" -ForegroundColor Yellow

# --- Cach 1 (mac dinh): setspn native ---
# setspn.exe thuoc RSAT AD Tools. Neu WS01 chua co thi cai bang Windows Capability (native, khong tai tool ngoai).
if (-not (Get-Command setspn.exe -ErrorAction SilentlyContinue)) {
    Write-Host "[i] WS01 chua co setspn.exe. Dang cai RSAT AD Tools (tinh nang san cua Windows)..." -ForegroundColor Gray
    Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDAP.Tools~~~~0.0.1.0" | Out-Null
}
Write-Host "[1] setspn -Q */* (liet ke SPN toan rung) -> chu ky SC1-V1 bat." -ForegroundColor Gray
setspn.exe -T clinic.local -Q */* | Out-Null

# Liet ke them nhom dac quyen (T1069.002), khong phai chu ky V1 nhung tao them nhieu recon native
net group "Domain Admins" /domain | Out-Null

# --- Cach 2 (tuy chon): SharpHound.exe neu ban da tu dat vao C:\Tools (xem README.md) ---
$SharpHound = "C:\Tools\SharpHound.exe"
if (Test-Path $SharpHound) {
    Write-Host "[2] Phat hien SharpHound.exe -> chay thu thap BloodHound day du." -ForegroundColor Gray
    & $SharpHound --CollectionMethods All --Domain clinic.local --OutputDirectory C:\Tools | Out-Null
} else {
    Write-Host "[i] Khong co C:\Tools\SharpHound.exe -> bo qua, chi dua vao setspn (du cho SC1-V1)." -ForegroundColor Gray
}

"$(Get-Date -Format 'o'),SC1-1A,END" | Add-Content -Path $GtFile

Write-Host "    KET THUC: $(Get-Date -Format 'o')" -ForegroundColor Yellow
Write-Host "[+] [SC1-1A] Xong. Kiem tra WS01 -> Sysmon Event ID 1 co ban ghi setspn.exe (va SharpHound.exe neu chay)." -ForegroundColor Green
