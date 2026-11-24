# Đặc tả Tập dữ liệu Nhật ký Chuẩn (`.evtx` Master Dataset Manifest)

> **Phương pháp luận:** Kiểm thử tất định thông qua phát lại nhật ký tĩnh (*Deterministic Log Replay*)  
> **Tổng quy mô mẫu chuẩn hóa:** `100,000` sự kiện (Trộn lẫn Lưu lượng nền Nghiệp vụ Phòng khám & 3 Kịch bản Tấn công Mặc định + Lẩn tránh)

---

## 1. Danh mục 3 Tệp Nhật ký `.evtx` Gốc Thu thập từ Hạ tầng AWS EC2 (3 VMs)

| Tên tệp trong `evtx_master_datasets/` | Máy chủ Nguồn | Kênh Nhật ký (Windows Event Channel) | Các Event ID Trọng tâm | Nội dung Lưu lượng Nền (Benign Noise) & Tấn công (Attack Ground Truth) |
| :--- | :--- | :--- | :--- | :--- |
| **`sample_dc01_directory_service_1644.evtx`** | `DC01.clinic.local` (`172.31.10.10`) | `Directory Service` | **1644** | - **Noise:** Truy vấn LDAP kiểm tra danh mục khoa phòng từ `SVC_HIS_Sync` và các máy trạm.<br>- **Attack (Scenario 1):** Chuỗi truy vấn ADSI Low-and-Slow chứa bộ lọc `(servicePrincipalName=*)`, `(adminCount=1)` và `(description=*Pass*)` từ `WS01`. |
| **`sample_dc01_security_4769_4624.evtx`** | `DC01.clinic.local` (`172.31.10.10`) | `Security` | **4624**, **4625**, **4769** | - **Noise:** 200 định danh Y bác sĩ, Điều dưỡng, Lễ tân đăng nhập đổi ca (95% `4624`, 5% gõ sai mật khẩu `4625`) và yêu cầu vé Kerberos TGS thông thường.<br>- **Attack (Scenario 2):** Yêu cầu vé TGS nhắm vào `MSSQLSvc/SRV02.clinic.local:1433` (`SVC_HIS_Database`) ở cả chế độ hạ cấp `RC4 0x17` và lẩn tránh `AES256 0x12`. |
| **`sample_srv02_application_sql_33205_15457.evtx`** | `SRV02.clinic.local` (`172.31.10.22`) | `Application` *(kèm đối chiếu SMB `5140/5145` & Sysmon `1`)* | **33205**, **15457** | - **Noise:** Bác sĩ tra cứu lẻ từng hồ sơ bệnh án (`SELECT ... WHERE MaBenhAn = ...`) và `SVC_HIS_Sync` đồng bộ XML BHYT theo QĐ 130/QĐ-BYT.<br>- **Attack (Scenario 3):** Lạm dụng `SVC_HIS_Database` bật `xp_cmdshell` (`15457`), tắt `Audit_BaoVeDuLieuBenhAn_TT13` (`33205: STATE = OFF`), đọc hàng loạt và `DELETE` bệnh án đã ký số (`DaKySoTT13 = 1`). |

---

## 2. Tuân thủ Quy định Ẩn danh hóa Dữ liệu Cá nhân Nhạy cảm (Luật 91/2025/QH15)

Toàn bộ dữ liệu nằm trong trường `statement` của `Event ID 33205` thuộc tập dữ liệu này là dữ liệu giả lập (Synthetic EMR Data) và đã được xử lý qua công cụ `01_clinic_lab_and_noise/log_anonymizer/anonymize_sensitive_emr_logs.py` để băm một chiều (SHA-256 + Salt) các trường `SoCCCD`, `MaTheBHYT` và `HoTen`, đảm bảo tuân thủ nghiêm ngặt **Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15** và **Nghị định 356/2025/NĐ-CP**.

## 3. Tập nhãn thời gian (Ground Truth Timestamps)

gán nhãn tĩnh cho .evtx dựa trên 2 file mốc thời gian thu cùng lúc với .evtx:

| File | Máy sinh | Nội dung | Dùng để gán nhãn |
| :--- | :--- | :--- | :--- |
| `ground_truth.csv` | WS01 | dòng `timestamp,scenario,phase` cho SC1-1A/1B, SC2-2A/2B (START/END mỗi pha) | khoảng thời gian tấn công của Kịch bản 1, 2 |
| `ground_truth_sql.log` | SRV02 | output sqlcmd chứa `SYSDATETIME()` của các pha P3/P2+P4/P5 | khoảng thời gian tấn công của Kịch bản 3 |

Quy ước: mọi cảnh báo rơi vào khoảng [START, END] của một pha tấn công -> gán True Positive (hoặc False Negative nếu luật bỏ lọt); cảnh báo ngoài các khoảng đó, sinh từ lưu lượng nền -> False Positive.