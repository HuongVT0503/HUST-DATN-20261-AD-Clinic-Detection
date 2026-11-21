Trong kho mã nguồn gốc `Orange-Cyberdefense/GOAD`, cấu hình của **GOAD-Light** nằm tại hai nơi: tệp định nghĩa dữ liệu `ad/GOAD-Light/data/config.json` (chứa toàn bộ danh sách OU, User, Group, SPN, lỗ hổng ACL, MSSQL, SMB) và các kịch bản thực thi nằm trong thư mục `ansible/roles/` (nơi Ansible gọi các module Windows/PowerShell để đọc dữ liệu từ `config.json` và áp vào máy ảo).
https://github.com/Orange-Cyberdefense/GOAD.git


---

### PHẦN 1: Cấu trúc Khởi tạo Miền (Forest/Domain) & Đơn vị tổ chức (OUs)

#### 1.1. Mã nguồn gốc trong GOAD-Light

* **Tệp dữ liệu gốc (`ad/GOAD-Light/data/config.json`):**

```json
"domains": {
  "sevenkingdoms.local": {
    "dc": "dc01",
    "netbios": "SEVENKINGDOMS",
    "ous": {
      "Crownlands": {},
      "KingsLanding": {},
      "Dragonstone": {}
    }
  },
  "north.sevenkingdoms.local": {
    "dc": "dc02",
    "parent_domain": "sevenkingdoms.local",
    "ous": {
      "Winterfell": {},
      "TheWall": {}
    }
  }
}

```

* **Tệp thực thi gốc (`ansible/roles/domain_controller/tasks/main.yml` & `ad/tasks/ous.yml`):**

```yaml
- name: Install AD-Domain-Services
  win_feature:
    name: AD-Domain-Services
    include_management_tools: yes
    state: present

- name: Create domain
  microsoft.ad.domain:
    dns_domain_name: "{{ domain_name }}"
    domain_netbios_name: "{{ netbios_name }}"
    safe_mode_password: "{{ safe_mode_password }}"

- name: Create OUs
  microsoft.ad.ou:
    name: "{{ item.key }}"
    path: "{{ domain_dn }}"
    state: present

```

#### 1.2. Phân tích Giữ / Sửa / Bỏ

* **GIỮ LẠI (Keep):** Cơ chế cài đặt feature `AD-Domain-Services` và khởi tạo Forest gốc kèm DNS; cơ chế vòng lặp tạo các `OrganizationalUnit` (OU) ngay dưới gốc tên miền (`domain_dn`).
* **LOẠI BỎ (Drop):** Bỏ miền con `north.sevenkingdoms.local` (`dc02` - *Winterfell*). Trong đồ án này, kiến trúc mục tiêu chỉ có **1 Domain Controller (`DC01`)**, không đánh vào lỗ hổng Cross-Forest/Child-Domain Trust mà tập trung vào lỗ hổng định danh và CSDL bệnh án nội bộ.
* **CHỈNH SỬA (Modify):**
* Đổi `sevenkingdoms.local` $\rightarrow$ **`clinic.local`** (NetBIOS: `CLINIC`).
* Đổi các OU địa danh phim (`KingsLanding`, `Winterfell`, `TheWall`) $\rightarrow$ các phòng ban thực tế của phòng khám: **`BacSi`, `YTa`, `LeTan`, `IT_Admin`, `ServiceAccounts**`.



#### 1.3. Đoạn mã PowerShell sau khi chuyển đổi (Tương đương 1:1 với Ansible gốc)

```powershell
# [GIỮ NGUYÊN TỪ ANSIBLE ROLE: domain_controller]
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
$dsrmPassword = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force

# [CHỈNH SỬA TỪ config.json: sevenkingdoms.local -> clinic.local]
Install-ADDSForest -DomainName "clinic.local" -DomainNetbiosName "CLINIC" `
                   -SafeModeAdministratorPassword $dsrmPassword -InstallDns:$true -Force:$true

