# Cẩm nang Tinh chỉnh Luật SIEM & Quy trình Rà soát Cảnh báo 30 Phút Đầu giờ (Morning Review Playbook)

> **Dành cho:** Bộ phận CNTT kiêm nhiệm (2–3 nhân sự) tại các Phòng khám Đa khoa & Bệnh viện quy mô vừa (~200 nhân sự)  
> **Căn cứ pháp lý:** Thông tư 13/2025/TT-BYT, Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15 và Nghị định 356/2025/NĐ-CP

---

## 1. Chiến lược Vận hành cho Đội ngũ IT Phòng khám Không có SOC 24/7

Tại các phòng khám tuyến quận/huyện hoặc phòng khám đa khoa tư nhân (~200 nhân sự), bộ phận CNTT chỉ làm việc giờ hành chính. Do đó, hệ thống cảnh báo trên SIEM được phân tách thành **2 luồng xử lý**:

| Phân nhóm Cảnh báo | Các Luật Kích hoạt (Bộ luật V4) | Cơ chế Phản ứng Tự động & Quy trình Xử lý |
| :--- | :--- | :--- |
| **Nhóm 1: Tối khẩn cấp (`CRITICAL` - Xâm phạm Bệnh án & Tắt Giám sát)** | - Tắt SQL Server Audit (`Event ID 33205: STATE = OFF`)<br>- Bật `xp_cmdshell` (`Event ID 15457`)<br>- Lệnh `DELETE` / `DROP` hoặc gỡ chữ ký số (`DaKySoTT13 = 0`) trên bảng `HoSoBenhAn`<br>- Hạ cấp mã hóa Kerberoasting `0x17` nhắm vào `SVC_HIS_Database` | **Kích hoạt ngay trong đêm:**<br>1. Gửi cảnh báo qua Telegram/SMS/Email cho IT trực.<br>2. Nếu phát hiện xâm phạm CSDL bệnh án, lập tức thu hồi phiên kết nối của tài khoản dịch vụ bị chiếm quyền.<br>3. Ghi nhận mốc thời gian để lập hồ sơ báo cáo Cục A05 (Bộ Công an) trong vòng **72 giờ** theo Luật BVDLCN 91/2025/QH15 nếu có rò rỉ dữ liệu nhạy cảm. |
| **Nhóm 2: Rà soát Đầu giờ Sáng (`HIGH/MEDIUM` - Morning Review 08:00 – 08:30)** | - Truy vấn LDAP nhạy cảm (`Event ID 1644` chứa `adminCount=1`, `servicePrincipalName=*`)<br>- Yêu cầu vé TGS `AES256 (0x12)` bất thường từ máy trạm lễ tân (`WS01`)<br>- Truy vấn `SELECT` vượt ngưỡng cửa sổ trượt trên `HoSoBenhAn` | **Rà soát trong 30 phút đầu giờ sáng:**<br>Nhờ bộ lọc ngữ cảnh V4 đã giảm phần lớn cảnh báo giả (số minh họa dự kiến, xem bảng ở docs/academic_references/Base_Rate_Fallacy_Axelsson1999.md; số thật điền sau replay), nhân viên IT chỉ mất 15–30 phút mỗi sáng để kiểm tra bảng tổng hợp Kibana. |

---

## 2. Quy trình 3 Bước Rà soát 30 Phút Đầu giờ Sáng (08:00 – 08:30)

### Bước 1 (08:00 – 08:10): Kiểm tra Tính toàn vẹn của CSDL Bệnh án & SQL Audit (`SC3_V4`)
1. Mở Kibana Saved Query **`SC3_V4_Tuned_HIS_EMR_Tampering_TT13`**.
2. Kiểm tra xem có bất kỳ bản ghi `Event ID 33205` nào chứa `STATE = OFF` hoặc `DELETE FROM dbo.HoSoBenhAn` trong 24 giờ qua không.
3. Đối chiếu với lịch bảo trì CSDL của phòng khám. Nếu không có lịch bảo trì được phê duyệt -> Cô lập máy trạm nguồn gửi lệnh `sqlcmd` và đổi mật khẩu tài khoản `SVC_HIS_Database`.

### Bước 2 (08:10 – 08:20): Kiểm tra An toàn Định danh Dịch vụ HIS (`SC2_V4`)
1. Mở Kibana Saved Query **`SC2_V4_Tuned_Kerberoast_OpSec_Clinic`**.
2. Kiểm tra trường `winlog.event_data.IpAddress` và `TargetUserName` yêu cầu vé TGS cho `SVC_HIS_Database`.
3. Nếu IP xuất phát từ máy trạm quầy lễ tân (`WS01`) kèm loại mã hóa `0x17` hoặc lặp lại liên tục ở `0x12` ngoài khung giờ khám bệnh -> Kiểm tra lịch sử đăng nhập ca trực (`Event ID 4624`) trên máy trạm đó.

### Bước 3 (08:20 – 08:30): Kiểm tra Hoạt động Dò quét Active Directory (`SC1_V4`)
1. Mở Kibana Saved Query **`SC1_V4_Tuned_LDAP_1644_Clinic`**.
2. Xem trường `LDAPFilter`. Nếu xuất hiện bộ lọc tìm kiếm `(servicePrincipalName=*)` hoặc `(adminCount=1)` từ một tài khoản bác sĩ/y tá (`BS_`, `YT_`, `LT_`) -> Tài khoản nhân viên y tế đó đã bị chiếm quyền để dò quét mạng nội bộ.

---

## 3. Hướng dẫn Áp dụng (Tuning Baseline 7 Ngày) cho Phòng khám Khác

Khi triển khai bộ luật V4 này cho một phòng khám sử dụng phần mềm HIS thương mại khác (ví dụ: Viettel HIS, VNPT-HIS, Medisoft):
1. **Ngày 1 – Ngày 7 (Thu thập Baseline):** Bật cấu hình Registry `1644` trên DC và `SQL Server Audit 33205` trên máy chủ DB.
2. **Xác định Định danh Dịch vụ:** Ghi nhận chính xác tên tài khoản chạy dịch vụ đồng bộ BHYT (tương ứng với `SVC_HIS_Sync`) và địa chỉ IP tĩnh của máy chủ ứng dụng HIS (tương ứng với `SRV02`).
3. **Cập nhật Khối `filter_clinic_whitelist`:** Điền tên tài khoản dịch vụ và IP máy chủ HIS vào mục `filter_` trong 3 tệp luật Sigma ở thư mục `v4_contextual_clinic_tuned/` để đạt hiệu quả giảm thiểu cảnh báo giả tương đương.