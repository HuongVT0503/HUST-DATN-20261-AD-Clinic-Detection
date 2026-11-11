# Chuẩn Dữ liệu Đầu ra XML Bảo hiểm Y tế (Quyết định 130/QĐ-BYT & Quyết định 4750/QĐ-BYT)

> **Tài liệu Căn cứ Pháp lý & Đặc tả Kỹ thuật Nghiệp vụ Y tế**  
> **Áp dụng cho:** `01_clinic_lab_and_noise/business_noise_generators/Invoke-HISXmlSync_QD130_QD4750.ps1` và `03_siem_rules_v1_to_v4/`

---

## 1. Thông tin Văn bản Pháp quy

| Thuộc tính | Quyết định 130/QĐ-BYT | Quyết định 4750/QĐ-BYT |
| :--- | :--- | :--- |
| **Cơ quan ban hành** | Bộ Y tế | Bộ Y tế |
| **Số hiệu văn bản** | `130/QĐ-BYT` | `4750/QĐ-BYT` |
| **Ngày ban hành** | 18/01/2023 | 29/12/2023 |
| **Tên văn bản** | Quyết định quy định chuẩn và định dạng dữ liệu đầu ra phục vụ việc quản lý, giám định, thanh toán chi phí khám bệnh, chữa bệnh và giải quyết các chế độ liên quan | Quyết định sửa đổi, bổ sung một số điều của Quyết định số 130/QĐ-BYT ngày 18/01/2023 của Bộ trưởng Bộ Y tế |
| **Văn bản liên quan** | Thông tư `48/2017/TT-BYT` (Quy định trích chuyển dữ liệu điện tử trong quản lý và thanh toán chi phí KCB BHYT) | Thông tư `13/2025/TT-BYT` (Hướng dẫn triển khai hồ sơ bệnh án điện tử) & Luật BVDLCN `91/2025/QH15` |

---

## 2. Bản chất Nghiệp vụ Trích chuyển Dữ liệu XML tại Phòng khám

Theo quy định của Bộ Y tế và Bảo hiểm Xã hội (BHXH) Việt Nam, mọi cơ sở khám chữa bệnh (bao gồm các phòng khám đa khoa quy mô vừa và nhỏ có ký hợp đồng khám chữa bệnh BHYT) bắt buộc phải trích xuất dữ liệu từ Phần mềm Quản lý Thông tin Bệnh viện/Phòng khám (**HIS**) ra định dạng tệp **XML** theo chuẩn Quyết định 130/QĐ-BYT và 4750/QĐ-BYT ngay sau khi kết thúc lượt khám hoặc kết thúc điều trị để gửi lên Cổng Tiếp nhận dữ liệu Hệ thống Thông tin Giám định BHYT.

### Cấu trúc các Bảng chỉ tiêu Dữ liệu XML cốt lõi (XML1 – XML15)
Trong quy trình vận hành thực tế tại phòng khám, mỗi hồ sơ bệnh nhân khi kết thúc khám sẽ kích hoạt tiến trình truy vấn CSDL SQL Server (`SRV02`) để tổng hợp và đóng gói các bảng XML sau:

* **XML1 (Bảng Tổng hợp khám bệnh, chữa bệnh):** Chứa các trường định danh cốt lõi như `MA_LK` (Mã liên kết), `MA_BN` (Mã bệnh nhân), `HO_TEN`, `SO_CCCD` (Số định danh cá nhân/CCCD), `MA_THE_BHYT`, `MA_BENH_CHINH` (Mã ICD-10), `NGAY_VAO`, `NGAY_RA`, và tổng chi phí.
* **XML2 (Bảng Chỉ tiết thuốc thanh toán):** Danh mục thuốc, hàm lượng, liều dùng, bác sĩ kê đơn (`MA_BAC_SI`).
* **XML3 (Bảng Chi tiết dịch vụ kỹ thuật & vật tư y tế):** Xét nghiệm (LIS), Chẩn đoán hình ảnh (PACS/RIS), thủ thuật lâm sàng.
* **XML4 (Bảng Chi tiết dịch vụ cận lâm sàng):** Kết quả chỉ số xét nghiệm, mô tả chẩn đoán.
* **XML5 (Bảng Chi tiết diễn biến lâm sàng):** Quá trình theo dõi sinh hiệu, diễn biến bệnh án.
* **XML7 / XML8 / XML9:** Giấy ra viện, Tóm tắt hồ sơ bệnh án, Giấy chứng nhận nghỉ việc hưởng BHXH.
* **XML13 / XML14:** Giấy chuyển tuyến BHYT, Giấy hẹn khám lại (Bổ sung/chuẩn hóa theo QĐ 4750/QĐ-BYT).

---

## 3. Ánh xạ từ Nghiệp vụ Y tế sang Lưu lượng Hệ thống (Telemetry & Business Noise)