# [CHỈNH SỬA TỪ ad/tasks/ous.yml: Thay OU phim bằng OU Phòng khám]
$domainDN = (Get-ADDomain).DistinguishedName
$clinicOUs = @("BacSi", "YTa", "LeTan", "IT_Admin", "ServiceAccounts")
foreach ($ou in $clinicOUs) {
    New-ADOrganizationalUnit -Name $ou -Path $domainDN -ProtectedFromAccidentalDeletion $false
}

```

---

### PHẦN 2: Khởi tạo Định danh (Users) & Lỗ hổng Kerberoasting / AS-REP Roasting

#### 2.1. Mã nguồn gốc trong GOAD-Light

* **Tệp dữ liệu gốc (`ad/GOAD-Light/data/config.json`):**

```json
"users": {
  "jon.snow": {
    "password": "iknownothing",
    "ou": "TheWall",
    "spn": ["MSSQLSvc/castelblack.north.sevenkingdoms.local:1433"],
    "description": "Night Watch Commander"
  },
  "brandon.stark": {
    "password": "iseedeadpeople",
    "ou": "Winterfell",
    "dont_req_preauth": true
  },
  "samwell.tarly": {
    "password": "heartsbane",
    "ou": "TheWall"
  },
  "arya.stark": {
    "password": "needle",
    "ou": "Winterfell"
  }
}

```

* **Tệp thực thi gốc (`ansible/roles/ad/tasks/users.yml` & `vulns/tasks/kerberoast.yml`):**

```yaml
- name: Create users
  microsoft.ad.user:
    name: "{{ item.key }}"
    sam_account_name: "{{ item.key }}"
    upn: "{{ item.key }}@{{ domain }}"
    password: "{{ item.value.password }}"
    path: "OU={{ item.value.ou }},{{ domain_dn }}"
    password_never_expires: yes
    state: present

- name: Set SPN for Kerberoasting (Powershell inside Ansible)
  win_shell: |
    Set-ADUser -Identity "{{ item.key }}" -ServicePrincipalNames @{Add="{{ spn }}"}

- name: Set AS-REP Roasting (DoNotRequirePreAuth)
  win_shell: |
    Set-ADAccountControl -Identity "{{ item.key }}" -DoesNotRequirePreAuth $true

```

#### 2.2. Phân tích Giữ / Sửa / Bỏ

* **GIỮ LẠI (Keep):**
* **100% lệnh PowerShell gốc** trong `win_shell` của GOAD-Light để cài lỗ hổng: dùng `Set-ADUser ... -ServicePrincipalNames @{Add="MSSQLSvc/..."}` để tạo lỗ hổng **Kerberoasting** (gốc là user `jon.snow` gắn SPN của SQL Server trên `SRV02/castelblack`) và `Set-ADAccountControl -DoesNotRequirePreAuth $true` (gốc là user `brandon.stark`).


* **LOẠI BỎ (Drop):** Bỏ tên các nhân vật `jon.snow`, `brandon.stark`, `arya.stark` và bỏ các mật khẩu từ điển tiếng Anh rời rạc không liên quan đến y tế.
* **CHỈNH SỬA (Modify):**
* Nhân bản (Scale-up) số lượng user từ ~15 nhân vật phim trong GOAD-Light lên **200 định danh nhân sự** (`BS_BacSi001`..`060`, `YT_YTa001`..`100`, `LT_LeTan001`..`035`...).
* Đổi tên `jon.snow` (tài khoản dịch vụ SQL bị Kerberoast) thành **`SVC_HIS_Database`** gắn SPN `MSSQLSvc/SRV02.clinic.local:1433`.
* **Bổ sung kỹ thuật cho Kịch bản 2 của PGNV:** Trong GOAD-Light gốc, tài khoản `jon.snow` để cấu hình mã hóa mặc định. Để thực hiện được Kịch bản 2 (*"so sánh kỹ thuật hạ cấp mã hóa RC4 0x17 và kỹ thuật lẩn tránh OpSec dùng AES256 0x12"*), tooi bổ sung thêm tham số `-KerberosEncryptionType RC4,AES128,AES256` vào lệnh `Set-ADUser`.



#### 2.3. Đoạn mã PowerShell sau khi chuyển đổi

```powershell
# [CHỈNH SỬA TỪ users.yml: Thay danh sách nhân vật phim bằng vòng lặp 200 nhân sự y tế]
$defaultPass = ConvertTo-SecureString "Clinic@2026!" -AsPlainText -Force
$weakPass    = ConvertTo-SecureString "Password123!" -AsPlainText -Force

