# Hướng dẫn dựng lab GOAD-Light Clinic Edition từ con số 0 trên AWS EC2

> Tài liệu tái lập (reproducibility) cho đồ án: *Phát triển giải pháp phát hiện tấn công lẩn tránh nhằm vào CSDL bệnh án trong môi trường Active Directory tại các phòng khám vừa và nhỏ.*
>
> Đây là tài liệu triển khai duy nhất. Bản điều hướng 10 bước: `QUICKSTART.md` (gốc repo).
> Pha phân tích offline: `04_evaluation_and_datasets/REPLAY_RUNBOOK.md`.

---

## 0. Cảnh báo an toàn (đọc trước)

- Lab này **cố tình cấu hình sai** (tài khoản dịch vụ bị Kerberoast, SMB share lỏng, đường leo quyền SQL). Chỉ chạy trong VPC riêng; không mở cổng nào ra Internet ngoài RDP giới hạn IP hợp lệ.
- Dữ liệu bệnh nhân giả lập, mật khẩu (`P@ssw0rd123!`, `Password123!`, `Clinic@2026!`) là mật khẩu lab dùng một lần.
- Có thể terminate cả 3 EC2 sau khi xuất xong `.evtx` để tiết kiệm chi phí.

## 0b. Hai phương thức triển khai
1. **AWS EC2 + PowerShell bootstrap (khuyên dùng cho máy cá nhân ~8GB RAM):** 3 máy Windows Server 2022 trắng, chạy tuần tự 6 script trong `aws_powershell_bootstrap/`. Toàn bộ guide này.
2. **Vagrant + Ansible (máy ≥16GB RAM):** `vagrant up && ansible-playbook -i inventory provisioning_clinic.yml`. Đường phụ, không phải luồng chính.

## 0c. Bắt buộc trước khi dựng
1. **SQL phải Mixed Mode** (`/SECURITYMODE=SQL`): script 04 đã đặt sẵn. Thiếu thì không tạo được SQL Login `SVC_HIS_Sync`.
2. **Thứ tự cố định:** DC01 lên trước (01→02), rồi SRV02/WS01 mới join được (03/04, 05/06).
3. **`sysmon_clinic_config.xml` và `Enable-LDAP-1644-Diagnostics.reg` không rỗng.
4. Chạy 6 script đúng máy đúng thứ tự (các mục 3–5).

---

## 1. Tài khoản AWS và mạng

### 1.1. Security Group `SG-Clinic-Lab-Internal`
- Region `ap-southeast-1` (Singapore).
- Inbound: `RDP 3389/TCP` ← **My IP**; rồi thêm `All traffic` ← **chính Security Group này** (self-referencing, cho 3 máy nói chuyện đủ cổng AD/DNS/Kerberos/SMB445/MSSQL1433 nội bộ).

### 1.2. Ghim Private IP tĩnh (fix lỗ hổng tái lập)

Bộ luật V4 và KQL **hardcode SRV02 = `172.31.10.22`** để whitelist. Nếu để AWS cấp IP ngẫu nhiên, whitelist sẽ sai và số FP của V4 vô nghĩa. Chọn một trong hai:

**Cách A (khuyên dùng): ghim Primary IP lúc launch.** Launch từng máy một, ở *Network settings → Advanced network configuration* điền **Primary IP** trong dải subnet (vd subnet `172.31.0.0/20`):

| Máy | Primary private IP |
|---|---|
| DC01 | `172.31.10.10` |
| SRV02 | `172.31.10.22` |
| WS01 | `172.31.10.30` |

> IP phải thuộc đúng subnet đã chọn và chưa bị dùng. Nếu subnet của lab khác `172.31.0.0/20`, chọn 3 IP hợp lệ trong subnet đó rồi **sửa** mọi chỗ `172.31.10.22` (xem §1.3 và các file luật V4/KQL).

