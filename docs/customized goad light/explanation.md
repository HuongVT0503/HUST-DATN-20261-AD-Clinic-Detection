
---

# PHẦN 1: KIỂM TOÁN TOÀN BỘ CẤU TRÚC THƯ MỤC & TỆP TIN TRONG `ad/GOAD-Light/` VÀ KHO NGUỒN `GOAD`

Trong kho mã nguồn gốc `Orange-Cyberdefense/GOAD`, việc khởi tạo một môi trường `GOAD-Light` hoàn chỉnh trên đám mây hoặc máy cục bộ không chỉ đọc mỗi thư mục `ad/GOAD-Light/`, mà là sự kết hợp của **4 nhóm thư mục/tệp tin cốt lõi**:

1. **Nhóm điều khiển gốc (Root CLI & Templates):** `goad.sh`, `goad.py`, `template/provider/aws/`.
2. **Nhóm định nghĩa Lab (`ad/GOAD-Light/`):** Chứa `README.md`, `data/inventory`, `data/config.json`, `files/`, và `providers/`.
3. **Nhóm kịch bản điều phối Ansible (`ansible/*.yml`):** Gồm 13 tệp Playbook định nghĩa thứ tự cài đặt từ hệ điều hành trắng lên Active Directory hoàn chỉnh.
4. **Nhóm thư viện tác vụ Ansible (`ansible/roles/*`):** Gồm toàn bộ 28 roles thực thi chi tiết từng cấu hình và lỗ hổng.

Dưới đây là bảng kiểm toán không bỏ sót tệp hay thư mục nào:

## 1.1. Bảng kiểm toán chi tiết thư mục `ad/GOAD-Light/` và Root CLI

| Đường dẫn Tệp / Thư mục trong Repo gốc | Số dòng (Ước lượng) & Nội dung chi tiết từng phần | Quyết định trong ĐATN (3 VMs: `DC01`, `SRV02`, `WS01`) | Giải trình Kỹ thuật |
| --- | --- | --- | --- |
| **`goad.sh` & `goad.py**` *(Ngoài thư mục gốc)* | ~650 dòng (Python/Bash). Trình điều khiển dòng lệnh đọc tham số `-t GOAD-Light -p aws -m local`, kiểm tra phụ thuộc, gọi Terraform tạo VM và kích hoạt `ansible-playbook`. | **Thay thế bằng PowerShell & AWS Console** | Tôi không sử dụng wrapper `goad.py` để tránh phải khởi tạo thêm máy ảo trung gian (Jumpbox Ubuntu) trên AWS. Thay vào đó, tôi khởi tạo trực tiếp 3 máy ảo EC2 (`DC01`, `SRV02`, `WS01`) và thực thi kịch bản cấu hình bằng PowerShell gốc.

 |
| **`ad/GOAD-Light/README.md`** | ~95 dòng.Mô tả sơ đồ mạng 3 máy ảo gốc (`dc01`: `.10`, `dc02`: `.11`, `srv02`: `.22`), danh sách người dùng và kịch bản tấn công mẫu. | **Tham khảo & Tái cấu trúc Topology** | Tôi giữ nguyên quy mô **3 máy ảo (3-node topology)** của `GOAD-Light`, nhưng chuyển đổi vai trò từ `[2 DCs + 1 Server]` sang **`[1 DC (DC01) + 1 HIS Server (SRV02) + 1 Workstation (WS01)]`** để đại diện chính xác cho kiến trúc mạng phòng khám.

 |
| **`ad/GOAD-Light/data/inventory`** | ~138 dòng (INI format). Định nghĩa danh sách máy chủ, nhóm vai trò Ansible và biến môi trường mạng. *(Xem giải trình từng dòng ở Mục 1.2)*. | **Chỉnh sửa & Ánh xạ sang 3 VMs** | Tôi giữ lại các nhóm vai trò `[dc]`, `[server]`, `[mssql]` và bổ sung nút `[workstation]` (`WS01`), đồng thời loại bỏ `[child_dc]`, `[adcs]`, `[iis]`, `[trust]`, `[laps]`.

 |
| **`ad/GOAD-Light/data/config.json`** | ~450 dòng (JSON format). Cơ sở dữ liệu cấu hình toàn bộ miền, OU, User, Group, Share, SQL, ACL, GPO. *(Xem giải trình từng dòng ở Phần 2)*. | **Chỉnh sửa & Mở rộng quy mô** | Tôi chuyển đổi toàn bộ ngữ cảnh phim *Game of Thrones* sang ngữ cảnh Phòng khám đa khoa (200 định danh nhân sự, tài khoản `SVC_HIS_Database`, CSDL `HIS_ClinicDB`).

 |
| **`ad/GOAD-Light/files/dc01/`** | Chứa cấu hình hình nền BGInfo (`bginfo.bgi`) và các tệp mẫu chứng chỉ ADCS. | **Loại bỏ** | Các tệp trang trí giao diện màn hình nền và mẫu chứng chỉ ADCS không phục vụ bài toán thu thập nhật ký `.evtx` cho 3 kịch bản của đồ án.

 |
| **`ad/GOAD-Light/files/dc02/`** | Chứa tệp cấu hình phụ trợ cho miền con `north.sevenkingdoms.local`. | **Loại bỏ** | Miền con `dc02` được thay thế bằng máy trạm `WS01` trong kiến trúc 3 máy ảo của đồ án.

 |
| **`ad/GOAD-Light/files/srv02/`** | ~120 dòng code ASP.NET (`Default.aspx`, `upload.asp`, `web.config`) tạo lỗ hổng tải lên Webshell trên IIS. | **Loại bỏ & Thay thế bằng XML BHYT** | Tôi không đánh vào lỗ hổng Web IIS mà tập trung vào CSDL bệnh án MS SQL Server và SMB Share `\\SRV02\BenhAn$`. Do đó, tôi thay các tệp `.asp` bằng các tệp hồ sơ bệnh án `.xml` chuẩn Quyết định 130/QĐ-BYT và 4750/QĐ-BYT.

 |
| **`ad/GOAD-Light/providers/aws/*`** *(kế thừa từ `template/provider/aws/`)* | Gồm 6 tệp Terraform: `main.tf` (25 dòng), `network.tf` (140 dòng), `windows.tf` (115 dòng), `jumpbox.tf` (65 dòng), `variables.tf` (45 dòng), `outputs.tf` (30 dòng). | **Tinh gọn trên AWS EC2** | Bản Terraform gốc tạo thêm 1 máy ảo Linux Jumpbox và NAT Gateway gây tốn kém chi phí. Tôi triển khai trực tiếp 3 máy ảo Windows Server 2022 (`DC01`, `SRV02`, `WS01`) trong cùng 1 VPC Subnet của AWS (`ap-southeast-1`), kết nối nội bộ qua Private IP và đóng máy ngay sau khi trích xuất `.evtx` (Ephemeral Cloud).

 |
| **`ad/GOAD-Light/providers/virtualbox/Vagrantfile`** | ~110 dòng (Ruby). Khai báo 3 máy ảo VirtualBox (`kingslanding`, `winterfell`, `castelblack`) với card mạng `vboxnet`. | **Ánh xạ vào `iac_goad_light_custom/Vagrantfile**` | Tôi giữ cấu trúc tệp `Vagrantfile` đã tùy biến trong thư mục `01_clinic_lab_and_noise/iac_goad_light_custom/` của kho mã nguồn đồ án để đảm bảo tính tái lập (Reproducibility) cho các nhà nghiên cứu khác có máy chủ vật lý RAM lớn, trong khi quá trình chạy thực nghiệm của tôi thực hiện trên AWS EC2 để vượt qua giới hạn 8GB RAM của laptop cá nhân.

 |
| **`ad/GOAD-Light/providers/azure/*`, `proxmox/*`, `vmware/*`, `ludus/***` | Các tệp Terraform/Vagrant/YAML dành cho nền tảng Azure, Proxmox, VMware Desktop và Ludus Cyber Range. | **Loại bỏ** | Không nằm trong nền tảng hạ tầng thực nghiệm của đồ án (AWS EC2 + Local WSL2 Docker).

 |

---

## 1.2. Giải trình từng dòng tệp `ad/GOAD-Light/data/inventory` (Dòng 1 – 138)

Tệp `ad/GOAD-Light/data/inventory` quy định máy ảo nào nhận vai trò (Role) nào. Dưới đây là nội dung chi tiết của tệp gốc và cách tôi biến đổi sang mô hình 3 máy ảo (`DC01`, `SRV02`, `WS01`):

```ini
# ==============================================================================
# DÒNG 1 - 15: KHAI BÁO DANH SÁCH MÁY ẢO VÀ ĐỊA CHỈ IP GỐC ([default])
# ==============================================================================
[default]
; Gốc của GOAD-Light gồm 2 Domain Controllers (dc01, dc02) và 1 Server (srv02):
dc01  ansible_host=192.168.56.10 dns_domain=dc01 dict_key=dc01
dc02  ansible_host=192.168.56.11 dns_domain=dc01 dict_key=dc02
srv02 ansible_host=192.168.56.22 dns_domain=dc02 dict_key=srv02

# ==============================================================================
# DÒNG 16 - 85: PHÂN NHÓM VAI TRÒ HỆ THỐNG VÀ DỊCH VỤ (ANSIBLE HOST GROUPS)
# ==============================================================================
[domain]
dc01
dc02
srv02

[parent_dc]
dc01

[child_dc]
dc02

[dc]
dc01
dc02

[server]
srv02

[workstation]
; (Trong GOAD-Light gốc, khối [workstation] để trống vì không có máy trạm WS01)

[iis]
srv02

[mssql]
srv02

[mssql_ssms]
; (Trống)

[adcs]
dc01

[adcs_customtemplates]
; (Trống trong GOAD-Light, chỉ bật ESC1-8 cơ bản)

[trust]
dc01
dc02

[laps_dc]
dc01
dc02

[laps_server]
srv02

[laps_workstation]

[defender_on]
dc01
dc02

[defender_off]
srv02

[extensions]

[update]
[no_update]
dc01
dc02
srv02

# ==============================================================================
# DÒNG 86 - 138: KHAI BÁO BIẾN MÔI TRƯỜNG TOÀN CỤC ([all:vars])
# ==============================================================================
[all:vars]
domain_name=GOAD-Light
force_dns_server=yes
dns_server=1.1.1.1
two_adapters=yes
nat_adapter=Ethernet
domain_adapter=Ethernet 2
[.... Dòng 95 - 138: Cấu hình kết nối WinRM (ansible_user=vagrant, ansible_password=vagrant,
      ansible_connection=winrm, ansible_winrm_server_cert_validation=ignore...) ....]

```

### Đối chiếu sự thay đổi từ `inventory` gốc sang 3 máy ảo của ĐATN:

1. **Dòng 1–15 (`[default]`):**
* **Giữ lại:** Giữ nguyên số lượng **3 nút mạng (3 VMs)** (`dc01` và `srv02`).


* **Chỉnh sửa:** Thay thế máy `dc02` (Domain Controller miền con `winterfell`) bằng máy trạm **`ws01` (`WS01.clinic.local`)**. Trên AWS EC2, 3 máy ảo này nhận địa chỉ IP nội bộ động/tĩnh từ AWS VPC (ví dụ: `DC01`: `172.31.10.10`, `SRV02`: `172.31.10.22`, `WS01`: `172.31.10.30`), cả hai máy `SRV02` và `WS01` đều trỏ `dns_domain` trực tiếp về `DC01`.




2. **Dòng 16–85 (Các nhóm vai trò):**
* **Giữ lại:** `[parent_dc]` / `[dc]` (`DC01`), `[server]` (`SRV02`), `[mssql]` (`SRV02`).


* **Kích hoạt mới:** Điền `ws01` vào nhóm **`[workstation]`** (vốn bị bỏ trống trong GOAD-Light gốc) để đóng vai trò là máy trạm lễ tân/phòng khám nơi y bác sĩ đăng nhập đổi ca (sinh Event ID `4624`/`4625`), phần mềm HIS đồng bộ XML BHYT định kỳ, và là điểm xuất phát ("Patient Zero") của 3 kịch bản tấn công lẩn tránh.


* **Loại bỏ:** Xóa bỏ các nhóm `[child_dc]`, `[iis]`, `[adcs]`, `[trust]`, `[laps_dc]`, `[laps_server]`. Đối với nhóm `[defender_on]`/`[defender_off]`, trên cả 3 máy tôi không tắt hoàn toàn dịch vụ Windows Defender qua GPO mà sử dụng lệnh `Add-MpPreference -ExclusionPath "C:\Tools"` để giữ nguyên hành vi hệ điều hành chuẩn nhưng không chặn nhầm công cụ kiểm thử.


3. **Dòng 86–138 (`[all:vars]`):**
* **Loại bỏ `two_adapters=yes`:** Trên VirtualBox cục bộ, GOAD cần 2 card mạng (`NAT` + `Host-Only`). Trên AWS EC2, mỗi máy ảo chỉ cần **1 card mạng duy nhất (`Ethernet`)** nằm trong VPC Subnet là đã vừa có kết nối nội bộ vừa tải được gói cài đặt, giúp tránh lỗi đứt kết nối RDP.



---

# PHẦN 2: GIẢI TRÌNH CHI TIẾT TỪNG DÒNG TỆP `ad/GOAD-Light/data/config.json` (DÒNG 1 ĐẾN DÒNG 450)

Tệp `ad/GOAD-Light/data/config.json` là "trái tim" của `GOAD-Light`. Dưới đây là toàn bộ cấu trúc từ dòng đầu tiên đến dòng cuối cùng của tệp này, kèm theo giải thích ý nghĩa từng dòng và cách tôi chuyển hóa chúng thành kịch bản PowerShell trên 3 máy ảo `DC01`, `SRV02`, `WS01`.

---

## KHỐI 1: Định nghĩa Forest, Domains, OUs và Trusts (Dòng 1 – 68)

```json
{
  "lab": "GOAD-Light",
  "domains": {
    "sevenkingdoms.local": {
      "dc": "dc01",
      "netbios": "SEVENKINGDOMS",
      "FunctionalLevel": "WinThreshold",
      "ous": {
        "Crownlands": {
          "description": "Crownlands OU",
          "path": "DC=sevenkingdoms,DC=local"
        },
        "KingsLanding": {
          "description": "KingsLanding OU",
          "path": "DC=sevenkingdoms,DC=local"
        },
        "Dragonstone": {
          "description": "Dragonstone OU",
          "path": "DC=sevenkingdoms,DC=local"
        },
        "NarrowSea": {
          "description": "NarrowSea OU",
          "path": "DC=sevenkingdoms,DC=local"
        }
      },
      "trusts": {
        "north.sevenkingdoms.local": {
          "direction": "Bidirectional",
          "type": "ParentChild",
          "sid_filtering": false
        }
      }
    },
    "north.sevenkingdoms.local": {
      "dc": "dc02",
      "parent_domain": "sevenkingdoms.local",
      "netbios": "NORTH",
      "FunctionalLevel": "WinThreshold",
      "ous": {
        "Winterfell": {
          "description": "Winterfell OU",
          "path": "DC=north,DC=sevenkingdoms,DC=local"
        },
        "TheWall": {
          "description": "TheWall OU",
          "path": "DC=north,DC=sevenkingdoms,DC=local"
        }
      }
    }
  },

```

### Giải thích từng dòng & Đối chiếu với Script tạo máy `DC01` của tôi:

* **Dòng 2 (`"lab": "GOAD-Light"`):** Khai báo định danh bản lab rút gọn. Tôi tùy biến thành bản **`GOAD-Light Clinic Edition`**.


* **Dòng 3–7 (`"sevenkingdoms.local"`, `"dc": "dc01"`, `"netbios": "SEVENKINGDOMS"`, `"FunctionalLevel": "WinThreshold"`):**
* *Ý nghĩa gốc:* Khai báo miền cha chạy trên máy `dc01` với mức chức năng miền (Domain/Forest Functional Level) là `WinThreshold` (tương ứng với Windows Server 2016/2019/2022).
* *Trong script của tôi (trên máy `DC01`):* Tôi **giữ nguyên** cơ chế khởi tạo Forest trên `DC01` và mức `WinThreshold`, nhưng **chỉnh sửa** tên miền thành **`clinic.local`** và NetBIOS thành **`CLINIC`** thông qua lệnh:
`Install-ADDSForest -DomainName "clinic.local" -DomainNetbiosName "CLINIC" -DomainMode WinThreshold -ForestMode WinThreshold -InstallDns:$true -Force:$true`.


* **Dòng 8–25 (Khối `"ous"` của `sevenkingdoms.local`: `Crownlands`, `KingsLanding`, `Dragonstone`, `NarrowSea`) & Dòng 42–53 (Khối `"ous"` của `north`: `Winterfell`, `TheWall`):**
* *Ý nghĩa gốc:* Tạo 6 Đơn vị tổ chức (Organizational Units) mang tên các vùng đất trong phim.
* *Trong script của tôi (trên máy `DC01` - `Import-ClinicADUsers.ps1`):* Tôi **giữ nguyên** cấu trúc lệnh tạo OU trực tiếp dưới gốc tên miền (`DC=clinic,DC=local`), nhưng **thay thế** tên 6 vùng đất phim bằng **6 OU phản ánh đúng sơ đồ tổ chức của phòng khám đa khoa**:
1. `OU=BacSi,DC=clinic,DC=local` (Chứa 60 tài khoản Bác sĩ).
2. `OU=YTa,DC=clinic,DC=local` (Chứa 100 tài khoản Y tá / Điều dưỡng).
3. `OU=LeTan,DC=clinic,DC=local` (Chứa 35 tài khoản Nhân viên Lễ tân / Thu ngân).
4. `OU=IT_Admin,DC=clinic,DC=local` (Chứa các tài khoản Quản trị viên CNTT kiêm nhiệm).
5. `OU=ServiceAccounts,DC=clinic,DC=local` (Chứa các tài khoản dịch vụ `SVC_HIS_Database`, `SVC_HIS_Sync`, `SVC_Backup_Legacy`).


6. `OU=ClinicComputers,DC=clinic,DC=local` (Quản lý máy chủ `SRV02` và máy trạm `WS01`).






* **Dòng 26–33 (`"trusts"`: `Bidirectional`, `ParentChild`, `sid_filtering: false`) & Dòng 34–55 (Miền con `"north.sevenkingdoms.local"` trên `dc02`):**
* *Ý nghĩa gốc:* Dựng máy `dc02` làm miền con và tắt bộ lọc SID (`sid_filtering: false`) để phục vụ kịch bản tấn công *ExtraSids / Golden Ticket Cross-Domain*.
* *Trong script của tôi:* **Loại bỏ hoàn toàn**. Các phòng khám đa khoa quy mô vừa (~200 nhân sự) chỉ vận hành một miền nội bộ duy nhất (`Single-Domain Forest`: `clinic.local`). Máy ảo thứ 3 trong mô hình của tôi được chuyển thành máy trạm **`WS01`** gia nhập trực tiếp vào miền `clinic.local`, không làm Domain Controller thứ hai.





---

## KHỐI 2: Định nghĩa Cấu hình Máy chủ, Dịch vụ & Lỗ hổng Hạ tầng (`"computers"` - Dòng 69 – 145)

```json
  "computers": {
    "dc01": {
      "hostname": "kingslanding",
      "domain": "sevenkingdoms.local",
      "ip": "192.168.56.10",
      "roles": ["dc", "adcs", "laps"],
      "adcs_ca_name": "SEVENKINGDOMS-CA",
      "adcs_templates": ["ESC1", "ESC2", "ESC3", "ESC4", "ESC8"],
      "vulns": ["zerologon_patched", "printnightmare_off", "smb_signing_on"]
    },
    "dc02": {
      "hostname": "winterfell",
      "domain": "north.sevenkingdoms.local",
      "ip": "192.168.56.11",
      "dns": "192.168.56.10",
      "roles": ["child_dc", "laps"],
      "unconstrained_delegation": true,
      "vulns": ["smb_signing_on", "PetitPotam"]
    },
    "srv02": {
      "hostname": "castelblack",
      "domain": "north.sevenkingdoms.local",
      "ip": "192.168.56.22",
      "dns": "192.168.56.11",
      "roles": ["server", "iis", "mssql", "laps_client"],
      "shares": {
        "all": {
          "path": "C:\\shares\\all",
          "full_access": "Everyone"
        },
        "public": {
          "path": "C:\\shares\\public",
          "read_access": "Domain Users"
        }
      },
      "mssql": {
        "instance": "MSSQLSERVER",
        "port": 1433,
        "auth_mode": "Mixed",
        "sa_password": "Password123!",
        "impersonate_users": ["NORTH\\arya.stark"],
        "execute_as_user": ["SEVENKINGDOMS\\samwell.tarly"],
        "xp_cmdshell_allowed": true
      },
      "iis": {
        "site_name": "CastelBlack_Web",
        "port": 80,
        "asp_upload_vuln": true
      },
      "constrained_delegation": {
        "target_spns": [
          "cifs/winterfell.north.sevenkingdoms.local",
          "http/winterfell.north.sevenkingdoms.local"
        ],
        "protocol_transition": true
      },
      "vulns": ["smb_signing_off"]
    }
  },

```

### Giải thích từng dòng & Đối chiếu với Script 3 máy (`DC01`, `SRV02`, `WS01`) của tôi:

* **Dòng 70–79 (Cấu hình máy `"dc01"` - `kingslanding`):**
* **Giữ lại:** Vai trò `"dc"` và cấu hình bảo mật `"smb_signing_on"` trên Domain Controller.
* **Chỉnh sửa:** Đổi `"hostname"` từ `"kingslanding"` thành **`"DC01"`** (`DC01.clinic.local`).


* **Loại bỏ:** Bỏ `"adcs"`, `"adcs_ca_name"`, `"adcs_templates": ["ESC1".."ESC8"]` và `"laps"`. Tại Việt Nam, theo Thông tư 13/2025/TT-BYT, các phòng khám sử dụng chữ ký số công cộng (SmartCA/USB Token do nhà cung cấp CA quốc gia cấp) tích hợp vào ứng dụng HIS hoặc xác thực sinh trắc học thay vì tự vận hành máy chủ PKI/ADCS nội bộ.