1..60  | ForEach-Object { New-ADUser -Name ("BS_BacSi{0:D3}" -f $_) -SamAccountName ("BS_BacSi{0:D3}" -f $_) -UserPrincipalName ("BS_BacSi{0:D3}@clinic.local" -f $_) -Path "OU=BacSi,$domainDN" -AccountPassword $defaultPass -Enabled $true -PasswordNeverExpires $true }
1..100 | ForEach-Object { New-ADUser -Name ("YT_YTa{0:D3}" -f $_)   -SamAccountName ("YT_YTa{0:D3}" -f $_)   -UserPrincipalName ("YT_YTa{0:D3}@clinic.local" -f $_)   -Path "OU=YTa,$domainDN"   -AccountPassword $defaultPass -Enabled $true -PasswordNeverExpires $true }
1..35  | ForEach-Object { New-ADUser -Name ("LT_LeTan{0:D3}" -f $_) -SamAccountName ("LT_LeTan{0:D3}" -f $_) -UserPrincipalName ("LT_LeTan{0:D3}@clinic.local" -f $_) -Path "OU=LeTan,$domainDN" -AccountPassword $defaultPass -Enabled $true -PasswordNeverExpires $true }

# [GIỮ NGUYÊN CƠ CHẾ TỪ config.json (user: jon.snow) & vulns/tasks/kerberoast.yml]
# Đổi tên jon.snow -> SVC_HIS_Database và castelblack -> SRV02.clinic.local
New-ADUser -Name "SVC_HIS_Database" -SamAccountName "SVC_HIS_Database" -UserPrincipalName "SVC_HIS_Database@clinic.local" `
           -Path "OU=ServiceAccounts,$domainDN" -AccountPassword $weakPass -Enabled $true -PasswordNeverExpires $true
Set-ADUser -Identity "SVC_HIS_Database" -ServicePrincipalNames @{Add="MSSQLSvc/SRV02.clinic.local:1433"}

# [BỔ SUNG CHO PGNV NỘI DUNG 3: Cho phép cả RC4 (0x17) và AES256 (0x12) để test Evasion]
Set-ADUser -Identity "SVC_HIS_Database" -KerberosEncryptionType RC4,AES128,AES256

# [GIỮ NGUYÊN CƠ CHẾ TỪ config.json (user: brandon.stark) - Lỗ hổng AS-REP Roasting]
New-ADUser -Name "SVC_Backup_Legacy" -SamAccountName "SVC_Backup_Legacy" -UserPrincipalName "SVC_Backup_Legacy@clinic.local" `
           -Path "OU=ServiceAccounts,$domainDN" -AccountPassword $weakPass -Enabled $true
Set-ADAccountControl -Identity "SVC_Backup_Legacy" -DoesNotRequirePreAuth $true

```

---

### PHẦN 3: Cấu hình SMB Share & Phân quyền Lỏng lẻo trên `SRV02`

#### 3.1. Mã nguồn gốc trong GOAD-Light

* **Tệp dữ liệu gốc (`ad/GOAD-Light/data/config.json` - cấu hình cho `srv02` / `castelblack`):**

```json
"srv02": {
  "shares": {
    "all": {
      "path": "C:\\shares\\all",
      "full_access": "Everyone"
    },
    "public": {
      "path": "C:\\shares\\public",
      "read_access": "Domain Users"
    }
  }
}

