# Ẩn danh hóa dữ liệu bệnh nhân

## 1 — LIVE (log vào SIEM): ES ingest pipeline `emr-anonymize`
Luồng nạp log là `.evtx -> Winlogbeat -> Elasticsearch`. Winlogbeat không chạy được script ngoài, nên che dữ liệu ở Elasticsearch ingest pipeline: Winlogbeat gửi sang ES, ES chạy pipeline `emr-anonymize` (redact CCCD/BHYT/tên bằng `gsub`) trước khi lưu index. Cách này giữ nguyên trường ECS nên luật KQL/Sigma chạy bình thường.

Bật:
```bash
# 1) Tạo pipeline (bỏ các khóa _comment_* trước khi PUT):
curl -X PUT "http://localhost:9200/_ingest/pipeline/emr-anonymize" \
  -H 'Content-Type: application/json' \
  --data-binary @../../03_siem_rules_v1_to_v4/elk_docker_wsl2/emr_anonymize_ingest_pipeline.json
```
```yaml
# 2) winlogbeat_evtx_replay.yml:
output.elasticsearch:
  hosts: ["http://localhost:9200"]
  pipeline: "emr-anonymize"
```

## 2 — EXPORT/SHARE (văn bản công khai): `anonymize_sensitive_emr_logs.py`
Dùng cho file văn bản công khai: CSV cảnh báo xuất từ Kibana, `ground_truth_sql.log`, log mẫu cho phụ lục, hoặc bộ `.evtx` đã convert ra text/JSON để phát hành dataset.
```bash
python3 -I anonymize_sensitive_emr_logs.py -i alerts_iteration_v4.csv -o alerts_iteration_v4_public.csv
```
Script này băm (SHA-256 + salt, giữ 10 ký tự để đối sánh tương quan), khác pipeline live (redact hẳn). Không đọc `.evtx` trực tiếp vì file ẩn danh dạng text/JSON nếu nạp lại bằng Filebeat sẽ mất ánh xạ ECS.

## Vì sao tách 2 
- Cách 1 giữ ECS để phân tích; redact là đủ cho an toàn vận hành.
- Cách 2 tạo bản sao công khai có thể đối sánh (hash) để kiểm chứng mà không lộ PII.
