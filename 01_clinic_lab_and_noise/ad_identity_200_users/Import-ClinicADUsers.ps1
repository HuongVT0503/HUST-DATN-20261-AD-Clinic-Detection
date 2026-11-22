<#
.SYNOPSIS
    Import-ClinicADUsers.ps1
    Khởi tạo 6 OUs, 5 Security Groups, tự động điền đủ 200 dòng CSV và nạp 200 định danh
    nhân sự y tế + tài khoản dịch vụ SVC_HIS_Database, SVC_HIS_Sync vào miền clinic.local.
.NOTES
    Kế thừa cơ chế service account gắn SPN cho Kerberoasting của GOAD-Light (castelblack/mssql_svc),
    đổi tên và đặt lại ngữ cảnh y tế. Đối chiếu repo gốc: docs/customized_goad_light/keep.md
#>

$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

$DomainDN  = (Get-ADDomain).DistinguishedName
$DomainDNS = (Get-ADDomain).DNSRoot
# Script tự sinh đủ 200 dòng vào tệp này lúc chạy (tệp này được gitignore, không commit).
# Bản xem trước 10 dòng để hình dung định dạng là clinic_staff_identities.sample_10rows.csv.
$CsvPath   = Join-Path $PSScriptRoot "clinic_200_staff_identities.csv"

Write-Host "[*] Bắt đầu khởi tạo cấu trúc định danh Phòng khám trên miền $DomainDNS ($DomainDN)..." -ForegroundColor Cyan

# ==============================================================================
# 1. KHỞI TẠO 6 ORGANIZATIONAL UNITS (OUs) & 5 SECURITY GROUPS (RBAC)
# ==============================================================================
$ClinicOUs = @(
    @{ Name = "BacSi";           Desc = "Đội ngũ Bác sĩ khám chữa bệnh" },
    @{ Name = "YTa";             Desc = "Đội ngũ Y tá và Điều dưỡng chăm sóc bệnh nhân" },
    @{ Name = "LeTan";           Desc = "Bộ phận Lễ tân tiếp đón và Thu ngân viện phí" },
    @{ Name = "IT_Admin";        Desc = "Bộ phận Quản trị CNTT kiêm nhiệm (2-3 nhân sự)" },
    @{ Name = "ServiceAccounts"; Desc = "Tài khoản dịch vụ phần mềm bệnh án điện tử HIS & BHYT" },
    @{ Name = "ClinicComputers"; Desc = "Máy chủ HIS (SRV02) và Máy trạm phòng khám (WS01)" }
)

foreach ($ou in $ClinicOUs) {
    $ouDN = "OU=$($ou.Name),$DomainDN"
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDN'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $ou.Name -Path $DomainDN -Description $ou.Desc -ProtectedFromAccidentalDeletion $false
        Write-Host "[+] Đã tạo OU: $ouDN" -ForegroundColor Green
    }
}

$ClinicGroups = @(
    @{ Name = "GRP_BacSi";        OU = "BacSi";           Desc = "Nhóm quyền Bác sĩ điều trị" },
    @{ Name = "GRP_YTa";          OU = "YTa";             Desc = "Nhóm quyền Y tá và Điều dưỡng" },
    @{ Name = "GRP_LeTan";        OU = "LeTan";           Desc = "Nhóm quyền Lễ tân tiếp đón" },
    @{ Name = "GRP_IT_Admin";     OU = "IT_Admin";        Desc = "Nhóm quyền Quản trị viên CNTT phòng khám" },
    @{ Name = "GRP_HIS_Services"; OU = "ServiceAccounts"; Desc = "Nhóm tài khoản dịch vụ vận hành HIS/EMR" }
)