```

* **Tệp thực thi gốc (`ansible/roles/smb/tasks/shares.yml`):**

```yaml
- name: Create share directory
  win_file:
    path: "{{ item.value.path }}"
    state: directory

- name: Create SMB share
  win_share:
    name: "{{ item.key }}"
    path: "{{ item.value.path }}"
    full: "{{ item.value.full_access | default(omit) }}"

```

#### 3.2. Phân tích Giữ / Sửa / Bỏ

* **GIỮ LẠI (Keep):** Giữ nguyên cơ chế tạo thư mục nội bộ và dùng module SMB của Windows để mở quyền `FullAccess` cho `"Everyone"` (hoặc `"Domain Users"`), tạo bề mặt tấn công đọc/ghi lén qua giao thức SMB (sinh **Event ID 5140 / 5145**).
* **CHỈNH SỬA (Modify):**
* Đổi tên thư mục chia sẻ vô nghĩa `C:\shares\all` (tên share: `all`) của GOAD-Light thành **`C:\HoSoBenhAn_XML`** (tên share ẩn: **`BenhAn$`**).
* Tạo sẵn bên trong đó các tệp mẫu `.xml` tuân thủ cấu trúc thẻ (`MA_LK`, `MA_CCCD`, `CHAN_DOAN`) của **Quyết định 130/QĐ-BYT** và **4750/QĐ-BYT**.



#### 3.3. Đoạn mã PowerShell sau khi chuyển đổi

```powershell
# [GIỮ NGUYÊN LOGIC TỪ ansible/roles/smb/tasks/shares.yml, ĐỔI TÊN SHARE THÀNH BenhAn$]
New-Item -Path "C:\HoSoBenhAn_XML" -ItemType Directory -Force
New-SmbShare -Name "BenhAn$" -Path "C:\HoSoBenhAn_XML" -FullAccess "Everyone" -ErrorAction SilentlyContinue

# [BỔ SUNG THEO PGNV: Tạo file XML BHYT mẫu theo QĐ 130/QĐ-BYT để script HIS đồng bộ và kẻ tấn công đánh cắp]
1..10 | ForEach-Object {
    $xmlContent = "<CHITIEU_HSBA><MA_LK>BN2026_{0:D4}</MA_LK><MA_CCCD>00120400{0:D4}</MA_CCCD><CHAN_DOAN>Tang_Huyet_Ap</CHAN_DOAN></CHITIEU_HSBA>" -f $_, $_
    Set-Content -Path ("C:\HoSoBenhAn_XML\BHYT_130_BN{0:D4}.xml" -f $_) -Value $xmlContent
}

```

---

### PHẦN 4: Cấu hình MS SQL Server & Lỗ hổng Leo thang (`SRV02`)

#### 4.1. Mã nguồn gốc trong GOAD-Light

* **Tệp thực thi gốc (`ansible/roles/mssql/tasks/main.yml` & `files/setup_mssql.ps1`):**
Trong GOAD-Light, role `mssql` cài đặt SQL Server lên máy `srv02` (`castelblack`), sau đó chạy lệnh SQL để cấp quyền mạo danh (`IMPERSONATE` / `EXECUTE AS`) cho tài khoản `samwell.tarly` và `arya.stark` nhằm cho phép kẻ tấn công leo quyền lên `sa` (System Administrator) và bật `xp_cmdshell`:

```sql
-- Trích từ kịch bản cấu hình SQL gốc của GOAD trên SRV02 (castelblack)
CREATE LOGIN [SEVENKINGDOMS\samwell.tarly] FROM WINDOWS;
CREATE LOGIN [NORTH\arya.stark] FROM WINDOWS;
GRANT IMPERSONATE ON LOGIN::sa TO [NORTH\arya.stark];

