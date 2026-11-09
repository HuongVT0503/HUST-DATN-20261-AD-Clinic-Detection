# Phát triển giải pháp phát hiện tấn công lẩn tránh nhằm vào CSDL bệnh án trong môi trường Active Directory tại các phòng khám vừa và nhỏ



> **Đồ án Tốt nghiệp Hệ Cử nhân - Kỳ 2026.1**  
> **Trường Công nghệ Thông tin và Truyền thông - Đại học Bách khoa Hà Nội**

---

## Thông tin chung

| Thông tin | Chi tiết |
| :--- | :--- |
| **Sinh viên thực hiện** | Vũ Thúy Hường - MSSV: `20225135` |
| **Lớp / Khóa** | Kỹ thuật máy tính 01 - K67 |
| **Email liên hệ** | `Huong.VT225135@sis.hust.edu.vn` |
| **Giảng viên hướng dẫn** | PGS. TS. Nguyễn Thị Hoàng Lan |
| **Lĩnh vực đề tài** | An toàn không gian số; Phần mềm doanh nghiệp |

---

## Đặt vấn đề

### 1. Hoàn cảnh thực tiễn
Để triển khai Hồ sơ bệnh án điện tử (EMR) với hạn cuối là ngày 31/12/2026 theo **Thông tư 13/2025/TT-BYT**, và tuân thủ quy định bảo vệ dữ liệu sức khỏe theo **Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15** và **Nghị định 356/2025/NĐ-CP** (hiệu lực từ 01/01/2026), các phòng khám quy mô vừa và nhỏ (~200 nhân sự) thường sử dụng **Microsoft Active Directory (AD)** để quản lý tập trung định danh y bác sĩ và kiểm soát quyền truy cập vào cơ sở dữ liệu bệnh án (HIS/EMR).

Các phòng khám này có vấn đề bảo mật sau:
* **Nhân sự CNTT quá ít:** Thường chỉ có 2–3 nhân viên IT kiêm nhiệm, làm việc theo giờ hành chính, không có đội ngũ trực giám sát an ninh mạng (SOC) 24/7.
* **Không phát hiện tấn công lẩn tránh (Evasion):** Các bộ luật giám sát mặc định (Out-of-the-Box) thường chỉ phát hiện tấn công dựa trên các chữ ký công cụ tĩnh. Kẻ tấn công dễ lẩn tránh việc bị phát hiện bằng cách làm chậm tốc độ dò quét, hạ cấp/thay đổi thuật toán mã hóa khi tấn công, hoặc lạm dụng chính các công cụ quản trị hợp lệ để đọc/sửa/xóa bệnh án.
* **Quá tải cảnh báo giả (Alert Fatigue):** Khi nhân sự IT nới lỏng điều kiện bắt của luật giám sát để phát hiện các hành vi lẩn tránh nói trên một cách thô sơ, hệ thống sẽ bắt nhầm các hoạt động nghiệp vụ y tế đặc thù (y bác sĩ đăng nhập đổi ca trên máy trạm dùng chung, phần mềm HIS tự động truy vấn CSDL và xuất tệp XML bảo hiểm y tế định kỳ...). Chính những nhân sự IT đó sẽ phải xử lí rất nhiều cảnh báo giả, làm giảm khả năng rà soát, có thể dẫn đến bỏ sót các cuộc tấn công thật sự.

### 2. Giải pháp của Đồ án
Đồ án giải quyết mâu thuẫn giữa **khả năng phát hiện tấn công lẩn tránh (Recall)** và **kiểm soát số lượng cảnh báo giả (Precision)** thông qua phương pháp kiểm thử tất định (Deterministic Log Replay) trên tập nhật ký tĩnh (`.evtx`) và tinh chỉnh bộ luật phát hiện qua 4 phiên bản (**V1 $\rightarrow$ V2 $\rightarrow$ V3 $\rightarrow$ V4**). Giải pháp kết hợp việc lập hồ sơ hành vi (Sliding Window Threshold), giám sát liên tầng (Active Directory + SQL Server Audit) và lọc ngoại lệ theo ngữ cảnh nghiệp vụ y tế, giúp nhân sự IT phòng khám bảo đảm an toàn cho hệ thống mà chỉ cần bỏ ra một khoảng thời gian ngắn đầu các buổi làm việc để rà soát một số lượng nhỏ cảnh báo có độ tin cậy cao.

---

## Sơ đồ Kiến trúc Tổng thể

Sơ đồ minh họa luồng liên kết giữa **3 phần** của đồ án:

```text
+======================================================================================+
|       PHẦN 1: MÔI TRƯỜNG MÔ PHỎNG PHÒNG KHÁM & SINH NHIỄU (01_clinic_lab_and_noise)  |
+======================================================================================+
|                                                                                      |
|  [ Hạ tầng GOAD-Light tùy biến (3 nút) ]        [ Bộ script sinh nhiễu y tế (PowerShell) ]  |
|  + DC01 : Quản lý 200 định danh nhân sự  <===>  + Giao ca (7h, 12h, 17h) -> ID 4624  |
|  + SRV02: Máy chủ HIS (MSSQL + BenhAn$)         + Đồng bộ XML BHYT (QĐ 130/4750)     |
|  + WS01 : Máy trạm phòng khám (Client)          + Bác sĩ tra cứu bệnh án lẻ (SMB/SQL)|
|                                                                                      |
+======================================================================================+
                                           |
                                           | (Chạy song song Lưu lượng nền & tấn công)
                                           v
+======================================================================================+
|      PHẦN 2: KỊCH BẢN TẤN CÔNG LẨN TRÁNH & THU THẬP LOG (02_telemetry_and_scenarios) |
+======================================================================================+
|                                                                                      |
|  [ 3 kịch bản tấn công lẩn tránh (WSL2) ]       [ Thu thập & ẩn danh hóa nhật ký /log ]   |
|  1. Dò quét AD & SPN chậm qua ADSI       ====>  + Windows Security (4624, 4625, 4769)|
|  2. Kerberoasting: RC4 0x17 vs AES 0x12         + Directory Service (1644) & Sysmon  |
|  3. Chiếm SVC đọc/xóa DB, tắt SQL Audit         + SQL Server Audit (33205, 15457)    |
|                                                 + Ẩn danh hóa (Luật BVDLCN 2025)     |
|                                                                                      |
+======================================================================================+
                                           |
                                           | (Trích xuất Master Dataset tĩnh: *.evtx)
                                           v
+======================================================================================+
|       PHẦN 3: TINH CHỈNH LUẬT SIEM V1-V4 & ĐÁNH GIÁ (03_siem_rules & 04_evaluation)  |
+======================================================================================+
|                                                                                      |
|  [ ELK Stack Offline (WSL2 Docker) ]            [ Đo lường & viết tài liệu hướng dẫn vận hành ]     |
|  • V1 (Mặc định) : Bỏ lọt lẩn tránh      ====>  + Tính Confusion Matrix (TP, FP, FN) |
|  • V2 (Nới lỏng) : Bùng nổ FP                   + Vẽ đồ thị Precision-Recall V1->V4  |
|  • V3 (Threshold): Lọc cửa sổ trượt             + Giảm phần lớn cảnh báo giả         |
|  • V4 (Ngữ cảnh) : Whitelist HIS + TT13         + Playbook rà soát 30 phút đầu giờ   |
|                                                                                      |
+======================================================================================+
```

---

## Cấu trúc mã nguồn (Repository Structure)

Thư mục mã nguồn gồm 4 thư mục thực thi và 1 thư mục tài liệu:

