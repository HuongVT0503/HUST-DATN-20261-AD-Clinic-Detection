# Kịch bản 1: Dò quét AD và SPN (mặc định ồn ào vs ADSI low-and-slow)

Thư mục này chứa 2 pha của Kịch bản 1. Mục tiêu detection engineering: pha mặc định phải bị V1 bắt, pha lẩn tránh phải vượt V1 và chỉ bị V2/V3/V4 bắt.

| File | Vai trò | Event sinh ra | Luật bắt |
| --- | --- | --- | --- |
| `sharphound_setspn_default.ps1` | 1A: dò quét bằng chữ ký công cụ mặc định | Sysmon Event ID 1 (setspn.exe / SharpHound.exe) | V1 bắt |
| `evasion_adsi_low_and_slow_spn.ps1` | 1B: dò quét chậm qua `[adsisearcher]` | Event ID 1644 (Directory Service, trên DC01) | V1 bỏ lọt, V2/V3/V4 bắt |