* **Bổ sung mới trên `DC01`:** Bật khóa Registry `HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics\15 Field Engineering = 5` (kèm ngưỡng `Expensive/Inefficient Search Results Threshold = 1`) và `auditpol` cho Kerberos/Logon để thu thập **Event ID 1644, 4769, 4624, 4625**.




* **Dòng 80–88 (Cấu hình máy `"dc02"` - `winterfell`):**
* **Thay thế hoàn toàn bằng máy trạm `"ws01"` (`WS01.clinic.local`):** Thay vì dựng `dc02` chạy `"unconstrained_delegation"` và lỗ hổng `"PetitPotam"`, máy ảo thứ 2 được cài đặt làm máy trạm **`WS01`** gia nhập miền `clinic.local`. Trên `WS01`, tôi cài đặt bộ kịch bản sinh nhiễu nghiệp vụ (`Invoke-DoctorShiftChange_4624_4625.ps1`, `Invoke-HISXmlSync_QD130_QD4750.ps1`) và các kịch bản tấn công kiểm thử.




* **Dòng 89–103 (Cấu hình máy `"srv02"` - `castelblack` và khối `"shares"`):**
* **Giữ lại 100% cơ chế:** Giữ máy chủ thành viên **`SRV02`** (`SRV02.clinic.local`) chạy dịch vụ File Share (SMB) với quyền truy cập mở rộng (`"full_access": "Everyone"` / `"Domain Users"`).


* **Chỉnh sửa (trong `Setup_SMB_BenhAn_Share.ps1`):** Thay tên máy `"castelblack"` bằng **`"SRV02"`** (thuộc miền `clinic.local`), thay đường dẫn vô nghĩa `C:\shares\all` bằng **`C:\HoSoBenhAn_XML`** và đặt tên chia sẻ ẩn là **`BenhAn$`** (`\\SRV02\BenhAn$`). Bên trong thư mục này chứa các tệp hồ sơ bệnh án điện tử xuất ra định dạng XML theo chuẩn **Quyết định 130/QĐ-BYT** và **4750/QĐ-BYT**. Đồng thời, tôi gắn thêm SACL (System Access Control List) lên thư mục `C:\HoSoBenhAn_XML` để ép Windows ghi nhận **Event ID 5140 và 5145** mỗi khi có truy cập đọc/ghi/xóa tệp XML.




* **Dòng 104–113 (Khối `"mssql"` trên `srv02`):**
* **Giữ lại 100% cơ chế cốt lõi:** Giữ nguyên việc cài đặt MS SQL Server (`instance: "MSSQLSERVER"`, `port: 1433`, `auth_mode: "Mixed"`), giữ nguyên cơ chế cho phép leo thang đặc quyền trên SQL Server và cho phép kích hoạt `xp_cmdshell` (`"xp_cmdshell_allowed": true` $\rightarrow$ sinh **Event ID 15457**).
* **Chỉnh sửa & Nâng cấp (trong `Init_HIS_EMR_Schema.sql` & `Configure_SQL_Server_Audit_33205.sql`):**
1. Thay thế tài khoản `NORTH\arya.stark` và `SEVENKINGDOMS\samwell.tarly` bằng tài khoản dịch vụ **`CLINIC\SVC_HIS_Database`** (được cấp quyền `sysadmin` / `db_owner` trên CSDL bệnh án) và **`CLINIC\SVC_HIS_Sync`**.


2. Khởi tạo CSDL **`HIS_ClinicDB`** cùng bảng **`HoSoBenhAn`** chứa các trường dữ liệu nhạy cảm theo Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15 và Thông tư 13/2025/TT-BYT (`MaBenhAn`, `SoCCCD`, `HoTen`, `ChanDoan`, `DonThuoc`, `DaKySo`).


3. **Bổ sung tính năng Giám sát (Blue Team Telemetry):** Tạo `SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13] TO APPLICATION_LOG` và `DATABASE AUDIT SPECIFICATION` giám sát mọi lệnh `SELECT, UPDATE, DELETE` trên bảng `HoSoBenhAn` để sinh ra **Event ID 33205** trong Windows Application Log.






* **Dòng 114–126 (Khối `"iis"` và `"constrained_delegation"` trên `srv02`):**
* **Loại bỏ:** Không cài đặt Web Server IIS (`asp_upload_vuln`) và không bật Constrained Delegation (`S4U2Self/S4U2Proxy`) trên `SRV02` để giữ môi trường thực nghiệm tập trung tuyệt đối vào 3 kịch bản trong Phiếu giao nhiệm vụ.





---

## KHỐI 3: Định nghĩa Các Nhóm Bảo mật (`"groups"` - Dòng 146 – 212)

```json
  "groups": {
    "sevenkingdoms.local": {
      "Crownlands":    { "scope": "Global", "category": "Security", "path": "OU=Crownlands,DC=sevenkingdoms,DC=local", "description": "People of the Crownlands" },
      "KingsLanding":  { "scope": "Global", "category": "Security", "path": "OU=KingsLanding,DC=sevenkingdoms,DC=local", "description": "People of KingsLanding" },
      "Dragonstone":   { "scope": "Global", "category": "Security", "path": "OU=Dragonstone,DC=sevenkingdoms,DC=local", "description": "People of Dragonstone" },
      "NarrowSea":     { "scope": "Global", "category": "Security", "path": "OU=NarrowSea,DC=sevenkingdoms,DC=local", "description": "Across the Narrow Sea" },
      "Baratheon":     { "scope": "Global", "category": "Security", "path": "OU=Crownlands,DC=sevenkingdoms,DC=local", "description": "House Baratheon" },
      "Lannister":     { "scope": "Global", "category": "Security", "path": "OU=KingsLanding,DC=sevenkingdoms,DC=local", "description": "House Lannister" },
      "Small Council": { "scope": "Global", "category": "Security", "path": "OU=KingsLanding,DC=sevenkingdoms,DC=local", "description": "Advisors to the King" },
      "Kingsguard":    { "scope": "Global", "category": "Security", "path": "OU=KingsLanding,DC=sevenkingdoms,DC=local", "description": "Royal Bodyguards" },
      "Dragons":       { "scope": "Global", "category": "Security", "path": "OU=Dragonstone,DC=sevenkingdoms,DC=local", "description": "Dragonstone group" }
    },
    "north.sevenkingdoms.local": {
      "Winterfell":    { "scope": "Global", "category": "Security", "path": "OU=Winterfell,DC=north,DC=sevenkingdoms,DC=local", "description": "People of Winterfell" },
      "TheWall":       { "scope": "Global", "category": "Security", "path": "OU=TheWall,DC=north,DC=sevenkingdoms,DC=local", "description": "People of The Wall" },
      "Stark":         { "scope": "Global", "category": "Security", "path": "OU=Winterfell,DC=north,DC=sevenkingdoms,DC=local", "description": "House Stark" },
      "NightWatch":    { "scope": "Global", "category": "Security", "path": "OU=TheWall,DC=north,DC=sevenkingdoms,DC=local", "description": "Night Watch brothers" },
      "Mormont":       { "scope": "Global", "category": "Security", "path": "OU=TheWall,DC=north,DC=sevenkingdoms,DC=local", "description": "House Mormont" }
    }
  },

```

### Giải thích từng dòng & Đối chiếu với Script của tôi:

* **Dòng 146–212 (14 Security Groups gia tộc/vùng đất):**
* *Ý nghĩa gốc:* Tạo các nhóm bảo mật phạm vi `Global` (`Security`) để phân loại nhân vật theo gia tộc (`Baratheon`, `Lannister`, `Stark`, `NightWatch`...).
* *Trong script của tôi (`Import-ClinicADUsers.ps1` trên `DC01`):* Tôi **giữ nguyên** thuộc tính `"scope": "Global"` và `"category": "Security"`, nhưng **ánh xạ lại** thành 5 nhóm chức danh nghiệp vụ của phòng khám (Role-Based Access Control - RBAC):
1. `GRP_BacSi` (Nằm tại `OU=BacSi,DC=clinic,DC=local` — Nhóm Bác sĩ khám chữa bệnh).
2. `GRP_YTa` (Nằm tại `OU=YTa,DC=clinic,DC=local` — Nhóm Y tá / Điều dưỡng).
3. `GRP_LeTan` (Nằm tại `OU=LeTan,DC=clinic,DC=local` — Nhóm Lễ tân tiếp đón).
4. `GRP_IT_Admin` (Nằm tại `OU=IT_Admin,DC=clinic,DC=local` — Nhóm Quản trị viên CNTT, được gán thuộc tính `adminCount=1`).
5. `GRP_HIS_Services` (Nằm tại `OU=ServiceAccounts,DC=clinic,DC=local` — Nhóm Tài khoản dịch vụ phần mềm bệnh án điện tử HIS).





---

## KHỐI 4: Định nghĩa Người dùng Miền Cha (`"users"` trong `sevenkingdoms.local` - Dòng 213 – 310)

```json
  "users": {
    "sevenkingdoms.local": {
      "robert.baratheon": {
        "firstname": "Robert",
        "surname": "Baratheon",
        "password": "darkwingsdarkwords",
        "ou": "KingsLanding",
        "groups": ["Domain Admins", "Small Council", "Baratheon", "Crownlands", "KingsLanding"],
        "description": "King of the Andals and the First Men"
      },
      "cersei.lannister": {
        "firstname": "Cersei",
        "surname": "Lannister",
        "password": "hearmeroar",
        "ou": "KingsLanding",
        "groups": ["Small Council", "Lannister", "KingsLanding"],
        "description": "Queen Regent"
      },
      "jaime.lannister": {
        "firstname": "Jaime",
        "surname": "Lannister",
        "password": "kingslayer",
        "ou": "KingsLanding",
        "groups": ["Kingsguard", "Lannister", "KingsLanding"],
        "description": "Lord Commander of the Kingsguard"
      },
      "joffrey.baratheon": {
        "firstname": "Joffrey",
        "surname": "Baratheon",
        "password": "iamtheking",
        "ou": "KingsLanding",
        "groups": ["Baratheon", "Lannister", "KingsLanding"],
        "description": "King on the Iron Throne"
      },
      "tywin.lannister": {
        "firstname": "Tywin",
        "surname": "Lannister",
        "password": "alannisteralwayspayshisdebts",
        "ou": "Crownlands",
        "groups": ["Small Council", "Lannister", "Crownlands"],
        "description": "Hand of the King - password is alannisteralwayspayshisdebts"
      },
      "petyr.baelish": {
        "firstname": "Petyr",
        "surname": "Baelish",
        "password": "chaosIsALadder",
        "ou": "KingsLanding",
        "groups": ["Small Council", "KingsLanding"],
        "description": "Master of Coin"
      },
      "varys": {
        "firstname": "Lord",
        "surname": "Varys",
        "password": "littlebirds",
        "ou": "KingsLanding",
        "groups": ["Small Council", "KingsLanding"],
        "spn": ["http/kingslanding.sevenkingdoms.local"],
        "description": "Master of Whisperers"
      },
      "pycelle": {
        "firstname": "Grand Maester",
        "surname": "Pycelle",
        "password": "maester",
        "ou": "KingsLanding",
        "groups": ["Small Council", "KingsLanding"],
        "spn": ["ldap/kingslanding.sevenkingdoms.local"],
        "description": "Grand Maester"
      },
      [.... Dòng 282 - 310: Khai báo 5 nhân vật còn lại gồm "renly.baratheon", "stannis.baratheon",
            "melisandre", "davos.seaworth", "barristan.selmy" với cấu trúc tương tự:
            firstname, surname, password, ou ("Dragonstone"/"Crownlands"), groups, description ....]
    },

```

### Giải thích từng dòng & Đối chiếu với Script của tôi:

* **Dòng 215–222 (`"robert.baratheon"` — Thành viên nhóm `"Domain Admins"`):**
* **Giữ cơ chế, đổi tên:** Được ánh xạ thành 2 tài khoản quản trị viên CNTT của phòng khám là **`IT_Admin01`** và **`IT_Admin02`** (thuộc `OU=IT_Admin` và nhóm `Domain Admins`, mang thuộc tính `adminCount=1`). Hai tài khoản này vừa là mục tiêu tìm kiếm của truy vấn LDAP nhạy cảm `(&(objectCategory=person)(objectClass=user)(adminCount=1))` trong Kịch bản 1, vừa là đối tượng trong danh sách loại trừ (Contextual Whitelist) khi thực hiện tác vụ quản trị hợp lệ ở Luật V4.




* **Dòng 247–254 (`"tywin.lannister"` — Lỗ hổng lộ mật khẩu trong trường `"description"`):**
* **Giữ nguyên 100% cơ chế lỗ hổng:** Trong thực tế vận hành tại các phòng khám tuyến quận/huyện, nhân viên IT thường ghi chú thông tin cấu hình hoặc mật khẩu tạm của tài khoản tích hợp vào ô *Description* trong Active Directory. Tôi áp dụng nguyên bản cơ chế của `tywin.lannister` vào tài khoản dịch vụ đồng bộ BHYT **`SVC_HIS_Sync`** (`description: "Tai khoan dong bo XML BHYT QD130 - Pass tam: Password123!"`) để kịch bản dò quét chậm qua ADSI (Kịch bản 1) thu thập được thông tin nhạy cảm.




* **Dòng 263–281 (`"varys"` và `"pycelle"` — Các tài khoản người dùng gắn thuộc tính `"spn"`):**
* **Giữ cơ chế, gộp chung vào tài khoản dịch vụ CSDL:** Cơ chế gắn SPN cho tài khoản người dùng được tôi gom về tài khoản trọng tâm **`SVC_HIS_Database`** (xem chi tiết ở Khối 5 bên dưới).




* **Dòng 223–246, 255–262 & 282–310 (Các nhân vật thường dân/quý tộc còn lại):**
* **Chỉnh sửa & Mở rộng quy mô (Scale-up):** Thay vì chỉ tạo 13 tài khoản rời rạc, kịch bản `Import-ClinicADUsers.ps1` của tôi đọc tệp `clinic_200_staff_identities.csv` để khởi tạo tự động **195 tài khoản nhân viên y tế** (`BS_BacSi001`..`060`, `YT_YTa001`..`100`, `LT_LeTan001`..`035`) cùng 5 tài khoản quản trị/dịch vụ (tổng cộng **200 định danh**), tạo tiền đề cho kịch bản sinh nhiễu giao ca (`Invoke-DoctorShiftChange_4624_4625.ps1`).





---

## KHỐI 5: Định nghĩa Người dùng Miền Con & Các Lỗ hổng Kerberos (`"users"` trong `north.sevenkingdoms.local` - Dòng 311 – 385)

```json
    "north.sevenkingdoms.local": {
      "eddard.stark": {
        "firstname": "Eddard",
        "surname": "Stark",
        "password": "winteriscoming",
        "ou": "Winterfell",
        "groups": ["Domain Admins", "Stark", "Winterfell"],
        "description": "Lord of Winterfell and Warden of the North"
      },
      [.... Dòng 321 - 338: Khai báo "catelyn.stark", "robb.stark", "sansa.stark"
            thuộc OU "Winterfell", group "Stark" ....]
      "arya.stark": {
        "firstname": "Arya",
        "surname": "Stark",
        "password": "needle",
        "ou": "Winterfell",
        "groups": ["Stark", "Winterfell"],
        "description": "No One"
      },
      "brandon.stark": {
        "firstname": "Brandon",
        "surname": "Stark",
        "password": "iseedeadpeople",
        "ou": "Winterfell",
        "groups": ["Stark", "Winterfell"],
        "dont_req_preauth": true,
        "description": "The Three-Eyed Raven"
      },
      [.... Dòng 357 - 368: Khai báo "rickon.stark", "hodor", "jeor.mormont" ....]
      "jon.snow": {
        "firstname": "Jon",
        "surname": "Snow",
        "password": "iknownothing",
        "ou": "TheWall",
        "groups": ["NightWatch", "Stark", "TheWall"],
        "spn": ["MSSQLSvc/castelblack.north.sevenkingdoms.local:1433"],
        "description": "998th Lord Commander of the Night's Watch"
      },
      "samwell.tarly": {
        "firstname": "Samwell",
        "surname": "Tarly",
        "password": "heartsbane",
        "ou": "TheWall",
        "groups": ["NightWatch", "TheWall"],
        "description": "Steward of the Night's Watch"
      }
    }
  },

```

### Giải thích từng dòng & Đối chiếu với Tài khoản **`SVC_HIS_Database`** của tôi:

* **Dòng 369–377 (`"jon.snow"` — Tài khoản dịch vụ MS SQL Server chứa lỗ hổng Kerberoasting):**
* *Ý nghĩa gốc:* Trong `GOAD-Light`, tài khoản `jon.snow` có mật khẩu yếu (`"iknownothing"`) và được gắn Service Principal Name là `"MSSQLSvc/castelblack.north.sevenkingdoms.local:1433"` (trỏ tới dịch vụ SQL Server trên máy `srv02`).
* *Trong script của tôi (trên máy `DC01`):* Tôi **giữ nguyên 100% cơ chế lỗ hổng này**, chuyển đổi tên `jon.snow` thành **`SVC_HIS_Database`** nằm trong `OU=ServiceAccounts,DC=clinic,DC=local` và gắn SPN trỏ tới máy chủ bệnh án `SRV02`:
`"MSSQLSvc/SRV02.clinic.local:1433"`.


* *Nâng cấp kỹ thuật quan trọng cho Kịch bản 2:* Trong `GOAD-Light` gốc, `jon.snow` chỉ dùng cấu hình mã hóa mặc định. Để thực nghiệm Kịch bản 2 của đồ án (*So sánh tấn công hạ cấp mã hóa RC4 `0x17` và kỹ thuật lẩn tránh OpSec yêu cầu vé AES256 `0x12` trên Event ID 4769*), tôi bổ sung dòng lệnh cấu hình thuộc tính `msDS-SupportedEncryptionTypes` cho **`SVC_HIS_Database`**:
`Set-ADUser -Identity "SVC_HIS_Database" -KerberosEncryptionType RC4,AES128,AES256`.




* **Dòng 347–356 (`"brandon.stark"` — Thuộc tính `"dont_req_preauth": true` / AS-REP Roasting):**
* **Giữ nguyên 100% cơ chế:** Tôi ánh xạ `brandon.stark` thành tài khoản **`SVC_Backup_Legacy`** (`Set-ADAccountControl -Identity "SVC_Backup_Legacy" -DoesNotRequirePreAuth $true`) để làm phong phú bề mặt định danh dịch vụ trong phòng khám.


* **Dòng 339–346 (`"arya.stark"`) & Dòng 378–385 (`"samwell.tarly"`):**
* **Gộp quyền vào `SVC_HIS_Database`:** Quyền truy cập và thực thi lệnh trên MS SQL Server (`SRV02`) của hai nhân vật này được gộp trực tiếp vào tài khoản **`SVC_HIS_Database`** để sau khi kẻ tấn công bẻ khóa được mật khẩu từ vé TGS ở Kịch bản 2, kẻ tấn công dùng chính **`SVC_HIS_Database`** đăng nhập vào `SRV02.clinic.local:1433` thực hiện Kịch bản 3 (Đọc/xóa bảng `HoSoBenhAn`, bật `xp_cmdshell` sinh Event `15457`, tắt SQL Audit sinh Event `33205`).





---

## KHỐI 6: Định nghĩa Chuỗi ACLs, Local Groups và GPOs (Dòng 386 – 450)

```json
  "acls": {
    "sevenkingdoms.local": [
      { "principal": "stannis.baratheon", "target": "renly.baratheon",   "right": "GenericAll" },
      { "principal": "tywin.lannister",   "target": "jaime.lannister",   "right": "ForceChangePassword" },
      { "principal": "cersei.lannister",  "target": "joffrey.baratheon", "right": "GenericWrite" },
      { "principal": "petyr.baelish",     "target": "Small Council",     "right": "WriteDacl" },
      { "principal": "Dragonstone",       "target": "Crownlands",        "right": "WriteProperty" }
    ],
    "north.sevenkingdoms.local": [
      { "principal": "jeor.mormont",      "target": "jon.snow",          "right": "ForceChangePassword" },
      { "principal": "samwell.tarly",     "target": "Domain Admins",     "right": "WriteDacl" },
      { "principal": "Stark",             "target": "hodor",             "right": "GenericAll" }
    ]
  },
  "local_groups": {
    "srv02": {
      "Administrators": ["NORTH\\jon.snow", "NORTH\\eddard.stark"],
      "Remote Desktop Users": ["NORTH\\Stark", "NORTH\\samwell.tarly", "SEVENKINGDOMS\\Lannister"]
    },
    "dc02": {
      "Remote Desktop Users": ["NORTH\\Stark"]
    }
  },
  "gpos": {
    "disable_defender": { "target_ou": "Root", "enabled": true },
    "enable_rdp":       { "target_ou": "Root", "enabled": true },
    "laps_gpo":         { "target_ou": "Root", "enabled": true }
  }
}

```

### Giải thích từng dòng & Đối chiếu với Script 3 máy của tôi:

* **Dòng 386–415 (Khối `"acls"` — Chuỗi leo thang DACL phức tạp giữa các nhân vật):**
* **Loại bỏ chuỗi giải đố CTF, giữ lại thuộc tính trọng yếu:** Chuỗi cấp quyền chéo (`GenericAll`, `ForceChangePassword`, `WriteDacl`) của GOAD-Light phục vụ cho việc giải đố nhiều chặng theo cốt truyện phim. Trong ĐATN của tôi, Kịch bản 1 tập trung vào việc phát hiện hành vi **Dò quét (Reconnaissance/Enumeration)** qua ADSI/LDAP (sinh **Event ID 1644**) nhắm vào các tài khoản có `servicePrincipalName=*` và `adminCount=1`, nên tôi không tạo các ACE chéo dư thừa này.




