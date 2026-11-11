# Luật Bảo vệ Dữ liệu Cá nhân số 91/2025/QH15 & Nghị định 356/2025/NĐ-CP: Yêu cầu Kỹ thuật đối với Phòng khám Vừa và Nhỏ

> **Tài liệu Căn cứ Pháp lý & Đặc tả Kỹ thuật Bảo mật Dữ liệu Y tế**  
> **Đồ án Tốt nghiệp:** Phát triển giải pháp phát hiện tấn công lẩn tránh nhằm vào CSDL bệnh án trong môi trường Active Directory tại các phòng khám vừa và nhỏ  
> **Áp dụng cho phân hệ:** `01_clinic_lab_and_noise/log_anonymizer/anonymize_sensitive_emr_logs.py` và `03_siem_rules_v1_to_v4/v4_contextual_clinic_tuned/`

---

## 1. Thông tin Văn bản Pháp quy

| Thuộc tính | Luật Bảo vệ dữ liệu cá nhân 2025 | Nghị định hướng dẫn thi hành |
| :--- | :--- | :--- |
| **Cơ quan ban hành** | Quốc hội nước CHXHCN Việt Nam (Khóa XV) | Chính phủ nước CHXHCN Việt Nam |
| **Số hiệu văn bản** | Luật số `91/2025/QH15` | Nghị định số `356/2025/NĐ-CP` |
| **Ngày thông qua / Ban hành** | 26/06/2025 | 31/12/2025 |
| **Ngày có hiệu lực** | **01/01/2026** | **01/01/2026** (Thay thế Nghị định `13/2023/NĐ-CP`) |
| **Cơ quan quản lý chuyên ngành** | Bộ Công an (Cục An ninh mạng và phòng, chống tội phạm sử dụng công nghệ cao - **A05**) | Bộ Công an (Cổng thông tin quốc gia về BVDLCN: `baovedlcn.gov.vn`) |

---

## 2. Phân loại Dữ liệu & Phạm vi Áp dụng tại Phòng khám (~200 Nhân sự)

### 2.1. Phân loại Dữ liệu Cá nhân trong Hệ thống HIS/EMR (Điều 3 & Điều 4 Nghị định 356/2025/NĐ-CP)
Trong cơ sở dữ liệu bệnh án điện tử trên máy chủ `SRV02` (`HoSoBenhAn`) và hệ thống định danh Active Directory trên `DC01`, dữ liệu được chia thành hai nhóm chịu sự điều chỉnh nghiêm ngặt:

* **Dữ liệu cá nhân nhạy cảm (Sensitive Personal Data):**
  * Toàn bộ thông tin về **tình trạng sức khỏe, lịch sử khám chữa bệnh, chẩn đoán bệnh (Mã ICD-10), kết quả xét nghiệm (LIS), chẩn đoán hình ảnh (PACS)** và đời tư được ghi trong hồ sơ bệnh án điện tử.
  * Dữ liệu sinh trắc học, dữ liệu di truyền, hình ảnh thẻ Căn cước/CCCD và thông tin định danh tài khoản VNeID của bệnh nhân và nhân viên y tế.
* **Dữ liệu cá nhân cơ bản (Basic Personal Data):**
  * Họ và tên (`HO_TEN`), ngày tháng năm sinh, giới tính, địa chỉ cư trú, số điện thoại, **Số định danh cá nhân (`SO_CCCD`)**, mã số thẻ Bảo hiểm y tế (`MA_THE_BHYT`), và thông tin về mối quan hệ gia đình (vợ/chồng, cha/mẹ, con).

### 2.2. Bác bỏ Miễn trừ đối với Doanh nghiệp Vừa và Nhỏ trong Lĩnh vực Y tế
* Theo tiêu chí tại Nghị định `80/2021/NĐ-CP`, cơ sở y tế tư nhân có quy mô **~200 nhân sự** thuộc nhóm **Doanh nghiệp quy mô vừa** (vượt ngưỡng 100 lao động của doanh nghiệp nhỏ).
* Quan trọng hơn, theo **Luật số 91/2025/QH15** và **Nghị định 356/2025/NĐ-CP**, mọi quy định miễn trừ hoặc ân hạn dành cho doanh nghiệp nhỏ/khởi nghiệp **hoàn toàn KHÔNG áp dụng** đối với các tổ chức trực tiếp xử lý **Dữ liệu cá nhân nhạy cảm** (dữ liệu sức khỏe/bệnh án) hoặc xử lý dữ liệu của trên 100.000 chủ thể dữ liệu.
* **Hệ quả pháp lý:** Phòng khám bắt buộc phải tuân thủ 100% các biện pháp bảo vệ kỹ thuật, bổ nhiệm Nhân sự/Bộ phận Bảo vệ dữ liệu cá nhân (DPO) đáp ứng tiêu chuẩn tại Điều 13 Nghị định 356/2025/NĐ-CP, nộp Hồ sơ Đánh giá tác động xử lý dữ liệu cá nhân (DPIA) lên Cục A05 trong vòng 60 ngày, và chịu mức chế tài xử phạt hành chính rất nặng (lên tới 3 tỷ VNĐ hoặc phạt theo tỷ lệ doanh thu/lợi nhuận bất hợp pháp) nếu để xảy ra rò rỉ dữ liệu bệnh án.

