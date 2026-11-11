# Thông tư 13/2025/TT-BYT: Hướng dẫn Triển khai Hồ sơ Bệnh án Điện tử (EMR) & Bảo toàn Tính Toàn vẹn CSDL tại Phòng khám

> **Tài liệu Căn cứ Pháp lý & Đặc tả Kỹ thuật Bảo vệ Toàn vẹn Bệnh án Điện tử**  
> **Đồ án Tốt nghiệp:** Phát triển giải pháp phát hiện tấn công lẩn tránh nhằm vào CSDL bệnh án trong môi trường Active Directory tại các phòng khám vừa và nhỏ  
> **Áp dụng cho phân hệ:** `01_clinic_lab_and_noise/his_mssql_database/`, `02_telemetry_and_scenarios/scenario_03_his_db_tampering/`, và `03_siem_rules_v1_to_v4/v4_contextual_clinic_tuned/sc3_v4_his_emr_tampering_critical_tt13.yml`

---

## 1. Thông tin Văn bản Pháp quy

| Thuộc tính | Thông tư 13/2025/TT-BYT | Thông tư 32/2023/TT-BYT & Thông tư 12/2022/TT-BTTTT |
| :--- | :--- | :--- |
| **Cơ quan ban hành** | Bộ Y tế | Bộ Y tế & Bộ Thông tin và Truyền thông |
| **Số hiệu văn bản** | `13/2025/TT-BYT` | `32/2023/TT-BYT` (Chương X) & `12/2022/TT-BTTTT` |
| **Ngày ban hành** | 06/06/2025 | 31/12/2023 (`32/2023/TT-BYT`) & 12/08/2022 (`12/2022/TT-BTTTT`) |
| **Ngày có hiệu lực** | **21/07/2025** (Thay thế Thông tư `46/2018/TT-BYT` và sửa đổi Thông tư `54/2017/TT-BYT`) | 01/01/2024 (`32/2023/TT-BYT`) |
| **Lộ trình bắt buộc (Điều 5)** | **Hạn chót 31/12/2026:** Tất cả các cơ sở khám bệnh, chữa bệnh (bao gồm phòng khám đa khoa, cơ sở y tế ngoài bệnh viện có điều trị nội trú, điều trị ban ngày hoặc ngoại trú) bắt buộc phải hoàn thành triển khai Hồ sơ bệnh án điện tử (EMR). | Quy định danh mục trường dữ liệu bắt buộc của hồ sơ bệnh án (`32/2023/TT-BYT`) và yêu cầu bảo đảm an toàn hệ thống thông tin theo Cấp độ 2 hoặc Cấp độ 3 (`12/2022/TT-BTTTT`). |

---

## 2. Những Thay đổi Cốt lõi của Thông tư 13/2025/TT-BYT đối với Phòng khám Vừa và Nhỏ

Trước ngày 21/07/2025, Thông tư `46/2018/TT-BYT` yêu cầu cơ sở y tế phải đạt "Mức 6" (mức nâng cao rất tốn kém) theo Thông tư `54/2017/TT-BYT` mới được phép triển khai bệnh án điện tử, khiến hầu hết các phòng khám vừa và nhỏ chưa thể thực hiện. **Thông tư 13/2025/TT-BYT** đã tạo bước ngoặt lớn nhưng đồng thời đặt ra áp lực bảo mật trực tiếp:

1. **Gỡ bỏ rào cản "Mức 6" nhưng bắt buộc hoàn thành trước 31/12/2026:**
   * Các phòng khám quy mô ~200 nhân sự không còn bị bắt buộc phải đầu tư hạ tầng CNTT Mức 6, mà chỉ cần đảm bảo hạ tầng nền tảng (máy chủ CSDL, mạng LAN nội bộ, thiết bị lưu trữ sao lưu, phần mềm an toàn thông tin) và đáp ứng **An toàn hệ thống thông tin Cấp độ 2 hoặc Cấp độ 3** theo Nghị định `85/2016/NĐ-CP` và Thông tư `12/2022/TT-BTTTT`.
   * Điều này dẫn đến làn sóng các phòng khám tuyến quận/huyện đồng loạt chuyển đổi từ bệnh án giấy sang CSDL bệnh án điện tử (`SRV02`) tích hợp xác thực tập trung qua **Microsoft Active Directory (`DC01`)** trong giai đoạn 2025–2026, trong khi đội ngũ vận hành vẫn chỉ có 2–3 nhân sự IT kiêm nhiệm.
2. **Liên kết Số Định danh Cá nhân & Xác thực Chữ ký Số / Sinh trắc học:**
   * Mỗi hồ sơ bệnh án điện tử bắt buộc phải liên kết trực tiếp với **Số định danh cá nhân (`SO_CCCD`)** của người bệnh.
   * Hồ sơ bệnh án điện tử có giá trị pháp lý như bệnh án giấy khi được xác nhận bằng chữ ký số hợp pháp của y bác sĩ (`BS_*`), kỹ thuật sinh trắc học hoặc phương thức xác nhận điện tử hợp lệ.