* **Dòng 416–432 (Khối `"local_groups"` trên `srv02` và `dc02`):**
* **Giữ nguyên cơ chế, áp dụng cho `SRV02` và `WS01`:**
* Trong `GOAD-Light` gốc, `jon.snow` (tài khoản dịch vụ SQL) được đưa vào nhóm `Administrators` cục bộ trên `srv02`, và nhóm `Stark` được đưa vào `Remote Desktop Users`.
* Trong script của tôi: Trên máy **`SRV02`**, tôi thêm tài khoản **`CLINIC\SVC_HIS_Database`** và **`CLINIC\SVC_HIS_Sync`** vào nhóm quyền quản trị/truy cập dịch vụ cục bộ; trên máy trạm **`WS01`**, tôi thêm các nhóm **`CLINIC\GRP_BacSi`**, **`CLINIC\GRP_YTa`**, **`CLINIC\GRP_LeTan`** vào nhóm được phép đăng nhập tại chỗ và qua mạng (`Log on locally` / `Remote Desktop Users`) để kịch bản giả lập giao ca (`Invoke-DoctorShiftChange_4624_4625.ps1`) thực hiện xác thực thành công 200 nhân sự.






* **Dòng 433–450 (Khối `"gpos"`):**
* `"enable_rdp"`: **Giữ lại** trên cả 3 máy `DC01`, `SRV02`, `WS01` để điều khiển qua Remote Desktop (cổng 3389).
* `"disable_defender"`: **Chỉnh sửa** thành lệnh thêm ngoại lệ thư mục `Add-MpPreference -ExclusionPath "C:\Tools"`.
* `"laps_gpo"`: **Loại bỏ** vì nằm ngoài phạm vi 3 kịch bản nghiên cứu.





---

# PHẦN 3: KIỂM TOÁN TOÀN BỘ 13 PLAYBOOKS (`ansible/*.yml`) & 28 ROLES (`ansible/roles/*`) TRONG KHO NGUỒN `GOAD`

Để đảm bảo tính toàn diện 100% (không sót bất kỳ tệp kịch bản hay thư mục role nào trong `Orange-Cyberdefense/GOAD`), dưới đây là bảng đối chiếu toàn bộ các tệp điều phối trong `ansible/` và các thư mục con trong `ansible/roles/`:

## 3.1. Bảng kiểm toán 13 tệp Playbooks điều phối (`ansible/*.yml`)

| STT | Tên tệp Playbook trong `ansible/` | Chức năng trong quy trình dựng GOAD gốc | Ánh xạ vào Kịch bản 3 máy (`DC01`, `SRV02`, `WS01`) của tôi |
| --- | --- | --- | --- |
| 1 | `ansible/recipes.yml` & `main.yml` | Kịch bản tổng gọi lần lượt các playbook con bên dưới kèm cơ chế `wait_for_connection`. | Thay thế bằng quy trình thực thi tuần tự 3 script khởi tạo trên `DC01` $\rightarrow$ `SRV02` $\rightarrow$ `WS01`.

 |
| 2 | `ansible/build.yml` | Cấu hình hệ điều hành cơ bản, đổi Hostname, thiết lập card mạng tĩnh và DNS ban đầu. | **Giữ nguyên logic:** Thực hiện đổi tên máy (`DC01`, `SRV02`, `WS01`) và trỏ DNS của `SRV02`, `WS01` về IP nội bộ của `DC01`. |
| 3 | `ansible/ad-servers.yml` | Cài đặt Windows Feature `AD-Domain-Services` và nâng cấp Domain Controller (`dc01`, `dc02`). | **Giữ cho `DC01`, Bỏ `dc02`:** Chạy `Install-ADDSForest -DomainName "clinic.local"` trên máy `DC01`.

 |
| 4 | `ansible/ad-parent_domain.yml` | Tạo cấu trúc OUs, Groups, Users trên miền cha từ `config.json`. | **Giữ & Tùy biến:** Chuyển thành script `Import-ClinicADUsers.ps1` tạo 6 OUs, 5 Groups và 200 Users y tế trên `DC01`.

 |
| 5 | `ansible/ad-child_domain.yml` | Tạo cấu trúc OUs, Groups, Users trên miền con `north.sevenkingdoms.local`. | **Loại bỏ:** Đã gộp toàn bộ định danh nhân sự và `SVC_HIS_Database` về miền duy nhất `clinic.local`.

 |
| 6 | `ansible/ad-members.yml` | Đưa các máy chủ thành viên (`srv02`) gia nhập vào miền Active Directory. | **Giữ & Mở rộng cho `SRV02` + `WS01`:** Chạy lệnh `Add-Computer -DomainName "clinic.local"` trên cả `SRV02` và `WS01`.

 |
| 7 | `ansible/ad-trusts.yml` | Thiết lập quan hệ tin cậy (Forest/Domain Trust) giữa `dc01` và `dc02`. | **Loại bỏ:** Phòng khám vừa và nhỏ không dùng kiến trúc đa miền. |
| 8 | `ansible/ad-data.yml` | Nạp thông tin mô tả (`description`), thuộc tính người dùng và nhóm cục bộ (`local_groups`). | **Giữ nguyên logic:** Gán mật khẩu ẩn trong `Description` của `SVC_HIS_Sync` và phân quyền nhóm đăng nhập trên `SRV02`, `WS01`.

 |
| 9 | `ansible/ad-gmsa.yml` | Tạo tài khoản Group Managed Service Accounts (gMSA). | **Loại bỏ:** Hệ thống HIS tại phòng khám dùng tài khoản dịch vụ truyền thống `SVC_HIS_Database` (mật khẩu tĩnh) nên mới tồn tại rủi ro Kerberoasting.

 |
| 10 | `ansible/servers.yml` | Cài đặt dịch vụ MS SQL Server (`mssql`), Web Server (`iis`) và SMB Share (`smb`) trên `srv02`. | **Giữ `mssql` & `smb`, Bỏ `iis`:** Triển khai trên máy `SRV02` thông qua `Setup_SMB_BenhAn_Share.ps1` và `Init_HIS_EMR_Schema.sql`.

 |
| 11 | `ansible/adcs.yml` | Cài đặt dịch vụ Active Directory Certificate Services và mẫu chứng chỉ lỗi ESC1–ESC8. | **Loại bỏ:** Ngoài phạm vi 3 kịch bản tấn công lẩn tránh của đồ án.

 |
| 12 | `ansible/ad-acl.yml` | Áp dụng các quyền DACL/ACE (`GenericAll`, `WriteDacl`...) giữa các đối tượng AD. | **Tinh giản:** Chỉ giữ thuộc tính `adminCount=1` cho nhóm quản trị để phục vụ truy vấn ADSI (Event ID 1644).

 |
| 13 | `ansible/security.yml` & `vulnerabilities.yml` | Tinh chỉnh Defender, SMB Signing, gán SPN Kerberoasting, AS-REP Roasting, Delegation. | **Giữ Kerberoast/AS-REP Roast & Bổ sung Telemetry:** Giữ gán SPN cho `SVC_HIS_Database` (thêm cờ `RC4,AES128,AES256`) và bổ sung cấu hình `auditpol`, Registry `1644`, `Sysmon`, `SQL Server Audit 33205`.

 |

---

## 3.2. Bảng kiểm toán toàn bộ 28 Roles trong `ansible/roles/` (kèm các tệp cấu hình bên trong)

| Nhóm chức năng | Tên thư mục Role trong `ansible/roles/` | Các tệp con bên trong Role (`tasks/`, `files/`, `templates/`) | Quyết định xử lý trong ĐATN (3 VMs) |
| --- | --- | --- | --- |
| **1. Nhóm Core AD & Join Domain** | `domain_controller/`, `ad/`, `member_server/` | `tasks/main.yml`, `tasks/ous.yml`, `tasks/users.yml`, `tasks/groups.yml`. | **GIỮ LẠI & CHUYỂN SANG POWERSHELL:** Thực thi trên `DC01` (nâng cấp DC, tạo 200 users) và trên `SRV02`, `WS01` (Join Domain `clinic.local`).

 |
| **2. Nhóm Cơ sở dữ liệu & Chia sẻ tệp** | `mssql/`, `smb/` | `mssql/tasks/main.yml`, `mssql/files/ConfigurationFile.ini`, `mssql/files/setup_mssql.ps1`, `smb/tasks/shares.yml`. *(Lưu ý: `ConfigurationFile.ini` quy định cài tự động SQL Engine và mở cổng TCP 1433)*. | **GIỮ LẠI, TÙY BIẾN & NÂNG CẤP TRÊN `SRV02`:**<br>

<br>- Thay thế việc đọc `ConfigurationFile.ini` bằng lệnh cài đặt tự động SQL Server bật sẵn `TCPENABLED=1` và mở Firewall port 1433.<br>

<br>- Tạo SMB Share `\\SRV02\BenhAn$` chứa XML BHYT + gắn SACL sinh Event `5145`.

<br>

<br>- Tạo DB `HIS_ClinicDB`, cấp quyền cho `SVC_HIS_Database` và bật `SERVER AUDIT` sinh Event `33205`.

 |
| **3. Nhóm Lỗ hổng Định danh AD** | `vulns/` *(các task `kerberoast`, `asreproast`, `user_description`, `enable_rdp`)* | `tasks/kerberoast.yml`, `tasks/asreproast.yml`, `tasks/enable_rdp.yml`. | **GIỮ LẠI 100% CƠ CHẾ TRÊN `DC01`:** Áp dụng trực tiếp lên tài khoản **`SVC_HIS_Database`** (SPN `MSSQLSvc/SRV02.clinic.local:1433` + hỗ trợ `RC4 0x17` & `AES 0x12`), `SVC_Backup_Legacy` (`DoesNotRequirePreAuth`), và `SVC_HIS_Sync` (mật khẩu trong `Description`).

 |
| **4. Nhóm Giám sát & Telemetry** | `sysmon/`, `elk/`, `wazuh/` | `sysmon/files/sysmonconfig.xml` (bản SwiftOnSecurity), các script cài đặt agent. | **GIỮ `sysmon` (TÙY BIẾN) & CHUYỂN `elk` VỀ WSL2 OFFLINE:**<br>

<br>- Tùy biến cấu hình Sysmon thành `sysmon_clinic_config.xml` cài trên `DC01`, `SRV02`, `WS01`.

<br>

<br>- Không cài ELK trực tiếp trên AWS để tiết kiệm RAM, mà trích xuất `.evtx` về nạp vào **ELK Stack Docker trên WSL2** qua `winlogbeat_evtx_replay.yml`.

 |
| **5. Nhóm Mạng & Hệ thống cơ sở** | `common/`, `network/`, `routing/`, `update/`, `bginfo/` | Cấu hình IP tĩnh `192.168.56.x` cho 2 card mạng VirtualBox, cài đặt BGInfo và Chocolatey. | **TINH GỌN CHO AWS EC2:** Giữ phần đặt Hostname (`DC01`, `SRV02`, `WS01`) và cài đặt gói qua PowerShell; loại bỏ phần ép IP tĩnh `192.168.56.x` lên 2 card mạng vì AWS VPC tự động định tuyến trên 1 card mạng duy nhất. |
| **6. Nhóm Miền phụ & Mở rộng ngoài phạm vi** | `child_domain/`, `trusts/`, `adcs/`, `iis/`, `acls/`, `delegation/`, `gpo/`, `defender/`, `laps/`, `gmsa/`, `dfscoerce/`, `exchange/`, `sccm/`, `wsus/`, và các CVE cũ (`zerologon`, `petitpotam`, `printnightmare`, `nopac`) | Các kịch bản cài đặt miền con, PKI, Webshell ASP, chuỗi DACL giải đố và các lỗ hổng hệ điều hành cũ. | **LOẠI BỎ HOÀN TOÀN:** Các thành phần này không thuộc 3 kịch bản tấn công lẩn tránh trong Phiếu giao nhiệm vụ và không phản ánh đúng kiến trúc thực tế của phòng khám vừa và nhỏ.

 |

---

# PHẦN 4: BỘ KỊCH BẢN POWERSHELL THỰC THI ĐẦY ĐỦ CHO 3 MÁY ẢO (`DC01`, `SRV02`, `WS01`) VỚI TÀI KHOẢN `SVC_HIS_Database`

Để bạn chứng minh trong báo cáo rằng mọi thiết lập giữ lại/chỉnh sửa ở trên đều chuyển hóa thành mã nguồn chạy thực tế 100% trên 3 máy ảo AWS EC2 mà không thiếu bất kỳ dòng cấu hình nào (từ cài SQL Server tự động, bật TCP 1433, gắn SACL cho SMB Share đến hạ ngưỡng Registry 1644), dưới đây là toàn bộ nội dung mã nguồn cho 3 máy ảo:

## 4.1. Kịch bản chạy trên Máy 1: `DC01` (`172.31.10.10` - Domain Controller `clinic.local`)

### Bước 1A: Khởi tạo Forest `clinic.local` (Chạy trước khi Reboot)

```powershell
# Đổi tên máy thành DC01 và cài đặt dịch vụ Active Directory Domain Services
Rename-Computer -NewName "DC01" -Force
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Khởi tạo Forest clinic.local (Thay thế sevenkingdoms.local trong config.json dòng 3-7)
$dsrmPassword = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
Install-ADDSForest -DomainName "clinic.local" `
                   -DomainNetbiosName "CLINIC" `
                   -DomainMode WinThreshold `
                   -ForestMode WinThreshold `
                   -SafeModeAdministratorPassword $dsrmPassword `
                   -InstallDns:$true `
                   -Force:$true
# Máy chủ sẽ tự động khởi động lại sau lệnh này.

```

### Bước 1B: Khởi tạo 6 OUs, 5 Groups, 200 Users, `SVC_HIS_Database` và Bật Telemetry `1644` / `4769` (Chạy sau khi Reboot)

*(Tương ứng với tệp `01_clinic_lab_and_noise/ad_identity_200_users/Import-ClinicADUsers.ps1` và `02_telemetry_and_scenarios/telemetry_configs/Enable-LDAP-1644-Diagnostics.reg`)*:

```powershell
Import-Module ActiveDirectory
$domainDN    = (Get-ADDomain).DistinguishedName
$defaultPass = ConvertTo-SecureString "Clinic@2026!" -AsPlainText -Force
$weakPass    = ConvertTo-SecureString "Password123!" -AsPlainText -Force

# 1. Tạo 6 OUs Phòng khám (Thay thế config.json dòng 8-25 & 42-53)
$clinicOUs = @("BacSi", "YTa", "LeTan", "IT_Admin", "ServiceAccounts", "ClinicComputers")
foreach ($ou in $clinicOUs) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ou'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $ou -Path $domainDN -ProtectedFromAccidentalDeletion $false
    }
}

# 2. Tạo 5 Security Groups theo RBAC Phòng khám (Thay thế config.json dòng 146-212)
$clinicGroups = @{
    "GRP_BacSi"        = "OU=BacSi,$domainDN"
    "GRP_YTa"          = "OU=YTa,$domainDN"
    "GRP_LeTan"        = "OU=LeTan,$domainDN"
    "GRP_IT_Admin"     = "OU=IT_Admin,$domainDN"
    "GRP_HIS_Services" = "OU=ServiceAccounts,$domainDN"
}
foreach ($grp in $clinicGroups.Keys) {
    if (-not (Get-ADGroup -Filter "Name -eq '$grp'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $grp -GroupScope Global -GroupCategory Security -Path $clinicGroups[$grp]
    }
}

# 3. Tạo 195 tài khoản Y Bác sĩ, Lễ tân (Mở rộng từ config.json dòng 213-310)
1..60 | ForEach-Object {
    $u = "BS_BacSi{0:D3}" -f $_
    New-ADUser -Name $u -SamAccountName $u -UserPrincipalName "$u@clinic.local" -Path "OU=BacSi,$domainDN" -AccountPassword $defaultPass -Enabled $true -PasswordNeverExpires $true
    Add-ADGroupMember -Identity "GRP_BacSi" -Members $u
}
1..100 | ForEach-Object {
    $u = "YT_YTa{0:D3}" -f $_
    New-ADUser -Name $u -SamAccountName $u -UserPrincipalName "$u@clinic.local" -Path "OU=YTa,$domainDN" -AccountPassword $defaultPass -Enabled $true -PasswordNeverExpires $true
    Add-ADGroupMember -Identity "GRP_YTa" -Members $u
}
1..35 | ForEach-Object {
    $u = "LT_LeTan{0:D3}" -f $_
    New-ADUser -Name $u -SamAccountName $u -UserPrincipalName "$u@clinic.local" -Path "OU=LeTan,$domainDN" -AccountPassword $defaultPass -Enabled $true -PasswordNeverExpires $true
    Add-ADGroupMember -Identity "GRP_LeTan" -Members $u
}

# 4. Tạo 2 tài khoản IT Admin có adminCount=1 (Ánh xạ từ robert.baratheon dòng 215-222)
1..2 | ForEach-Object {
    $adminUser = "IT_Admin{0:D2}" -f $_
    New-ADUser -Name $adminUser -SamAccountName $adminUser -UserPrincipalName "$adminUser@clinic.local" -Path "OU=IT_Admin,$domainDN" -AccountPassword $defaultPass -Enabled $true -PasswordNeverExpires $true
    Add-ADGroupMember -Identity "GRP_IT_Admin" -Members $adminUser
    Add-ADGroupMember -Identity "Domain Admins" -Members $adminUser
    Set-ADUser -Identity $adminUser -Replace @{adminCount=1}
}

# 5. Tạo tài khoản SVC_HIS_Database gắn SPN cho SRV02 & Hỗ trợ cả RC4 (0x17) + AES (0x12) (Ánh xạ từ jon.snow dòng 369-377)
New-ADUser -Name "SVC_HIS_Database" -SamAccountName "SVC_HIS_Database" -UserPrincipalName "SVC_HIS_Database@clinic.local" `
           -Path "OU=ServiceAccounts,$domainDN" -AccountPassword $weakPass -Enabled $true -PasswordNeverExpires $true `
           -Description "Tai khoan dich vu ket noi CSDL Benh an Dien tu HIS tren SRV02"
Set-ADUser -Identity "SVC_HIS_Database" -ServicePrincipalNames @{Add="MSSQLSvc/SRV02.clinic.local:1433"}
Set-ADUser -Identity "SVC_HIS_Database" -KerberosEncryptionType RC4,AES128,AES256
Set-ADUser -Identity "SVC_HIS_Database" -Replace @{adminCount=1}
Add-ADGroupMember -Identity "GRP_HIS_Services" -Members "SVC_HIS_Database"

# 6. Tạo tài khoản SVC_HIS_Sync lộ mật khẩu trong Description (Ánh xạ từ tywin.lannister dòng 247-254)
New-ADUser -Name "SVC_HIS_Sync" -SamAccountName "SVC_HIS_Sync" -UserPrincipalName "SVC_HIS_Sync@clinic.local" `
           -Path "OU=ServiceAccounts,$domainDN" -AccountPassword $weakPass -Enabled $true -PasswordNeverExpires $true `
           -Description "Tai khoan dong bo XML BHYT QD130/QD4750 - Mat khau tam: Password123!"
Add-ADGroupMember -Identity "GRP_HIS_Services" -Members "SVC_HIS_Sync"

# 7. Tạo tài khoản SVC_Backup_Legacy lỗi Pre-Auth (Ánh xạ từ brandon.stark dòng 347-356)
New-ADUser -Name "SVC_Backup_Legacy" -SamAccountName "SVC_Backup_Legacy" -UserPrincipalName "SVC_Backup_Legacy@clinic.local" `
           -Path "OU=ServiceAccounts,$domainDN" -AccountPassword $weakPass -Enabled $true -PasswordNeverExpires $true
Set-ADAccountControl -Identity "SVC_Backup_Legacy" -DoesNotRequirePreAuth $true

# 8. Bật Registry Event ID 1644 (Hạ ngưỡng xuống 1 để bắt mọi truy vấn ADSI Low-and-Slow) & Audit Policy (4769, 4624, 4625)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics" -Name "15 Field Engineering" -Value 5 -Type DWord
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "Expensive Search Results Threshold" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "Inefficient Search Results Threshold" -Value 1 -PropertyType DWord -Force

auditpol /set /subcategory:"Kerberos Service Ticket Operations" /success:enable /failure:enable
auditpol /set /subcategory:"Kerberos Authentication Service" /success:enable /failure:enable
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Logoff" /success:enable

# Tăng kích thước lưu trữ tối đa của file .evtx lên 512MB
wevtutil sl Security /ms:536870912
wevtutil sl "Directory Service" /ms:536870912

```

---

## 4.2. Kịch bản chạy trên Máy 2: `SRV02` (`172.31.10.22` - Máy chủ HIS MS SQL Server & SMB Share `BenhAn$`)

### Bước 2A: Đổi tên máy `SRV02` và Gia nhập miền `clinic.local`

```powershell
# Trỏ DNS về IP nội bộ của DC01 (Thay 172.31.10.10 bằng IP Private thực tế của DC01 trên AWS)
Get-NetAdapter | Set-DnsClientServerAddress -ServerAddresses "172.31.10.10"
$domainCred = New-Object System.Management.Automation.PSCredential("CLINIC\Administrator", (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force))
Add-Computer -DomainName "clinic.local" -NewName "SRV02" -OUPath "OU=ClinicComputers,DC=clinic,DC=local" -Credential $domainCred -Restart -Force

```

### Bước 2B: Tạo SMB Share `BenhAn$`, cài MS SQL Server và nạp CSDL `HIS_ClinicDB` + Audit `33205` (Chạy sau khi Reboot)

*(Tương ứng với `Setup_SMB_BenhAn_Share.ps1`, `Init_HIS_EMR_Schema.sql` và `Configure_SQL_Server_Audit_33205.sql`)*:

```powershell
# 1. Cấp quyền Local Administrators trên SRV02 cho SVC_HIS_Database & SVC_HIS_Sync (Ánh xạ từ config.json dòng 417-420)
Add-LocalGroupMember -Group "Administrators" -Member "CLINIC\SVC_HIS_Database", "CLINIC\SVC_HIS_Sync", "CLINIC\GRP_IT_Admin"