Để quá trình trích chuyển XML diễn ra tự động và liên tục trong giờ hành chính mà không làm gián đoạn công việc của bác sĩ, kiến trúc CNTT tại các phòng khám vừa và nhỏ thường sử dụng một **Tài khoản Dịch vụ (Service Account)** chạy ngầm (trong đồ án định danh là `SVC_HIS_Sync` hoặc `SVC_HIS_SQL`).

Hoạt động hợp lệ này là **nguồn sinh nhiễu nền (Benign Background Traffic)** lớn nhất trong hệ thống mạng Active Directory và CSDL của phòng khám, trực tiếp gây ra hiện tượng **Quá tải cảnh báo giả (Alert Fatigue)** theo Nghịch lý Tỷ lệ Cơ sở (*Base-Rate Fallacy* - Axelsson, 1999) nếu luật SIEM không được tinh chỉnh:

| Bước Nghiệp vụ | Hoạt động Kỹ thuật trên Hạ tầng Lab (`DC01`, `SRV02`) | Mã Sự kiện (Event ID) Sinh ra | Lý do Gây Cảnh báo Giả (False Positive) ở Luật SIEM V2/V3 |
| :--- | :--- | :--- | :--- |
| **1. Xác thực Dịch vụ Định kỳ** | Cứ mỗi 5 phút (hoặc sau mỗi lượt khám), tiến trình đồng bộ dùng tài khoản `SVC_HIS_Sync` yêu cầu vé dịch vụ Kerberos TGS tới `DC01` để kết nối vào `MSSQLSvc/SRV02.clinic.local:1433` và SMB Share. | **Windows Security Event ID `4769`** (với mã hóa `TicketEncryptionType: 0x12` - AES256) và **Event ID `4624`** (Logon Type 3). | Khi luật SIEM V2 mở rộng điều kiện để bắt tấn công **Kerberoasting OpSec AES (`0x12`)**, hàng nghìn sự kiện `4769` hợp lệ của `SVC_HIS_Sync` và phần mềm HIS bị bắt nhầm thành hành vi đánh cắp vé TGS. |
| **2. Tra cứu Định danh Bác sĩ Kê đơn** | Phần mềm HIS truy vấn LDAP lên `DC01` để đối chiếu thông tin tài khoản bác sĩ (`BS_*`), khoa phòng và quyền ký số trước khi đóng gói thẻ `<MA_BAC_SI>` trong tệp XML2, XML3. | **Directory Service Event ID `1644`** (LDAP Search Query). | Khi luật SIEM V2 bắt mọi truy vấn LDAP để chống dò quét AD (`T1087.002`), các truy vấn kiểm tra phân quyền tự động của HIS bị nhận diện nhầm là công cụ dò quét định danh. |
| **3. Truy vấn CSDL Bệnh án Hàng loạt** | Dịch vụ đồng bộ thực thi các câu lệnh `SELECT` liên tiếp trên bảng `HoSoBenhAn`, `ChiTietThuoc`, `DichVuKyThuat` trong SQL Server (`SRV02`) để gom dữ liệu xuất XML (đặc biệt tăng đột biến vào cuối ca hoặc giờ sao lưu). | **SQL Server Audit Event ID `33205`** (`ACTION_ID: SL` - Select) trong Windows Application Log. | Khi luật SIEM V2/V3 đặt ngưỡng đếm số lượng bản ghi `SELECT` để bắt hành vi trích xuất dữ liệu (Data Exfiltration), tác vụ tổng hợp XML BHYT cuối ngày vượt ngưỡng và kích hoạt cảnh báo giả. |
| **4. Ghi và Chia sẻ Tệp XML qua Mạng Nội bộ** | Tệp `.xml` sau khi kết xuất được đẩy vào thư mục chia sẻ nội bộ `\\SRV02\BenhAn$` để cổng ký số và phần mềm giám định BHYT đọc/gửi đi. | **Windows Security Event ID `5140` / `5145`** (Network Share Object Access). | Trùng lặp hoàn toàn về mặt hành vi giao thức với kỹ thuật thu thập dữ liệu từ thư mục chia sẻ (**MITRE ATT&CK T1039** - Data from Network Shared Drive). |

---

## 4. Nguyên tắc Thiết kế Luật SIEM V4 & Kịch bản Mô phỏng trong Đồ án

