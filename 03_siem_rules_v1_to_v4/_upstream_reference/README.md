# Rule gốc "giải pháp hiện có" (upstream reference)

Thư mục này chứa bản gốc các luật cộng đồng mà bộ luật V1 kế thừa, để:
- đối chiếu "giải pháp hiện có" trong quyển (V1 so với bản gốc),
- có thể kiểm chứng provenance ngay tại repo (không phụ thuộc link).

## Có được phép đưa rule gốc vào repo không? (theo license)

| Rule gốc (dùng cho) | Nguồn | License | Đưa vào repo? |
| --- | --- | --- | --- |
| SharpHound/BloodHound (SC1-V1) | SigmaHQ | **DRL-1.1** (Detection Rule License) | Được, kèm attribution |
| RC4 Kerberos (SC2-V1) | SigmaHQ | **DRL-1.1** | Được, kèm attribution |
| Windows Sqlservr Spawning Shell (SC3-V1) | Splunk security_content | **Apache-2.0** | Được, kèm attribution |
| Execution via MSSQL xp_cmdshell (SC3-V1) | Elastic detection-rules | **Elastic License v2** | **KHÔNG** vendor — chỉ link |

## Lưu ý
- Mọi tùy biến nằm ở `03_siem_rules_v1_to_v4/v1_default_ootb/`.
- Attribution đầy đủ: `NOTICE.md`.