foreach ($grp in $ClinicGroups) {
    $grpPath = "OU=$($grp.OU),$DomainDN"
    if (-not (Get-ADGroup -Filter "SamAccountName -eq '$($grp.Name)'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $grp.Name -SamAccountName $grp.Name -GroupScope Global -GroupCategory Security -Path $grpPath -Description $grp.Desc
        Write-Host "[+] Đã tạo Security Group: $($grp.Name)" -ForegroundColor Green
    }
}

# ==============================================================================
# 2. TỰ ĐỘNG SINH ĐỦ 200 ĐỊNH DANH VÀO TỆP CSV NẾU TỆP TRỐNG HOẶC CHƯA ĐỦ
# ==============================================================================
$ExistingRows = if (Test-Path $CsvPath) { @(Import-Csv -Path $CsvPath) } else { @() }

if ($ExistingRows.Count -lt 200) {
    Write-Host "[*] Đang tự động sinh danh mục chuẩn 200 định danh nhân sự vào $CsvPath..." -ForegroundColor Yellow
    $StaffList = New-Object System.Collections.Generic.List[PSObject]

    # 2.1. 2 Tài khoản Dịch vụ (Service Accounts) cho 3 kịch bản
    $StaffList.Add([PSCustomObject]@{
        SamAccountName="SVC_HIS_Database"; GivenName="SVC"; Surname="HIS_Database"; DisplayName="HIS SQL Server Database Service";
        Title="Service Account"; Department="He Thong HIS"; OU="ServiceAccounts"; Group="GRP_HIS_Services";
        Password="Password123!"; IsServiceAccount="TRUE"; SPN="MSSQLSvc/SRV02.clinic.local:1433";
        Description="Tai khoan dich vu ket noi CSDL Benh an Dien tu HIS tren SRV02"
    })
    $StaffList.Add([PSCustomObject]@{
        SamAccountName="SVC_HIS_Sync"; GivenName="SVC"; Surname="HIS_Sync"; DisplayName="BHYT XML Gateway Sync Service";
        Title="Service Account"; Department="He Thong BHYT"; OU="ServiceAccounts"; Group="GRP_HIS_Services";
        Password="Password123!"; IsServiceAccount="TRUE"; SPN="";
        Description="Tai khoan dong bo XML BHYT QD130/QD4750 len cong BHXH"
    })

    # 2.2. 3 Tài khoản Quản trị viên CNTT kiêm nhiệm (IT_Admin01..03, đội 2-3 người)
    1..3 | ForEach-Object {
        $id = "IT_Admin{0:D2}" -f $_
        $StaffList.Add([PSCustomObject]@{
            SamAccountName=$id; GivenName=$id; Surname="IT"; DisplayName="Chuyen vien CNTT $id";
            Title="IT Administrator"; Department="To CNTT & An Ninh"; OU="IT_Admin"; Group="GRP_IT_Admin";
            Password="Clinic@2026!"; IsServiceAccount="FALSE"; SPN="";
            Description="Quan tri vien CNTT kiem nhiem tai phong kham"
        })
    }

    # 2.3. 60 Tài khoản Bác sĩ (BS_BacSi001 .. BS_BacSi060)
    1..60 | ForEach-Object {
        $id = "BS_BacSi{0:D3}" -f $_
        $StaffList.Add([PSCustomObject]@{
            SamAccountName=$id; GivenName=$id; Surname="BacSi"; DisplayName="Bac si Dieu tri ({0:D3})" -f $_;
            Title="Bac si Kham benh"; Department="Khoa Kham Benh"; OU="BacSi"; Group="GRP_BacSi";
            Password="Clinic@2026!"; IsServiceAccount="FALSE"; SPN="";
            Description="Bac si kham chua benh va ky so Benh an dien tu TT 13/2025/TT-BYT"
        })
    }

    # 2.4. 100 Tài khoản Y tá / Điều dưỡng (YT_YTa001 .. YT_YTa100)
    1..100 | ForEach-Object {
        $id = "YT_YTa{0:D3}" -f $_
        $StaffList.Add([PSCustomObject]@{
            SamAccountName=$id; GivenName=$id; Surname="YTa"; DisplayName="Dieu duong vien ({0:D3})" -f $_;
            Title="Dieu duong"; Department="Khoa Dieu Duong"; OU="YTa"; Group="GRP_YTa";
            Password="Clinic@2026!"; IsServiceAccount="FALSE"; SPN="";
            Description="Dieu duong cham soc benh nhan theo ca truc"
        })
    }

    # 2.5. 35 Tài khoản Lễ tân / Thu ngân (LT_LeTan001 .. LT_LeTan035) -> Tổng = 2 + 3 + 60 + 100 + 35 = 200 định danh
    1..35 | ForEach-Object {
        $id = "LT_LeTan{0:D3}" -f $_
        $StaffList.Add([PSCustomObject]@{
            SamAccountName=$id; GivenName=$id; Surname="LeTan"; DisplayName="Nhan vien Le tan ({0:D3})" -f $_;
            Title="Le tan - Thu ngan"; Department="Phong Tiep Don"; OU="LeTan"; Group="GRP_LeTan";
            Password="Clinic@2026!"; IsServiceAccount="FALSE"; SPN="";
            Description="Nhan vien tiep don benh nhan tai may tram WS01"
        })
    }

    $StaffList | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    $ExistingRows = $StaffList
    Write-Host "[+] Đã xuất thành công $($ExistingRows.Count) định danh ra tệp CSV: $CsvPath" -ForegroundColor Green
}

# ==============================================================================
# 3. NẠP TOÀN BỘ 200 ĐỊNH DANH TỪ CSV VÀO ACTIVE DIRECTORY
# ==============================================================================
$ImportedCount = 0
foreach ($row in $ExistingRows) {
    $sam  = $row.SamAccountName
    $ouDN = "OU=$($row.OU),$DomainDN"
    $pass = ConvertTo-SecureString $row.Password -AsPlainText -Force

    if (-not (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue)) {
        New-ADUser -Name $sam `
                   -SamAccountName $sam `
                   -UserPrincipalName "$sam@$DomainDNS" `
                   -GivenName $row.GivenName `
                   -Surname $row.Surname `
                   -DisplayName $row.DisplayName `
                   -Title $row.Title `
                   -Department $row.Department `
                   -Description $row.Description `
                   -Path $ouDN `
                   -AccountPassword $pass `
                   -Enabled $true `
                   -PasswordNeverExpires $true
        $ImportedCount++
    }

    if ($row.Group) {
        Add-ADGroupMember -Identity $row.Group -Members $sam -ErrorAction SilentlyContinue
    }

    if ($row.SPN -and $row.SPN.Trim() -ne "") {
        Set-ADUser -Identity $sam -ServicePrincipalNames @{Add=$row.SPN.Trim()} -ErrorAction SilentlyContinue
    }
}

# ==============================================================================
# 4. CẤU HÌNH ĐẶC THÙ CHO 2 KỊCH BẢN TẤN CÔNG LẨN TRÁNH (SCENARIO 1 và 2)
# (Kịch bản 3 thao túng DB không cần cấu hình định danh ở đây, xem Init_HIS_EMR_Schema.sql)
# ==============================================================================
# 4.1. Cho IT_Admin01..03 vào Domain Admins + đặt adminCount=1 làm mục tiêu dò quét của Kịch bản 1.
# Dò quét theo thuộc tính adminCount=1 là cách enumerate tài khoản đặc quyền (nhóm được bảo vệ bởi AdminSDHolder). Tham khảo: thehacker.recipes/ad/movement/kerberos; Microsoft AdminSDHolder docs.
@("IT_Admin01", "IT_Admin02", "IT_Admin03") | ForEach-Object {
    Add-ADGroupMember -Identity "Domain Admins" -Members $_ -ErrorAction SilentlyContinue
    Set-ADUser -Identity $_ -Replace @{adminCount=1}
}

# 4.2. Cho SVC_HIS_Database hỗ trợ cả RC4-HMAC (0x17) và AES128/AES256 (0x12).
# Lý do học thuật: đây là chỗ để Kịch bản 2 so sánh "encryption downgrade" (xin vé 0x17 dễ crack,
# dễ bị bắt) với "OpSec AES" (xin vé 0x12 để né luật SIEM chỉ lọc 0x17). Phân biệt 0x17/0x12 lấy từ
# GhostPack Rubeus (github.com/GhostPack/Rubeus) và The Hacker Recipes (thehacker.recipes/ad/movement/kerberos/kerberoast). 
# Ngữ cảnh y tế: SVC tài khoản phần mềm HIS có SPN MSSQLSvc nên là đối tượng tấn công Kerberoast trong mạng phòng khám.
# Lệnh -KerberosEncryptionType đã tự set msDS-SupportedEncryptionTypes = 28, không cần Replace lại.
# SPN đã gắn từ trường SPN của CSV trong vòng lặp ở trên, nên KHÔNG gọi setspn.exe nữa (tránh Duplicate SPN).
Set-ADUser -Identity "SVC_HIS_Database" -KerberosEncryptionType RC4,AES128,AES256
Set-ADUser -Identity "SVC_HIS_Database" -Replace @{adminCount=1}

Write-Host "[+] Hoàn tất nạp $ImportedCount định danh mới! Tổng số AD Users hiện tại: $((Get-ADUser -Filter *).Count)" -ForegroundColor Green