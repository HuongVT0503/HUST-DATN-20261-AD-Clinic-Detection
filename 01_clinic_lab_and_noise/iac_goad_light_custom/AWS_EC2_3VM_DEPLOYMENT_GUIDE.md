# Hướng dẫn Triển khai Môi trường Thực nghiệm Phòng khám 3 Máy ảo (`DC01`, `SRV02`, `WS01`) từ đầu trên AWS EC2

> **Tài liệu Hướng dẫn Tái lập Thực nghiệm (Reproducibility Playbook)**  
> Thuộc Đồ án Tốt nghiệp: *Phát triển giải pháp phát hiện tấn công lẩn tránh nhằm vào CSDL bệnh án trong môi trường Active Directory tại các phòng khám vừa và nhỏ*

---

## 0. Hai Phương thức Triển khai Linh hoạt

Kho mã nguồn này hỗ trợ **2 phương thức triển khai** tùy theo cấu hình phần cứng của người nghiên cứu:
1. **Cách 1 — Triển khai trên AWS EC2 bằng PowerShell Bootstrap (Khuyên dùng cho máy tính cá nhân 8GB RAM):** Khởi tạo 3 máy Windows Server 2022 trắng trên AWS Console và chạy tuần tự 6 kịch bản trong thư mục `aws_powershell_bootstrap/` theo hướng dẫn chi tiết từ Mục 1 đến Mục 8 bên dưới.
2. **Cách 2 — Triển khai tự động hoàn toàn qua Vagrant & Ansible (Dành cho máy trạm/server vật lý có từ 16GB–32GB RAM):**
   ```bash
   cd 01_clinic_lab_and_noise/iac_goad_light_custom
   vagrant up
   ansible-playbook -i inventory provisioning_clinic.yml
   ```

---

## 1. Tổng quan Kiến trúc & Chi phí Thực nghiệm trên AWS EC2

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
   * **Rule 2 (Thông mạng nội bộ giữa 3 máy `DC01`, `SRV02`, `WS01`):** Sau khi tạo xong Security Group, nhấn **Edit inbound rules** $\rightarrow$ Thêm dòng: Type = `All traffic` | Source = Chọn chính ID của `SG-Clinic-Lab-Internal` (ví dụ: `sg-0abc12345...`). *Quy tắc tự tham chiếu (Self-referencing rule) này cho phép 3 máy ảo giao tiếp toàn bộ các cổng AD, DNS, Kerberos, SMB 445, MSSQL 1433 qua địa chỉ Private IP mà không phơi lộ ra Internet.*

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