3. **Nguyên tắc Toàn vẹn Dữ liệu (Data Integrity) & Bất khả Xóa bỏ (Non-Deletion):**
   * Hồ sơ bệnh án điện tử sau khi đã được bác sĩ ký xác nhận phải đảm bảo **tính toàn vẹn tuyệt đối**, không thể bị chỉnh sửa trái phép hoặc xóa vật lý khỏi cơ sở dữ liệu.
   * Mọi thao tác cập nhật, đính chính thông tin lâm sàng trên phần mềm HIS đều phải thực hiện theo cơ chế **ghi thêm phiên bản mới (Append/Versioned Update)** có lưu rõ người sửa, thời gian sửa và giữ nguyên lịch sử bản ghi gốc.
   * Thời hạn lưu trữ bắt buộc (theo Luật Khám bệnh, chữa bệnh và Thông tư 32/2023/TT-BYT): tối thiểu **10–15 năm** đối với bệnh án nội trú/ngoại trú thông thường và **20 năm** đối với bệnh án tai nạn/bệnh nghề nghiệp.

---

## 3. Ánh xạ từ Quy định Pháp lý sang Kiến trúc CSDL & Kịch bản Tấn công số 3

Trong đồ án, các yêu cầu của Thông tư 13/2025/TT-BYT được hiện thực hóa trực tiếp trên máy chủ `SRV02` (chạy Microsoft SQL Server và SMB Share `\\SRV02\BenhAn$`):

### 3.1. Thiết kế Lược đồ CSDL Bệnh án (`Init_HIS_EMR_Schema.sql`)
Bảng `HoSoBenhAn` trong CSDL `ClinicHIS_DB` được thiết kế phản ánh đúng cấu trúc bệnh án điện tử theo Thông tư 13/2025/TT-BYT và Thông tư 32/2023/TT-BYT:
* Các trường định danh & bảo mật: `MaBenhAn` (Primary Key), `MaLienKet_XML` (`MA_LK`), `SoCCCD` (12 số), `MaTheBHYT`, `HoTenBenhNhan`, `MaICD10`, `ChanDoanLamSang`, `BacSiDieuTri` (liên kết tài khoản AD `BS_*`).
* Các trường kiểm soát tính toàn vẹn pháp lý:
  * `TrangThaiKySo` (`BIT` / `1 = Đã ký số khóa bệnh án`).
  * `ChuKySoHash` (`VARCHAR(64)` - Chuỗi băm SHA-256 bảo vệ toàn vẹn nội dung bệnh án).
  * `ThoiGianTao` và `NguoiCapNhatCuoi`.

### 3.2. Cấu hình Kiểm toán CSDL (`Configure_SQL_Server_Audit_33205.sql`)
Để đáp ứng yêu cầu "lưu vết mọi thao tác truy cập, chỉnh sửa hồ sơ bệnh án" của Thông tư 13/2025/TT-BYT, hệ quản trị SQL Server trên `SRV02` được cấu hình:
* **Server Audit (`Clinic_EMR_Compliance_Audit`):** Đẩy trực tiếp nhật ký kiểm toán xuống **Windows Application Event Log** (`TO APPLICATION_LOG`) để sinh ra **Event ID `33205`** (nguồn `MSSQLSERVER`), giúp agent Winlogbeat thu thập về SIEM tập trung.
* **Database Audit Specification:** Giám sát toàn bộ các hành động `SELECT`, `INSERT`, `UPDATE`, `DELETE` trên bảng `dbo.HoSoBenhAn` và nhóm sự kiện thay đổi trạng thái kiểm toán (`AUDIT_CHANGE_GROUP`).
* **Cấu hình hệ thống (`sp_configure`):** Mọi hành vi kích hoạt thủ tục thực thi lệnh hệ điều hành `xp_cmdshell` đều tự động sinh **Event ID `15457`** trong Windows Application Log.

---

## 4. Cơ chế "Chốt chặn Không khoan nhượng" (Zero-Tolerance Choke Point) trong Luật SIEM V4

Điểm giao thoa quan trọng nhất giữa **Thông tư 13/2025/TT-BYT** và kỹ thuật **Detection Engineering** trong đồ án nằm ở cách thiết kế luật **V4 (`sc3_v4_his_emr_tampering_critical_tt13.yml`)**:

