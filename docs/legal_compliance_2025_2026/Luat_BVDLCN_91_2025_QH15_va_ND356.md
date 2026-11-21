# Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15 và Nghị định 356/2025/NĐ-CP

Căn cứ pháp lý và ánh xạ sang giải pháp kỹ thuật trong đồ án.
Áp dụng cho: `01_clinic_lab_and_noise/log_anonymizer/anonymize_sensitive_emr_logs.py` và `03_siem_rules_v1_to_v4/v4_contextual_clinic_tuned/`.

## 1. Thông tin văn bản

| Thuộc tính | Luật Bảo vệ dữ liệu cá nhân | Nghị định hướng dẫn |
| --- | --- | --- |
| Cơ quan ban hành | Quốc hội khóa XV | Chính phủ |
| Số hiệu | 91/2025/QH15 | 356/2025/NĐ-CP |
| Ngày thông qua / ban hành | 26/06/2025 (kỳ họp thứ 9) | 31/12/2025 |
| Người ký | Chủ tịch Quốc hội Trần Thanh Mẫn | Phó Thủ tướng Nguyễn Hòa Bình |
| Hiệu lực | 01/01/2026 | 01/01/2026 (thay thế Nghị định 13/2023/NĐ-CP) |
| Bố cục | 5 Chương, 39 Điều | 5 Chương, 42 Điều, 1 Phụ lục (10 hồ sơ, biểu mẫu) |
| Cơ quan quản lý | Bộ Công an (A05) | Cổng thông tin quốc gia về BVDLCN: baovedlcn.gov.vn |

## 2. Phân loại dữ liệu và phạm vi áp dụng tại phòng khám

Trong CSDL bệnh án trên `SRV02` (bảng `HoSoBenhAn`) và hệ thống định danh Active Directory trên `DC01`, dữ liệu chia làm hai nhóm theo Điều 3 và Điều 4 Nghị định 356/2025/NĐ-CP:

- Dữ liệu cá nhân nhạy cảm: tình trạng sức khỏe, lịch sử khám chữa bệnh, chẩn đoán (mã ICD-10), kết quả xét nghiệm (LIS), chẩn đoán hình ảnh (PACS), dữ liệu sinh trắc học, di truyền, ảnh thẻ CCCD và thông tin định danh VNeID của bệnh nhân lẫn nhân viên y tế.
- Dữ liệu cá nhân cơ bản: họ tên, ngày sinh, giới tính, địa chỉ, số điện thoại, số định danh cá nhân (CCCD), mã thẻ BHYT, quan hệ gia đình.

Lưu ý: theo Luật 91/2025 và Nghị định 356/2025, mọi miễn trừ hay ân hạn dành cho doanh nghiệp nhỏ và khởi nghiệp không áp dụng cho tổ chức trực tiếp xử lý dữ liệu cá nhân nhạy cảm (dữ liệu sức khỏe) hoặc xử lý dữ liệu của trên 100.000 chủ thể. Phòng khám xử lý bệnh án nên phải tuân thủ đầy đủ ngay từ đầu: bổ nhiệm nhân sự hoặc bộ phận bảo vệ dữ liệu (DPO,,Điều 13 Nghị định 356), nộp hồ sơ đánh giá tác động xử lý dữ liệu (DPIA) lên A05, và bảo vệ kỹ thuật cho dữ liệu nhạy cảm.

### Về mức phạt

Luật 91/2025/QH15 đặt trần phạt tiền tối đa 3 tỷ đồng cho các hành vi vi phạm hành chính khác trong lĩnh vực này. Nhưng khung chế tài chi tiết không nằm trong Luật hay Nghị định 356, mà nằm ở Nghị định 330/2026/NĐ-CP ngày 19/08/2026 quy định xử phạt vi phạm hành chính trong lĩnh vực an ninh mạng và bảo vệ dữ liệu cá nhân. 
Vậy nói đúng là: Luật quy định quyền và nghĩa vụ, Nghị định 356/2025 hướng dẫn tuân thủ, Nghị định 330/2026 quy định chế tài. Các con số kiểu "5% doanh thu" hay "gấp 10 lần khoản thu bất chính" chưa kiểm tra kĩ trong Nghị định 330/2026, không gán cho Luật 91 hay Nghị định 356.