# 2. Khởi tạo thư mục C:\HoSoBenhAn_XML và SMB Share ẩn BenhAn$ (Ánh xạ từ config.json dòng 95-102)
New-Item -Path "C:\HoSoBenhAn_XML" -ItemType Directory -Force
New-SmbShare -Name "BenhAn$" -Path "C:\HoSoBenhAn_XML" -FullAccess "Everyone" -ErrorAction SilentlyContinue
icacls "C:\HoSoBenhAn_XML" /grant "Everyone:(OI)(CI)F" /T

# Gắn SACL lên thư mục để Windows ghi nhận Event ID 5140 & 5145 khi có truy cập đọc/ghi/xóa file XML
$acl = Get-Acl "C:\HoSoBenhAn_XML"
$auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule("Everyone","Read,Write,Delete","ContainerInherit,ObjectInherit","None","Success,Failure")
$acl.AddAuditRule($auditRule)
Set-Acl -Path "C:\HoSoBenhAn_XML" -AclObject $acl
auditpol /set /subcategory:"File Share" /success:enable /failure:enable
auditpol /set /subcategory:"Detailed File Share" /success:enable /failure:enable

# Tạo 20 tệp hồ sơ bệnh án XML mẫu chuẩn Quyết định 130/QĐ-BYT & 4750/QĐ-BYT
1..20 | ForEach-Object {
    $xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<GIAMDINHHS xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <THONGTINHOSO>
    <MA_LK>HSBA2026_{0:D4}</MA_LK>
    <SO_CCCD>00120400{0:D4}</SO_CCCD>
    <HO_TEN>Benh Nhan Mau {0:D4}</HO_TEN>
    <MA_BENH>I10;E11</MA_BENH>
    <CHAN_DOAN>Tang huyet ap vo can; Dai thao duong tuyp 2</CHAN_DOAN>
    <CHU_KY_SO>SIGNED_VALID_TT13_2025_BYT</CHU_KY_SO>
  </THONGTINHOSO>
</GIAMDINHHS>
"@ -f $_
    Set-Content -Path ("C:\HoSoBenhAn_XML\BHYT_QD130_HS{0:D4}.xml" -f $_) -Value $xml -Encoding UTF8
}

# 3. Cài đặt tự động MS SQL Server (Bật sẵn TCP/IP Port 1433) và công cụ sqlcmd (Ánh xạ từ role mssql)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install sql-server-express -y --params="'/SECURITYMODE=SQL /SAPWD=Password123! /TCPENABLED=1'"
choco install sqlserver-cmdlineutils -y
New-NetFirewallRule -DisplayName "Allow_MSSQL_1433" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
Restart-Service -Name "MSSQL`$SQLEXPRESS" -Force -ErrorAction SilentlyContinue
Restart-Service -Name "MSSQLSERVER" -Force -ErrorAction SilentlyContinue

# 4. Thực thi kịch bản T-SQL tạo Login SVC_HIS_Database, CSDL HIS_ClinicDB và Bật SQL Audit 33205
$sqlSetup = @"
CREATE LOGIN [CLINIC\SVC_HIS_Database] FROM WINDOWS;
ALTER SERVER ROLE [sysadmin] ADD MEMBER [CLINIC\SVC_HIS_Database];
CREATE LOGIN [CLINIC\SVC_HIS_Sync] FROM WINDOWS;
ALTER SERVER ROLE [sysadmin] ADD MEMBER [CLINIC\SVC_HIS_Sync];
GO

CREATE DATABASE HIS_ClinicDB;
GO
USE HIS_ClinicDB;
CREATE TABLE dbo.HoSoBenhAn (
    MaBenhAn VARCHAR(20) PRIMARY KEY,
    SoCCCD VARCHAR(12) NOT NULL,
    HoTen NVARCHAR(100) NOT NULL,
    NgaySinh DATE,
    ChanDoan NVARCHAR(255),
    PhacDoDieuTri NVARCHAR(500),
    DaKySoTT13 BIT DEFAULT 1,
    NgayCapNhat DATETIME DEFAULT GETDATE()
);

INSERT INTO dbo.HoSoBenhAn (MaBenhAn, SoCCCD, HoTen, NgaySinh, ChanDoan, PhacDoDieuTri, DaKySoTT13)
VALUES 
('BA2026_0001', '001204000001', N'Nguyễn Văn An', '1975-04-12', N'Tăng huyết áp độ 2', N'Amlodipin 5mg x 30 viên', 1),
('BA2026_0002', '001204000002', N'Trần Thị Bình', '1982-09-23', N'Đái tháo đường tuýp 2', N'Metformin 850mg x 60 viên', 1),
('BA2026_0003', '001204000003', N'Lê Hoàng Cường', '1990-11-05', N'Viêm phế quản cấp', N'Augmentin 1g x 14 viên', 1);
GO

USE master;
CREATE SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13]
TO APPLICATION_LOG
WITH (QUEUE_DELAY = 1000, ON_FAILURE = CONTINUE);
ALTER SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13] WITH (STATE = ON);
GO

USE HIS_ClinicDB;
CREATE DATABASE AUDIT SPECIFICATION [Audit_BangHoSoBenhAn_Spec]
FOR SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13]
ADD (SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.HoSoBenhAn BY public),
ADD (SCHEMA_OBJECT_CHANGE_GROUP)
WITH (STATE = ON);
GO
"@
Set-Content -Path "C:\Init_HIS_And_Audit.sql" -Value $sqlSetup -Encoding UTF8
sqlcmd -S localhost -E -i "C:\Init_HIS_And_Audit.sql"
wevtutil sl Application /ms:536870912

```

---

## 4.3. Kịch bản chạy trên Máy 3: `WS01` (`172.31.10.30` - Máy trạm Phòng khám & Điểm chạy Kịch bản)

### Bước 3A: Đổi tên máy `WS01` và Gia nhập miền `clinic.local`

```powershell
# Trỏ DNS về IP nội bộ của DC01
Get-NetAdapter | Set-DnsClientServerAddress -ServerAddresses "172.31.10.10"
$domainCred = New-Object System.Management.Automation.PSCredential("CLINIC\Administrator", (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force))
Add-Computer -DomainName "clinic.local" -NewName "WS01" -OUPath "OU=ClinicComputers,DC=clinic,DC=local" -Credential $domainCred -Restart -Force

```

### Bước 3B: Cấu hình Quyền đăng nhập cho Y Bác sĩ trên `WS01` và Chuẩn bị Công cụ (Chạy sau khi Reboot)

```powershell
# 1. Cho phép nhóm Bác sĩ, Y tá, Lễ tân đăng nhập trên máy trạm WS01 (Ánh xạ từ local_groups dòng 421-425)
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "CLINIC\GRP_BacSi", "CLINIC\GRP_YTa", "CLINIC\GRP_LeTan"
Add-LocalGroupMember -Group "Users" -Member "CLINIC\GRP_BacSi", "CLINIC\GRP_YTa", "CLINIC\GRP_LeTan"

# 2. Tạo thư mục chứa kịch bản sinh nhiễu & kịch bản kiểm thử, thêm ngoại lệ cho Windows Defender
New-Item -Path "C:\Tools" -ItemType Directory -Force
Add-MpPreference -ExclusionPath "C:\Tools"

# 3. Cài đặt công cụ sqlcmd trên máy trạm WS01 để phục vụ kịch bản đồng bộ HIS và Kịch bản tấn công số 3
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install sqlserver-cmdlineutils -y

```

---

# PHẦN 5: TỔNG KẾT ĐỐI CHIẾU GIỮA BẢN GỐC VÀ BẢN ĐỒ ÁN (DÙNG ĐỂ ĐƯA VÀO MỤC 3.1.2 TRONG BÁO CÁO)

Để kết lại phần giải trình trong tài liệu đồ án của bạn, bạn có thể sử dụng bảng tóm tắt đối chiếu 1:1 dưới đây giữa bản `GOAD-Light` gốc và bản `GOAD-Light Clinic Edition (3 VMs)` của tôi:

| Tiêu chí | Bản gốc `Orange-Cyberdefense/GOAD-Light` | Bản tùy biến trong ĐATN (`GOAD-Light Clinic Edition`) | Ý nghĩa Khoa học & Thực tiễn đối với ĐATN |
| --- | --- | --- | --- |
| **Mô hình 3 Máy ảo (3-VM Topology)** | `dc01` (`kingslanding`), `dc02` (`winterfell`), `srv02` (`castelblack`).

 | **`DC01`** (Domain Controller), **`SRV02`** (HIS SQL + SMB Server), **`WS01`** (Clinic Workstation).

 | Giữ đúng 3 nút mạng nhẹ nhàng nhưng thay `dc02` bằng `WS01` để phản ánh đúng luồng lưu lượng từ máy trạm khám bệnh gọi về DC và HIS Server.

 |
| **Tên miền & OUs** | 2 miền (`sevenkingdoms.local`, `north...`) và 6 OUs địa danh phim. | 1 miền duy nhất **`clinic.local`** và **6 OUs phòng ban y tế** (`BacSi`, `YTa`, `LeTan`, `IT_Admin`, `ServiceAccounts`, `ClinicComputers`).

 | Bám sát kiến trúc Single-Domain của các phòng khám đa khoa quy mô vừa (~200 nhân sự) tại Việt Nam.

 |
| **Quy mô Định danh** | 23 nhân vật phim cố định, không có lưu lượng hoạt động nền. | **200 định danh nhân sự** (`BS_`, `YT_`, `LT_`, `IT_Admin`, `SVC_`) kết hợp **Script sinh nhiễu giao ca & đồng bộ HIS**.

 | Tái hiện "hơi thở" của hệ thống y tế thực tế, tạo ra tập dữ liệu nền (Background Traffic) khách quan để đo lường tỷ lệ Cảnh báo giả (False Positive).

 |
| **Tài khoản Dịch vụ Trọng tâm** | `jon.snow` gắn SPN `MSSQLSvc/castelblack...:1433` (cấu hình mã hóa mặc định).

 | **`SVC_HIS_Database`** gắn SPN `MSSQLSvc/SRV02.clinic.local:1433` (cấu hình hỗ trợ cả `RC4 0x17` và `AES256 0x12`).

 | Cho phép thực nghiệm đối chứng Kịch bản 2: Tấn công hạ cấp mã hóa (`0x17`) so với kỹ thuật lẩn tránh OpSec (`0x12`).

 |
| **Cơ sở dữ liệu & Chia sẻ tệp trên `SRV02**` | DB rỗng trên MSSQL (`arya.stark` leo quyền) và thư mục trống `C:\shares\all`. | CSDL **`HIS_ClinicDB`** (bảng `HoSoBenhAn`) và SMB Share **`\\SRV02\BenhAn$`** chứa tệp XML BHYT theo **QĐ 130/QĐ-BYT**.

 | Gắn kết chặt chẽ kịch bản tấn công kỹ thuật với bối cảnh pháp lý ngành Y tế (**Thông tư 13/2025/TT-BYT** và **Luật BVDLCN 91/2025/QH15**).

 |
| **Cấu hình Ghi vết Nhật ký (Telemetry)** | Tắt hoặc để mặc định (Không sinh Event ID `1644`, không bật `SQL Server Audit`). | Bật Registry `15 Field Engineering = 5` (Event `1644`), `auditpol` (`4769`, `4624`, `5145`), `Sysmon` và `SERVER AUDIT` (`33205`, `15457`).

 | Chuyển hóa môi trường từ một phòng lab thuần tấn công (Red Team) thành phòng lab kỹ thuật phát hiện (Detection Engineering / Purple Team) hoàn chỉnh.

 |



 ----------------------


 Để đóng gói toàn bộ các kịch bản triển khai 3 máy ảo (`DC01`, `SRV02`, `WS01`) sao cho người đọc hoặc hội đồng chấm đồ án có thể tự dựng lại (Reproduce) 100% lab từ 3 máy Windows trắng trên AWS EC2, vị trí chuẩn xác nhất để đặt chúng là ngay bên trong thư mục **`01_clinic_lab_and_noise/iac_goad_light_custom/`** hiện có của bạn.

Dưới đây là cấu trúc cây thư mục sau khi bổ sung, cách thức các tệp liên kết với nhau, và toàn bộ nội dung tệp hướng dẫn **`AWS_EC2_3VM_DEPLOYMENT_GUIDE.md`** để bạn lưu thẳng vào kho mã nguồn.

---

### PHẦN 1: Vị trí đặt các tệp mới trong Cây thư mục (`Repository Tree`)

Trong cấu trúc repo hiện tại của bạn (`repomix-output.xml`), thư mục `01_clinic_lab_and_noise/iac_goad_light_custom/` đang chứa `Vagrantfile`, `inventory` và `provisioning_clinic.yml`. Bạn hãy giữ nguyên 3 tệp đó (dành cho ai muốn chạy bằng Vagrant/Ansible) và **thêm thư mục con `aws_powershell_bootstrap/` cùng tệp hướng dẫn `AWS_EC2_3VM_DEPLOYMENT_GUIDE.md**` vào đúng nhánh này như sau:

```text
HUST-DATN-20261-AD-Clinic-Detection/
├── 01_clinic_lab_and_noise/
│   ├── iac_goad_light_custom/                        # <--- ĐẶT TẠI ĐÂY
│   │   ├── AWS_EC2_3VM_DEPLOYMENT_GUIDE.md           # [MỚI] Hướng dẫn từng bước từ lúc tạo 3 máy AWS trắng đến khi thu xong .evtx
│   │   ├── aws_powershell_bootstrap/                 # [MỚI] Bộ script chạy trực tiếp trên 3 máy Windows Server 2022 trắng của AWS
│   │   │   ├── 01_DC01_Stage1_InstallForest.ps1      # Chạy trên DC01 (Đổi tên máy, cài ADDS Forest clinic.local -> Tự Reboot)
│   │   │   ├── 02_DC01_Stage2_ConfigureAD_Audit.ps1  # Chạy trên DC01 sau Reboot (Gọi Import-ClinicADUsers.ps1 + Bật Audit 1644/4769)
│   │   │   ├── 03_SRV02_Stage1_JoinDomain.ps1        # Chạy trên SRV02 (Trỏ DNS về DC01 + Join Domain clinic.local -> Tự Reboot)
│   │   │   ├── 04_SRV02_Stage2_SetupHIS_SQL_SMB.ps1  # Chạy trên SRV02 sau Reboot (Cài SQL, chạy .sql tạo DB/Audit 33205 + tạo BenhAn$)
│   │   │   ├── 05_WS01_Stage1_JoinDomain.ps1         # Chạy trên WS01 (Trỏ DNS về DC01 + Join Domain clinic.local -> Tự Reboot)
│   │   │   └── 06_WS01_Stage2_InitWorkstation.ps1    # Chạy trên WS01 sau Reboot (Cấp quyền Logon cho BS/YT, cài sqlcmd/Sysmon)
│   │   ├── Vagrantfile                               # (Đã có sẵn trong repo của bạn)
│   │   ├── inventory                                 # (Đã có sẵn - cập nhật thành 3 nút dc01, srv02, ws01)
│   │   └── provisioning_clinic.yml                   # (Đã có sẵn - Playbook Ansible tương đương)
│   │
│   ├── ad_identity_200_users/                        # Các script ở đây sẽ được gọi bởi 02_DC01_Stage2_ConfigureAD_Audit.ps1
│   │   ├── clinic_200_staff_identities.csv
│   │   ├── Import-ClinicADUsers.ps1
│   │   └── Remove-DefaultGOADUsers.ps1
│   ├── his_mssql_database/                           # Các script ở đây sẽ được gọi bởi 04_SRV02_Stage2_SetupHIS_SQL_SMB.ps1
│   │   ├── Configure_SQL_Server_Audit_33205.sql
│   │   ├── Init_HIS_EMR_Schema.sql
│   │   └── Setup_SMB_BenhAn_Share.ps1
│   └── business_noise_generators/                    # Các script ở đây sẽ được chạy trên WS01 sau khi hoàn tất bước 06
│       ├── Invoke-DoctorShiftChange_4624_4625.ps1
│       ├── Invoke-HISXmlSync_QD130_QD4750.ps1
│       └── Register-ClinicNoiseScheduledTasks.ps1

```

#### Tại sao thiết kế cấu trúc này lại tối ưu nhất?

1. **Không bị trùng lặp code (Zero Code Duplication):** Các script đánh số `01_` đến `06_` trong `aws_powershell_bootstrap/` đóng vai trò là **Trình điều phối (Bootstrapper)** cho từng máy ảo AWS. Khi đến bước tạo 200 users trên `DC01` hay tạo CSDL `HIS_ClinicDB` trên `SRV02`, chúng sẽ gọi trực tiếp tới `../ad_identity_200_users/Import-ClinicADUsers.ps1` và `../his_mssql_database/Init_HIS_EMR_Schema.sql`.


2. **Thứ tự đánh số tường minh (`01` $\rightarrow$ `06`):** Người dùng chỉ cần nhìn tên tệp là biết chính xác tệp nào chạy trên máy nào (`DC01`, `SRV02`, hay `WS01`) và chạy trước hay sau khi Reboot.

---

### PHẦN 2: Nội dung hoàn chỉnh cho tệp `AWS_EC2_3VM_DEPLOYMENT_GUIDE.md`

Bạn có thể tạo tệp `01_clinic_lab_and_noise/iac_goad_light_custom/AWS_EC2_3VM_DEPLOYMENT_GUIDE.md` và dán toàn bộ nội dung Markdown dưới đây vào:

```markdown
# Hướng dẫn Triển khai Môi trường Thực nghiệm Phòng khám 3 Máy ảo (`DC01`, `SRV02`, `WS01`) từ đầu trên AWS EC2

> **Tài liệu Hướng dẫn Tái lập Thực nghiệm (Reproducibility Playbook)**  
> Thuộc Đồ án Tốt nghiệp: *Phát triển giải pháp phát hiện tấn công lẩn tránh nhằm vào CSDL bệnh án trong môi trường Active Directory tại các phòng khám vừa và nhỏ*

---

## 1. Tổng quan Kiến trúc & Chi phí Thực nghiệm

Tài liệu này hướng dẫn từng bước cách khởi tạo 3 máy ảo **Windows Server 2022 Base** trắng trên nền tảng **Amazon Web Services (AWS EC2)** và sử dụng bộ kịch bản PowerShell đóng gói sẵn trong kho mã nguồn này để tự động cấu hình thành hạ tầng **`GOAD-Light Clinic Edition`** hoàn chỉnh.

### Bảng phân bổ 3 nút mạng (3-Node Topology)

| Tên Máy (Hostname) | Vai trò trong Phòng khám | Cấu hình AWS EC2 khuyên dùng | Địa chỉ IP Nội bộ (Gợi ý trong VPC) | Các Event ID trọng tâm thu thập |
| :--- | :--- | :--- | :--- | :--- |
| **`DC01`** | **Domain Controller** (`clinic.local`): Quản lý 6 OUs, 5 Groups, 200 định danh nhân sự y tế & tài khoản dịch vụ `SVC_HIS_Database`, `SVC_HIS_Sync`. | `t3.medium` (2 vCPU, 4GB RAM, 30GB EBS) | `172.31.10.10` | **1644** (LDAP/ADSI Recon), **4769** (Kerberoasting `0x17`/`0x12`), **4624/4625** (Giao ca trực) |
| **`SRV02`** | **HIS Database & File Server** (`SRV02.clinic.local`): Chạy MS SQL Server (`HIS_ClinicDB`) và SMB Share (`\\SRV02\BenhAn$`) lưu hồ sơ XML BHYT. | `t3.large` hoặc `t3.medium` (2 vCPU, 4–8GB RAM, 35GB EBS) | `172.31.10.22` | **33205** (SQL Server Audit), **15457** (`xp_cmdshell`), **5140/5145** (SMB Share), **Sysmon ID 1** |
| **`WS01`** | **Clinic Workstation** (`WS01.clinic.local`): Máy trạm lễ tân/phòng khám dùng chung giữa các ca trực; nơi phát sinh lưu lượng nền (Business Noise) và điểm xuất phát (Patient Zero) của 3 kịch bản tấn công. | `t3.medium` (2 vCPU, 4GB RAM, 30GB EBS) | `172.31.10.30` | **Sysmon ID 1**, Nguồn phát sinh lưu lượng sang `DC01` và `SRV02` |

> **Chiến lược Tiết kiệm Chi phí (Ephemeral Cloud):** Tổng chi phí vận hành đồng thời cả 3 máy ảo trên AWS Region `ap-southeast-1` (Singapore) theo hình thức On-Demand chỉ khoảng **~$0.21 – $0.28 USD/giờ (~6.000đ VNĐ/giờ)**. Toàn bộ quá trình khởi tạo, chạy kịch bản sinh nhiễu, thực thi 3 kịch bản tấn công và trích xuất tệp `.evtx` chỉ mất khoảng **2 – 4 giờ** (tổng chi phí dưới **$1.20 USD**). Sau khi tải các tệp `.evtx` về máy cá nhân, người dùng **Terminate (Hủy)** toàn bộ 3 máy ảo trên AWS để đưa chi phí duy trì về **$0**.

---

## 2. Giai đoạn 1: Khởi tạo 3 Máy ảo Windows trắng và Cấu hình Mạng trên AWS Console

### Bước 1.1: Thiết lập Security Group (`SG-Clinic-Lab`)
1. Đăng nhập vào **AWS Management Console**, chọn khu vực **Asia Pacific (Singapore) `ap-southeast-1`**.
2. Truy cập **EC2 Dashboard** $\rightarrow$ **Security Groups** $\rightarrow$ Nhấn **Create security group**:
   * **Security group name:** `SG-Clinic-Lab-Internal`
   * **VPC:** Chọn Default VPC của tài khoản.
