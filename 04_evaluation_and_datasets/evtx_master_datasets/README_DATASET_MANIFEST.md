# Đặc tả Tập dữ liệu `.evtx` (Master Dataset Manifest)

> Phương pháp: phát lại nhật ký tĩnh (Deterministic Log Replay).
> `.evtx` không nằm trong repo (bị `.gitignore`) -> phân phối qua **GitHub Release** (mục 4).

## 1. Danh mục `.evtx` (8 tệp, khớp AWS_EC2_3VM_DEPLOYMENT_GUIDE.md §8)

Xuất thiếu bất kỳ tệp nào dưới đây sẽ làm kịch bản tương ứng bị bỏ lọt tấn công oan (xem bảng Event ID -> log ở guide §11).

| Tệp | Máy | Kênh log | Event ID | Dùng cho |
| --- | --- | --- | --- | --- |
| `dc01_security_4769_4624_4625.evtx` | DC01 | Security | 4769, 4624, 4625 | SC2; nhiễu giao ca |
| `dc01_directory_service_1644.evtx` | DC01 | Directory Service | 1644 | SC1-1B (ADSI low-and-slow) |
| `dc01_sysmon.evtx` | DC01 | Sysmon/Operational | 1 | đối chiếu |
| `srv02_application_33205_15457.evtx` | SRV02 | Application | 33205, 15457 | SC3 (audit/xp_cmdshell) |
| `srv02_security_5140_5145.evtx` | SRV02 | Security | 5140, 5145 | truy cập SMB `BenhAn$` |
| `srv02_sysmon_sqlservr.evtx` | SRV02 | Sysmon/Operational | 1 | SC3-P3 (sqlservr->cmd) |
| `ws01_security.evtx` | WS01 | Security | 4624/4625 | đăng nhập máy trạm |
| `ws01_sysmon_setspn.evtx` | WS01 | Sysmon/Operational | 1 | SC1-1A (setspn/SharpHound) |

## 2. Ẩn danh hóa
Dữ liệu bệnh nhân là giả lập, bản phát hành công khai được che PII bằng `01_clinic_lab_and_noise/log_anonymizer/` (xem README ở thư mục đó. 2 cách: ES ingest pipeline khi nạp, script `.py` khi xuất file văn bản/chia sẻ).

## 3. Ground truth (gán nhãn thời gian)
| File | Máy | Nội dung | Gán nhãn |
| --- | --- | --- | --- |
| `ground_truth.csv` | WS01 | `timestamp,scenario,phase` (SC1/SC2, START/END) | khoảng tấn công SC1, SC2 |
| `ground_truth_sql.log` | SRV02 | output sqlcmd chứa `SYSDATETIME()` (P3/P2+P4/P5) | khoảng tấn công SC3 |

Quy ước: cảnh báo trong [START,END] một pha -> TP (hoặc FN nếu bỏ lọt); ngoài khoảng -> FP.

## 4. Phân phối dataset qua GitHub Release

**Vì sao Release (không Git LFS):** dataset tĩnh, sinh 1 lần, người đọc chỉ tải 1 lần để replay. Release giữ repo nhẹ, không tốn quota LFS, không yêu cầu người clone cài `git-lfs`.

### 4.1. Cách tải dataset về để replay
- Vào tab **Releases** của repo -> tải `clinic-evtx-dataset-v1.0.zip` -> giải nén vào thư mục này.
- Hoặc bằng `gh`:
  ```bash
  gh release download v1.0-dataset -p "clinic-evtx-dataset-v1.0.zip"
  unzip clinic-evtx-dataset-v1.0.zip -d .
  ```

### 4.2. Cách publish dataset
```bash
# 1) Gom 8 .evtx + 2 ground truth (đã ẩn danh nếu cần) thành 1 zip
cd 04_evaluation_and_datasets/evtx_master_datasets
zip clinic-evtx-dataset-v1.0.zip *.evtx ground_truth.csv ground_truth_sql.log

# 2) Tạo release và đính file (cần gh đã đăng nhập)
gh release create v1.0-dataset clinic-evtx-dataset-v1.0.zip \
  --title "Clinic EVTX dataset v1.0" \
  --notes "8 tệp .evtx (3 máy) + ground truth. Dữ liệu giả lập, đã ẩn danh. Xem README_DATASET_MANIFEST.md."
```
> Giới hạn: ≤2GB/tệp cho release, đủ rộng cho dataset lab. Nếu dataset lớn hơn, tách nhiều zip theo máy.