```

#### 4.2. Phân tích Giữ / Sửa / Bỏ

* **GIỮ LẠI (Keep):** Giữ nguyên cơ chế cài đặt MS SQL Server, tạo Windows Login từ tài khoản Active Directory và cấp quyền cao trên Database để kẻ tấn công (sau khi Kerberoast hoặc chiếm được tài khoản dịch vụ) có thể đăng nhập vào SQL, chạy lệnh **`sp_configure 'xp_cmdshell', 1`** (sinh **Event ID 15457**).
* **LOẠI BỎ (Drop):** Không tạo DB rỗng không có dữ liệu như GOAD gốc.
* **CHỈNH SỬA & BỔ SUNG (Modify & Add):**
* Thay `NORTH\arya.stark` bằng tài khoản dịch vụ **`CLINIC\SVC_HIS_Database`**.
* Tạo cơ sở dữ liệu **`HIS_ClinicDB`** và bảng **`HoSoBenhAn`** chứa dữ liệu bệnh nhân mẫu.
* **Quan trọng nhất (Bổ sung so với GOAD-Light gốc):** Vì GOAD-Light là lab dành cho Red Team (chỉ dựng lỗ hổng để đi chiếm quyền), tác giả Mayfly **KHÔNG bật SQL Server Audit**. Nhưng ĐATN này là *Purple Team / Detection Engineering* theo **Thông tư 13/2025/TT-BYT** và **Nghị định 356/2025/NĐ-CP**, yêu cầu bắt được hành vi đọc/sửa/xóa trái phép bảng bệnh án và hành vi tắt kiểm toán (**Event ID 33205**). Do đó, tôi thêm khối lệnh T-SQL `CREATE SERVER AUDIT ... TO APPLICATION_LOG` vào kịch bản khởi tạo.



#### 4.3. Đoạn mã SQL / PowerShell sau khi chuyển đổi

```sql
-- [CHỈNH SỬA TỪ ansible/roles/mssql: Thay arya.stark bằng CLINIC\SVC_HIS_Database và cấp quyền sysadmin]
CREATE LOGIN [CLINIC\SVC_HIS_Database] FROM WINDOWS;
ALTER SERVER ROLE [sysadmin] ADD MEMBER [CLINIC\SVC_HIS_Database];
GO

-- [BỔ SUNG CHO PGNV: Tạo CSDL Bệnh án điện tử HIS_ClinicDB]
CREATE DATABASE HIS_ClinicDB;
GO
USE HIS_ClinicDB;
CREATE TABLE HoSoBenhAn (
    MaBenhAn VARCHAR(20) PRIMARY KEY,
    SoCCCD VARCHAR(12),
    HoTen NVARCHAR(100),
    ChanDoan NVARCHAR(255),
    DaKySo BIT
);
INSERT INTO HoSoBenhAn VALUES ('BA001', '001204000001', N'Nguyễn Văn A', N'Viêm phế quản cấp', 1);
INSERT INTO HoSoBenhAn VALUES ('BA002', '001204000002', N'Trần Thị B', N'Đái tháo đường tuýp 2', 1);
GO

-- [BỔ SUNG ĐẶC THÙ CỦA ĐATN (Không có trong GOAD gốc): Bật SQL Audit đẩy vào Windows Application Log để sinh Event ID 33205]
USE master;
CREATE SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13]
TO APPLICATION_LOG
WITH (QUEUE_DELAY = 1000, ON_FAILURE = CONTINUE);
ALTER SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13] WITH (STATE = ON);
GO

USE HIS_ClinicDB;
CREATE DATABASE AUDIT SPECIFICATION [Audit_BangHoSoBenhAn]
FOR SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13]
ADD (SELECT, UPDATE, DELETE ON OBJECT::dbo.HoSoBenhAn BY public)
WITH (STATE = ON);
GO

