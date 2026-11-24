<#
.SYNOPSIS
    evasion_adsi_low_and_slow_spn.ps1
    Kich ban 1B (EVASION): do quet AD "low and slow" bang [adsisearcher] .NET tich hop
    san trong PowerShell. KHONG dung SharpHound/setspn nen vuot qua V1. Sinh Event ID
    1644 tren DC01 (Directory Service log), khong sinh chu ky tool.
.NOTES
    CHAY TRONG LAB CO LAP (clinic.local)
    MITRE ATT&CK: T1087.002, T1018, T1069.002.

    Diem manh cho quyen: ca kich ban 1B lam duoc bang .NET native, zero tooling ngoai.

    PHU THUOC TELEMETRY: Event 1644 chi sinh khi da nap
    02_telemetry_and_scenarios/telemetry_configs/Enable-LDAP-1644-Diagnostics.reg tren DC01.

    Han che cua whitelist V4: xem README.md thu muc nay.
    Whitelist nen neo vao DANH TINH + NGUON (SVC_HIS_Sync tu SRV02), khong neo vao chuoi filter (ke tan cong tu dat duoc chuoi filter).
#>

param(
    [int]$QueryCount = 8,
    [int]$MinDelaySeconds = 20,
    [int]$MaxDelaySeconds = 60
)

$ErrorActionPreference = "SilentlyContinue"

# Ghi moc ground truth ra CSV de gan nhan .evtx
$GtFile = "C:\ground_truth.csv"
if (-not (Test-Path $GtFile)) { "timestamp,scenario,phase" | Set-Content -Path $GtFile -Encoding UTF8 }
"$(Get-Date -Format 'o'),SC1-1B,START" | Add-Content -Path $GtFile

Write-Host "[*] [SC1-1B EVASION] Do quet ADSI low-and-slow (muc tieu: vuot qua V1, sinh 1644)." -ForegroundColor Cyan
Write-Host "    BAT DAU: $(Get-Date -Format 'o')" -ForegroundColor Yellow

# Cac bo loc LDAP nhay cam: tim SPN dich vu, tai khoan admin, mat khau de lo trong Description.
$Filters = @(
    "(&(objectCategory=user)(servicePrincipalName=*MSSQL*))",   # tim tai khoan SQL co SPN -> Kerberoast
    "(&(objectCategory=user)(servicePrincipalName=*))",         # moi tai khoan co SPN
    "(&(objectCategory=user)(adminCount=1))",                   # tai khoan duoc AdminSDHolder bao ve
    "(&(objectCategory=user)(description=*Pass*))",             # mat khau de lo trong description   
    # Lab khong plant password trong description (xem discard.md). Filter nay van sinh 1644 ghi lai chuoi filter 
    #-> du cho V4 bat, du khong tra ve ket qua. Day la hanh vi recon thuc te cua attacker.
    "(&(objectCategory=computer)(operatingSystem=*Server*))"    # tim may chu
)

for ($i = 1; $i -le $QueryCount; $i++) {
    $filter = $Filters[($i - 1) % $Filters.Count]
    $searcher = [adsisearcher]$filter
    $searcher.PageSize  = 1          # tra ve it, cham, giong truy van le hop le
    $searcher.SizeLimit = 5
    $null = $searcher.FindAll()
    Write-Host "[$i/$QueryCount] Truy van ADSI: $filter" -ForegroundColor Gray

    # Do tre lon (low and slow) de xuong duoi nguong 50 truy van/phut cua V3
    Start-Sleep -Seconds (Get-Random -Minimum $MinDelaySeconds -Maximum $MaxDelaySeconds)
}

"$(Get-Date -Format 'o'),SC1-1B,END" | Add-Content -Path $GtFile

Write-Host "    KET THUC: $(Get-Date -Format 'o')" -ForegroundColor Yellow
Write-Host "[+] [SC1-1B] Xong. Kiem tra DC01 -> Directory Service log -> Event ID 1644." -ForegroundColor Green
