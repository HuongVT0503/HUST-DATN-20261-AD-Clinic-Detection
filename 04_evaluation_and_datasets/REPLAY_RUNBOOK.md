# Runbook: nạp `.evtx` vào ELK, chạy luật V1->V4, xuất số

> Pha phân tích offline (sau khi đã có `.evtx` + ground truth từ AWS). Máy 8GB RAM, ELK trên WSL2 Docker.

## 0. Yêu cầu trước
- Đã có các `.evtx` trong `04_evaluation_and_datasets/evtx_master_datasets/` (xem danh sách đầy đủ trong `AWS_EC2_3VM_DEPLOYMENT_GUIDE.md` mục 8 — phải đủ Sysmon + Security + Application + Directory Service).
- Đã có `ground_truth.csv` (WS01) và `ground_truth_sql.log` (SRV02).
- `winlogbeat.exe` (bản 8.12.x khớp `.env`): tải tại https://www.elastic.co/downloads/beats/winlogbeat

## 1. Bật ELK
```bash
cd 03_siem_rules_v1_to_v4/elk_docker_wsl2
docker compose up -d
# đợi ~1 phút: http://localhost:9200 (JSON) và http://localhost:5601 (Kibana)
```

## 2. (Khuyến nghị) Tạo ingest pipeline ẩn danh
```bash
# Bỏ các khóa _comment_* trước khi PUT
curl -X PUT "http://localhost:9200/_ingest/pipeline/emr-anonymize" \
  -H 'Content-Type: application/json' \
  --data-binary @elk_docker_wsl2/emr_anonymize_ingest_pipeline.json
```
Trong `winlogbeat_evtx_replay.yml`, thêm `pipeline: "emr-anonymize"` dưới `output.elasticsearch`.

## 3. Nạp từng `.evtx` (deterministic replay)
Chạy winlogbeat một lần cho MỖI file `.evtx` (đọc tĩnh, xong thì dừng):
```powershell
# Ví dụ trên Windows (hoặc winlogbeat Linux đọc file đã copy sang WSL):
.\winlogbeat.exe -e -c winlogbeat_evtx_replay.yml -E EVTX_FILE="C:\evtx\dc01_directory_service_1644.evtx"
.\winlogbeat.exe -e -c winlogbeat_evtx_replay.yml -E EVTX_FILE="C:\evtx\dc01_security_4769_4624_4625.evtx"
.\winlogbeat.exe -e -c winlogbeat_evtx_replay.yml -E EVTX_FILE="C:\evtx\dc01_sysmon.evtx"
.\winlogbeat.exe -e -c winlogbeat_evtx_replay.yml -E EVTX_FILE="C:\evtx\srv02_application_33205_15457.evtx"
.\winlogbeat.exe -e -c winlogbeat_evtx_replay.yml -E EVTX_FILE="C:\evtx\srv02_security_5140_5145.evtx"
.\winlogbeat.exe -e -c winlogbeat_evtx_replay.yml -E EVTX_FILE="C:\evtx\srv02_sysmon_sqlservr.evtx"
.\winlogbeat.exe -e -c winlogbeat_evtx_replay.yml -E EVTX_FILE="C:\evtx\ws01_security.evtx"
.\winlogbeat.exe -e -c winlogbeat_evtx_replay.yml -E EVTX_FILE="C:\evtx\ws01_sysmon_setspn.evtx"
```

## 4. Xác nhận log đã vào index
```bash
curl "http://localhost:9200/_cat/indices/winlogbeat-clinic-replay-*?v"        # docs.count > 0
curl "http://localhost:9200/winlogbeat-clinic-replay-*/_count?q=event.code:1644"
curl "http://localhost:9200/winlogbeat-clinic-replay-*/_count?q=event.code:33205"
curl "http://localhost:9200/winlogbeat-clinic-replay-*/_count?q=event.code:1"   # Sysmon - phai > 0
```
Nếu một `event.code` kỳ vọng = 0 -> đã xuất thiếu `.evtx` đó (quay lại mục 8 guide).

## 5. Import saved queries + chạy V1->V4
1. Kibana -> Stack Management -> Saved Objects -> Import `kql_queries/elastic_kibana_saved_queries.ndjson`.
2. Discover -> chọn index pattern `winlogbeat-clinic-replay-*` -> mở từng saved query -> đếm số hit.
3. **V3 (ngưỡng):** tạo Elastic Threshold rule theo `README_sigma_kql_mapping.md`, HOẶC để script đánh giá áp ngưỡng khi gán nhãn.
4. Xuất kết quả mỗi phiên bản ra CSV (Discover -> Share -> CSV, hoặc Reporting) vào `04_evaluation_and_datasets/alerts_exported_csv/alerts_iteration_v{1,2,3,4}.csv`. Mỗi CSV cần ít nhất 1 cột thời gian (`@timestamp`); thêm cột `scenario` để khớp đúng nhóm kịch bản.

## 6. Gán nhãn + tính số + vẽ
```bash
cd ../notebooks_and_scripts
# chuyển ground_truth_sql.log -> CSV 'timestamp,scenario,phase' (vd SC3-P4,START,<SYSDATETIME>) rồi:
for V in v1 v2 v3 v4; do
  python3 -I label_alerts_from_ground_truth.py \
    --alerts ../alerts_exported_csv/alerts_iteration_${V}.csv --force-version ${V^^} \
    --ground-truth ground_truth.csv ground_truth_sql.csv \
    --out ../alerts_exported_csv/${V}_labeled.csv
done
python3 -I calculate_confusion_matrix.py \
  --labeled ../alerts_exported_csv/v1_labeled.csv ../alerts_exported_csv/v2_labeled.csv \
            ../alerts_exported_csv/v3_labeled.csv ../alerts_exported_csv/v4_labeled.csv \
  --scenario-list SC1 SC2 SC3 --out metrics_summary.csv
python3 -I plot_precision_recall_tradeoff.py --metrics metrics_summary.csv --outdir ../figures
```
`metrics_summary.csv` + 2 ảnh trong `figures/` là số liệu thật (Chương Kết quả).

## 7. Giải phóng RAM
```powershell
wsl --shutdown
```
