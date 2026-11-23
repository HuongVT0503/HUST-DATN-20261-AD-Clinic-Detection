# Kịch bản 3: Leo thang đặc quyền và thao túng CSDL bệnh án (đặc tả thiết kế)

Đây là kịch bản trọng tâm của đồ án: nó là cái duy nhất thể hiện rõ chuỗi leo thang đặc quyền xuyên tầng (AD -> OS -> DB) và vi phạm trực tiếp các điều luật mới về bảo vệ dữ liệu y tế.

ĐẶC TẢ THIẾT KẾ HƯỚNG PHÁT HIỆN,  kèm script tấn công chạy sẵn. 
mục tiêu đồ án là detection engineering, cái được chấm là luật phát hiện và telemetry, không phải bộ công cụ tấn công

## 1. Tiền đề (misconfig làm điểm tựa, KHÔNG phải misconfig thường)

Điểm tựa KHÔNG phải là mật khẩu `sa` yếu. Điểm tựa là một over-privilege thực tế rất hay gặp ở phòng khám Việt Nam: tài khoản dịch vụ HIS được nhà cung cấp cấu hình làm **local administrator trên chính máy chủ CSDL** (trong lab là `SVC_HIS_Database` thuộc nhóm Administrators của SRV02, đã set ở `04_SRV02_Stage2_SetupHIS_SQL_SMB.ps1`). Đây là loại cấu hình sai nghiêm trọng và khó phát hiện mà đề tài muốn chỉ ra,  không phải lỗi sơ đẳng.

## 2. Chuỗi tấn công xuyên tầng (ground truth, ghi timestamp từng pha)

| Pha | Tầng | Hành vi (hiện thực từ nguồn công khai) | Dấu vết để bắt |
| --- | --- | --- | --- |
| P1 | AD | Kerberoast `SVC_HIS_Database` lấy hash, crack offline (Kịch bản 2) | 4769 (0x12) |
| P2 | OS -> DB | Từ quyền local admin trên SRV02, leo lên SQL `sysadmin` | 33205 role-change |
| P3 | DB | Bật `xp_cmdshell` qua `sp_configure` | 15457 + Sysmon 1 (sqlservr.exe -> cmd) |
| P4 | DB | Đọc hàng loạt + xóa bệnh án đã ký số (vượt DENY DELETE) | 33205 SELECT/DELETE |
| P5 | DB | Tắt SQL Server Audit để xóa dấu vết | 33205 STATE=OFF |

Thứ tự: P2 -> P3 -> **P4 (đọc/xóa) -> P5 (tắt audit CUỐI)**.
Nếu tắt audit trước P4 thì DELETE không còn sinh 33205, mất ground truth. 

## 3. Pha P2 (leo thang): brainstorm các hướng, chọn hướng chặt chẽ

Vấn đề cốt lõi: `SVC_HIS_Database` chỉ có `db_datareader/writer` + DENY DELETE, KHÔNG phải sysadmin. Mà tắt audit / bật xp_cmdshell / vượt DENY DELETE đều cần sysadmin. Dưới đây là các hướng leo thang, bạn CHỌN 1 và tự hiện thực từ nguồn gốc:

- **Hướng B1 (khuyên dùng) - local admin -> sysadmin qua single-user mode.** Local admin của
  máy chủ SQL có thể đưa SQL về single-user mode; ở chế độ đó thành viên nhóm Administrators cục
  bộ kết nối được với quyền sysadmin, rồi tự thêm mình vào server role `sysadmin` vĩnh viễn.
  Sinh sự kiện 33205 role-change (chính là cái V4 bắt). Chỉ dùng công cụ sẵn có của Windows/SQL.
  Nguồn gốc để hiện thực và trích dẫn:
  Microsoft Learn, "Connect to SQL Server When System Administrators Are Locked Out"
  https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/connect-to-sql-server-when-system-administrators-are-locked-out




## 4. Pha P3/P4/P5: hiện thực từ nguồn công khai (ghi rõ để cite)

Bạn tự viết các câu lệnh SQL cho 3 pha này; tất cả đều là lệnh SQL chuẩn, có tài liệu gốc:

- P3 bật xp_cmdshell: `sp_configure 'xp_cmdshell', 1` sinh Event ID 15457. Nguồn Event 15457:
  NetSPI PowerUpSQL wiki và Microsoft Learn (sp_configure). Dùng Atomic Red Team T1059.003 làm
  mẫu lệnh: https://github.com/redcanaryco/atomic-red-team (atomics/T1059.003).
- P4 đọc hàng loạt + DELETE bệnh án đã ký (`DaKySoTT13 = 1`): `SELECT`/`DELETE` chuẩn trên
  `dbo.HoSoBenhAn`. Database Audit Specification đã bật ở `Configure_SQL_Server_Audit_33205.sql`
  sẽ ghi 33205 cho các thao tác này (khi audit còn ON).
- P5 tắt audit: `ALTER SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13] WITH (STATE = OFF)`. Nguồn
  Event 33205 + phát hiện tamper: Microsoft Learn "SQL Server Audit Records" và Elastic
  Security "MSSQL Audit Stopped or Tampered". Xem docs/PROVENANCE_detection_rules.md.

Mỗi pha, ghi lại mốc thời gian bắt đầu/kết thúc (dùng `SELECT SYSDATETIME();` trước và sau) để
gán nhãn tĩnh cho .evtx.

## 5. Lưu ý đúng-sai quan trọng về instance SQL (ảnh hưởng cả KB2 và KB3)

SPN là `MSSQLSvc/SRV02.clinic.local:1433` và mọi script nối `-S localhost` / `-S SRV02.clinic.local`,
tức giả định SQL là DEFAULT instance trên cổng 1433. Nhưng `choco install sql-server-express`
mặc định cài instance TÊN `SQLEXPRESS` (cổng động, không phải 1433). Nếu để vậy thì SPN sai cổng
và sqlcmd không tìm thấy instance. Sửa: thêm `/INSTANCENAME=MSSQLSERVER` vào params choco ở
`04_SRV02_Stage2_SetupHIS_SQL_SMB.ps1` và `provisioning_clinic.yml` để cài default instance:

    choco install sql-server-express -y --params="'/SECURITYMODE=SQL /SAPWD=... /TCPENABLED=1 /INSTANCENAME=MSSQLSERVER'"
