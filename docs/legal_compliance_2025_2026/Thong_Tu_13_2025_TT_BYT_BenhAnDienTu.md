# Thông tư 13/2025/TT-BYT: Hồ sơ bệnh án điện tử và bảo toàn tính toàn vẹn CSDL

Căn cứ pháp lý và đặc tả kỹ thuật cho nhánh bảo vệ toàn vẹn bệnh án điện tử.
Áp dụng cho: `01_clinic_lab_and_noise/his_mssql_database/`, `02_telemetry_and_scenarios/scenario_03_his_db_tampering/`, `03_siem_rules_v1_to_v4/v4_contextual_clinic_tuned/sc3_v4_his_emr_tampering_critical_tt13.yml`.

## 1. Thông tin văn bản

| Thuộc tính | Thông tư 13/2025/TT-BYT |
| --- | --- |
| Cơ quan ban hành | Bộ Y tế |
| Số hiệu | 13/2025/TT-BYT |
| Ngày ban hành | 06/06/2025 |
| Người ký | Thứ trưởng Nguyễn Tri Thức |
| Hiệu lực | 21/07/2025 |
| Căn cứ | Luật Khám bệnh, chữa bệnh năm 2023 |
| Thay thế | Thông tư 46/2018/TT-BYT (và một số quy định liên quan về bệnh án điện tử tại Thông tư 54/2017/TT-BYT) |

Lộ trình triển khai (Điều 5) chia làm hai nhóm:

- Các bệnh viện: hoàn thành triển khai hồ sơ bệnh án điện tử chậm nhất 30/09/2025.
- Các cơ sở khám chữa bệnh khác có điều trị nội trú, điều trị ban ngày hoặc ngoại trú (gồm phòng khám đa khoa): hoàn thành chậm nhất 31/12/2026.

Phòng khám trong đồ án thuộc nhóm thứ hai nên mốc bắt buộc là 31/12/2026.

## 2. Những thay đổi cốt lõi của Thông tư 13/2025 với phòng khám vừa và nhỏ

Trước 21/07/2025, Thông tư 46/2018/TT-BYT yêu cầu cơ sở phải đạt mức cao theo Thông tư 54/2017/TT-BYT mới được triển khai bệnh án điện tử, nên hầu hết phòng khám nhỏ chưa làm được.

Thông tư 13/2025 gỡ rào cản đó nhưng kèm áp lực bảo mật:
1. Gỡ yêu cầu mức cao, chỉ cần bảo đảm hạ tầng nền tảng (máy chủ CSDL, mạng LAN, lưu trữ sao lưu, phần mềm an toàn thông tin) và đạt an toàn hệ thống thông tin Cấp độ 2 hoặc Cấp độ 3 theo Nghị định 85/2016/NĐ-CP và Thông tư 12/2022/TT-BTTTT. Hệ quả là nhiều phòng khám chuyển sang CSDL bệnh án điện tử (`SRV02`) xác thực tập trung qua Active Directory (`DC01`) trong 2025 đến 2026, trong khi IT vẫn chỉ 2 đến 3 người kiêm nhiệm.
2. Liên kết số định danh cá nhân (CCCD) với mỗi hồ sơ, và xác nhận bằng chữ ký số, sinh trắc học hoặc phương thức xác nhận điện tử hợp lệ. Hồ sơ bệnh án điện tử khi đó có giá trị pháp lý như bệnh án giấy theo Điều 69 Luật Khám bệnh, chữa bệnh.
3. Toàn vẹn dữ liệu và hạn chế xóa: bệnh án đã ký xác nhận phải giữ toàn vẹn, không chỉnh sửa hay xóa vật lý trái phép; mọi đính chính thực hiện theo cơ chế ghi thêm phiên bản có lưu người sửa và thời gian. Thời hạn lưu trữ theo Luật Khám bệnh, chữa bệnh là nhiều năm 
//(tra cứu con số cụ thể theo loại bệnh án trong văn bản gốc trước khi cite).

## 3. Ánh xạ sang CSDL và kịch bản tấn công số 3

### 3.1. Lược đồ CSDL (`Init_HIS_EMR_Schema.sql`)

Bảng `HoSoBenhAn` phản ánh cấu trúc bệnh án điện tử: các trường định danh (`MaBenhAn`, `MaLienKet_XML`, `SoCCCD`, `MaTheBHYT`, `HoTenBenhNhan`, `MaICD10`, `ChanDoanLamSang`, `BacSiDieuTri` liên kết tài khoản AD `BS_*`) và các trường kiểm soát tính toàn vẹn (`TrangThaiKySo`, `ChuKySoHash`, `ThoiGianTao`, `NguoiCapNhatCuoi`).

### 3.2. Cấu hình kiểm toán (`Configure_SQL_Server_Audit_33205.sql`)

- Server Audit đẩy nhật ký xuống Windows Application Log để sinh Event ID 33205 (nguồn MSSQLSERVER), cho Winlogbeat thu về SIEM.
- Database Audit Specification giám sát SELECT, INSERT, UPDATE, DELETE trên bảng `HoSoBenhAn` và nhóm sự kiện thay đổi trạng thái kiểm toán.
- Mọi lần bật `xp_cmdshell` qua `sp_configure` sinh Event ID 15457 trong Application Log.