**Cách B — IP ngẫu nhiên rồi sửa luật.** Ghi lại 3 IP được cấp, sửa IP SRV02 trong
`v4_contextual_clinic_tuned/sc1_v4_...yml`, `sc2_v4_...yml`, và `kql_queries/elastic_kibana_saved_queries.ndjson`.

### 1.3. Hướng dẫn tune IP cho phòng khám (dành cho IT triển khai thật)
Whitelist V4 neo theo **IP tĩnh máy chủ HIS** + **tài khoản dịch vụ đồng bộ BHYT**. Khi áp cho phòng khám thật: chạy baseline 7 ngày (xem `Clinic_IT_Morning_Review_Playbook.md` Bước 0), xác định đúng 2 giá trị đó, điền vào trường `IpAddress`/`SubjectUserName`/`source.ip` trong 3 file luật V4 + file KQL.

### 1.4. Launch 3 máy
- AMI **Windows Server 2022 Base** (64-bit); `t3.medium` (2vCPU/4GB); `35 GiB gp3`; cùng 1 subnet/AZ.
- Key pair `clinic-lab-key.pem`. Auto-assign public IP = Enable.
- Name tag: `DC01`, `SRV02`, `WS01`. Sau `Running` ~4 phút: Connect → Get password (nạp `.pem`).

---

## 2. Đưa mã nguồn lên cả 3 máy
RDP vào từng máy, PowerShell (Admin):
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
New-Item -Path "C:\Tools" -ItemType Directory -Force | Out-Null
Add-MpPreference -ExclusionPath "C:\Tools"
Add-MpPreference -ExclusionPath "C:\HUST-DATN-20261-AD-Clinic-Detection"
```
Đưa repo vào `C:\HUST-DATN-20261-AD-Clinic-Detection` (git clone hoặc Ctrl+C/V qua RDP).

---

## 3. DC01 — Domain Controller
```powershell
cd C:\HUST-DATN-20261-AD-Clinic-Detection\01_clinic_lab_and_noise\iac_goad_light_custom\aws_powershell_bootstrap
.\01_DC01_Stage1_InstallForest.ps1      # tạo forest clinic.local, tự reboot -> RDP lại CLINIC\Administrator
.\02_DC01_Stage2_ConfigureAD_Audit.ps1  # 200 user + telemetry 1644/4769/4624/4625 + Sysmon
```
Script 02 tạo: 6 OU, 5 group, và **200 định danh** = 2 service account + **3 IT_Admin (IT_Admin01–03)**
+ 60 BS + 100 YT + 35 LT. (Lưu ý: 3 IT_Admin, không phải 2.)

Kiểm tra:
```powershell
(Get-ADUser -Filter *).Count     # > 200
Get-ADUser SVC_HIS_Database -Properties ServicePrincipalNames, KerberosEncryptionType, adminCount
dcdiag /q ; Get-Service Sysmon64
```

---

## 4. SRV02 — máy chủ HIS (SQL + SMB)
```powershell
cd C:\HUST-DATN-20261-AD-Clinic-Detection\01_clinic_lab_and_noise\iac_goad_light_custom\aws_powershell_bootstrap
.\03_SRV02_Stage1_JoinDomain.ps1 -DC01PrivateIP "172.31.10.10"   # join, tự reboot
.\04_SRV02_Stage2_SetupHIS_SQL_SMB.ps1                            # SMB + SQL + Audit + Sysmon
```

### 4.3. KIỂM TRA BẮT BUỘC trên SRV02
```powershell
# (a) Default instance trên 1433?
sqlcmd -S localhost -E -Q "SELECT SERVERPROPERTY('InstanceName') AS Inst, SERVERPROPERTY('Edition') AS Edition, @@VERSION AS Ver;"
#   Inst = NULL. Nếu = 'SQLEXPRESS' -> SPN sai cổng, cài lại với /INSTANCENAME=MSSQLSERVER.

