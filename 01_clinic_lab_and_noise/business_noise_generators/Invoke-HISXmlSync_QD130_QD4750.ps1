<#
.SYNOPSIS
    Invoke-HISXmlSync_QD130_QD4750.ps1
    Mô phỏng hoạt động định kỳ hợp lệ của phần mềm HIS:
    1. Tài khoản SVC_HIS_Sync & Bác sĩ truy vấn lẻ từng hồ sơ bệnh án trên CSDL HIS_ClinicDB (Event 33205).
    2. Trích xuất và đồng bộ tệp XML BHYT chuẩn QĐ 130/QĐ-BYT & 4750/QĐ-BYT qua \\SRV02\BenhAn$ (Event 5140/5145).
    3. Thực hiện truy vấn LDAP kiểm tra thông tin phòng ban hợp lệ (Event 1644 nền).
.NOTES
    Đồ án Tốt nghiệp Kỳ 2026.1 - Sinh viên: Vũ Thúy Hường (MSSV: 20225135)
#>

param(
    [string]$TargetServer = "SRV02.clinic.local",
    [string]$DomainName   = "clinic.local",
    [int]$SyncCycles      = 15
)

$ErrorActionPreference = "SilentlyContinue"
Write-Host "[*] Khởi chạy Bộ sinh nhiễu Đồng bộ XML BHYT (QĐ 130/4750) & Tra cứu HIS lẻ..." -ForegroundColor Cyan

$SyncUser  = "SVC_HIS_Sync"
$SyncPass  = "Password123!"
$SharePath = "\\$TargetServer\BenhAn$"

for ($cycle = 1; $cycle -le $SyncCycles; $cycle++) {
    Write-Host "`n--- [Chu kỳ đồng bộ HIS/BHYT $cycle / $SyncCycles] ---" -ForegroundColor Cyan

    # 1. Truy vấn LDAP đơn lẻ hợp lệ kiểm tra thông tin đơn vị (Sinh Event ID 1644 tần suất thấp < ngưỡng 50/phút)
    $Searcher = [adsisearcher]"(&(objectCategory=person)(objectClass=user)(department=Khoa Kham Benh))"
    $Searcher.PageSize = 5
    $null = $Searcher.FindOne()
    Write-Host "  [1] Đã thực hiện 1 truy vấn LDAP hợp lệ kiểm tra danh mục Khoa Khám Bệnh (Event 1644)." -ForegroundColor Gray

    # 2. Bác sĩ / Phần mềm HIS tra cứu lẻ 1 hồ sơ bệnh án cụ thể trên SQL Server (Sinh Event ID 33205 hợp lệ)
    $RandomID = "BA2026_{0:D4}" -f (Get-Random -Minimum 1 -Maximum 50)
    $SingleQuery = "SET NOCOUNT ON; SELECT MaBenhAn, HoTen, ChanDoanICD10, DaKySoTT13 FROM HIS_ClinicDB.dbo.HoSoBenhAn WHERE MaBenhAn = '$RandomID';"
    sqlcmd -S $TargetServer -U $SyncUser -P $SyncPass -Q $SingleQuery 2>$null | Out-Null
    Write-Host "  [2] Tra cứu lẻ 01 hồ sơ bệnh án ($RandomID) trên $TargetServer (Event 33205)." -ForegroundColor Green

    # 3. Đồng bộ tệp XML BHYT theo Quyết định 130/QĐ-BYT qua SMB Share \\SRV02\BenhAn$ (Sinh Event 5140/5145)
    net use $SharePath $SyncPass /user:"$DomainName\$SyncUser" 2>$null | Out-Null
    if (Test-Path $SharePath) {
        $XmlFiles = Get-ChildItem -Path $SharePath -Filter "BHYT_QD130_*.xml" | Select-Object -First 2
        foreach ($file in $XmlFiles) {
            $null = Get-Content -Path $file.FullName -TotalCount 5
        }
        $SyncLogFile = Join-Path $SharePath ("HIS_Sync_Heartbeat_{0:D2}.xml" -f ($cycle % 5))
        "<SYNC_STATUS><TIME>$(Get-Date -Format 'o')</TIME><ACCOUNT>$SyncUser</ACCOUNT><STANDARD>QD130_QD4750_BYT</STANDARD></SYNC_STATUS>" | Set-Content -Path $SyncLogFile -Encoding UTF8
        Write-Host "  [3] Đồng bộ thành công tệp XML BHYT qua SMB Share $SharePath (Event 5140/5145)." -ForegroundColor Green
    }
    net use $SharePath /delete /y 2>$null | Out-Null

    Start-Sleep -Seconds 2
}

Write-Host "`n[+] Hoàn tất mô phỏng lưu lượng đồng bộ HIS & XML BHYT!" -ForegroundColor Cyan