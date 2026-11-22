<#
.SYNOPSIS
    Invoke-HISXmlSync_QD130_QD4750.ps1
    Mô phỏng hoạt động định kỳ hợp lệ của phần mềm HIS:
    1. Tài khoản SVC_HIS_Sync & Bác sĩ truy vấn lẻ từng hồ sơ bệnh án trên CSDL HIS_ClinicDB (Event 33205).
    2. Trích xuất và đồng bộ tệp XML BHYT chuẩn QĐ 130/QĐ-BYT & 4750/QĐ-BYT qua \\SRV02\BenhAn$ (Event 5140/5145).
    3. Thực hiện truy vấn LDAP kiểm tra thông tin phòng ban hợp lệ (Event 1644 nền).
.NOTES
    CƠ SỞ HỌC THUẬT (chi tiết + link: docs/academic_references/Noise_Generation_GHOSTS_Methodology.md):
    - Triết lý mô phỏng hành vi người dùng để lưu lượng tổng hợp khó phân biệt với thật:
      GHOSTS Framework, Updyke et al., CMU/SEI-2018-TR-005 (2018). github.com/cmu-sei/GHOSTS
    - Trộn nhiễu hợp lệ + tấn công rồi gán nhãn tĩnh theo timestamp (tỉ lệ độc hại thấp để phản ánh
      thực tế): ATLASv2, Riddle/Westfall/Bates, arXiv:2401.01341; HIKARI-2021, Ferriyan et al.,
      Appl. Sci. 2021, 11, 7868, doi.org/10.3390/app11177868
    - Vì sao FP là vấn đề lớn nhất khi nền hợp lệ rất lớn: Axelsson 1999 (xem Base_Rate_Fallacy_Axelsson1999.md)
    - Chuẩn XML BHYT: QĐ 130/QĐ-BYT & 4750/QĐ-BYT (xem legal_compliance_2025_2026/Chuan_XML_BHYT_QD130_QD4750.md)

    Lưu ý kỹ thuật: sqlcmd dưới đây dùng SQL auth (SVC_HIS_Sync) nên CSDL phải chạy Mixed Mode và
    phải tạo SQL Login SVC_HIS_Sync (đã xử lý trong Init_HIS_EMR_Schema.sql, mục 1b).
    Task nên chạy dưới chính SVC_HIS_Sync (xem Register-ClinicNoiseScheduledTasks.ps1) để Event 1644/33205
    gán đúng danh tính phần mềm HIS.
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
    # GIẢ ĐỊNH MÔ HÌNH HÓA (không phải số liệu quy định): phần mềm HIS định kỳ tra phân quyền bác sĩ trên AD.
    # Đây là "benign LDAP" dễ bị luật dò quét (SharpHound/ADSI) bắt nhầm -> nguồn FP mà đồ án phải khử.
    # Căn cứ phương pháp sinh nhiễu hợp lệ: GHOSTS (CMU/SEI-2018-TR-005).
    $Searcher = [adsisearcher]"(&(objectCategory=person)(objectClass=user)(department=Khoa Kham Benh))"
    $Searcher.PageSize = 5
    $null = $Searcher.FindOne()
    Write-Host "   Đã thực hiện 1 truy vấn LDAP hợp lệ kiểm tra danh mục Khoa Khám Bệnh (Event 1644)." -ForegroundColor Gray

    # 2. Bác sĩ / Phần mềm HIS tra cứu lẻ 1 hồ sơ bệnh án cụ thể trên SQL Server (Sinh Event ID 33205 hợp lệ)
    # CĂN CỨ: TT 13/2025/TT-BYT yêu cầu bệnh án điện tử phải phân quyền truy cập và lưu vết thao tác, nên mọi truy vấn hợp lệ đều bị ghi log. 
    # GIẢ ĐỊNH MÔ HÌNH HÓA: tần suất/khối lượng SELECT mỗi lượt khám.
    # Nền SELECT lớn khiến Kịch bản 3 (đọc/xóa trái phép) khó tách khỏi thường -> minh họa Base-Rate (Axelsson 1999).
    $RandomID = "BA2026_{0:D4}" -f (Get-Random -Minimum 1 -Maximum 50)
    $SingleQuery = "SET NOCOUNT ON; SELECT MaBenhAn, HoTen, ChanDoanICD10, DaKySoTT13 FROM HIS_ClinicDB.dbo.HoSoBenhAn WHERE MaBenhAn = '$RandomID';"
    sqlcmd -S $TargetServer -U $SyncUser -P $SyncPass -Q $SingleQuery 2>$null | Out-Null
    Write-Host "   Tra cứu lẻ 01 hồ sơ bệnh án ($RandomID) trên $TargetServer (Event 33205)." -ForegroundColor Green

    # 3. Đồng bộ tệp XML BHYT theo Quyết định 130/QĐ-BYT qua SMB Share \\SRV02\BenhAn$ (Sinh Event 5140/5145)
    # CĂN CỨ: cơ sở KCB phải xuất dữ liệu XML theo QĐ 130/QĐ-BYT (18/01/2023) và 4750/QĐ-BYT đẩy lên Cổng giám định BHYT (gdbhyt.baohiemxahoi.gov.vn), gửi chính thức từ 01/7/2024. 
    # GIẢ ĐỊNH MÔ HÌNH HÓA: chu kỳ 5 phút.
    # Truy cập file share hợp lệ này dễ bị luật exfil/di chuyển ngang bắt nhầm -> cũng là FP cần khử.
    net use $SharePath $SyncPass /user:"$DomainName\$SyncUser" 2>$null | Out-Null
    if (Test-Path $SharePath) {
        $XmlFiles = Get-ChildItem -Path $SharePath -Filter "BHYT_QD130_*.xml" | Select-Object -First 2
        foreach ($file in $XmlFiles) {
            $null = Get-Content -Path $file.FullName -TotalCount 5
        }
        $SyncLogFile = Join-Path $SharePath ("HIS_Sync_Heartbeat_{0:D2}.xml" -f ($cycle % 5))
        "<SYNC_STATUS><TIME>$(Get-Date -Format 'o')</TIME><ACCOUNT>$SyncUser</ACCOUNT><STANDARD>QD130_QD4750_BYT</STANDARD></SYNC_STATUS>" | Set-Content -Path $SyncLogFile -Encoding UTF8
        Write-Host "   Đồng bộ thành công tệp XML BHYT qua SMB Share $SharePath (Event 5140/5145)." -ForegroundColor Green
    }
    net use $SharePath /delete /y 2>$null | Out-Null

    Start-Sleep -Seconds 2
}

Write-Host "`n[+] Hoàn tất mô phỏng lưu lượng đồng bộ HIS & XML BHYT!" -ForegroundColor Cyan