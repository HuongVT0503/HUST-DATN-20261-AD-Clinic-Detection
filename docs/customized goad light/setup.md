# Hướng dẫn dựng Lab GOAD-Light Clinic Edition từ 3 máy AWS trắng

Kiến trúc chốt: **DC01** (Domain Controller, clinic.local) · **SRV02** (HIS: MSSQL + SMB) · **WS01** (máy trạm, Patient Zero).
Yêu cầu: tài khoản AWS, RDP client, ~2–4 giờ chạy, chi phí < 1.5 USD/phiên (nhớ Terminate khi xong).

## 0. Thứ tự tổng quát
Mạng AWS → tạo 3 EC2 → DC01 lên domain trước → SRV02 & WS01 join → cài SQL/SMB/Sysmon → sinh noise + chạy tấn công → xuất .evtx → Terminate.

## 1. Mạng AWS (một lần)
1. Region: `ap-southeast-1` (Singapore).
2. Security Group `SG-Clinic-Lab`:
   - Inbound RDP 3389 ← **My IP**.
   - Inbound **All traffic** ← chính SG này (self-referencing) để DC/DNS/Kerberos/SMB445/MSSQL1433 thông nội bộ.
3. Dùng Default VPC + 1 Subnet, cùng 1 AZ cho cả 3 máy.

## 2. Tạo 3 EC2 (Windows Server 2022 Base)
- DC01: t3.medium, 30GB gp3, Private IP ví dụ 172.31.10.10
- SRV02: t3.large, 35GB gp3, 172.31.10.22
- WS01: t3.medium, 30GB gp3, 172.31.10.30
- Enable auto-assign public IP; gắn `SG-Clinic-Lab`; tạo key pair để lấy mật khẩu Administrator.
- RDP vào cả 3, tắt IE ESC, bật ExecutionPolicy Bypass, thêm Defender exclusion cho thư mục repo.

## 3. DC01 — dựng forest clinic.local  (file thiếu: 01_DC01_Stage1_InstallForest.ps1)
```powershell
$sec = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
Rename-Computer -NewName "DC01" -Force
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName "clinic.local" -DomainNetbiosName "CLINIC" `
  -SafeModeAdministratorPassword $sec -InstallDns -Force
# Máy tự reboot. RDP lại bằng CLINIC\Administrator.
```
Sau reboot, chạy `Import-ClinicADUsers.ps1` (đã có sẵn trong repo) để tạo 6 OU, 5 group, 200 user, SVC_HIS_Database/Sync/Backup, bật audit 1644/4769:
```powershell
cd <repo>\01_clinic_lab_and_noise\ad_identity_200_users
.\Import-ClinicADUsers.ps1
# Bật telemetry:
reg import "<repo>\02_telemetry_and_scenarios\telemetry_configs\Enable-LDAP-1644-Diagnostics.reg"
auditpol /set /subcategory:"Kerberos Service Ticket Operations" /success:enable /failure:enable
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
wevtutil sl Security /ms:536870912
wevtutil sl "Directory Service" /ms:536870912
```

## 4. SRV02 — join + HIS  (file thiếu: 03_..JoinDomain.ps1, 04_..SetupHIS.ps1)
```powershell
# Trỏ DNS về DC01 rồi join
Get-NetAdapter | ? Status -eq Up | Set-DnsClientServerAddress -ServerAddresses "172.31.10.10"
Rename-Computer -NewName "SRV02" -Force; Restart-Computer
# Sau reboot:
Add-Computer -DomainName "clinic.local" -Credential (Get-Credential CLINIC\Administrator) -Restart
```
Sau khi join (RDP lại bằng tài khoản domain):
```powershell
# Cài SQL Server (Developer Edition free, đủ Server Audit - khuyên dùng thay Express)
# 1) Cài choco, 2) choco install sql-server-2022 (hoặc tải ISO Developer), 3) choco install sqlserver-cmdlineutils
Setup_SMB_BenhAn_Share.ps1          # tạo \\SRV02\BenhAn$ + SACL 5140/5145 (đã có)
sqlcmd -S localhost -E -i Init_HIS_EMR_Schema.sql
sqlcmd -S localhost -E -i Configure_SQL_Server_Audit_33205.sql
wevtutil sl Application /ms:536870912
# Cài Sysmon với sysmon_clinic_config.xml (CẦN điền file này trước - hiện rỗng)
```

## 5. WS01 — join + công cụ  (file thiếu: 05_..JoinDomain.ps1, 06_..Init.ps1)
Như bước 4 phần join. Sau đó cài `sqlcmd`, `Sysmon`, cấp quyền logon cho GRP_BacSi/YTa/LeTan.

## 6. Sinh dataset
```powershell
# Trên WS01: bật noise
.\Invoke-DoctorShiftChange_4624_4625.ps1
.\Invoke-HISXmlSync_QD130_QD4750.ps1 -TargetServer SRV02.clinic.local
# Chạy 3 kịch bản (ghi lại timestamp bắt đầu/kết thúc từng pha - đây là ground truth)
```

## 7. Xuất .evtx + Terminate
```powershell
# DC01
wevtutil epl Security "C:\dc01_security.evtx"
wevtutil epl "Directory Service" "C:\dc01_ds_1644.evtx"
# SRV02
wevtutil epl Application "C:\srv02_app_sql.evtx"
```
Copy .evtx về máy cá nhân qua RDP → **Terminate cả 3 EC2** → phân tích offline bằng ELK trên WSL2.