```

---

### PHẦN 5: Cấu hình Ghi vết Nhật ký Sự kiện (Telemetry / Audit Policy)

* **Trong GOAD-Light gốc:** Không bật Registry `15 Field Engineering` (nên không sinh ra **Event ID 1644** khi quét LDAP/ADSI) và không bật đầy đủ `auditpol` cho Kerberos TGS (vì Red Team chỉ cần lấy được cờ/mật khẩu chứ không cần thu thập `.evtx`).
* **Trong kịch bản theo đồ án:** Thêm 2 khối lệnh bật `auditpol` và Registry `NTDS\Diagnostics` thì Windows Server mới ghi lại **Event ID 1644** và **Event ID 4769** vào file `.evtx` để nạp vào ELK.

---

### Bảng tổng hợp đối chiếu (Chương 3 quyển Báo cáo)

| Thành phần kiến trúc | Trong GOAD-Light Gốc (`Orange-Cyberdefense/GOAD`) | Quyết định xử lý | Trong Môi trường Thực nghiệm ĐATN (`GOAD-Light Clinic Edition`) | Lý do chỉnh sửa (Bám sát PGNV) |
| --- | --- | --- | --- | --- |
| **Tên miền (Domain)** | `sevenkingdoms.local` & `north.sevenkingdoms.local` | **Sửa & Rút gọn** | `clinic.local` (1 Domain duy nhất) | Phù hợp quy mô phòng khám vừa và nhỏ (1-2 cơ sở dùng chung 1 miền nội bộ). |
| **Đơn vị tổ chức (OUs)** | `KingsLanding`, `Winterfell`, `TheWall`, `Crownlands` | **Sửa** | `BacSi`, `YTa`, `LeTan`, `IT_Admin`, `ServiceAccounts` | Mô phỏng đúng cơ cấu phòng ban của cơ sở khám chữa bệnh. |
| **Định danh người dùng** | ~15 nhân vật phim (*Jon Snow, Arya Stark, Samwell Tarly...*) | **Sửa & Mở rộng** | **200 tài khoản nhân sự** (`BS_BacSi001..060`, `YT_YTa001..100`...) | Đáp ứng quy mô ~200 nhân sự trong PGNV để chạy kịch bản sinh nhiễu giao ca thực tế. |
| **Lỗ hổng Kerberoasting** | User `jon.snow` gắn SPN `MSSQLSvc/castelblack...:1433` | **Giữ cơ chế, Sửa tên & Thêm cờ** | User `SVC_HIS_Database` gắn SPN `MSSQLSvc/SRV02.clinic.local:1433` (Hỗ trợ cả RC4 `0x17` & AES `0x12`) | Giữ nguyên kỹ thuật của GOAD-Light nhưng mở rộng mã hóa để thực nghiệm so sánh hạ cấp `0x17` và lẩn tránh `0x12`. |
| **Dịch vụ SMB Share** | Share `C:\shares\all` (`FullAccess: Everyone`) | **Giữ cơ chế, Sửa nội dung** | Share `\\SRV02\BenhAn$` chứa các file XML BHYT mẫu | Phục vụ kịch bản đồng bộ hồ sơ BHYT theo QĐ 130/QĐ-BYT và 4750/QĐ-BYT. |
| **Dịch vụ MS SQL Server** | Cài trên `SRV02`, cấp quyền `IMPERSONATE` cho `arya.stark`, **không bật Audit** | **Giữ lỗ hổng, Thêm DB & Bật Audit** | Cấp quyền cho `SVC_HIS_Database`, tạo bảng `HoSoBenhAn` và bật `SERVER AUDIT TO APPLICATION_LOG` | Bắt buộc phải bật Audit về Application Log để sinh **Event ID 33205** và **15457** phục vụ kiểm thử luật SIEM V1–V4. |