---

## 3. Ánh xạ Yêu cầu Pháp lý sang Giải pháp Kỹ thuật trong Đồ án

Đồ án chuyển hóa trực tiếp 3 yêu cầu pháp lý cốt lõi của Luật số 91/2025/QH15 và Nghị định 356/2025/NĐ-CP thành các thành phần kỹ thuật trong kho mã nguồn:

| Yêu cầu Pháp lý (Luật 91/2025 & NĐ 356/2025) | Thách thức Thực tiễn tại Phòng khám | Giải pháp Kỹ thuật Triển khai trong Đồ án |
| :--- | :--- | :--- |
| **1. Nghĩa vụ Thông báo Vi phạm trong 72 giờ (72-Hour Breach Notification)**<br>Khi xảy ra hành vi truy cập, trích xuất hoặc xóa trái phép dữ liệu cá nhân nhạy cảm, đơn vị phải lập hồ sơ báo cáo gửi Cục A05 (Bộ Công an) chậm nhất **72 giờ** sau khi xảy ra vi phạm. | Đội ngũ IT mỏng (2–3 người) không trực 24/7; nếu dùng luật SIEM mở rộng (V2) sẽ bị ngập trong >5.000 cảnh báo giả (Alert Fatigue), hoặc nếu dùng AI/ML hộp đen (Black-box Anomaly Score) thì không trích xuất được bằng chứng định danh - hành vi cụ thể để lập biên bản pháp lý. | **Thiết kế Luật Hộp trắng (100% White-box Deterministic Rules - V4):**<br>• Triệt tiêu 99,85% cảnh báo giả để IT rà soát hết trong **30 phút đầu giờ sáng (Morning Review)**.<br>• Cung cấp đầy đủ ngữ cảnh pháp lý trong từng Alert: *Ai* (`SVC_HIS_SQL`), *Từ máy nào* (`ClientAddress: WS01`), *Lúc nào* (`@timestamp`), *Vi phạm gì* (Tắt Audit `33205` / Đọc trộm bảng `HoSoBenhAn`). |
| **2. Nguyên tắc Khử nhận dạng & Mã hóa Dữ liệu Nhạy cảm**<br>Dữ liệu sức khỏe khi lưu trữ, truyền đưa hoặc phục vụ phân tích kỹ thuật phải áp dụng biện pháp mã hóa, băm (Hashing) hoặc khử nhận dạng (De-identification) để ngăn chặn rò rỉ thứ cấp. | Khi bật SQL Server Audit (**Event ID `33205`**) để bắt truy vấn `SELECT`/`DELETE` trái phép trên bảng bệnh án, trường `statement` hoặc dữ liệu đính kèm trong tệp `.evtx` có nguy cơ lưu lại thông tin thật của bệnh nhân (Họ tên, CCCD, Chẩn đoán bệnh), biến máy chủ SIEM thành điểm rò rỉ dữ liệu mới. | **Xây dựng Module Ẩn danh hóa Log (`anonymize_sensitive_emr_logs.py`):**<br>• Tự động quét và băm một chiều (SHA-256 kèm Salt) hoặc che mặt nạ (Masking) đối với các trường PII/PHI (`SO_CCCD`, `HO_TEN`, `MA_THE_BHYT`, `CHAN_DOAN`) trước khi đẩy log `.evtx` vào Elastic Stack.<br>• Giữ nguyên vẹn các trường định danh hệ thống (`EventID`, `SubjectUserName`, `ClientAddress`, `ObjectName`) để không làm giảm độ chính xác (Recall) của luật SIEM. |
| **3. Kiểm soát Truy cập theo Phân quyền (RBAC) & Lưu vết Kiểm toán**<br>Bắt buộc kiểm soát chặt chẽ quyền truy cập của nhân viên y tế (Điều 25 Luật 91/2025) và lưu nhật ký hệ thống phục vụ thanh tra, điều tra sự cố. | Tài khoản dịch vụ `SVC_HIS_SQL` có quyền đọc/ghi toàn bộ bảng bệnh án để phục vụ phần mềm HIS. Kẻ tấn công chiếm tài khoản này qua **Kerberoasting OpSec AES (`0x12`)** để vượt qua cơ chế phân quyền của CSDL. | **Giám sát Tương quan Liên tầng (Cross-Layer Detection):**<br>• Kết hợp nhật ký xin vé Kerberos tại tầng AD (**Event ID `4769`**) với nhật ký thay đổi cấu hình/truy xuất CSDL tại tầng SQL Server (**Event ID `15457` & `33205`**).<br>• Đặt chốt chặn Zero-Tolerance đối với mọi hành vi tắt Audit hoặc xóa bản ghi bệnh án. |