# (b) Edition đủ mới cho Database Audit Specification?
#   Mọi edition hỗ trợ SERVER audit; DATABASE audit chỉ chạy từ SQL Server 2016 SP1 trở lên
#   Express 2019/2022 (choco cài) là đủ. Nếu tạo Database Audit Spec báo:
#       Msg 33075: Granular auditing is not available in this edition of SQL Server
#   -> ĐỔI sang SQL Server Developer Edition (miễn phí lab) rồi nạp lại schema + audit

# (c) Audit đang bật?
sqlcmd -S localhost -E -Q "SELECT name,is_state_enabled FROM sys.server_audits;"
sqlcmd -S localhost -E -Q "SELECT name,is_state_enabled FROM sys.server_audit_specifications;"
sqlcmd -S localhost -E -d HIS_ClinicDB -Q "SELECT name,is_state_enabled FROM sys.database_audit_specifications;"
#   Cả 3 phải is_state_enabled = 1.

# (d) 50 bệnh án mẫu? (e) Firewall + share?
sqlcmd -S localhost -E -d HIS_ClinicDB -Q "SELECT COUNT(*) FROM dbo.HoSoBenhAn;"
Get-NetFirewallRule -DisplayName "Allow_MSSQL_1433"; Get-SmbShare -Name "BenhAn$"
```
> Nếu (c) rỗng/0 → **dừng và sửa**: toàn bộ telemetry 33205 của Kịch bản 3 phụ thuộc vào đây

---

## 5. WS01 — máy trạm
```powershell
cd C:\HUST-DATN-20261-AD-Clinic-Detection\01_clinic_lab_and_noise\iac_goad_light_custom\aws_powershell_bootstrap
.\05_WS01_Stage1_JoinDomain.ps1 -DC01PrivateIP "172.31.10.10"
.\06_WS01_Stage2_InitWorkstation.ps1
```

---

## 6. Sinh nhiễu (chạy TRƯỚC khi tấn công; để song song ~30–60 phút)
Quy tắc đặt máy (whitelist V4 dựa vào IP nguồn):
- Nhiễu **giao ca** (4624/4625) → **WS01**.
- Nhiễu **đồng bộ HIS** (1644/33205/5140) → **SRV02**, dưới `SVC_HIS_Sync` (để 1644 mang IP SRV02).
```powershell
# WS01:
cd ...\business_noise_generators ; .\Register-ClinicNoiseScheduledTasks.ps1
# SRV02:
cd ...\business_noise_generators ; .\Register-ClinicNoiseScheduledTasks.ps1   # tự nhận SRV02 -> task sync dưới SVC_HIS_Sync
```
> Task sync lỗi khởi động → cấp *Log on as a batch job* cho `SVC_HIS_Sync` (`secpol.msc`).

---

## 7. Chạy 3 kịch bản (ghi ground truth)
### 7.1 Kịch bản 1 (WS01)
```powershell
cd ...\scenario_01_adsi_slow_recon
.\sharphound_setspn_default.ps1      # 1A (V1 bắt) - Sysmon 1 trên WS01
.\evasion_adsi_low_and_slow_spn.ps1  # 1B (V1 bỏ lọt) - 1644 trên DC01
```
### 7.2 Kịch bản 2 (WS01)
```powershell
cd ...\scenario_02_kerberoast_opsec
.\attack_rc4_downgrade_0x17.ps1      # 2A - cần Rubeus.exe trong C:\Tools
.\evasion_aes256_opsec_0x12.ps1      # 2B - .NET native
```
### 7.3 Kịch bản 3 (leo quyền P2 trên SRV02, rồi P3→P4→P5)
`SVC_HIS_Database` là Windows login → dùng `runas /netonly`, không `-U/-P`.
```powershell
# P2 trên SRV02 (quyền local-admin của SVC_HIS_Database):
net stop MSSQLSERVER ; net start MSSQLSERVER /m
sqlcmd -S localhost -E -Q "ALTER SERVER ROLE sysadmin ADD MEMBER [CLINIC\SVC_HIS_Database];"
net stop MSSQLSERVER ; net start MSSQLSERVER
# P3 -> P4 -> P5 (đọc/xóa khi audit CÒN ON; tắt audit CUỐI):
cd ...\scenario_03_his_db_tampering
sqlcmd -S SRV02.clinic.local -E -i .\enable_xp_cmdshell_15457.sql       | Tee-Object C:\ground_truth_sql.log -Append
sqlcmd -S SRV02.clinic.local -E -i .\abuse_svc_his_read_delete_emr.sql  | Tee-Object C:\ground_truth_sql.log -Append
sqlcmd -S SRV02.clinic.local -E -i .\disable_sql_audit_33205.sql        | Tee-Object C:\ground_truth_sql.log -Append
```
Ground truth: `C:\ground_truth.csv` (WS01, SC1/SC2) + `C:\ground_truth_sql.log` (SRV02, SC3).

---

## 8. Xuất `.evtx`
```powershell
# DC01
New-Item C:\evtx -ItemType Directory -Force | Out-Null
wevtutil epl Security                              "C:\evtx\dc01_security_4769_4624_4625.evtx"
wevtutil epl "Directory Service"                   "C:\evtx\dc01_directory_service_1644.evtx"
wevtutil epl Microsoft-Windows-Sysmon/Operational  "C:\evtx\dc01_sysmon.evtx"
# SRV02
New-Item C:\evtx -ItemType Directory -Force | Out-Null
wevtutil epl Application                           "C:\evtx\srv02_application_33205_15457.evtx"
wevtutil epl Security                              "C:\evtx\srv02_security_5140_5145.evtx"
wevtutil epl Microsoft-Windows-Sysmon/Operational  "C:\evtx\srv02_sysmon_sqlservr.evtx"
# WS01
New-Item C:\evtx -ItemType Directory -Force | Out-Null
wevtutil epl Security                              "C:\evtx\ws01_security.evtx"
wevtutil epl Microsoft-Windows-Sysmon/Operational  "C:\evtx\ws01_sysmon_setspn.evtx"
```
Copy tất cả `.evtx` + 2 file ground truth về `04_evaluation_and_datasets/evtx_master_datasets/`.

### 8.1. Kiểm tra 1 lần: Event 1644 có trường danh tính không?
```powershell
Get-WinEvent -LogName "Directory Service" -FilterXPath "*[System[(EventID=1644)]]" -MaxEvents 1 | Format-List *
```
Có `SubjectUserName`/`User` → whitelist SC1-V4 theo danh tính + IP. Chỉ có IP → whitelist theo IP SRV02.

---

## 9. Hủy hạ tầng
EC2 → chọn 3 máy → Instance state → **Terminate**.

---

## 10. Phân tích offline
Xem `04_evaluation_and_datasets/REPLAY_RUNBOOK.md` (bật ELK, nạp `.evtx`, chạy V1→V4, gán nhãn, tính số, vẽ).

---

## 11. Bảng Event ID → log nào → kịch bản nào (để không xuất thiếu)
| Event ID | Kênh log | Máy | Dùng cho |
|---|---|---|---|
| 1 (ProcessCreate) | Microsoft-Windows-Sysmon/Operational | WS01, SRV02 | SC1-1A (setspn), SC3-P3 (sqlservr→cmd) |
| 1644 | Directory Service | DC01 | SC1-1B (ADSI low-and-slow) |
| 4624/4625 | Security | DC01, WS01 | Nhiễu giao ca |
| 4769 | Security | DC01 | SC2 (0x17 vs 0x12) |
| 5140/5145 | Security | SRV02 | Truy cập SMB BenhAn$ |
| 15457 | Application | SRV02 | SC3-P3 (xp_cmdshell) |
| 33205 | Application | SRV02 | SC3 (role-change, SELECT/DELETE, tắt audit) |

Dòng nào không có `.evtx` tương ứng ở §8 → xuất thiếu