```text
HUST-DATN-20261-AD-Clinic-Detection/
├── 01_clinic_lab_and_noise/                  # [PHẦN 1] Hạ tầng phòng khám 200 users, HIS DB & script sinh nhiễu
│   ├── iac_goad_light_custom/                # Cấu hình IaC triển khai 3 máy ảo: DC01, SRV02 (HIS/MSSQL), WS01
│   ├── ad_identity_200_users/                # Danh sách CSV & script khởi tạo 200 nhân sự y tế + Service Accounts
│   ├── his_mssql_database/                   # Schema CSDL bệnh án, SMB Share và cấu hình SQL Audit (Event 33205)
│   ├── business_noise_generators/            # Script PowerShell giả lập giao ca trực & đồng bộ XML BHYT định kỳ
│   └── log_anonymizer/                       # Script Python ẩn danh hóa dữ liệu nhạy cảm trước khi nạp SIEM
│
├── 02_telemetry_and_scenarios/               # [PHẦN 2] Cấu hình thu thập Log & 3 kịch bản kiểm thử lẩn tránh
│   ├── telemetry_configs/                    # Cấu hình Sysmon, Registry bật LDAP 1644 và Winlogbeat replay
│   ├── scenario_01_adsi_slow_recon/          # Kịch bản 1: BloodHound mặc định vs Dò quét chậm qua ADSI
│   ├── scenario_02_kerberoast_opsec/         # Kịch bản 2: Kerberoasting hạ cấp RC4 (0x17) vs OpSec AES256 (0x12)
│   └── scenario_03_his_db_tampering/         # Kịch bản 3: Chiếm quyền SVC đọc/xóa bệnh án, bật xp_cmdshell, tắt Audit
│
├── 03_siem_rules_v1_to_v4/                   # [PHẦN 3A] SIEM Offline & Bộ luật Sigma/KQL từ V1 đến V4 & Playbook
│   ├── elk_docker_wsl2/                      # Docker Compose ELK Single-node
│   ├── v1_default_ootb/                      # Luật V1: Mặc định (Out-of-the-Box) dựa trên chữ ký tĩnh
│   ├── v2_widened_evasion/                   # Luật V2: Nới lỏng điều kiện để bắt kỹ thuật lẩn tránh
│   ├── v3_threshold_sliding_window/          # Luật V3: Tinh chỉnh ngưỡng thời gian (Sliding Window) & tần suất
│   ├── v4_contextual_clinic_tuned/           # Luật V4: Tối ưu ngữ cảnh y tế & ràng buộc pháp lý Thông tư 13/2025
│   ├── kql_queries/                          # Các truy vấn KQL/EQL đóng gói sẵn để import vào Kibana
│   └── tuning_playbook/                      # Hướng dẫn vận hành & kiếm tra cảnh báo 30 phút đầu giờ cho IT phòng khám
│
├── 04_evaluation_and_datasets/               # [PHẦN 3B] Tập dữ liệu .evtx chuẩn & công cụ đo lường thực nghiệm
│   ├── evtx_master_datasets/                 # Các tệp log mẫu (.evtx) đã gán nhãn thời gian và ẩn danh hóa
│   ├── alerts_exported_csv/                  # Kết quả cảnh báo xuất từ SIEM qua 4 vòng lặp V1 -> V4
│   ├── notebooks_and_scripts/                # Script Python/Jupyter tính Confusion Matrix & vẽ đồ thị Precision-Recall
│   └── figures/                              # Biểu đồ thực nghiệm
│
└── docs/                                     # Tài liệu căn cứ pháp lý (2025-2026), trích dẫn học thuật & Playbook
    ├── legal_compliance_2025_2026/           # Tóm tắt yêu cầu kỹ thuật từ luật BVDLCN 2025, NĐ 356, TT 13/2025/TT-BYT
    └── academic_references/                  # Cơ sở lý thuyết: Base-Rate Fallacy (Axelsson, 1999) & Alert Granularity

```

---

## Checklist 

### 
- [ ] tổng hợp văn bản căn cứ pháp lý (`Luật BVDLCN 91/2025/QH15`, `Nghị định 356/2025/NĐ-CP`, `Thông tư 13/2025/TT-BYT`, `QĐ 130 & 4750/QĐ-BYT`) vào thư mục `docs/legal_compliance_2025_2026/`.

### tạo danh mục 200 định danh y tế & lược đồ CSDL bệnh án (Phần 1A)
- [ ]  `clinic_200_staff_identities.csv` và  `Import-ClinicADUsers.ps1` (phân chia rõ các nhóm OU: Bác sĩ, Y tá, Lễ tân, Hành chính, và tài khoản dịch vụ `SVC_HIS_Database`, `SVC_HIS_Sync`).
- [ ] `Init_HIS_EMR_Schema.sql` khởi tạo bảng hồ sơ bệnh án điện tử giả lập; `Configure_SQL_Server_Audit_33205.sql` để ghi vết các thao tác `SELECT`, `UPDATE`, `DELETE` vào Windows Application Log.

### tạo Bộ Script Sinh Nhiễu Nghiệp vụ Phòng khám (Phần 1B)
- [ ] `Invoke-DoctorShiftChange_4624_4625.ps1` mô phỏng y bác sĩ đăng nhập/đăng xuất vào giờ giao ca (7h, 12h, 17h) kèm tỷ lệ 5% gõ sai mật khẩu.
- [ ] `Invoke-HISXmlSync_QD130_QD4750.ps1` mô phỏng tk dịch vụ truy vấn CSDL và trích xuất tệp XML BHYT 5 phút/lần qua SMB Share `\\SRV02\BenhAn$`.
- [ ] `anonymize_sensitive_emr_logs.py` để băm/ẩn danh hóa trường thông tin nhạy cảm của bệnh nhân trong log trước khi đưa vào SIEM.

