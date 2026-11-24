# Ánh xạ Sigma (`.yml`) ↔ KQL (`elastic_kibana_saved_queries.ndjson`)

File `.ndjson` này chứa 12 saved query (3 kịch bản × 4 phiên bản). Mỗi query là bản dịch
trực tiếp từ file Sigma tương ứng. Import vao Kibana: **Stack Management → Saved Objects → Import**.

| Saved query (title) | Dịch từ file Sigma | Ghi chú |
| --- | --- | --- |
| `SC1_V1_Default_SharpHound_CLI` | `v1_default_ootb/sc1_v1_bloodhound_sharphound.yml` | Sysmon 1; nhánh setspn: đồ án tự thêm |
| `SC1_V2_Widened_All_1644` | `v2_widened_evasion/sc1_v2_ldap_1644_all_queries.yml` | bắt hết 1644 |
| `SC1_V3_Threshold_1644_PerSource` | `v3_threshold_sliding_window/sc1_v3_ldap_1644_threshold_50_per_min.yml` | xem mục NGƯỠNG ở dưới |
| `SC1_V4_Tuned_LDAP_1644_Clinic` | `v4_contextual_clinic_tuned/sc1_v4_ldap_sensitive_filter_whitelist.yml` | whitelist danh tính+IP |
| `SC2_V1_Default_Kerberoast_RC4_0x17` | `v1_default_ootb/sc2_v1_kerberoast_rc4_0x17.yml` | chỉ 0x17 |
| `SC2_V2_Widened_RC4_and_AES` | `v2_widened_evasion/sc2_v2_kerberoast_rc4_and_aes_0x12.yml` | 0x17 + 0x12 |
| `SC2_V3_SlidingWindow_TGS_PerUser` | `v3_threshold_sliding_window/sc2_v3_tgs_sliding_window.yml` | xem mục NGƯỠNG |
| `SC2_V4_Tuned_Kerberoast_OpSec_Clinic` | `v4_contextual_clinic_tuned/sc2_v4_kerberoast_clinic_context.yml` | whitelist HIS |
| `SC3_V1_Default_Sqlservr_Spawns_Shell` | `v1_default_ootb/sc3_v1_sql_process_creation.yml` | Sysmon 1 |
| `SC3_V2_Widened_All_DB_SMB` | `v2_widened_evasion/sc3_v2_all_his_db_smb_access.yml` | 33205+15457+SMB |
| `SC3_V3_Threshold_Bulk_EMR_Read` | `v3_threshold_sliding_window/sc3_v3_bulk_emr_query_threshold.yml` | xem mục NGƯỠNG |
| `SC3_V4_Tuned_HIS_EMR_Tampering_TT13` | `v4_contextual_clinic_tuned/sc3_v4_his_emr_tampering_critical_tt13.yml` | chốt chặn critical |

## Về phiên bản V3 (ngưỡng / cửa sổ trượt)

1 **saved query** của Kibana (bộ lọc Discover) **không tự đếm theo cửa sổ thời gian** được. Với V3, query trong `.ndjson` chỉ **lọc nền** (ví dụ mọi 1644, mọi 4769 0x17/0x12). Ngưỡng thật ra được áp theo 1 trong 2 cách:

1. **Elastic Threshold rule** (Security → Rules → Create → Threshold): dùng chính KQL base làm query, đặt `Group by = source.ip` (hoặc `TargetUserName`), `Threshold = N`, `Window = T`.-> cách "chạy thật" tương đương Sigma Correlation.
2. **Trong script đánh giá** (`04_evaluation_and_datasets/notebooks_and_scripts/`): đếm số sự kiện/cửa sổ khi gán nhãn.-> cho việc lập bảng TP/FP.

Ngưỡng `N`, `T` trong file V3 là **placeholder** — phải tune từ baseline 7 ngày (xem `Clinic_IT_Morning_Review_Playbook.md`). //phải ghi rõ số được chọn + lý do

## Lưu ý trường (field) có thể lệch khi Winlogbeat phân tích
- `winlog.event_data.SubjectUserName` / `TargetUserName` / `ServiceName` / `TicketEncryptionType`: kiểm tra Discover một document mẫu để chắc tên field đúng (một số sự kiện đẩy nội dung vào `message`).
- `source.ip`: với 4769 Winlogbeat thường map từ `IpAddress`; với **1644** có thể KHÔNG có `source.ip` → khi đó whitelist SC1 neo theo trường thực sự có (xem `PROVENANCE`, mục kiểm tra 1644 1 lần).