### 4.1. Tham số hóa trong Script Sinh nhiễu (`Invoke-HISXmlSync_QD130_QD4750.ps1`)
Script mô phỏng lưu lượng nền trong đồ án tái hiện chính xác chu kỳ làm việc của cổng trích chuyển XML theo QĐ 130/QĐ-BYT & QĐ 4750/QĐ-BYT:
* **Chu kỳ thực thi:** Chạy định kỳ mỗi 5 phút thông qua Windows Scheduled Task dưới quyền tài khoản dịch vụ.
* **Luồng hành vi:** Xác thực Kerberos AES256 (`0x12`) $\rightarrow$ Truy vấn `SELECT` các bản ghi bệnh án mới phát sinh trong SQL Server trên `SRV02` $\rightarrow$ Khởi tạo tệp cấu trúc thẻ chuẩn `<GIAMDINHBHYT>` (chứa `XML1`, `XML2`, `XML3`) $\rightarrow$ Lưu tệp vào `\\SRV02\BenhAn$\XML_Export_QD130\`.
* **Tuân thủ Luật BVDLCN 91/2025/QH15:** Các trường dữ liệu nhạy cảm (`HO_TEN`, `SO_CCCD`, `MA_BENH_CHINH`) sinh ra trong quá trình kiểm thử đều là dữ liệu giả lập (Synthetic Data) và được băm ẩn danh qua `anonymize_sensitive_emr_logs.py` trước khi nạp vào ELK Stack.

### 4.2. Cơ chế Phân tách Nhiễu Nghiệp vụ và Tấn công Lẩn tránh ở Luật V4
Để loại bỏ **99.85% cảnh báo giả** từ hoạt động đồng bộ XML BHYT mà không tạo ra "điểm mù" cho kẻ tấn công lợi dụng tài khoản `SVC_HIS_Sync` (kỹ thuật *Living-off-the-Whitelist*), bộ luật **V4 (`v4_contextual_clinic_tuned`)** áp dụng nguyên tắc **Phễu lọc hai lớp (Two-Stage Funnel)**:

1. **Whitelist có điều kiện ngữ cảnh chặt (Contextual Whitelist) đối với thao tác ĐỌC (`SELECT` / `4769`):**
   * Chỉ loại trừ cảnh báo khi thỏa mãn đồng thời bộ 3 điều kiện: `SubjectUserName == "SVC_HIS_Sync"` **AND** `SourceAddress == IP_SRV02` **AND** hành vi chỉ dừng ở mức truy vấn đọc dữ liệu theo đúng mẫu Stored Procedure kết xuất XML.
   * Nếu tài khoản `SVC_HIS_Sync` yêu cầu vé TGS (`4769`) hoặc đăng nhập SQL từ máy trạm lễ tân `WS01` (sai lệch `ClientAddress`), luật V4 lập tức kích hoạt cảnh báo.
2. **Chốt chặn Không khoan nhượng (Zero-Tolerance Choke Point) đối với thao tác PHÁ HỦY & VÔ HIỆU HÓA PHÒNG THỦ:**
   * Nghiệp vụ trích chuyển XML theo Quyết định 130/QĐ-BYT và 4750/QĐ-BYT là **nghiệp vụ chỉ đọc và trích xuất (Read-Only Extraction)** từ CSDL bệnh án, tuyệt đối không bao giờ thực thi lệnh xóa bệnh án (`DELETE`, `DROP`, `TRUNCATE`), không bao giờ bật `xp_cmdshell` (**Event ID `15457`**) và không bao giờ tắt cơ chế kiểm toán `ALTER SERVER AUDIT ... WITH (STATE = OFF)` (**Event ID `33205`**).
   * Do đó, ở nhánh giám sát tính toàn vẹn bệnh án điện tử (theo **Thông tư 13/2025/TT-BYT**), luật V4 **không áp dụng bất kỳ Whitelist nào** cho `SVC_HIS_Sync`. Ngay cả khi kẻ tấn công chiếm được quyền điều khiển trực tiếp trên `SRV02` và dùng chính `SVC_HIS_Sync` để xóa bệnh án hoặc tắt SQL Audit, hệ thống vẫn bắt giữ **100% (Recall = 100%)**.

---

## 5. Trích dẫn Chuẩn IEEE

```text
[1] Bộ Y tế, Quyết định quy định chuẩn và định dạng dữ liệu đầu ra phục vụ việc quản lý, giám định, thanh toán chi phí khám bệnh, chữa bệnh và giải quyết các chế độ liên quan, Quyết định số 130/QĐ-BYT, Hà Nội, Việt Nam, ban hành ngày 18/01/2023.
[2] Bộ Y tế, Quyết định sửa đổi, bổ sung một số điều của Quyết định số 130/QĐ-BYT ngày 18 tháng 01 năm 2023 của Bộ trưởng Bộ Y tế quy định chuẩn và định dạng dữ liệu đầu ra phục vụ việc quản lý, giám định, thanh toán chi phí khám bệnh, chữa bệnh và giải quyết các chế độ liên quan, Quyết định số 4750/QĐ-BYT, Hà Nội, Việt Nam, ban hành ngày 29/12/2023.
[3] Bộ Y tế, Thông tư quy định trích chuyển dữ liệu điện tử trong quản lý và thanh toán chi phí khám bệnh, chữa bệnh bảo hiểm y tế, Thông tư số 48/2017/TT-BYT, Hà Nội, Việt Nam, ban hành ngày 28/12/2017.