### 3 kịch bản tấn công lẩn tránh & cấu hình Telemetry (Phần 2)
- [ ] Cấu hình `Enable-LDAP-1644-Diagnostics.reg` trên Domain Controller và `sysmon_clinic_config.xml` trên máy chủ HIS.
- [ ] Kịch bản 1 (Dò quét AD/SPN chậm qua ADSI) và Kịch bản 2 (Kerberoasting so sánh hạ cấp mã hóa RC4 `0x17` với OpSec AES256 `0x12`).
- [ ] Kịch bản 3 (Lạm dụng tài khoản dịch vụ HIS để đọc/xóa trái phép bảng bệnh án, bật `xp_cmdshell` sinh Event `15457` và tắt SQL Audit sinh Event `33205`).

### thiết lập SIEM Offline (WSL2 Docker) & viết bộ luật Sigma V1 – V4 (Phần 3A)
- [ ] Cấu hình `docker-compose.yml` cho Elastic Stack Single-node trên WSL2 với giới hạn bộ nhớ `ES_JAVA_OPTS="-Xms1536m -Xmx1536m"`  (laptop 8GB RAM.)
- [ ] 4 phiên bản luật Sigma (`.yml`) và truy vấn KQL cho cả 3 kịch bản từ `v1_default_ootb` đến `v4_contextual_clinic_tuned`.
- [ ] nạp thử nghiệm `.evtx` vào Kibana qua `winlogbeat_evtx_replay.yml`.

### tự động hóa đo lường & vẽ biểu đồ (Phần 3B)
- [ ] Hoàn thiện `calculate_confusion_matrix.py` tự động đọc dữ liệu từ `alerts_exported_csv/` và xuất bảng thống kê TP, FP, FN, Precision, Recall.
- [ ] Chạy script `plot_precision_recall_tradeoff.py` (sử dụng `matplotlib` và `seaborn`) để xuất biểu đồ so sánh sự sụt giảm cảnh báo giả từ V2 xuống V4 lưu vào `04_evaluation_and_datasets/figures/`.
- [ ] `Clinic_IT_Morning_Review_Playbook.md` hướng dẫn quy trình tune rule, kiếm tra cảnh báo cho nhân viên IT phòng khám.

###  demo
- [ ] chạy thử luồng demo 15 phút trên VS Code & trình duyệt (Kibana Dashboard + Jupyter Notebook hiển thị biểu đồ).

---

## Tách pha

Quy trình thực nghiệm tách pha thu thập dữ liệu và pha phân tích:

1. **Khi chỉ làm việc với mã nguồn và chạy script tạo biểu đồ Python:**
   ```bash
   cd ~/HUST-DATN-20261-AD-Clinic-Detection
   python3 -m venv .venv && source .venv/bin/activate
   pip install pandas matplotlib seaborn jupyter
   python3 04_evaluation_and_datasets/notebooks_and_scripts/plot_precision_recall_tradeoff.py
   ```
2. **Khi bật Elastic Stack (SIEM) trên WSL2 để nạp file `.evtx` và demo luật V1–V4:**
   ```bash
   cd ~/HUST-DATN-20261-AD-Clinic-Detection/03_siem_rules_v1_to_v4/elk_docker_wsl2
   docker compose up -d
   ```
3. **Giải phóng toàn bộ RAM (trên Windows PowerShell):**
   ```powershell
   wsl --shutdown
   ```

---

## Tài liệu Tham khảo & Căn cứ Pháp lý

1. **Quốc hội (2025)**, *Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15*, thông qua ngày 26/06/2025, có hiệu lực từ ngày 01/01/2026.
2. **Chính phủ (2025)**, *Nghị định số 356/2025/NĐ-CP quy định chi tiết một số điều và biện pháp thi hành Luật Bảo vệ dữ liệu cá nhân*, ban hành ngày 31/12/2025.
3. **Bộ Y tế (2025)**, *Thông tư số 13/2025/TT-BYT hướng dẫn triển khai hồ sơ bệnh án điện tử*, ban hành ngày 06/06/2025 (Quy định lộ trình hoàn thành triển khai bệnh án điện tử trước ngày 31/12/2026).
4. **Bộ Y tế (2023)**, *Quyết định số 130/QĐ-BYT và Quyết định số 4750/QĐ-BYT quy định chuẩn và định dạng dữ liệu đầu ra (XML) phục vụ quản lý, giám định và thanh toán chi phí khám chữa bệnh BHYT*.
5. **Axelsson, S. (1999)**, *"The Base-Rate Fallacy and the Difficulty of Intrusion Detection"*, ACM Transactions on Information and System Security (TISSEC).
6. **SigmaHQ & Orange Cyberdefense (2025)**, *Sigma Detection Format Specification & Game of Active Directory (GOAD-Light) Architecture*.