Trên **cả 3 máy ảo**, mở **Windows PowerShell (Run as Administrator)** và chạy đoạn lệnh sau để chuẩn bị thư mục và tải kho mã nguồn của đồ án về ổ `C:\`:

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
- **Nội dung thực thi:** Đổi Hostname thành `DC01`, cài đặt feature `AD-Domain-Services`, khởi tạo Forest mới tên **`clinic.local`** (NetBIOS: `CLINIC`) với mật khẩu quản trị miền thống nhất là `P@ssw0rd123!`.
- **Lưu ý:** Sau khi chạy xong (~3 phút), máy `DC01` sẽ **tự động khởi động lại (Reboot)**. Hãy đợi khoảng 3–4 phút rồi kết nối RDP lại vào `DC01` với tài khoản:
  * **Username:** `CLINIC\Administrator`
  * **Password:** *(Mật khẩu Administrator của EC2 hoặc `P@ssw0rd123!`)*

### Bước 4.2: Khởi tạo 200 Nhân sự Y tế, `SVC_HIS_Database`, Audit `1644`/`4769` và Sysmon (Stage 2)
Sau khi đăng nhập lại vào **`DC01`**, mở PowerShell (Administrator) và chạy kịch bản `02_DC01_Stage2_ConfigureAD_Audit.ps1`:

```powershell
cd C:\HUST-DATN-20261-AD-Clinic-Detection\01_clinic_lab_and_noise\iac_goad_light_custom\aws_powershell_bootstrap
.\02_DC01_Stage2_ConfigureAD_Audit.ps1
```
- **Nội dung thực thi:**
  1. Tạo 6 OUs (`BacSi`, `YTa`, `LeTan`, `IT_Admin`, `ServiceAccounts`, `ClinicComputers`) và 5 nhóm RBAC (`GRP_BacSi`, `GRP_YTa`, `GRP_LeTan`, `GRP_IT_Admin`, `GRP_HIS_Services`).
  2. Gọi `Import-ClinicADUsers.ps1` nạp 200 định danh nhân sự từ tệp CSV (`BS_BacSi001..060`, `YT_YTa001..100`, `LT_LeTan001..035`, `IT_Admin01..02`).
  3. Khởi tạo tài khoản dịch vụ trọng tâm **`SVC_HIS_Database`** (gắn SPN `MSSQLSvc/SRV02.clinic.local:1433`, cho phép cả mã hóa `RC4 0x17` và `AES256 0x12`), **`SVC_HIS_Sync`** (chứa mật khẩu tạm trong trường `Description`), và **`SVC_Backup_Legacy`** (`DoesNotRequirePreAuth = $true`).
  4. Áp dụng cấu hình Registry `Enable-LDAP-1644-Diagnostics.reg` (bật `15 Field Engineering = 5` và hạ ngưỡng `Expensive/Inefficient Search Results Threshold = 1` để bắt mọi truy vấn ADSI) và bật `auditpol` cho Event ID `4769`, `4624`, `4625`.
  5. Tải và cài đặt `Sysmon64.exe` với cấu hình `sysmon_clinic_config.xml`.
- **Kiểm tra hoàn tất trên `DC01`:** Chạy lệnh `(Get-ADUser -Filter *).Count` thấy trả về `> 200` tài khoản và `Get-ADUser SVC_HIS_Database -Properties ServicePrincipalNames` hiển thị đúng SPN `MSSQLSvc/SRV02.clinic.local:1433`.

---

## 5. Giai đoạn 4: Cấu hình Máy 2 — `SRV02` (Máy chủ Bệnh án HIS SQL & SMB Share)

### Bước 5.1: Trỏ DNS về `DC01` và Gia nhập Miền `clinic.local` (Stage 1)
Trên máy **`SRV02`**, mở PowerShell (Administrator) và chạy kịch bản `03_SRV02_Stage1_JoinDomain.ps1` (nhớ truyền địa chỉ **Private IP của máy `DC01`** vào tham số `-DC01PrivateIP`):

```powershell
cd C:\HUST-DATN-20261-AD-Clinic-Detection\01_clinic_lab_and_noise\iac_goad_light_custom\aws_powershell_bootstrap
.\03_SRV02_Stage1_JoinDomain.ps1 -DC01PrivateIP "172.31.10.10"
```
- **Lưu ý:** Máy `SRV02` sẽ đổi tên thành `SRV02.clinic.local`, gia nhập miền và **tự động Reboot**. Sau 2 phút, kết nối RDP lại vào `SRV02` bằng tài khoản miền:
  * **Username:** `CLINIC\Administrator` (hoặc `CLINIC\IT_Admin01` với mật khẩu `Clinic@2026!`)

### Bước 5.2: Cài đặt MS SQL Server, Khởi tạo CSDL `HIS_ClinicDB`, SQL Audit `33205` và SMB Share `BenhAn$` (Stage 2)
Sau khi đăng nhập lại vào **`SRV02`**, mở PowerShell (Administrator) và chạy kịch bản `04_SRV02_Stage2_SetupHIS_SQL_SMB.ps1`:

```powershell
cd C:\HUST-DATN-20261-AD-Clinic-Detection\01_clinic_lab_and_noise\iac_goad_light_custom\aws_powershell_bootstrap
.\04_SRV02_Stage2_SetupHIS_SQL_SMB.ps1
```
- **Nội dung thực thi:**
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
- Đợi máy `WS01` khởi động lại và đăng nhập RDP bằng tài khoản `CLINIC\Administrator` (hoặc `CLINIC\BS_BacSi001` / `Clinic@2026!`).

### Bước 6.2: Cấp quyền Giao ca và Cài đặt Công cụ trên `WS01` (Stage 2)
Trên máy **`WS01`**, mở PowerShell (Administrator) và chạy kịch bản `06_WS01_Stage2_InitWorkstation.ps1`:

```powershell
cd C:\HUST-DATN-20261-AD-Clinic-Detection\01_clinic_lab_and_noise\iac_goad_light_custom\aws_powershell_bootstrap
.\06_WS01_Stage2_InitWorkstation.ps1
```
- **Nội dung thực thi:** Cho phép các nhóm `GRP_BacSi`, `GRP_YTa`, `GRP_LeTan` đăng nhập trên `WS01`; cài đặt `sqlcmd.exe` và `Sysmon` trên `WS01`.

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