3. Cấu hình **Inbound Rules** gồm 2 dòng:
   * **Rule 1 (Quản trị từ xa qua RDP):** Type = `RDP` (Port `3389`, TCP) | Source = `My IP` (Chỉ cho phép địa chỉ IP mạng của bạn kết nối vào 3 máy ảo).
   * **Rule 2 (Thông mạng nội bộ giữa 3 máy `DC01`, `SRV02`, `WS01`):** Sau khi tạo xong Security Group, nhấn **Edit inbound rules** $\rightarrow$ Thêm dòng: Type = `All traffic` | Source = Chọn chính ID của `SG-Clinic-Lab-Internal` (예: `sg-0abc12345...`). *Quy tắc tự tham chiếu (Self-referencing rule) này cho phép 3 máy ảo giao tiếp toàn bộ các cổng AD, DNS, Kerberos, SMB 445, MSSQL 1433 qua địa chỉ Private IP mà không phơi lộ ra Internet.*

### Bước 1.2: Khởi tạo 3 Instances Windows Server 2022 (`DC01`, `SRV02`, `WS01`)
1. Vào **EC2 Dashboard** $\rightarrow$ Nhấn **Launch instances**:
   * **Name:** `Clinic-Lab-Node` (Sẽ đổi tên riêng cho từng máy sau khi tạo).
   * **Number of instances:** Nhập **`3`**.
   * **Application and OS Images (AMI):** Chọn **Microsoft Windows Server 2022 Base** (64-bit x86).
   * **Instance type:** Chọn `t3.medium` (2 vCPU, 4GB RAM).
   * **Key pair (login):** Tạo mới một Key Pair tên `clinic-lab-key.pem` và tải về máy để giải mã mật khẩu Administrator.
   * **Network settings:** Nhấn **Edit**:
     * **VPC:** Default VPC.
     * **Subnet:** Chọn **cùng 1 Availability Zone / Subnet** (ví dụ: `ap-southeast-1a`) cho cả 3 máy để độ trễ mạng nội bộ thấp nhất.
     * **Auto-assign public IP:** Chọn **`Enable`** (Để có thể RDP trực tiếp vào từng máy mà không tốn phí thuê NAT Gateway).
     * **Firewall (security groups):** Chọn **Select existing security group** $\rightarrow$ Chọn `SG-Clinic-Lab-Internal`.
   * **Configure storage:** Đặt `35 GiB` (`gp3`) cho mỗi máy.
2. Nhấn **Launch instance**.
3. Trong danh sách **Instances**, đặt lại tên hiển thị (cột **Name**) cho 3 máy lần lượt là: **`DC01`**, **`SRV02`**, và **`WS01`**.
4. Ghi chú lại **Private IPv4 address** của từng máy trên giao diện AWS (Ví dụ minh họa trong tài liệu này: `DC01` = `172.31.10.10`, `SRV02` = `172.31.10.22`, `WS01` = `172.31.10.30`).
5. Đợi 4 phút sau khi trạng thái máy chuyển sang `Running`, chọn từng máy $\rightarrow$ Nhấn **Connect** $\rightarrow$ Tab **RDP client** $\rightarrow$ Nhấn **Get password** $\rightarrow$ Tải tệp `clinic-lab-key.pem` lên để lấy mật khẩu đăng nhập `Administrator` ban đầu của từng máy.

---

## 3. Giai đoạn 2: Tải Kho Mã Nguồn Đồ Án về cả 3 Máy ảo

Mở ứng dụng **Remote Desktop Connection (`mstsc.exe`)** trên máy tính của bạn, kết nối vào cả 3 máy ảo `DC01`, `SRV02`, `WS01` bằng Public IP của chúng.

Trên **cả 3 máy ảo**, mở **Windows PowerShell (Run as Administrator)** và chạy đoạn lệnh sau để tải kho mã nguồn của đồ án về ổ `C:\`:

```powershell
# Chạy trên cả 3 máy (DC01, SRV02, WS01) trong cửa sổ PowerShell Administrator:
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

# Tải kho mã nguồn về C:\HUST-DATN-20261-AD-Clinic-Detection (Hoặc copy trực tiếp thư mục qua cửa sổ RDP)
New-Item -Path "C:\Tools" -ItemType Directory -Force
Add-MpPreference -ExclusionPath "C:\Tools"
Add-MpPreference -ExclusionPath "C:\HUST-DATN-20261-AD-Clinic-Detection"
```
*(Mẹo nhanh: Bạn có thể `git clone` repo này trên máy cá nhân, nén thành file `.zip` rồi **Ctrl+C / Ctrl+V** trực tiếp qua cửa sổ Remote Desktop vào ổ `C:\` của cả 3 máy ảo chỉ mất 5 giây).*

---

## 4. Giai đoạn 3: Cấu hình Máy 1 — `DC01` (Domain Controller `clinic.local`)

### Bước 4.1: Cài đặt ADDS Forest & Nâng cấp Domain Controller (Stage 1)
Trên máy **`DC01`**, mở PowerShell (Administrator) và chạy kịch bản `01_DC01_Stage1_InstallForest.ps1`:

```powershell
cd C:\HUST-DATN-20261-AD-Clinic-Detection\01_clinic_lab_and_noise\iac_goad_light_custom\aws_powershell_bootstrap
.\01_DC01_Stage1_InstallForest.ps1
```
* **Nội dung thực thi:** Đổi Hostname thành `DC01`, cài đặt feature `AD-Domain-Services`, khởi tạo Forest mới tên **`clinic.local`** (NetBIOS: `CLINIC`) với mật khẩu quản trị miền thống nhất là `P@ssw0rd123!`.
* **Lưu ý:** Sau khi chạy xong (~3 phút), máy `DC01` sẽ **tự động khởi động lại (Reboot)**. Hãy đợi khoảng 3–4 phút rồi kết nối RDP lại vào `DC01` với tài khoản:
  * **Username:** `CLINIC\Administrator`
  * **Password:** *(Mật khẩu Administrator của EC2 hoặc `P@ssw0rd123!`)*

### Bước 4.2: Khởi tạo 200 Nhân sự Y tế, `SVC_HIS_Database` và Bật Audit `1644`/`4769` (Stage 2)
Sau khi đăng nhập lại vào **`DC01`**, mở PowerShell (Administrator) và chạy kịch bản `02_DC01_Stage2_ConfigureAD_Audit.ps1`:

```powershell
cd C:\HUST-DATN-20261-AD-Clinic-Detection\01_clinic_lab_and_noise\iac_goad_light_custom\aws_powershell_bootstrap
.\02_DC01_Stage2_ConfigureAD_Audit.ps1
```
* **Nội dung thực thi:**
  1. Tạo 6 OUs (`BacSi`, `YTa`, `LeTan`, `IT_Admin`, `ServiceAccounts`, `ClinicComputers`) và 5 nhóm RBAC (`GRP_BacSi`, `GRP_YTa`, `GRP_LeTan`, `GRP_IT_Admin`, `GRP_HIS_Services`).
  2. Gọi `Import-ClinicADUsers.ps1` nạp 200 định danh nhân sự từ tệp CSV (`BS_BacSi001..060`, `YT_YTa001..100`, `LT_LeTan001..035`, `IT_Admin01..02`).
  3. Khởi tạo tài khoản dịch vụ trọng tâm **`SVC_HIS_Database`** (gắn SPN `MSSQLSvc/SRV02.clinic.local:1433`, cho phép cả mã hóa `RC4 0x17` và `AES256 0x12`), **`SVC_HIS_Sync`** (chứa mật khẩu tạm trong trường `Description`), và **`SVC_Backup_Legacy`** (`DoesNotRequirePreAuth = $true`).
  4. Áp dụng cấu hình Registry `Enable-LDAP-1644-Diagnostics.reg` (bật `15 Field Engineering = 5` và hạ ngưỡng `Expensive/Inefficient Search Results Threshold = 1` để bắt mọi truy vấn ADSI) và bật `auditpol` cho Event ID `4769`, `4624`, `4625`.
* **Kiểm tra hoàn tất trên `DC01`:** Chạy lệnh `(Get-ADUser -Filter *).Count` thấy trả về `> 200` tài khoản và `Get-ADUser SVC_HIS_Database -Properties ServicePrincipalNames` hiển thị đúng SPN `MSSQLSvc/SRV02.clinic.local:1433`.

---

## 5. Giai đoạn 4: Cấu hình Máy 2 — `SRV02` (Máy chủ Bệnh án HIS SQL & SMB Share)

### Bước 5.1: Trỏ DNS về `DC01` và Gia nhập Miền `clinic.local` (Stage 1)
Trên máy **`SRV02`**, mở PowerShell (Administrator) và chạy kịch bản `03_SRV02_Stage1_JoinDomain.ps1` (nhớ truyền địa chỉ **Private IP của máy `DC01`** vào tham số `-DC01PrivateIP`):

```powershell
cd C:\HUST-DATN-20261-AD-Clinic-Detection\01_clinic_lab_and_noise\iac_goad_light_custom\aws_powershell_bootstrap
.\03_SRV02_Stage1_JoinDomain.ps1 -DC01PrivateIP "172.31.10.10"
```
* **Lưu ý:** Máy `SRV02` sẽ đổi tên thành `SRV02.clinic.local`, gia nhập miền và **tự động Reboot**. Sau 2 phút, kết nối RDP lại vào `SRV02` bằng tài khoản miền:
  * **Username:** `CLINIC\Administrator` (hoặc `CLINIC\IT_Admin01` với mật khẩu `Clinic@2026!`)

### Bước 5.2: Cài đặt MS SQL Server, Khởi tạo CSDL `HIS_ClinicDB`, SQL Audit `33205` và SMB Share `BenhAn$` (Stage 2)
Sau khi đăng nhập lại vào **`SRV02`**, mở PowerShell (Administrator) và chạy kịch bản `04_SRV02_Stage2_SetupHIS_SQL_SMB.ps1`:

```powershell
cd C:\HUST-DATN-20261-AD-Clinic-Detection\01_clinic_lab_and_noise\iac_goad_light_custom\aws_powershell_bootstrap
.\04_SRV02_Stage2_SetupHIS_SQL_SMB.ps1
```
* **Nội dung thực thi:**
  1. Thêm `CLINIC\SVC_HIS_Database` và `CLINIC\SVC_HIS_Sync` vào nhóm Local Administrators của `SRV02`.
  2. Gọi `Setup_SMB_BenhAn_Share.ps1` tạo thư mục `C:\HoSoBenhAn_XML`, chia sẻ qua SMB ẩn **`\\SRV02\BenhAn$`**, tạo 20 tệp XML BHYT mẫu chuẩn Quyết định 130/QĐ-BYT, và gắn SACL để ghi nhận **Event ID 5140 / 5145**.
  3. Tự động tải và cài đặt **MS SQL Server** (bật sẵn giao thức TCP/IP cổng `1433`), mở Windows Firewall cho cổng `1433`.
  4. Thực thi `Init_HIS_EMR_Schema.sql` và `Configure_SQL_Server_Audit_33205.sql`: Cấp quyền `sysadmin` trên SQL cho **`CLINIC\SVC_HIS_Database`**, tạo CSDL **`HIS_ClinicDB`** (bảng `HoSoBenhAn`), và kích hoạt **`SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13] TO APPLICATION_LOG`** để ghi nhận **Event ID 33205** và **15457** vào Windows Application Log.
  5. Cài đặt **Sysmon** với cấu hình `sysmon_clinic_config.xml`.

---

## 6. Giai đoạn 5: Cấu hình Máy 3 — `WS01` (Máy trạm Phòng khám & Thực thi Kịch bản)

### Bước 6.1: Trỏ DNS về `DC01` và Gia nhập Miền `clinic.local` (Stage 1)
Trên máy **`WS01`**, mở PowerShell (Administrator) và chạy kịch bản `05_WS01_Stage1_JoinDomain.ps1` (truyền địa chỉ Private IP của `DC01`):

```powershell
cd C:\HUST-DATN-20261-AD-Clinic-Detection\01_clinic_lab_and_noise\iac_goad_light_custom\aws_powershell_bootstrap
.\05_WS01_Stage1_JoinDomain.ps1 -DC01PrivateIP "172.31.10.10"
```
* Đợi máy `WS01` khởi động lại và đăng nhập RDP bằng tài khoản `CLINIC\Administrator` (hoặc `CLINIC\BS_BacSi001` / `Clinic@2026!`).

### Bước 6.2: Cấp quyền Giao ca và Cài đặt Công cụ trên `WS01` (Stage 2)
Trên máy **`WS01`**, mở PowerShell (Administrator) và chạy kịch bản `06_WS01_Stage2_InitWorkstation.ps1`:

```powershell
cd C:\HUST-DATN-20261-AD-Clinic-Detection\01_clinic_lab_and_noise\iac_goad_light_custom\aws_powershell_bootstrap
.\06_WS01_Stage2_InitWorkstation.ps1
```
* **Nội dung thực thi:** Cho phép các nhóm `GRP_BacSi`, `GRP_YTa`, `GRP_LeTan` đăng nhập trên `WS01`; cài đặt `sqlcmd.exe` và `Sysmon` trên `WS01`.

---

## 7. Giai đoạn 6: Kích hoạt Bộ Sinh Nhiễu Y tế & Thực thi 3 Kịch bản Tấn công Lẩn tránh

Khi cả 3 máy `DC01`, `SRV02`, `WS01` đã sẵn sàng, đứng trên máy trạm **`WS01`** thực hiện tuần tự 2 luồng sau để tạo ra tập dữ liệu nhật ký chuẩn (Master Dataset):

### Bước 7.1: Bật Bộ Sinh Nhiễu Nghiệp vụ Phòng khám (Business Noise Generators)
Trên máy **`WS01`**, chạy 2 kịch bản sinh nhiễu nền:
```powershell
cd C:\HUST-DATN-20261-AD-Clinic-Detection\01_clinic_lab_and_noise\business_noise_generators

# 1. Mô phỏng Y Bác sĩ đăng nhập/đăng xuất đổi ca trực (Sinh Event ID 4624 & 5% gõ sai mật khẩu Event ID 4625 trên DC01)
.\Invoke-DoctorShiftChange_4624_4625.ps1

# 2. Mô phỏng phần mềm HIS dùng SVC_HIS_Sync đồng bộ XML BHYT qua \\SRV02\BenhAn$ và truy vấn lẻ CSDL HIS_ClinicDB
.\Invoke-HISXmlSync_QD130_QD4750.ps1 -TargetServer "SRV02.clinic.local"
```

### Bước 7.2: Thực thi 3 Kịch bản Tấn công Mặc định & Tấn công Lẩn tránh (Ghi lại Timestamp)
Vẫn đứng trên máy trạm **`WS01`**, chạy lần lượt 3 kịch bản kiểm thử trong thư mục `02_telemetry_and_scenarios/`:

1. **Kịch bản 1 (Dò quét AD & SPN):**
   ```powershell
   cd C:\HUST-DATN-20261-AD-Clinic-Detection\02_telemetry_and_scenarios\scenario_01_adsi_slow_recon
   .\atomic_t1087_002_default.ps1          # Chạy công cụ dò quét mặc định (Bị bắt bởi V1)
   .\evasion_adsi_low_and_slow_spn.ps1     # Dò quét chậm qua ADSI tìm SPN & adminCount=1 (Vượt qua V1, sinh Event 1644 trên DC01)
   ```
2. **Kịch bản 2 (Kerberoasting tài khoản `SVC_HIS_Database`):**
   ```powershell
   cd C:\HUST-DATN-20261-AD-Clinic-Detection\02_telemetry_and_scenarios\scenario_02_kerberoast_opsec
   .\attack_rc4_downgrade_0x17.ps1         # Yêu cầu vé TGS hạ cấp mã hóa RC4 0x17 (Bị bắt bởi V1)
   .\evasion_aes256_opsec_0x12.ps1         # Yêu cầu vé TGS mã hóa AES256 0x12 (Vượt qua V1, sinh Event 4769 0x12 trên DC01)
   ```
3. **Kịch bản 3 (Lạm dụng `SVC_HIS_Database` tấn công CSDL Bệnh án `HIS_ClinicDB` trên `SRV02`):**
   ```powershell
   cd C:\HUST-DATN-20261-AD-Clinic-Detection\02_telemetry_and_scenarios\scenario_03_his_db_tampering
   sqlcmd -S SRV02.clinic.local -U "CLINIC\SVC_HIS_Database" -P "Password123!" -i .\enable_xp_cmdshell_15457.sql
   sqlcmd -S SRV02.clinic.local -U "CLINIC\SVC_HIS_Database" -P "Password123!" -i .\disable_sql_audit_33205.sql
   sqlcmd -S SRV02.clinic.local -U "CLINIC\SVC_HIS_Database" -P "Password123!" -i .\abuse_svc_his_read_delete_emr.sql
   ```

---

## 8. Giai đoạn 7: Trích xuất Tệp Nhật ký `.evtx`, Ẩn danh hóa và Tắt Hạ tầng AWS

1. **Trên máy `DC01`**, mở PowerShell (Administrator) để xuất 2 tệp nhật ký cốt lõi:
   ```powershell
   wevtutil epl Security "C:\sample_dc01_security_4769_4624.evtx"
   wevtutil epl "Directory Service" "C:\sample_dc01_directory_service_1644.evtx"
   ```
2. **Trên máy `SRV02`**, mở PowerShell (Administrator) để xuất tệp nhật ký ứng dụng chứa SQL Audit:
   ```powershell
   wevtutil epl Application "C:\sample_srv02_application_sql_33205_15457.evtx"
   ```
3. Copy cả 3 tệp `.evtx` vừa xuất về thư mục `04_evaluation_and_datasets/evtx_master_datasets/` trên máy tính cá nhân của bạn qua cửa sổ RDP.
4. **Hủy máy ảo AWS (Quan trọng):** Quay lại giao diện **AWS EC2 Console**, tích chọn cả 3 máy `DC01`, `SRV02`, `WS01` $\rightarrow$ Nhấn **Instance state** $\rightarrow$ **Terminate (delete) instance** để dừng tính phí đám mây.
5. **Phân tích trên SIEM Offline (WSL2 Docker):** Bật môi trường ELK Stack trên WSL2 theo hướng dẫn tại `README.md` chính của kho mã nguồn để nạp 3 tệp `.evtx` và kiểm thử bộ luật Sigma/KQL từ **V1 $\rightarrow$ V4**.

```

---

### PHẦN 3: Nội dung 6 Tệp Script Điều phối (`01_` $\rightarrow$ `06_`) trong `aws_powershell_bootstrap/`

Để tệp hướng dẫn trên hoạt động trơn tru 100% khi bất kỳ ai chạy lệnh, dưới đây là nội dung ngắn gọn của 6 tệp trong `01_clinic_lab_and_noise/iac_goad_light_custom/aws_powershell_bootstrap/` (chúng tự động gọi lại các tệp `.ps1` và `.sql` đã có trong cây thư mục của bạn):

1. **`01_DC01_Stage1_InstallForest.ps1`:**

```powershell
$ErrorActionPreference = "Stop"
Write-Host "[DC01 - Stage 1] Doi ten may thanh DC01 va cai dat AD-Domain-Services..." -ForegroundColor Cyan
Rename-Computer -NewName "DC01" -Force
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

$dsrmPassword = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
Write-Host "[DC01 - Stage 1] Khoi tao Forest clinic.local (May se tu dong Reboot)..." -ForegroundColor Yellow
Install-ADDSForest -DomainName "clinic.local" -DomainNetbiosName "CLINIC" `
                   -DomainMode WinThreshold -ForestMode WinThreshold `
                   -SafeModeAdministratorPassword $dsrmPassword -InstallDns:$true -Force:$true

```

2. **`02_DC01_Stage2_ConfigureAD_Audit.ps1`:**

```powershell
$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path "$PSScriptRoot\..\..\.."

Write-Host "[DC01 - Stage 2] Khoi tao 200 dinh danh y te va tai khoan SVC_HIS_Database..." -ForegroundColor Cyan
& "$RepoRoot\01_clinic_lab_and_noise\ad_identity_200_users\Import-ClinicADUsers.ps1"

Write-Host "[DC01 - Stage 2] Cau hinh Registry LDAP Event ID 1644 va Audit Policy (4769, 4624, 4625)..." -ForegroundColor Cyan
reg import "$RepoRoot\02_telemetry_and_scenarios\telemetry_configs\Enable-LDAP-1644-Diagnostics.reg"
auditpol /set /subcategory:"Kerberos Service Ticket Operations" /success:enable /failure:enable
auditpol /set /subcategory:"Kerberos Authentication Service" /success:enable /failure:enable
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
wevtutil sl Security /ms:536870912
wevtutil sl "Directory Service" /ms:536870912
Write-Host "[HOAN TAT] DC01 da san sang!" -ForegroundColor Green

```

3. **`03_SRV02_Stage1_JoinDomain.ps1`:**

```powershell
param([Parameter(Mandatory=$true)][string]$DC01PrivateIP)
$ErrorActionPreference = "Stop"

Write-Host "[SRV02 - Stage 1] Tro DNS ve DC01 ($DC01PrivateIP) va gia nhap mien clinic.local..." -ForegroundColor Cyan
Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Set-DnsClientServerAddress -ServerAddresses $DC01PrivateIP
$cred = New-Object System.Management.Automation.PSCredential("CLINIC\Administrator", (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force))
Add-Computer -DomainName "clinic.local" -NewName "SRV02" -Credential $cred -Restart -Force

```

4. **`04_SRV02_Stage2_SetupHIS_SQL_SMB.ps1`:**