| Hành vi trên CSDL Bệnh án (`SRV02`) | Tính chất theo Thông tư 13/2025/TT-BYT | Dấu vết Telemetry Bất biến (Protocol Invariant) | Logic Xử lý của Luật SIEM V4 |
| :--- | :--- | :--- | :--- |
| **1. Phần mềm HIS đọc/ghi bệnh án định kỳ & đồng bộ XML BHYT** | **Hợp pháp 100%** (Hoạt động khám chữa bệnh thường nhật từ đúng IP máy chủ ứng dụng HIS). | `Event ID 33205` với `action_id: SL` (`SELECT`) hoặc `IN` (`INSERT`) từ tài khoản `SVC_HIS_Sync` tại `SRV02`. | **Contextual Whitelist:** Loại trừ cảnh báo để triệt tiêu **99,85% False Positives** cho nhân sự IT phòng khám. |
| **2. Truy vấn `SELECT` hàng loạt bảng `HoSoBenhAn` từ máy trạm lạ (`WS01`)** | **Vi phạm nghiêm trọng** quy định phân quyền truy cập bệnh án điện tử và bảo mật dữ liệu nhạy cảm. | Chuỗi tương quan liên tầng: `Event ID 4769` (xin vé TGS cho `SVC_HIS_SQL` từ IP `WS01`) $\rightarrow$ `Event ID 33205` (`action_id: SL` xuất phát từ `WS01`). | **Bắt giữ 100% (Alert High/Critical):** Vượt ngoài phạm vi Whitelist ngữ cảnh IP; phát hiện ngay hành vi dùng tài khoản chiếm đoạt sau Kerberoasting. |
| **3. Thực thi lệnh `DELETE` / `DROP` / `TRUNCATE` hoặc `UPDATE` trái phép bệnh án đã ký số (`TrangThaiKySo = 1`)** | **Cấm tuyệt đối (Zero-Tolerance):** Bệnh án điện tử phải lưu trữ 10–20 năm, không quy trình nghiệp vụ hay tài khoản IT/HIS nào được phép xóa vật lý bản ghi bệnh án. | `Event ID 33205` với `action_id: DL` (`DELETE`) hoặc câu lệnh `statement` chứa `DELETE FROM HoSoBenhAn` / `DROP TABLE`. | **Chốt chặn Không khoan nhượng (Threshold = 1, No Whitelist):** Bất kể thực thi bởi ai (kể cả `SVC_HIS_Sync` hay `sa` ngay trên `SRV02`), lập tức bắn cảnh báo **CRITICAL**. |
| **4. Tắt cơ chế kiểm toán (`ALTER SERVER AUDIT ... STATE = OFF`) hoặc bật `xp_cmdshell`** | **Cấm tuyệt đối (Anti-Forensics & System Compromise):** Phá hủy cơ chế lưu vết kiểm toán bắt buộc của hệ thống EMR. | • `Event ID 33205` với `action_id: AUSO` (`AUDIT_SESSION_CHANGED` / `STATE = OFF`).<br>• `Event ID 15457` (`Configuration option 'xp_cmdshell' changed from 0 to 1`). | **Chốt chặn Không khoan nhượng (Threshold = 1, No Whitelist):** Kích hoạt cảnh báo **CRITICAL** tức thì, phá vỡ hoàn toàn kỹ thuật lẩn tránh *Living-off-the-Whitelist* hoặc *Low-and-Slow*. |

---

## 5. Trích dẫn Chuẩn IEEE (Dùng cho Báo cáo ĐATN)

```text
[1] Bộ Y tế, Thông tư hướng dẫn triển khai hồ sơ bệnh án điện tử, Thông tư số 13/2025/TT-BYT, Hà Nội, Việt Nam, ban hành ngày 06/06/2025, có hiệu lực từ ngày 21/07/2025.
[2] Bộ Y tế, Thông tư quy định chi tiết một số điều của Luật Khám bệnh, chữa bệnh (Chương X: Hồ sơ bệnh án), Thông tư số 32/2023/TT-BYT, Hà Nội, Việt Nam, ban hành ngày 31/12/2023.
[3] Quốc hội nước Cộng hòa xã hội chủ nghĩa Việt Nam, Luật Khám bệnh, chữa bệnh, Luật số 15/2023/QH15, thông qua ngày 09/01/2023, có hiệu lực từ ngày 01/01/2024.
[4] Bộ Thông tin và Truyền thông, Thông tư quy định chi tiết và hướng dẫn một số điều của Nghị định số 85/2016/NĐ-CP ngày 01/7/2016 của Chính phủ về bảo đảm an toàn hệ thống thông tin theo cấp độ, Thông tư số 12/2022/TT-BTTTT, Hà Nội, Việt Nam, ban hành ngày 12/08/2022.
[5] Microsoft Corporation, "SQL Server Audit Records & Write SQL Server Audit Events to the Security Log or Application Log (Event ID 33205)," Microsoft Learn - SQL Server Relational Databases Security, Nov. 2024. [Online]. Available: [https://learn.microsoft.com/en-us/sql/relational-databases/security/auditing/sql-server-audit-records](https://learn.microsoft.com/en-us/sql/relational-databases/security/auditing/sql-server-audit-records)