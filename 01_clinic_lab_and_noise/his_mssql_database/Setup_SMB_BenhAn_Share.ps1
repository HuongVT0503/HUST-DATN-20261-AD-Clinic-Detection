<#
.SYNOPSIS
    Setup_SMB_BenhAn_Share.ps1
    Khởi tạo thư mục C:\HoSoBenhAn_XML, mở SMB Share ẩn \\SRV02\BenhAn$,
    cấu hình SACL Auditing (Event ID 5140/5145) và sinh 20 tệp XML BHYT mẫu theo Quyết định 130/QĐ-BYT & 4750/QĐ-BYT.
.NOTES
    Chạy trên máy chủ bệnh án SRV02 (SRV02.clinic.local).
    Chuẩn định dạng XML BHYT: xem docs/legal_compliance_2025_2026/Chuan_XML_BHYT_QD130_QD4750.md
    GUID subcategory File Share/Detailed File Share là GUID chuẩn của Microsoft (audit policy).
#>

$ErrorActionPreference = "Stop"
$ShareFolder = "C:\HoSoBenhAn_XML"
$ShareName   = "BenhAn$"

Write-Host "[*] Đang khởi tạo thư mục lưu trữ XML BHYT tại $ShareFolder..." -ForegroundColor Cyan
if (-not (Test-Path $ShareFolder)) {
    New-Item -Path $ShareFolder -ItemType Directory -Force | Out-Null
}

# 1. Tạo SMB Share ẩn \\SRV02\BenhAn$
if (-not (Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name $ShareName -Path $ShareFolder -FullAccess "Everyone" `
                 -Description "Thu muc dong bo Ho so Benh an Dien tu & XML BHYT (QD 130/QD-BYT)" | Out-Null
    Write-Host "[+] Đã tạo SMB Share ẩn: \\$env:COMPUTERNAME\$ShareName" -ForegroundColor Green
}

# 2. Cấp quyền NTFS và gắn SACL Auditing để bắt buộc Windows sinh Event ID 5140 & 5145
icacls.exe $ShareFolder /grant "Everyone:(OI)(CI)F" /T | Out-Null

$Acl = Get-Acl -Path $ShareFolder
$AuditRule = New-Object System.Security.AccessControl.FileSystemAuditRule(
    "Everyone",
    "Read,Write,Delete",
    "ContainerInherit,ObjectInherit",
    "None",
    "Success,Failure"
)
$Acl.AddAuditRule($AuditRule)
Set-Acl -Path $ShareFolder -AclObject $Acl

# Bật chính sách Audit File Share và Detailed File Share bằng GUID chuẩn của Microsoft
auditpol.exe /set /subcategory:"{0CCE9224-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable | Out-Null
auditpol.exe /set /subcategory:"{0CCE9244-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable | Out-Null

# 3. Khởi tạo 20 tệp XML BHYT mẫu chuẩn Quyết định 130/QĐ-BYT & 4750/QĐ-BYT
1..20 | ForEach-Object {
    $MaLK = "HSBA2026_{0:D4}" -f $_
    $CCCD = "00120400{0:D4}" -f $_
    $XmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<GIAMDINHHS xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <THONGTINDONVI>
    <MACSKCB>01999</MACSKCB>
  </THONGTINDONVI>
  <THONGTINHOSO>
    <NGAYLAP>$(Get-Date -Format "yyyyMMdd")</NGAYLAP>
    <SOLUONGHOSO>1</SOLUONGHOSO>
    <DANHSACHHOSO>
      <HOSO>
        <FILEHOSO>
          <LOAIHOSO>XML1</LOAIHOSO>
          <NOIDUNGFILE>
            <TONG_HOP>
              <MA_LK>$MaLK</MA_LK>
              <STT>$_</STT>
              <MA_BN>BN2026_{0:D4}</MA_BN>
              <HO_TEN>NGUYEN VAN BENH NHAN {0:D2}</HO_TEN>
              <SO_CCCD>$CCCD</SO_CCCD>
              <MA_THE_BHYT>DN401012040{0:D4}</MA_THE_BHYT>
              <MA_BENH_CHINH>I10</MA_BENH_CHINH>
              <MA_BENH_KT>E11.9</MA_BENH_KT>
              <TEN_BENH>Tăng huyết áp vô căn; Đái tháo đường tuýp 2</TEN_BENH>
              <CHU_KY_SO_TT13>SIGNED_PKI_VALID_2026</CHU_KY_SO_TT13>
            </TONG_HOP>
          </NOIDUNGFILE>
        </FILEHOSO>
      </HOSO>
    </DANHSACHHOSO>
  </THONGTINHOSO>
</GIAMDINHHS>
"@ -f $_
    $FilePath = Join-Path $ShareFolder ("BHYT_QD130_HS{0:D4}.xml" -f $_)
    Set-Content -Path $FilePath -Value $XmlContent -Encoding UTF8
}

Write-Host "[+] Đã tạo 20 tệp XML BHYT mẫu và bật kiểm toán Event ID 5140/5145 trên $ShareFolder!" -ForegroundColor Green