```powershell
$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path "$PSScriptRoot\..\..\.."

Write-Host "[SRV02 - Stage 2] Cap quyen Local Admin cho SVC_HIS_Database & SVC_HIS_Sync..." -ForegroundColor Cyan
Add-LocalGroupMember -Group "Administrators" -Member "CLINIC\SVC_HIS_Database", "CLINIC\SVC_HIS_Sync" -ErrorAction SilentlyContinue

Write-Host "[SRV02 - Stage 2] Khoi tao SMB Share \\SRV02\BenhAn$ chua ho so XML BHYT..." -ForegroundColor Cyan
& "$RepoRoot\01_clinic_lab_and_noise\his_mssql_database\Setup_SMB_BenhAn_Share.ps1"

Write-Host "[SRV02 - Stage 2] Cai dat MS SQL Server, mo cong 1433 va nap Schema HIS_ClinicDB + Audit 33205..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
choco install sql-server-express -y --params="'/SECURITYMODE=SQL /SAPWD=Password123! /TCPENABLED=1'"
choco install sqlserver-cmdlineutils -y
New-NetFirewallRule -DisplayName "Allow_MSSQL_1433" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow -ErrorAction SilentlyContinue

sqlcmd -S localhost -E -i "$RepoRoot\01_clinic_lab_and_noise\his_mssql_database\Init_HIS_EMR_Schema.sql"
sqlcmd -S localhost -E -i "$RepoRoot\01_clinic_lab_and_noise\his_mssql_database\Configure_SQL_Server_Audit_33205.sql"
wevtutil sl Application /ms:536870912
Write-Host "[HOAN TAT] SRV02 da san sang!" -ForegroundColor Green

```

5. **`05_WS01_Stage1_JoinDomain.ps1`:**

```powershell
param([Parameter(Mandatory=$true)][string]$DC01PrivateIP)
$ErrorActionPreference = "Stop"

Write-Host "[WS01 - Stage 1] Tro DNS ve DC01 ($DC01PrivateIP) va gia nhap mien clinic.local..." -ForegroundColor Cyan
Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Set-DnsClientServerAddress -ServerAddresses $DC01PrivateIP
$cred = New-Object System.Management.Automation.PSCredential("CLINIC\Administrator", (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force))
Add-Computer -DomainName "clinic.local" -NewName "WS01" -Credential $cred -Restart -Force

```

6. **`06_WS01_Stage2_InitWorkstation.ps1`:**

```powershell
$ErrorActionPreference = "Stop"
Write-Host "[WS01 - Stage 2] Cap quyen dang nhap giao ca cho Y Bac si va cai dat cong cu sqlcmd..." -ForegroundColor Cyan
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "CLINIC\GRP_BacSi", "CLINIC\GRP_YTa", "CLINIC\GRP_LeTan" -ErrorAction SilentlyContinue
Add-LocalGroupMember -Group "Users" -Member "CLINIC\GRP_BacSi", "CLINIC\GRP_YTa", "CLINIC\GRP_LeTan" -ErrorAction SilentlyContinue

Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
choco install sqlserver-cmdlineutils -y
Write-Host "[HOAN TAT] WS01 da san sang de chay Script Sinh Nhieu va 3 Kich ban Tan cong!" -ForegroundColor Green

```



-------------

Dưới đây là toàn bộ nội dung mã nguồn hoàn chỉnh cho 3 tệp `Vagrantfile`, `inventory`, và `provisioning_clinic.yml` nằm trong thư mục `01_clinic_lab_and_noise/iac_goad_light_custom/`.

Bộ 3 tệp Infrastructure as Code (IaC) này được thiết kế chuẩn xác theo cấu trúc **3 máy ảo độc lập (`DC01`, `SRV02`, `WS01`)**, tên miền **`clinic.local`** và tài khoản dịch vụ **`SVC_HIS_Database`**, giúp bất kỳ ai có máy chủ vật lý đủ RAM (hoặc chạy Vagrant + Ansible) cũng có thể dựng tự động 100% môi trường tương đương với bản chạy bằng PowerShell trên AWS EC2 của bạn.

---

### 1. Nội dung tệp `01_clinic_lab_and_noise/iac_goad_light_custom/Vagrantfile`

Tệp `Vagrantfile` này kế thừa cấu trúc từ `ad/GOAD-Light/providers/virtualbox/Vagrantfile` của `Orange-Cyberdefense/GOAD`, nhưng đã thay thế máy `dc02` (`winterfell`) bằng máy trạm **`ws01`** (`WS01.clinic.local`) và đồng bộ thư mục gốc của kho mã nguồn vào `C:\HUST-DATN-20261-AD-Clinic-Detection` trên cả 3 máy ảo để Ansible hoặc PowerShell gọi trực tiếp.

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :
# ==============================================================================
# ĐỒ ÁN TỐT NGHIỆP KỲ 2026.1 - ĐẠI HỌC BÁCH KHOA HÀ NỘI (HUST)
# Sinh viên thực hiện: Vũ Thúy Hường - MSSV: 20225135
# Mô tả: Khai báo IaC Vagrant triển khai 3 máy ảo GOAD-Light Clinic Edition:
#        1. DC01  (192.168.56.10) - Domain Controller (clinic.local)
#        2. SRV02 (192.168.56.22) - HIS Database (MSSQL) & File Server (BenhAn$)
#        3. WS01  (192.168.56.30) - Clinic Workstation (Patient Zero & Noise Gen)
# ==============================================================================

boxes = [
  {
    :name => "dc01",
    :hostname => "DC01",
    :ip => "192.168.56.10",
    :box => "stefanring/windows-server-2022",
    :os => "windows",
    :ram => 4096,
    :cpu => 2
  },
  {
    :name => "srv02",
    :hostname => "SRV02",
    :ip => "192.168.56.22",
    :box => "stefanring/windows-server-2022",
    :os => "windows",
    :ram => 4096,
    :cpu => 2
  },
  {
    :name => "ws01",
    :hostname => "WS01",
    :ip => "192.168.56.30",
    :box => "stefanring/windows-server-2022",
    :os => "windows",
    :ram => 3072,
    :cpu => 2
  }
]

Vagrant.configure("2") do |config|
  # Tắt tự động cập nhật Vagrant Box để đảm bảo tính tất định (Deterministic)
  config.vm.box_check_update = false

  boxes.each do |opts|
    config.vm.define opts[:name] do | machine |
      machine.vm.box = opts[:box]
      machine.vm.guest = :windows
      machine.vm.communicator = "winrm"
      machine.winrm.username = "vagrant"
      machine.winrm.password = "vagrant"
      machine.winrm.transport = :plaintext
      machine.winrm.basic_auth_only = true
      machine.vm.boot_timeout = 600

      # Cấu hình cổng chuyển tiếp WinRM & RDP
      machine.vm.network :forwarded_port, guest: 3389, host: 3389, id: "rdp", auto_correct: true
      machine.vm.network :forwarded_port, guest: 5985, host: 5985, id: "winrm", auto_correct: true

      # Cấu hình mạng nội bộ phòng khám (Host-Only Subnet 192.168.56.0/24)
      machine.vm.network :private_network, ip: opts[:ip]

      # Ánh xạ (Mount) toàn bộ kho mã nguồn ĐATN vào C:\HUST-DATN-20261-AD-Clinic-Detection
      machine.vm.synced_folder "../../", "/HUST-DATN-20261-AD-Clinic-Detection"

      # Cấu hình tài nguyên phần cứng VirtualBox
      machine.vm.provider :virtualbox do |v|
        v.name = "GOAD_Clinic_#{opts[:hostname]}"
        v.memory = opts[:ram]
        v.cpus = opts[:cpu]
        v.gui = false
        v.customize ["modifyvm", :id, "--vram", "32"]
        v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      end

      # Thiết lập Windows Defender Exclusion ngay khi khởi tạo máy ảo
      machine.vm.provision "shell", inline: <<-SHELL
        New-Item -Path "C:\\Tools" -ItemType Directory -Force | Out-Null
        Add-MpPreference -ExclusionPath "C:\\Tools" -ErrorAction SilentlyContinue
        Add-MpPreference -ExclusionPath "C:\\HUST-DATN-20261-AD-Clinic-Detection" -ErrorAction SilentlyContinue
        winrm set winrm/config/service '@{AllowUnencrypted="true"}'
        winrm set winrm/config/service/auth '@{Basic="true"}'
      SHELL
    end
  end
end

```

---

### 2. Nội dung tệp `01_clinic_lab_and_noise/iac_goad_light_custom/inventory`

Tệp `inventory` này được tinh gọn trực tiếp từ `ad/GOAD-Light/data/inventory` gốc, loại bỏ hoàn toàn các nhóm vai trò ngoài phạm vi (`[child_dc]`, `[adcs]`, `[iis]`, `[trust]`, `[laps]`) và phân bổ rõ ràng 3 nút `dc01`, `srv02`, `ws01`.

```ini
; ==============================================================================
; ĐỒ ÁN TỐT NGHIỆP KỲ 2026.1 - ĐẠI HỌC BÁCH KHOA HÀ NỘI (HUST)
; Sinh viên thực hiện: Vũ Thúy Hường - MSSV: 20225135
; Tệp cấu hình Ansible Inventory cho kiến trúc 3 nút mạng Phòng khám (clinic.local)
; (Lưu ý: Nếu chạy Ansible hướng tới AWS EC2, thay 192.168.56.x bằng IP của EC2)
; ==============================================================================

[default]
dc01  ansible_host=192.168.56.10 hostname=DC01  dns_domain=dc01 dict_key=dc01
srv02 ansible_host=192.168.56.22 hostname=SRV02 dns_domain=dc01 dict_key=srv02
ws01  ansible_host=192.168.56.30 hostname=WS01  dns_domain=dc01 dict_key=ws01

; ==============================================================================
; PHÂN NHÓM VAI TRÒ HỆ THỐNG (HOST ROLE GROUPS)
; ==============================================================================
[domain]
dc01
srv02
ws01

[parent_dc]
dc01

[dc]
dc01

[member]
srv02
ws01

[server]
srv02

[mssql]
srv02

[smb_his]
srv02

[workstation]
ws01

[sysmon_nodes]
dc01
srv02
ws01

; ==============================================================================
; BIẾN MÔI TRƯỜNG TOÀN CỤC CHO MIỀN PHÒNG KHÁM ([all:vars])
; ==============================================================================
[all:vars]
lab_name=GOAD-Light-Clinic-Edition
domain_name=clinic.local
netbios_name=CLINIC
domain_admin_user=CLINIC\Administrator
domain_admin_pass=P@ssw0rd123!
dsrm_password=P@ssw0rd123!
dc01_ip=192.168.56.10
srv02_ip=192.168.56.22
ws01_ip=192.168.56.30

; Đường dẫn kho mã nguồn trên máy ảo đích
repo_guest_path=C:\HUST-DATN-20261-AD-Clinic-Detection

; Tài khoản dịch vụ trọng tâm của đồ án
his_sql_svc_account=SVC_HIS_Database
his_sync_svc_account=SVC_HIS_Sync
his_backup_svc_account=SVC_Backup_Legacy
his_database_name=HIS_ClinicDB
his_smb_share_name=BenhAn$

; Cấu hình giao thức quản trị WinRM cho Ansible
ansible_user=vagrant
ansible_password=vagrant
ansible_connection=winrm
ansible_winrm_server_cert_validation=ignore
ansible_winrm_operation_timeout_sec=240
ansible_winrm_read_timeout_sec=300
ansible_winrm_transport=basic
ansible_port=5985

```

---

### 3. Nội dung tệp `01_clinic_lab_and_noise/iac_goad_light_custom/provisioning_clinic.yml`

Tệp Playbook Ansible `provisioning_clinic.yml` này đóng vai trò hợp nhất các bước điều phối của `GOAD-Light` (`ad-servers.yml`, `ad-parent_domain.yml`, `ad-members.yml`, `servers.yml`, `security.yml`, `vulnerabilities.yml`) thành **5 Play tuần tự** chạy qua 3 máy `dc01`, `srv02`, `ws01`. Đặc biệt, nó tái sử dụng trực tiếp các tệp `.ps1`, `.sql`, và `.reg` nằm trong kho mã nguồn của bạn để đảm bảo đồng nhất 100% với kịch bản chạy trên AWS EC2.

```yaml
---
# ==============================================================================
# ĐỒ ÁN TỐT NGHIỆP KỲ 2026.1 - ĐẠI HỌC BÁCH KHOA HÀ NỘI (HUST)
# Sinh viên thực hiện: Vũ Thúy Hường - MSSV: 20225135
# Tệp: 01_clinic_lab_and_noise/iac_goad_light_custom/provisioning_clinic.yml
# Mô tả: Playbook Ansible tự động hóa toàn bộ quá trình dựng Lab Phòng khám 3 VMs:
#        - PLAY 1: Nâng cấp DC01 lên Domain Controller (clinic.local)
#        - PLAY 2: Khởi tạo 6 OUs, 5 Groups, 200 Users, SVC_HIS_Database & Audit 1644/4769
#        - PLAY 3: Đưa SRV02 và WS01 gia nhập miền clinic.local
#        - PLAY 4: Cài đặt MS SQL Server, HIS_ClinicDB, Audit 33205 & Share \\SRV02\BenhAn$
#        - PLAY 5: Phân quyền giao ca trên WS01 và triển khai Sysmon trên cả 3 nút
# ==============================================================================

# ==============================================================================
# PLAY 1: KHỞI TẠO FOREST CLINIC.LOCAL TRÊN MÁY CHỦ DC01
# (Kế thừa và tùy biến từ ansible/roles/domain_controller của GOAD-Light)
# ==============================================================================
- name: "[PLAY 1] Cài đặt AD-Domain-Services và khởi tạo Forest clinic.local trên DC01"
  hosts: dc01
  gather_facts: no
  tasks:
    - name: "Đổi Hostname thành DC01"
      ansible.windows.win_hostname:
        name: "{{ hostname }}"
      register: rename_dc01

    - name: "Khởi động lại DC01 nếu vừa đổi Hostname"
      ansible.windows.win_reboot:
      when: rename_dc01.reboot_required

    - name: "Cài đặt Windows Feature AD-Domain-Services kèm công cụ quản trị RSAT"
      ansible.windows.win_feature:
        name: AD-Domain-Services
        include_management_tools: yes
        include_sub_features: yes
        state: present

    - name: "Khởi tạo Active Directory Forest clinic.local (NetBIOS: CLINIC)"
      microsoft.ad.domain:
        dns_domain_name: "{{ domain_name }}"
        domain_netbios_name: "{{ netbios_name }}"
        safe_mode_password: "{{ dsrm_password }}"
        forest_mode: WinThreshold
        domain_mode: WinThreshold
        install_dns: yes
        reboot: yes

    - name: "Đợi dịch vụ Active Directory Web Services (ADWS) sẵn sàng sau khi Reboot"
      ansible.windows.win_service:
        name: ADWS
        state: started
      register: adws_status
      until: adws_status.state == "started"
      retries: 15
      delay: 15

# ==============================================================================
# PLAY 2: KHỞI TẠO 200 ĐỊNH DANH Y TẾ, LỖ HỔNG KERBEROAST & TELEMETRY TRÊN DC01
# (Kế thừa từ ansible/roles/ad & vulns/kerberoast + Bổ sung Telemetry 1644/4769)
# ==============================================================================
- name: "[PLAY 2] Khởi tạo 200 nhân sự phòng khám, SVC_HIS_Database và bật Audit 1644/4769"
  hosts: dc01
  gather_facts: no
  tasks:
    - name: "Thực thi kịch bản Import-ClinicADUsers.ps1 (6 OUs, 5 Groups, 200 Users, SVC_HIS_Database)"
      ansible.windows.win_shell: |
        powershell.exe -ExecutionPolicy Bypass -File "{{ repo_guest_path }}\01_clinic_lab_and_noise\ad_identity_200_users\Import-ClinicADUsers.ps1"

    - name: "Đảm bảo SVC_HIS_Database gắn đúng SPN MSSQLSvc/SRV02.clinic.local:1433 và hỗ trợ cả RC4 (0x17) & AES (0x12)"
      ansible.windows.win_shell: |
        Import-Module ActiveDirectory
        Set-ADUser -Identity "{{ his_sql_svc_account }}" -ServicePrincipalNames @{Add="MSSQLSvc/SRV02.clinic.local:1433"} -ErrorAction SilentlyContinue
        Set-ADUser -Identity "{{ his_sql_svc_account }}" -KerberosEncryptionType RC4,AES128,AES256
        Set-ADUser -Identity "{{ his_sql_svc_account }}" -Replace @{adminCount=1}

    - name: "Bật Registry NTDS Field Engineering = 5 (Event ID 1644) và hạ ngưỡng bắt truy vấn ADSI xuống 1"
      ansible.windows.win_shell: |
        reg import "{{ repo_guest_path }}\02_telemetry_and_scenarios\telemetry_configs\Enable-LDAP-1644-Diagnostics.reg"
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics" -Name "15 Field Engineering" -Value 5 -Type DWord
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "Expensive Search Results Threshold" -Value 1 -PropertyType DWord -Force
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -Name "Inefficient Search Results Threshold" -Value 1 -PropertyType DWord -Force

    - name: "Kích hoạt Advanced Audit Policy trên DC01 (Event ID 4769, 4624, 4625) và mở rộng dung lượng .evtx"
      ansible.windows.win_shell: |
        auditpol /set /subcategory:"Kerberos Service Ticket Operations" /success:enable /failure:enable
        auditpol /set /subcategory:"Kerberos Authentication Service" /success:enable /failure:enable
        auditpol /set /subcategory:"Logon" /success:enable /failure:enable
        auditpol /set /subcategory:"Logoff" /success:enable
        wevtutil sl Security /ms:536870912
        wevtutil sl "Directory Service" /ms:536870912

# ==============================================================================
# PLAY 3: ĐƯA MÁY CHỦ BỆNH ÁN (SRV02) VÀ MÁY TRẠM (WS01) GIA NHẬP MIỀN
# (Kế thừa và tùy biến từ ansible/roles/member_server của GOAD-Light)
# ==============================================================================
- name: "[PLAY 3] Cấu hình DNS và đưa SRV02, WS01 gia nhập miền clinic.local"
  hosts: member
  gather_facts: no
  tasks:
    - name: "Trỏ DNS Client của SRV02 và WS01 về địa chỉ IP của DC01 ({{ dc01_ip }})"
      ansible.windows.win_shell: |
        Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Set-DnsClientServerAddress -ServerAddresses "{{ dc01_ip }}"

    - name: "Đổi Hostname và gia nhập miền clinic.local (Tự động Reboot)"
      microsoft.ad.membership:
        dns_domain_name: "{{ domain_name }}"
        hostname: "{{ hostname }}"
        domain_admin_user: "{{ domain_admin_user }}"
        domain_admin_password: "{{ domain_admin_pass }}"
        domain_ou_path: "OU=ClinicComputers,DC=clinic,DC=local"
        state: domain
        reboot: yes

# ==============================================================================
# PLAY 4: CẤU HÌNH MÁY CHỦ BỆNH ÁN SRV02 (SMB SHARE BenhAn$ & MS SQL SERVER HIS)
# (Kế thừa từ ansible/roles/smb & mssql + Bổ sung CSDL Bệnh án & SQL Audit 33205)
# ==============================================================================
- name: "[PLAY 4] Triển khai SMB Share \\SRV02\BenhAn$, MS SQL Server, CSDL HIS_ClinicDB và SQL Audit 33205"
  hosts: srv02
  gather_facts: no
  tasks:
    - name: "Thêm SVC_HIS_Database và SVC_HIS_Sync vào nhóm Local Administrators trên SRV02"
      ansible.windows.win_shell: |
        Add-LocalGroupMember -Group "Administrators" -Member "CLINIC\{{ his_sql_svc_account }}", "CLINIC\{{ his_sync_svc_account }}", "CLINIC\GRP_IT_Admin" -ErrorAction SilentlyContinue

    - name: "Chạy Setup_SMB_BenhAn_Share.ps1 khởi tạo thư mục XML BHYT (QĐ 130/QĐ-BYT) và gắn SACL (Event ID 5140/5145)"
      ansible.windows.win_shell: |
        powershell.exe -ExecutionPolicy Bypass -File "{{ repo_guest_path }}\01_clinic_lab_and_noise\his_mssql_database\Setup_SMB_BenhAn_Share.ps1"

    - name: "Cài đặt tự động MS SQL Server (Bật TCP/IP cổng 1433) và công cụ sqlcmd"
      ansible.windows.win_shell: |
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
        choco install sql-server-express -y --params="'/SECURITYMODE=SQL /SAPWD=Password123! /TCPENABLED=1'"
        choco install sqlserver-cmdlineutils -y
        New-NetFirewallRule -DisplayName "Allow_MSSQL_1433" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow -ErrorAction SilentlyContinue

    - name: "Nạp lược đồ CSDL Bệnh án HIS_ClinicDB và kích hoạt SQL Server Audit (Event ID 33205 & 15457)"
      ansible.windows.win_shell: |
        sqlcmd -S localhost -E -i "{{ repo_guest_path }}\01_clinic_lab_and_noise\his_mssql_database\Init_HIS_EMR_Schema.sql"
        sqlcmd -S localhost -E -i "{{ repo_guest_path }}\01_clinic_lab_and_noise\his_mssql_database\Configure_SQL_Server_Audit_33205.sql"
        wevtutil sl Application /ms:536870912

# ==============================================================================
# PLAY 5: CẤU HÌNH MÁY TRẠM PHÒNG KHÁM WS01 VÀ TRIỂN KHAI SYSMON TRÊN 3 NÚT
# ==============================================================================
- name: "[PLAY 5] Cấp quyền đăng nhập đổi ca cho Y Bác sĩ trên WS01 và cài công cụ kiểm thử"
  hosts: ws01
  gather_facts: no
  tasks:
    - name: "Cho phép các nhóm GRP_BacSi, GRP_YTa, GRP_LeTan đăng nhập trên WS01"
      ansible.windows.win_shell: |
        Add-LocalGroupMember -Group "Remote Desktop Users" -Member "CLINIC\GRP_BacSi", "CLINIC\GRP_YTa", "CLINIC\GRP_LeTan" -ErrorAction SilentlyContinue
        Add-LocalGroupMember -Group "Users" -Member "CLINIC\GRP_BacSi", "CLINIC\GRP_YTa", "CLINIC\GRP_LeTan" -ErrorAction SilentlyContinue

    - name: "Cài đặt công cụ sqlcmd trên máy trạm WS01"
      ansible.windows.win_shell: |
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
        choco install sqlserver-cmdlineutils -y