## 3. Ánh xạ yêu cầu pháp lý sang kỹ thuật trong đồ án

| Yêu cầu pháp lý | Thách thức tại phòng khám | Giải pháp trong đồ án |
| --- | --- | --- |
| Thông báo vi phạm cho A05 trong thời hạn luật định khi có truy cập, trích xuất hoặc xóa trái phép dữ liệu nhạy cảm | IT mỏng 2 đến 3 người, không trực 24/7; luật SIEM nới lỏng (V2) sinh quá nhiều cảnh báo giả, còn AI hộp đen thì không cho bằng chứng định danh để lập biên bản | Luật hộp trắng tất định (V4): mỗi cảnh báo nêu rõ ai (SubjectUserName), từ máy nào (ClientAddress), lúc nào (timestamp), vi phạm gì (tắt Audit 33205 hoặc đọc trộm bảng HoSoBenhAn) |
| Khử nhận dạng và bảo vệ dữ liệu nhạy cảm khi lưu trữ, truyền đưa, phân tích | Bật SQL Server Audit (Event ID 33205) để bắt SELECT/DELETE trái phép thì trường statement trong .evtx có thể lưu lại CCCD, họ tên, chẩn đoán thật, biến SIEM thành điểm rò rỉ mới | Module `anonymize_sensitive_emr_logs.py`: băm một chiều (SHA-256 kèm salt) hoặc che mặt nạ các trường PII/PHI (SO_CCCD, HO_TEN, MA_THE_BHYT, CHAN_DOAN) trước khi nạp vào ELK, giữ nguyên các trường phục vụ logic phát hiện |
| Kiểm soát truy cập theo phân quyền và lưu vết kiểm toán (Điều 25 Luật 91/2025) | Tài khoản `SVC_HIS_Database` có quyền đọc ghi toàn bộ bảng bệnh án; kẻ tấn công chiếm nó qua Kerberoasting để vượt phân quyền CSDL | Giám sát tương quan liên tầng: ghép vé Kerberos tầng AD (4769) với thay đổi cấu hình, truy xuất CSDL tầng SQL (15457, 33205), đặt chốt chặn với hành vi tắt Audit hoặc xóa bệnh án |

Lưu ý về số liệu: con số giảm cảnh báo giả (ví dụ 99,85%) và số cảnh báo nền (ví dụ vài nghìn sự kiện) hiện là minh họa dự kiến. Số thật sẽ điền sau khi chạy replay và đếm TP/FP/FN.

## 4. Nguồn tra cứu

- Luật 91/2025/QH15 (TVPL): https://thuvienphapluat.vn/van-ban/Cong-nghe-thong-tin/Luat-Bao-ve-du-lieu-ca-nhan-2025-91-2025-QH15-625628.aspx
- Nghị định 356/2025/NĐ-CP (TVPL): https://thuvienphapluat.vn/van-ban/Quyen-dan-su/Nghi-dinh-356-2025-ND-CP-huong-dan-Luat-Bao-ve-du-lieu-ca-nhan-687428.aspx
- Nghị định 356 bản gốc (Bộ Tư pháp): https://vbpl.moj.gov.vn/TW/Lists/vbpq/Attachments/187276/ND.356.2025.doc
- Nghị định 330/2026/NĐ-CP (bản tin EY tóm tắt): https://www.ey.com/vi_vn/technical/tax/tax-and-law-updates

## 5. Trích dẫn (IEEE)

```text
[1] Quốc hội, "Luật Bảo vệ dữ liệu cá nhân," Luật số 91/2025/QH15, Hà Nội, Việt Nam, ngày 26/06/2025, hiệu lực 01/01/2026.
[2] Chính phủ, "Nghị định quy định chi tiết một số điều và biện pháp thi hành Luật Bảo vệ dữ liệu cá nhân," Nghị định số 356/2025/NĐ-CP, Hà Nội, Việt Nam, ngày 31/12/2025, hiệu lực 01/01/2026.
[3] Chính phủ, "Nghị định quy định xử phạt vi phạm hành chính trong lĩnh vực an ninh mạng và bảo vệ dữ liệu cá nhân," Nghị định số 330/2026/NĐ-CP, Hà Nội, Việt Nam, ngày 19/08/2026.
```