## 3.3. hướng leo thang cho Kịch bản 3

Kịch bản 3 cần một mốc hành vi sinh Event ID 33205 role-change để luật V4 bắt. Từ quyền local admin trên SRV02, đưa SQL về single-user mode để đạt sysadmin rồi
ghi quyền vĩnh viễn (ALTER SERVER ROLE sysadmin ADD MEMBER). -> chỉ dùng công cụ sẵn có của Windows/SQL (không tải hacktool ngoài), và sinh đúng một ban ghi 33205 role-change rõ ràng. 
Nguồn: Microsoft Learn "Connect to SQL Server When System Administrators Are Locked Out".

Ghi chú phạm vi: đồ án là detection engineering, dữ liệu .evtx sinh từ các hành vi SAU khi đã có sysadmin. Có thể mô hình hóa theo hướng "tài khoản dịch vụ bị cấp dư quyền sysadmin" để bỏ hẳn bước exploit leo thang mà vẫn đủ telemetry cần bắt.

## 4. Chốt chặn trong luật V4

Thông tư 13/2025 thể hiện trong Detection Engineering, thể hiện trong luật
`sc3_v4_his_emr_tampering_critical_tt13.yml`:

| Hành vi trên CSDL bệnh án (`SRV02`) | Tính chất theo TT13 | Dấu vết bất biến | Logic luật V4 |
| --- | --- | --- | --- |
| HIS đọc ghi bệnh án định kỳ và đồng bộ XML BHYT | Hợp pháp (từ đúng IP máy chủ HIS) | Event ID 33205 action SELECT hoặc INSERT từ `SVC_HIS_Sync` tại `SRV02` | Whitelist theo ngữ cảnh để giảm cảnh báo giả |
| SELECT hàng loạt bảng `HoSoBenhAn` từ máy trạm lạ (`WS01`) | Vi phạm phân quyền truy cập bệnh án | Chuỗi liên tầng 4769 (vé TGS cho `SVC_HIS_Database` từ `WS01`) rồi 33205 từ `WS01` | Cảnh báo High, ngoài phạm vi whitelist IP |
| DELETE, DROP, TRUNCATE hoặc UPDATE trái phép bệnh án đã ký số | Cấm tuyệt đối (bệnh án phải lưu trữ nhiều năm) | 33205 action DELETE, hoặc statement chứa DELETE FROM HoSoBenhAn, DROP TABLE | Chốt chặn, không whitelist cho bất kỳ ai kể cả `SVC_HIS_Sync` hay `sa`, bắn CRITICAL |
| Tắt Audit (ALTER SERVER AUDIT STATE OFF) hoặc bật `xp_cmdshell` | Cấm tuyệt đối (phá hủy lưu vết) | 33205 action đổi trạng thái Audit, và 15457 (xp_cmdshell 0 sang 1) | Chốt chặn, bắn CRITICAL tức thì |

Lưu ý: tỷ lệ giảm cảnh báo giả ở hàng whitelist sẽ điền sau replay.

## 5. Nguồn tra cứu

- Thông tư 13/2025/TT-BYT (TVPL): https://thuvienphapluat.vn/van-ban/the-thao-y-te/Thong-tu-13-2025-TT-BYT-huong-dan-trien-khai-ho-so-benh-an-dien-tu-660809.aspx
- Bản phân tích (LuatVietnam): https://luatvietnam.vn/y-te/thong-tu-13-2025-tt-byt-huong-dan-trien-khai-ho-so-benh-an-dien-tu-tu-bo-y-te-402396-d1.html

## 6. Trích dẫn (IEEE)

```text
[1] Bộ Y tế, "Thông tư hướng dẫn triển khai hồ sơ bệnh án điện tử," Thông tư số 13/2025/TT-BYT, Hà Nội, Việt Nam, ngày 06/06/2025, hiệu lực 21/07/2025.
[2] Bộ Y tế, "Thông tư quy định chi tiết một số điều của Luật Khám bệnh, chữa bệnh (Chương X: Hồ sơ bệnh án)," Thông tư số 32/2023/TT-BYT, Hà Nội, Việt Nam, ngày 31/12/2023.
[3] Quốc hội, "Luật Khám bệnh, chữa bệnh," Luật số 15/2023/QH15, Hà Nội, Việt Nam, hiệu lực 01/01/2024.
[4] Bộ Thông tin và Truyền thông, "Thông tư hướng dẫn Nghị định 85/2016/NĐ-CP về bảo đảm an toàn hệ thống thông tin theo cấp độ," Thông tư số 12/2022/TT-BTTTT, Hà Nội, Việt Nam, ngày 12/08/2022.
[5] Microsoft, "SQL Server Audit Records (Event ID 33205)," Microsoft Learn. [Online]. Available: https://learn.microsoft.com/en-us/sql/relational-databases/security/auditing/sql-server-audit-records
```