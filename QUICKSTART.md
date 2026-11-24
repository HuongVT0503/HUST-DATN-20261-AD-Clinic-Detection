# QUICKSTART — 10 bước từ AWS đến số liệu

> Bản điều hướng ngắn. Chi tiết từng bước xem file được nhắc.
> Toàn bộ là lab cô lập, dữ liệu giả lập. đọc cảnh báo an toàn trong guide trước khi làm.

| # | Bước | Làm ở đâu | Tài liệu chi tiết |
|---|------|-----------|-------------------|
| 1 | Tạo Security Group + ghim Private IP tĩnh cho 3 máy (SRV02 = 172.31.10.22) | AWS Console | `AWS_EC2_3VM_DEPLOYMENT_GUIDE.md` §1 |
| 2 | Launch 3 EC2 Windows Server 2022 (DC01, SRV02, WS01), đưa repo lên `C:\` | AWS / RDP | guide §1–2 |
| 3 | DC01: dựng forest + 200 user + telemetry + Sysmon | DC01 | guide §3 |
| 4 | SRV02: SQL + SMB + Audit + Sysmon -> chạy khối kiểm tra §4.3 | SRV02 | guide §4 |
| 5 | WS01: join + quyền + Sysmon | WS01 | guide §5 |
| 6 | Bật sinh nhiễu (giao ca trên WS01, đồng bộ HIS trên SRV02) ~30–60 phút | WS01 + SRV02 | guide §6 |
| 7 | Chạy 3 kịch bản tấn công (ghi ground truth) | WS01 (+SRV02 cho P2) | guide §7 |
| 8 | Xuất đủ `.evtx` (Sysmon + Security + Application + Directory Service) + 2 file ground truth | 3 máy | guide §8 + bảng §11 |
| 9 | Terminate EC2 -> bật ELK trên WSL2, nạp `.evtx`, chạy luật V1->V4, xuất CSV | WSL2/Docker | `04_.../REPLAY_RUNBOOK.md` |
| 10 | Gán nhãn + tính Confusion Matrix + vẽ PR | `notebooks_and_scripts/` | `REPLAY_RUNBOOK.md` §6 |

**Kết quả cuối:** `metrics_summary.csv` + `figures/precision_recall_tradeoff.png` + `figures/false_positive_by_version.png`.

**3 điểm dễ lỗi:**
1. SRV02 không đúng IP 172.31.10.22 -> whitelist V4 sai (guide §1.2).
2. SQL Audit không bật/sai edition -> mất toàn bộ 33205 của Kịch bản 3 (guide §4.3).
3. Xuất thiếu Sysmon/Security log -> Kịch bản 1 & 3 bị bỏ lọt tấn công oan (guide §8 + §11).