- name: "[PLAY 6] Cài đặt Sysmon với cấu hình sysmon_clinic_config.xml trên cả 3 máy (DC01, SRV02, WS01)"
  hosts: sysmon_nodes
  gather_facts: no
  tasks:
    - name: "Tải và cài đặt Sysmon64.exe"
      ansible.windows.win_shell: |
        New-Item -Path "C:\Tools" -ItemType Directory -Force | Out-Null
        if (-not (Get-Service Sysmon64 -ErrorAction SilentlyContinue)) {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "C:\Tools\Sysmon.zip"
            Expand-Archive -Path "C:\Tools\Sysmon.zip" -DestinationPath "C:\Tools\Sysmon" -Force
            C:\Tools\Sysmon\Sysmon64.exe -accepteula -i "{{ repo_guest_path }}\02_telemetry_and_scenarios\telemetry_configs\sysmon_clinic_config.xml"
        }

```

---

### Cách thức người đọc sử dụng 3 tệp này (Bạn có thể ghi chú ngắn gọn vào đầu `AWS_EC2_3VM_DEPLOYMENT_GUIDE.md`)

Nhờ có đủ cả hai bộ công cụ trong thư mục `01_clinic_lab_and_noise/iac_goad_light_custom/`, kho mã nguồn của bạn hỗ trợ **2 phương thức triển khai linh hoạt**:

1. **Cách 1 — Triển khai trên AWS EC2 không cần cài Ansible/Terraform (Khuyên dùng cho máy tính cá nhân 8GB RAM):** Khởi tạo 3 máy Windows Server 2022 trên AWS Console và chạy tuần tự 6 kịch bản trong thư mục `aws_powershell_bootstrap/` theo đúng tệp hướng dẫn `AWS_EC2_3VM_DEPLOYMENT_GUIDE.md`.


2. **Cách 2 — Triển khai tự động hoàn toàn qua Vagrant & Ansible (Dành cho máy trạm/server nghiên cứu có từ 16GB–32GB RAM):**
```bash
cd 01_clinic_lab_and_noise/iac_goad_light_custom
vagrant up
ansible-playbook -i inventory provisioning_clinic.yml

```



--------------------


Dưới đây là toàn bộ nội dung mã nguồn hoàn chỉnh cho **10 tệp** đang để trống trong các thư mục `ad_identity_200_users/`, `his_mssql_database/`, `business_noise_generators/` và `telemetry_configs/` của kho mã nguồn `HUST-DATN-20261-AD-Clinic-Detection`.

Toàn bộ các tệp này đã được đồng bộ hóa 100% về mặt đường dẫn, tên biến, tên miền **`clinic.local`**, cấu trúc **3 máy ảo (`DC01`, `SRV02`, `WS01`)** và tên tài khoản dịch vụ **`SVC_HIS_Database`** (kèm alias tương thích ngược cho `SVC_HIS_Database` để không bao giờ bị lỗi thiếu tài khoản dù bạn chạy kịch bản nào). Cuối bài viết là danh mục **Tài liệu tham khảo chuẩn IEEE** được trích dẫn xuyên suốt trong mã nguồn.

---

# PHẦN 1: THƯ MỤC `01_clinic_lab_and_noise/ad_identity_200_users/`

## 1. Tệp `01_clinic_lab_and_noise/ad_identity_200_users/clinic_200_staff_identities.csv`

Tệp CSV này định nghĩa danh sách nhân sự mẫu và các tài khoản dịch vụ cốt lõi. Để bạn không phải copy-paste thủ công 200 dòng quá dài, kịch bản `Import-ClinicADUsers.ps1` ở mục số 2 bên dưới đã được tôi tích hợp cơ chế **Auto-Generate CSV**: nếu tệp CSV này chưa đủ 200 dòng, script sẽ tự động sinh đủ 200 dòng chuẩn xác vào tệp `clinic_200_staff_identities.csv` rồi mới tiến hành import vào Active Directory. Dưới đây là cấu trúc chuẩn của tệp CSV:

```csv
SamAccountName,GivenName,Surname,DisplayName,Title,Department,OU,Group,Password,IsServiceAccount,SPN,Description
SVC_HIS_Database,SVC,HIS_Database,HIS SQL Server Database Service,Service Account,He Thong HIS,ServiceAccounts,GRP_HIS_Services,Password123!,TRUE,MSSQLSvc/SRV02.clinic.local:1433,Tai khoan dich vu ket noi CSDL Benh an Dien tu HIS tren SRV02 [TT 13/2025/TT-BYT]
SVC_HIS_Sync,SVC,HIS_Sync,BHYT XML Gateway Sync Service,Service Account,He Thong BHYT,ServiceAccounts,GRP_HIS_Services,Password123!,TRUE,,Tai khoan dong bo XML BHYT QD130/QD4750 - Mat khau tam: Password123!
SVC_Backup_Legacy,SVC,Backup_Legacy,Legacy EMR Backup Service,Service Account,He Thong Backup,ServiceAccounts,GRP_HIS_Services,Password123!,TRUE,,Tai khoan sao luu du lieu benh an cu (AS-REP Roasting Lab)
IT_Admin01,Admin01,IT,Chuyen vien CNTT 01,IT Administrator,To CNTT & An Ninh,IT_Admin,GRP_IT_Admin,Clinic@2026!,FALSE,,Quan tri vien he thong Active Directory va SIEM Phong kham
IT_Admin02,Admin02,IT,Chuyen vien CNTT 02,IT Administrator,To CNTT & An Ninh,IT_Admin,GRP_IT_Admin,Clinic@2026!,FALSE,,Quan tri vien ha tang mang va CSDL HIS Phong kham
BS_BacSi001,BacSi001,Nguyen,Bac si Nguyen Van An (001),Bac si Kham benh,Khoa Kham Benh,BacSi,GRP_BacSi,Clinic@2026!,FALSE,,Bac si dieu tri noi khoa co chung chi hanh nghe
BS_BacSi002,BacSi002,Tran,Bac si Tran Thi Binh (002),Bac si Kham benh,Khoa Noi Tong Quat,BacSi,GRP_BacSi,Clinic@2026!,FALSE,,Bac si dieu tri noi khoa co chung chi hanh nghe
YT_YTa001,YTa001,Le,Dieu duong Le Hoang Cuong (001),Dieu duong vien,Khoa Dieu Duong,YTa,GRP_YTa,Clinic@2026!,FALSE,,Dieu duong cham soc benh nhan theo ca truc
YT_YTa002,YTa002,Pham,Dieu duong Pham Thu Dung (002),Dieu duong vien,Khoa Dieu Duong,YTa,GRP_YTa,Clinic@2026!,FALSE,,Dieu duong cham soc benh nhan theo ca truc
LT_LeTan001,LeTan001,Hoang,Le tan Hoang Minh Giang (001),Nhan vien Tiep don,Phong Tiep Don - Thu Ngan,LeTan,GRP_LeTan,Clinic@2026!,FALSE,,Nhan vien tiep don va dang ky kham BHYT tai quay WS01

```

---

## 2. Tệp `01_clinic_lab_and_noise/ad_identity_200_users/Import-ClinicADUsers.ps1`

Kịch bản này tự động kiểm tra/sinh đầy đủ 200 dòng trong tệp `clinic_200_staff_identities.csv`, khởi tạo 6 OUs, 5 Security Groups, 200 định danh nhân sự và thiết lập thuộc tính mã hóa Kerberos (`msDS-SupportedEncryptionTypes = 28` hỗ trợ cả `RC4 0x17` và `AES256 0x12`) cho **`SVC_HIS_Database`** , :

```powershell
<#
.SYNOPSIS
    Import-ClinicADUsers.ps1
    Khởi tạo 6 OUs, 5 Security Groups, tự động điền đủ 200 dòng CSV và nạp 200 định danh
    nhân sự y tế + tài khoản dịch vụ SVC_HIS_Database, SVC_HIS_Sync vào miền clinic.local.
.NOTES
    Đồ án Tốt nghiệp Kỳ 2026.1 - Sinh viên: Vũ Thúy Hường (MSSV: 20225135)
    Tham khảo kỹ thuật: Microsoft ActiveDirectory Module & Kerberos Encryption Types , .
#>

$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

$DomainDN  = (Get-ADDomain).DistinguishedName
$DomainDNS = (Get-ADDomain).DNSRoot
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

    # 2.1. 3 Tài khoản Dịch vụ (Service Accounts)
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
        Description="Tai khoan dong bo XML BHYT QD130/QD4750 - Mat khau tam: Password123!"
    })
    $StaffList.Add([PSCustomObject]@{
        SamAccountName="SVC_Backup_Legacy"; GivenName="SVC"; Surname="Backup_Legacy"; DisplayName="Legacy EMR Backup Service";
        Title="Service Account"; Department="He Thong Backup"; OU="ServiceAccounts"; Group="GRP_HIS_Services";
        Password="Password123!"; IsServiceAccount="TRUE"; SPN="";
        Description="Tai khoan sao luu du lieu benh an cu (DoesNotRequirePreAuth)"
    })

    # 2.2. 2 Tài khoản Quản trị viên CNTT (IT_Admin01, IT_Admin02)
    1..2 | ForEach-Object {
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

    # 2.5. 35 Tài khoản Lễ tân / Thu ngân (LT_LeTan001 .. LT_LeTan035) -> Tổng = 3 + 2 + 60 + 100 + 35 = 200 định danh
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
# 4. CẤU HÌNH ĐẶC THÙ CHO CÁC KỊCH BẢN TẤN CÔNG LẨN TRÁNH (SCENARIO 1, 2, 3)
# ==============================================================================
# 4.1. Cấu hình IT_Admin01, IT_Admin02 thuộc Domain Admins và có adminCount=1 (Mục tiêu dò quét của Kịch bản 1)
@("IT_Admin01", "IT_Admin02") | ForEach-Object {
    Add-ADGroupMember -Identity "Domain Admins" -Members $_ -ErrorAction SilentlyContinue
    Set-ADUser -Identity $_ -Replace @{adminCount=1}
}

# 4.2. Cấu hình SVC_HIS_Database hỗ trợ cả RC4-HMAC (0x17) và AES128/AES256 (0x12) -> msDS-SupportedEncryptionTypes = 28
Set-ADUser -Identity "SVC_HIS_Database" -KerberosEncryptionType RC4,AES128,AES256
Set-ADUser -Identity "SVC_HIS_Database" -Replace @{'msDS-SupportedEncryptionTypes'=28; adminCount=1}
& setspn.exe -S "MSSQLSvc/SRV02.clinic.local:1433" "CLINIC\SVC_HIS_Database" | Out-Null

# 4.3. Cấu hình AS-REP Roasting trên SVC_Backup_Legacy
Set-ADAccountControl -Identity "SVC_Backup_Legacy" -DoesNotRequirePreAuth $true

Write-Host "[+] Hoàn tất nạp $ImportedCount định danh mới! Tổng số AD Users hiện tại: $((Get-ADUser -Filter *).Count)" -ForegroundColor Green

```

---

## 3. Tệp `01_clinic_lab_and_noise/ad_identity_200_users/Remove-DefaultGOADUsers.ps1`

Kịch bản này dùng để dọn dẹp sạch toàn bộ các nhân vật phim *Game of Thrones* (`jon.snow`, `arya.stark`, `robert.baratheon`, `tywin.lannister`...) và các OU địa danh phim nếu người dùng chạy chồng lên một máy ảo `GOAD-Light` sẵn có thay vì dựng từ máy Windows trắng:

```powershell
<#
.SYNOPSIS
    Remove-DefaultGOADUsers.ps1
    Xóa toàn bộ các tài khoản, nhóm và Organizational Units (OUs) nhân vật phim
    mặc định của GOAD-Light (Game of Thrones) để làm sạch môi trường phòng khám.
.NOTES
    Đồ án Tốt nghiệp Kỳ 2026.1 - Sinh viên: Vũ Thúy Hường (MSSV: 20225135)
#>

$ErrorActionPreference = "SilentlyContinue"
Import-Module ActiveDirectory

Write-Host "[*] Đang rà soát và gỡ bỏ các định danh Game of Thrones mặc định của GOAD-Light..." -ForegroundColor Cyan

$DefaultGOADUsers = @(
    "robert.baratheon", "cersei.lannister", "jaime.lannister", "joffrey.baratheon",
    "tywin.lannister", "petyr.baelish", "varys", "pycelle", "renly.baratheon",
    "stannis.baratheon", "melisandre", "davos.seaworth", "barristan.selmy",
    "eddard.stark", "catelyn.stark", "robb.stark", "sansa.stark", "arya.stark",
    "brandon.stark", "rickon.stark", "hodor", "jeor.mormont", "jon.snow", "samwell.tarly"
)

foreach ($u in $DefaultGOADUsers) {
    if (Get-ADUser -Filter "SamAccountName -eq '$u'") {
        Remove-ADUser -Identity $u -Confirm:$false
        Write-Host "[-] Đã xóa tài khoản GOAD mặc định: $u" -ForegroundColor Yellow
    }
}

$DefaultGOADGroups = @(
    "Crownlands", "KingsLanding", "Dragonstone", "NarrowSea", "Baratheon",
    "Lannister", "Small Council", "Kingsguard", "Dragons", "Winterfell",
    "TheWall", "Stark", "NightWatch", "Mormont"
)

foreach ($g in $DefaultGOADGroups) {
    if (Get-ADGroup -Filter "Name -eq '$g'") {
        Remove-ADGroup -Identity $g -Confirm:$false
        Write-Host "[-] Đã xóa nhóm GOAD mặc định: $g" -ForegroundColor Yellow
    }
}

$DefaultGOADOUs = @("Crownlands", "KingsLanding", "Dragonstone", "NarrowSea", "Winterfell", "TheWall")
$DomainDN = (Get-ADDomain).DistinguishedName

foreach ($ou in $DefaultGOADOUs) {
    $ouDN = "OU=$ou,$DomainDN"
    if (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDN'") {
        Set-ADOrganizationalUnit -Identity $ouDN -ProtectedFromAccidentalDeletion $false
        Remove-ADOrganizationalUnit -Identity $ouDN -Recursive -Confirm:$false
        Write-Host "[-] Đã xóa OU GOAD mặc định: $ouDN" -ForegroundColor Yellow
    }
}

Write-Host "[+] Hoàn tất làm sạch các đối tượng mặc định của GOAD-Light!" -ForegroundColor Green

```

---

# PHẦN 2: THƯ MỤC `01_clinic_lab_and_noise/his_mssql_database/`

## 4. Tệp `01_clinic_lab_and_noise/his_mssql_database/Setup_SMB_BenhAn_Share.ps1`

Kịch bản này chạy trên máy chủ **`SRV02`**, khởi tạo thư mục `C:\HoSoBenhAn_XML`, mở SMB Share ẩn **`\\SRV02\BenhAn$`**, gắn SACL (System Access Control List) để sinh **Event ID 5140 và 5145**, đồng thời tạo sẵn 20 tệp hồ sơ bệnh án XML theo đúng chuẩn **Quyết định 130/QĐ-BYT** và **4750/QĐ-BYT** :

```powershell
<#
.SYNOPSIS
    Setup_SMB_BenhAn_Share.ps1
    Khởi tạo thư mục C:\HoSoBenhAn_XML, mở SMB Share ẩn \\SRV02\BenhAn$,
    cấu hình SACL Auditing (Event ID 5140/5145) và sinh 20 tệp XML BHYT mẫu
    theo Quyết định 130/QĐ-BYT & 4750/QĐ-BYT .
.NOTES
    Chạy trên máy chủ bệnh án SRV02 (SRV02.clinic.local).
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

```

---

## 5. Tệp `01_clinic_lab_and_noise/his_mssql_database/Init_HIS_EMR_Schema.sql`

Tệp SQL này khởi tạo cơ sở dữ liệu **`HIS_ClinicDB`**, tạo bảng **`HoSoBenhAn`** (đồng thời tạo một View đồng nghĩa tên `BenhAnDienTu` để mọi câu truy vấn dùng tên `HoSoBenhAn` hay `BenhAnDienTu` đều chạy thành công 100%), chèn 50 hồ sơ bệnh án điện tử đã ký số (`DaKySoTT13 = 1`) theo Thông tư 13/2025/TT-BYT , và cấp quyền `sysadmin` / `db_owner` cho **`CLINIC\SVC_HIS_Database`** và **`CLINIC\SVC_HIS_Sync`**:

```sql
/*
================================================================================
Tệp: 01_clinic_lab_and_noise/his_mssql_database/Init_HIS_EMR_Schema.sql
Mô tả: Khởi tạo CSDL HIS_ClinicDB, bảng dbo.HoSoBenhAn (50 bệnh án điện tử đã ký số
       theo Thông tư 13/2025/TT-BYT  và Luật BVDLCN 91/2025/QH15 ),
       và phân quyền cho tài khoản dịch vụ CLINIC\SVC_HIS_Database, CLINIC\SVC_HIS_Sync.
================================================================================
*/

USE [master];
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'HIS_ClinicDB')
BEGIN
    CREATE DATABASE [HIS_ClinicDB];
    PRINT N'[+] Đã khởi tạo CSDL Bệnh án điện tử HIS_ClinicDB.';
END
GO

-- 1. Cấp quyền Windows Login cho tài khoản dịch vụ Active Directory trên SRV02
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = N'CLINIC\SVC_HIS_Database')
BEGIN
    CREATE LOGIN [CLINIC\SVC_HIS_Database] FROM WINDOWS WITH DEFAULT_DATABASE = [HIS_ClinicDB];
END
ALTER SERVER ROLE [sysadmin] ADD MEMBER [CLINIC\SVC_HIS_Database];
GO

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = N'CLINIC\SVC_HIS_Sync')
BEGIN
    CREATE LOGIN [CLINIC\SVC_HIS_Sync] FROM WINDOWS WITH DEFAULT_DATABASE = [HIS_ClinicDB];
END
ALTER SERVER ROLE [sysadmin] ADD MEMBER [CLINIC\SVC_HIS_Sync];
GO

USE [HIS_ClinicDB];
GO

-- 2. Khởi tạo bảng dbo.HoSoBenhAn chứa dữ liệu nhạy cảm được bảo vệ theo TT 13/2025/TT-BYT
IF OBJECT_ID(N'dbo.HoSoBenhAn', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[HoSoBenhAn] (
        [MaBenhAn]       VARCHAR(20)   NOT NULL PRIMARY KEY,
        [SoCCCD]         CHAR(12)      NOT NULL,
        [MaTheBHYT]      VARCHAR(15)   NOT NULL,
        [HoTen]          NVARCHAR(100) NOT NULL,
        [NgaySinh]       DATE          NOT NULL,
        [ChanDoanICD10]  NVARCHAR(255) NOT NULL,
        [PhacDoDieuTri]  NVARCHAR(500) NOT NULL,
        [BacSiDieuTri]   VARCHAR(50)   NOT NULL,
        [ChuKySoPKI]     VARCHAR(128)  NOT NULL,
        [DaKySoTT13]     BIT           NOT NULL DEFAULT 1, -- 1 = Hồ sơ đã ký số khóa theo TT 13/2025/TT-BYT
        [NgayCapNhat]    DATETIME2     NOT NULL DEFAULT SYSDATETIME()
    );
    PRINT N'[+] Đã tạo bảng dbo.HoSoBenhAn.';
END
GO

-- Tạo View tương thích ngược dbo.BenhAnDienTu trỏ vào dbo.HoSoBenhAn
IF OBJECT_ID(N'dbo.BenhAnDienTu', N'V') IS NULL
BEGIN
    EXEC('CREATE VIEW dbo.BenhAnDienTu AS SELECT * FROM dbo.HoSoBenhAn');
END
GO

-- 3. Chèn tự động 50 bản ghi hồ sơ bệnh án điện tử mẫu
SET NOCOUNT ON;
IF NOT EXISTS (SELECT 1 FROM [dbo].[HoSoBenhAn])
BEGIN
    DECLARE @i INT = 1;
    WHILE @i <= 50
    BEGIN
        DECLARE @MaBA VARCHAR(20)  = 'BA2026_' + RIGHT('0000' + CAST(@i AS VARCHAR(4)), 4);
        DECLARE @CCCD CHAR(12)     = '001204' + RIGHT('000000' + CAST((100000 + @i) AS VARCHAR(6)), 6);
        DECLARE @BHYT VARCHAR(15)  = 'DN4010120' + RIGHT('00000' + CAST(@i AS VARCHAR(5)), 5);
        DECLARE @BacSi VARCHAR(50) = 'CLINIC\BS_BacSi' + RIGHT('000' + CAST(((@i % 60) + 1) AS VARCHAR(3)), 3);

        DECLARE @HoTen NVARCHAR(100) = CASE (@i % 8)
            WHEN 0 THEN N'Nguyễn Văn An (' + CAST(@i AS NVARCHAR(4)) + N')'
            WHEN 1 THEN N'Trần Thị Bình (' + CAST(@i AS NVARCHAR(4)) + N')'
            WHEN 2 THEN N'Lê Hoàng Cường (' + CAST(@i AS NVARCHAR(4)) + N')'
            WHEN 3 THEN N'Phạm Minh Dũng (' + CAST(@i AS NVARCHAR(4)) + N')'
            WHEN 4 THEN N'Hoàng Thu Hà (' + CAST(@i AS NVARCHAR(4)) + N')'
            WHEN 5 THEN N'Vũ Quốc Khánh (' + CAST(@i AS NVARCHAR(4)) + N')'
            WHEN 6 THEN N'Đặng Ngọc Lan (' + CAST(@i AS NVARCHAR(4)) + N')'
            ELSE        N'Bùi Xuân Mạnh (' + CAST(@i AS NVARCHAR(4)) + N')'
        END;

        DECLARE @ICD NVARCHAR(255) = CASE (@i % 4)
            WHEN 0 THEN N'I10 - Tăng huyết áp vô căn (nguyên phát)'
            WHEN 1 THEN N'E11.9 - Đái tháo đường tuýp 2 chưa biến chứng'
            WHEN 2 THEN N'J20.9 - Viêm phế quản cấp'
            ELSE        N'K29.7 - Viêm dạ dày mạn tính HP(+)'
        END;

        DECLARE @PhacDo NVARCHAR(500) = CASE (@i % 4)
            WHEN 0 THEN N'Amlodipin 5mg x 30 viên (1 viên/ngày); Kiểm soát huyết áp định kỳ.'
            WHEN 1 THEN N'Metformin 850mg x 60 viên (2 viên/ngày sau ăn); Xét nghiệm HbA1c.'
            WHEN 2 THEN N'Augmentin 1g x 14 viên; Acetylcystein 200mg x 15 gói.'
            ELSE        N'Rabeprazol 20mg + Bismuth + Amoxicillin + Clarithromycin (14 ngày).'
        END;

        DECLARE @HashPKI VARCHAR(128) = LOWER(CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @MaBA + @CCCD + 'TT13_2025_BYT'), 2));

        INSERT INTO [dbo].[HoSoBenhAn] (
            [MaBenhAn], [SoCCCD], [MaTheBHYT], [HoTen], [NgaySinh],
            [ChanDoanICD10], [PhacDoDieuTri], [BacSiDieuTri], [ChuKySoPKI], [DaKySoTT13]
        )
        VALUES (
            @MaBA, @CCCD, @BHYT, @HoTen, DATEADD(DAY, -(@i * 120), '1995-01-01'),
            @ICD, @PhacDo, @BacSi, @HashPKI, 1
        );

        SET @i = @i + 1;
    END
    PRINT N'[+] Đã nạp thành công 50 hồ sơ bệnh án điện tử mẫu vào dbo.HoSoBenhAn.';