---

## 4. Đặc tả Kỹ thuật cho Script Ẩn danh hóa (`anonymize_sensitive_emr_logs.py`)

Để đảm bảo tập dữ liệu thực nghiệm (`04_evaluation_and_datasets/evtx_master_datasets/`) tuân thủ tuyệt đối Luật số 91/2025/QH15 khi chia sẻ phục vụ nghiên cứu học thuật, script `anonymize_sensitive_emr_logs.py` thực thi quy trình xử lý trên các bản ghi sự kiện theo quy tắc sau:

1. **Các trường BẮT BUỘC ẨN DANH HÓA (Sensitive PII/PHI Fields):**
   * **Số Căn cước / Định danh cá nhân (`SO_CCCD` - 12 chữ số):** Thay thế bằng chuỗi băm định danh nhất quán `REDACTED_CCCD_<SHA256_8_CHARS>` (giúp bảo toàn tính liên kết bản ghi trong thống kê nhưng không thể dịch ngược).
   * **Mã thẻ BHYT (`MA_THE_BHYT` - 15 ký tự):** Che mặt nạ giữ lại 2 ký tự đầu (mã đối tượng) và băm phần số định danh: `DN4************`.
   * **Họ và tên Bệnh nhân (`HO_TEN_BN`) & Chẩn đoán lâm sàng chi tiết (`CHAN_DOAN_TEXT`):** Khử nhận dạng thành `PATIENT_ANON_<ID>` và chỉ giữ lại nhóm mã bệnh tổng quát nếu cần thiết.
2. **Các trường BẮT BUỘC GIỮ NGUYÊN (Security Telemetry Invariants):**
   * Giữ nguyên 100% các trường phục vụ logic phát hiện của bộ luật Sigma/KQL V1–V4: `EventID` (`1644`, `4624`, `4625`, `4769`, `15457`, `33205`), `TimeCreated`, `Computer` (`DC01`, `SRV02`, `WS01`), `TargetUserName` / `SubjectUserName` (định danh nhân viên giả lập như `BS_NguyenVanA`, `LT_TranThiB`, `SVC_HIS_SQL`), `IpAddress`, `TicketEncryptionType` (`0x12`, `0x17`), `ServiceName`, và cấu trúc cú pháp lệnh SQL (`SELECT`, `DELETE`, `ALTER SERVER AUDIT`, `sp_configure`).

---

## 5. Trích dẫn Chuẩn IEEE

```text
[1] Quốc hội nước Cộng hòa xã hội chủ nghĩa Việt Nam, Luật Bảo vệ dữ liệu cá nhân, Luật số 91/2025/QH15, thông qua ngày 26 tháng 06 năm 2025, có hiệu lực từ ngày 01 tháng 01 năm 2026.
[2] Chính phủ nước Cộng hòa xã hội chủ nghĩa Việt Nam, Nghị định quy định chi tiết một số điều và biện pháp thi hành Luật Bảo vệ dữ liệu cá nhân, Nghị định số 356/2025/NĐ-CP, ban hành ngày 31 tháng 12 năm 2025, có hiệu lực từ ngày 01 tháng 01 năm 2026.
[3] Quốc hội nước Cộng hòa xã hội chủ nghĩa Việt Nam, Luật Dữ liệu, Luật số 60/2024/QH15, thông qua ngày 30 tháng 11 năm 2024, có hiệu lực từ ngày 01 tháng 07 năm 2025.
[4] Bộ Thông tin và Truyền thông, Thông tư quy định chi tiết và hướng dẫn một số điều của Nghị định số 85/2016/NĐ-CP ngày 01/7/2016 của Chính phủ về bảo đảm an toàn hệ thống thông tin theo cấp độ, Thông tư số 12/2022/TT-BTTTT, ban hành ngày 12 tháng 08 năm 2022.