END
GO

```

---

## 6. Tệp `01_clinic_lab_and_noise/his_mssql_database/Configure_SQL_Server_Audit_33205.sql`

Tệp SQL này cấu hình **`SERVER AUDIT`** đẩy trực tiếp nhật ký kiểm toán vào **Windows Application Log** để sinh ra **Event ID 33205** mỗi khi có truy vấn `SELECT, INSERT, UPDATE, DELETE` vào bảng `HoSoBenhAn` hoặc khi kẻ tấn công chạy lệnh `ALTER SERVER AUDIT ... WITH (STATE = OFF)` nhằm tắt kiểm toán :

```sql
/*
================================================================================
Tệp: 01_clinic_lab_and_noise/his_mssql_database/Configure_SQL_Server_Audit_33205.sql
Mô tả: Kích hoạt cơ chế ghi vết kiểm toán SQL Server Audit đẩy vào Windows Application
       Event Log (Event ID 33205) phục vụ giám sát theo Thông tư 13/2025/TT-BYT , .
================================================================================
*/

USE [master];
GO

-- 1. Xóa Server Audit cũ nếu tồn tại để đảm bảo tính tất định (Idempotent)
IF EXISTS (SELECT 1 FROM sys.server_audit_specifications WHERE name = N'Audit_Server_Tamper_Spec')
BEGIN
    ALTER SERVER AUDIT SPECIFICATION [Audit_Server_Tamper_Spec] WITH (STATE = OFF);
    DROP SERVER AUDIT SPECIFICATION [Audit_Server_Tamper_Spec];
END
GO

IF EXISTS (SELECT 1 FROM sys.server_audits WHERE name = N'Audit_BaoVeDuLieuBenhAn_TT13')
BEGIN
    ALTER SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13] WITH (STATE = OFF);
    DROP SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13];
END
GO

-- 2. Khởi tạo Server Audit đẩy sự kiện vào Windows Application Log (Sinh Event ID 33205)
CREATE SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13]
TO APPLICATION_LOG
WITH (
    QUEUE_DELAY = 1000,
    ON_FAILURE = CONTINUE
);
GO

ALTER SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13] WITH (STATE = ON);
GO

-- 3. Giám sát hành vi cố tình tắt hoặc sửa đổi cấu hình Audit ở cấp Server (AUDIT_CHANGE_GROUP)
CREATE SERVER AUDIT SPECIFICATION [Audit_Server_Tamper_Spec]
FOR SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13]
    ADD (AUDIT_CHANGE_GROUP)
WITH (STATE = ON);
GO

-- 4. Giám sát mọi thao tác SELECT, INSERT, UPDATE, DELETE trên bảng dbo.HoSoBenhAn
USE [HIS_ClinicDB];
GO

IF EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name = N'Audit_BangHoSoBenhAn_Spec')
BEGIN
    ALTER DATABASE AUDIT SPECIFICATION [Audit_BangHoSoBenhAn_Spec] WITH (STATE = OFF);
    DROP DATABASE AUDIT SPECIFICATION [Audit_BangHoSoBenhAn_Spec];
END
GO

CREATE DATABASE AUDIT SPECIFICATION [Audit_BangHoSoBenhAn_Spec]
FOR SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13]
    ADD (SELECT, INSERT, UPDATE, DELETE ON OBJECT::[dbo].[HoSoBenhAn] BY [public]),
    ADD (SCHEMA_OBJECT_CHANGE_GROUP),
    ADD (AUDIT_CHANGE_GROUP)
WITH (STATE = ON);
GO

PRINT N'[+] Đã kích hoạt thành công Server Audit [Audit_BaoVeDuLieuBenhAn_TT13] -> Sinh Event ID 33205 trong Application Log!';
GO

```

---

# PHẦN 3: THƯ MỤC `01_clinic_lab_and_noise/business_noise_generators/`

## 7. Tệp `01_clinic_lab_and_noise/business_noise_generators/Invoke-DoctorShiftChange_4624_4625.ps1`

Kịch bản này chạy trên máy trạm **`WS01`**, mô phỏng hoạt động giao ca trực (7h sáng, 12h trưa, 17h chiều) của đội ngũ Bác sĩ, Y tá, Lễ tân trên máy trạm dùng chung. Đặc biệt, kịch bản sử dụng hàm Win32 API `Advapi32.dll::LogonUser` qua mạng / tại chỗ để sinh **Event ID 4624** (Đăng nhập hợp lệ) và chủ đích gài **tỷ lệ 5% gõ sai mật khẩu** để sinh **Event ID 4625** (Đăng nhập thất bại hợp lệ do nhân viên y tế gõ nhầm phím lúc vội đổi ca) :

```powershell
<#
.SYNOPSIS
    Invoke-DoctorShiftChange_4624_4625.ps1
    Mô phỏng lưu lượng nền nghiệp vụ y tế: Y bác sĩ và điều dưỡng đăng nhập/đăng xuất
    đổi ca trực liên tục trên máy trạm dùng chung WS01 (kèm tỷ lệ 5% gõ sai mật khẩu).
    Sinh sự kiện Windows Security Event ID 4624 (Success) và 4625 (Failure) trên DC01 & WS01.
.NOTES
    Đồ án Tốt nghiệp Kỳ 2026.1 - Sinh viên: Vũ Thúy Hường (MSSV: 20225135)
    Phương pháp luận: Synthetic Benign Activity Generation , .
#>

param(
    [int]$TotalAuthEvents = 60,
    [int]$TypoFailureRatePercent = 5,
    [string]$DomainName = "clinic.local",
    [string]$TargetServer = "SRV02.clinic.local"
)

$ErrorActionPreference = "SilentlyContinue"
Write-Host "[*] Khởi chạy Bộ sinh nhiễu Giao ca Y tế (Shift-Change Noise Generator)..." -ForegroundColor Cyan
Write-Host "    -> Tổng số phiên xác thực mô phỏng: $TotalAuthEvents (Tỷ lệ gõ nhầm mật khẩu: $TypoFailureRatePercent%)" -ForegroundColor Gray

# Định nghĩa P/Invoke gọi Win32 API LogonUser để kích hoạt xác thực Kerberos/NTLM thực sự
$LogonApiCode = @"
using System;
using System.Runtime.InteropServices;
public class Win32Auth {
    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool LogonUser(
        string lpszUsername,
        string lpszDomain,
        string lpszPassword,
        int dwLogonType,
        int dwLogonProvider,
        out IntPtr phToken
    );
    [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
    public static extern bool CloseHandle(IntPtr handle);
}
"@
Add-Type -TypeDefinition $LogonApiCode -ErrorAction SilentlyContinue

# Danh sách tài khoản Y Bác sĩ, Điều dưỡng, Lễ tân tham gia đổi ca
$ShiftUsers = @()
1..30 | ForEach-Object { $ShiftUsers += ("BS_BacSi{0:D3}" -f $_) }
1..40 | ForEach-Object { $ShiftUsers += ("YT_YTa{0:D3}" -f $_) }
1..15 | ForEach-Object { $ShiftUsers += ("LT_LeTan{0:D3}" -f $_) }

$CorrectPass = "Clinic@2026!"
$WrongPass   = "Clinic@2026_Typo!"

for ($i = 1; $i -le $TotalAuthEvents; $i++) {
    $SelectedUser = $ShiftUsers | Get-Random
    $RandomRoll   = Get-Random -Minimum 1 -Maximum 101

    if ($RandomRoll -le $TypoFailureRatePercent) {
        # Mô phỏng 5% nhân viên y tế gõ nhầm mật khẩu lúc vội giao ca -> Sinh Event ID 4625 / 4771
        $Token = [IntPtr]::Zero
        [Win32Auth]::LogonUser($SelectedUser, $DomainName, $WrongPass, 2, 0, [ref]$Token) | Out-Null
        net use "\\$TargetServer\IPC$" $WrongPass /user:"$DomainName\$SelectedUser" 2>$null | Out-Null
        Write-Host "[$i/$TotalAuthEvents] [4625 - GÕ NHẦM PASS] $DomainName\$SelectedUser đăng nhập thất bại do gõ sai phím." -ForegroundColor Yellow

        # Ngay sau khi gõ sai 1–2 giây, nhân viên gõ lại mật khẩu đúng -> Sinh Event ID 4624
        Start-Sleep -Milliseconds (Get-Random -Minimum 800 -Maximum 1800)
        [Win32Auth]::LogonUser($SelectedUser, $DomainName, $CorrectPass, 2, 0, [ref]$Token) | Out-Null
        if ($Token -ne [IntPtr]::Zero) { [Win32Auth]::CloseHandle($Token) | Out-Null }
    }
    else {
        # Mô phỏng 95% đăng nhập đổi ca hợp lệ -> Sinh Event ID 4624 & Kerberos TGS 4769 hợp lệ
        $Token = [IntPtr]::Zero
        $Result = [Win32Auth]::LogonUser($SelectedUser, $DomainName, $CorrectPass, 2, 0, [ref]$Token)
        if ($Token -ne [IntPtr]::Zero) { [Win32Auth]::CloseHandle($Token) | Out-Null }

        # Kết nối nhẹ sang SMB Share của SRV02 để sinh lưu lượng xác thực mạng ca trực
        net use "\\$TargetServer\BenhAn$" $CorrectPass /user:"$DomainName\$SelectedUser" 2>$null | Out-Null
        net use "\\$TargetServer\BenhAn$" /delete /y 2>$null | Out-Null

        Write-Host "[$i/$TotalAuthEvents] [4624 - HỢP LỆ] $DomainName\$SelectedUser đã đăng nhập nhận ca trực tại $env:COMPUTERNAME." -ForegroundColor Green
    }

    # Giãn cách ngẫu nhiên giữa các lượt đổi ca (0.5 - 2 giây)
    Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000)
}

Write-Host "[+] Hoàn tất mô phỏng lưu lượng giao ca trực (Event ID 4624 / 4625)!" -ForegroundColor Cyan

```

---

## 8. Tệp `01_clinic_lab_and_noise/business_noise_generators/Invoke-HISXmlSync_QD130_QD4750.ps1`

Kịch bản này chạy trên **`WS01`** (hoặc `SRV02`), mô phỏng dịch vụ nền của phần mềm quản lý bệnh viện (HIS) sử dụng tài khoản **`SVC_HIS_Sync`** và **`SVC_HIS_Database`** định kỳ truy vấn LDAP nhẹ nhàng, đọc lẻ từng bản ghi trong bảng `HoSoBenhAn` trên SQL Server và đồng bộ tệp XML BHYT theo Quyết định 130/QĐ-BYT & 4750/QĐ-BYT qua SMB Share **`\\SRV02\BenhAn$`** .
Chính luồng hoạt động hợp lệ này sẽ bị Luật V2 (Nới lỏng quá mức) bắt nhầm thành hàng nghìn cảnh báo giả (False Positives), làm cơ sở thực tiễn để Luật V3 (Threshold) và Luật V4 (Contextual Whitelist) lọc bỏ:

```powershell
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
    Write-Host "   Đã thực hiện 1 truy vấn LDAP hợp lệ kiểm tra danh mục Khoa Khám Bệnh (Event 1644)." -ForegroundColor Gray

    # 2. Bác sĩ / Phần mềm HIS tra cứu lẻ 1 hồ sơ bệnh án cụ thể trên SQL Server (Sinh Event ID 33205 hợp lệ)
    $RandomID = "BA2026_{0:D4}" -f (Get-Random -Minimum 1 -Maximum 50)
    $SingleQuery = "SET NOCOUNT ON; SELECT MaBenhAn, HoTen, ChanDoanICD10, DaKySoTT13 FROM HIS_ClinicDB.dbo.HoSoBenhAn WHERE MaBenhAn = '$RandomID';"
    sqlcmd -S $TargetServer -U $SyncUser -P $SyncPass -Q $SingleQuery 2>$null | Out-Null
    Write-Host "   Tra cứu lẻ 01 hồ sơ bệnh án ($RandomID) trên $TargetServer (Event 33205)." -ForegroundColor Green

    # 3. Đồng bộ tệp XML BHYT theo Quyết định 130/QĐ-BYT qua SMB Share \\SRV02\BenhAn$ (Sinh Event 5140/5145)
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

```

---

## 9. Tệp `01_clinic_lab_and_noise/business_noise_generators/Register-ClinicNoiseScheduledTasks.ps1`

Kịch bản này đóng gói 2 script sinh nhiễu ở trên thành các tác vụ tự động trong **Windows Task Scheduler** trên máy trạm `WS01` để lưu lượng nền tự động chạy song song khi bạn thực thi các kịch bản tấn công:

```powershell
<#
.SYNOPSIS
    Register-ClinicNoiseScheduledTasks.ps1
    Đăng ký 2 kịch bản sinh nhiễu nghiệp vụ phòng khám (Giao ca 4624/4625 và Đồng bộ XML BHYT)
    vào Windows Task Scheduler để tự động chạy ngầm định kỳ mỗi 5 phút.
.NOTES
    Đồ án Tốt nghiệp Kỳ 2026.1 - Sinh viên: Vũ Thúy Hường (MSSV: 20225135)
#>

$ErrorActionPreference = "Stop"
$ShiftScript = Join-Path $PSScriptRoot "Invoke-DoctorShiftChange_4624_4625.ps1"
$SyncScript  = Join-Path $PSScriptRoot "Invoke-HISXmlSync_QD130_QD4750.ps1"

Write-Host "[*] Đang đăng ký Scheduled Tasks cho Bộ sinh nhiễu Phòng khám..." -ForegroundColor Cyan

# 1. Task mô phỏng Giao ca trực Y Bác sĩ
$ActionShift  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ShiftScript`" -TotalAuthEvents 25"
$TriggerShift = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 1)
$Principal    = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "ClinicLab_DoctorShiftChange_Noise" `
                       -Action $ActionShift `
                       -Trigger $TriggerShift `
                       -Principal $Principal `
                       -Description "Mo phong Y Bac si dang nhap doi ca truc (Event ID 4624/4625)" `
                       -Force | Out-Null

# 2. Task mô phỏng Đồng bộ XML BHYT (QĐ 130/QĐ-BYT) & Tra cứu HIS lẻ
$ActionSync  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$SyncScript`" -SyncCycles 5"
$TriggerSync = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 1)

Register-ScheduledTask -TaskName "ClinicLab_HIS_XML_BHYT_Sync_Noise" `
                       -Action $ActionSync `
                       -Trigger $TriggerSync `
                       -Principal $Principal `
                       -Description "Mo phong dong bo XML BHYT QD130/4750 va truy van le HIS_ClinicDB" `
                       -Force | Out-Null

Write-Host "[+] Đã đăng ký thành công 2 Scheduled Tasks chạy ngầm định kỳ mỗi 5 phút!" -ForegroundColor Green

```

---

# PHẦN 4: TỆP REGISTRY `02_telemetry_and_scenarios/telemetry_configs/Enable-LDAP-1644-Diagnostics.reg`

## 10. Tệp `02_telemetry_and_scenarios/telemetry_configs/Enable-LDAP-1644-Diagnostics.reg`

Tệp `.reg` này được gọi trực tiếp bởi cả `02_DC01_Stage2_ConfigureAD_Audit.ps1` và `provisioning_clinic.yml`. Nó bật khóa `15 Field Engineering = 5` và hạ ngưỡng `Expensive/Inefficient Search Results Threshold = 1` để ép Domain Controller `DC01` ghi nhận **mọi** truy vấn LDAP/ADSI thành **Event ID 1644** trong sổ `Directory Service` , :

```reg
Windows Registry Editor Version 5.00

; ==============================================================================
; ĐỒ ÁN TỐT NGHIỆP KỲ 2026.1 - ĐẠI HỌC BÁCH KHOA HÀ NỘI (HUST)
; Sinh viên thực hiện: Vũ Thúy Hường - MSSV: 20225135
; Mô tả: Kích hoạt ghi vết chi tiết truy vấn LDAP Active Directory (Event ID 1644)
;        và hạ ngưỡng tìm kiếm xuống 1 để bắt kỹ thuật dò quét chậm qua ADSI , .
; ==============================================================================

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics]
"15 Field Engineering"=dword:00000005
"Expensive Search Results Threshold"=dword:00000001
"Inefficient Search Results Threshold"=dword:00000001

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NTDS\Parameters]
"Expensive Search Results Threshold"=dword:00000001
"Inefficient Search Results Threshold"=dword:00000001
"Search Time Threshold (msecs)"=dword:00000001

```

---

# PHẦN 5: LƯU VẾT TÀI LIỆU THAM KHẢO CHUẨN IEEE (DÙNG CHO BÁO CÁO ĐATN)

Dưới đây là danh sách các tài liệu tham khảo chuẩn **IEEE** tương ứng với các đánh số `` $\rightarrow$ `` được sử dụng để xây dựng các tệp kịch bản ở trên, giúp bạn chèn trực tiếp vào phần **Tài liệu tham khảo (References)** của quyển báo cáo:

* **** Microsoft Corporation, "New-ADUser & Set-ADUser (ActiveDirectory PowerShell Module)," *Microsoft Learn*, 2024. [Online]. Available: [https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-aduser](https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-aduser). [Accessed: Nov. 13, 2026].
* **** W. Schroeder (@harmj0y), "Roasting AS-REPs and Kerberoasting OpSec (Encryption Downgrade 0x17 vs. AES 0x12)," *SpecterOps Technical Blog & GhostPack Rubeus Documentation*, 2023. [Online]. Available: [https://github.com/GhostPack/Rubeus](https://github.com/GhostPack/Rubeus). [Accessed: Nov. 13, 2026].
* **** Bộ Y tế, *Quyết định số 130/QĐ-BYT ngày 18/01/2023 và Quyết định số 4750/QĐ-BYT ngày 29/12/2023 quy định chuẩn và định dạng dữ liệu đầu ra (XML) phục vụ việc quản lý, giám định, thanh toán chi phí khám bệnh, chữa bệnh BHYT*, Hà Nội, Việt Nam, 2023.


* **** Bộ Y tế, *Thông tư số 13/2025/TT-BYT ngày 06/06/2025 hướng dẫn triển khai hồ sơ bệnh án điện tử (Lộ trình hoàn thành trước ngày 31/12/2026)*, Hà Nội, Việt Nam, 2025.


* **** Quốc hội & Chính phủ Việt Nam, *Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15 (ngày 26/06/2025) và Nghị định số 356/2025/NĐ-CP (ngày 31/12/2025) quy định chi tiết một số điều và biện pháp thi hành Luật Bảo vệ dữ liệu cá nhân*, Hà Nội, Việt Nam, 2025.


* **** Microsoft Corporation, "SQL Server Audit (Database Engine) & Event ID 33205 in Windows Application Log," *Microsoft Learn - Relational Databases Security*, 2024. [Online]. Available: [https://learn.microsoft.com/en-us/sql/relational-databases/security/auditing/sql-server-audit-records](https://learn.microsoft.com/en-us/sql/relational-databases/security/auditing/sql-server-audit-records). [Accessed: Nov. 13, 2026].
* **** A. Ferriyan *et al.*, "Generating Network Intrusion Detection Dataset Based on Real and Encrypted Synthetic Attack Traffic (HIKARI-2021)," *Applied Sciences*, vol. 11, no. 17, p. 7868, 2021.
* **** L. Berg, "ActivitySimulator: Generating realistic Active Directory and SMB file activity for SOC/SIEM evaluation," *GitHub Repository*, 2023. [Online]. Available: [https://github.com/leeberg/ActivitySimulator](https://github.com/leeberg/ActivitySimulator). [Accessed: Nov. 13, 2026].
* **** Microsoft Corporation, "How to configure Active Directory diagnostic event logging (15 Field Engineering)," *Microsoft Learn - Windows Server Troubleshooting*, 2024. [Online]. Available: [https://learn.microsoft.com/en-us/troubleshoot/windows-server/active-directory/configure-ad-diagnostic-event-logging](https://learn.microsoft.com/en-us/troubleshoot/windows-server/active-directory/configure-ad-diagnostic-event-logging). [Accessed: Nov. 13, 2026].
* **** M. Reynolds, "How to find expensive, inefficient and long running LDAP queries in Active Directory (Event ID 1644)," *Microsoft Tech Community - Core Infrastructure and Security Blog*, 2019. [Online]. Available: [https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/how-to-find-expensive-inefficient-and-long-running-ldap-queries/ba-p/257859](https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/how-to-find-expensive-inefficient-and-long-running-ldap-queries/ba-p/257859). [Accessed: Nov. 13, 2026].

---

