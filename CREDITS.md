# Credits & Attribution

Đồ án này kế thừa/điều chỉnh từ nhiều nguồn mở. Mỗi nguồn giữ license riêng. Bảng dưới liệt kê
thành phần, nguồn gốc, và license của chúng.

## Hạ tầng lab
| Thành phần | Nguồn | License |
| --- | --- | --- |
| Kiến trúc GOAD-Light (ý tưởng forest/OU, service account có SPN, MSSQL, SMB lỏng) | Orange Cyberdefense — https://github.com/Orange-Cyberdefense/GOAD (tác giả Mayfly / mayfly277) | GPLv3 (repo gốc). Lab này viết lại từ việc đọc config, không copy mã |
| Phương pháp DetectionLab (AD + log forwarding) | https://github.com/clong/DetectionLab | MIT |

## Luật phát hiện (03_siem_rules_v1_to_v4/)
| Luật | Nguồn gốc | id | License |
| --- | --- | --- | --- |
| SC1-V1 (SharpHound/BloodHound) | SigmaHQ `proc_creation_win_hktl_bloodhound_sharphound.yml`, Florian Roth | `f376c8a7-a2d0-4ddc-aa0c-16c17236d962` | DRL-1.1 |
| SC2-V1 (Kerberoast RC4 0x17) | SigmaHQ `win_security_susp_rc4_kerberos.yml`, Florian Roth | `496a0e47-0a33-4dca-b009-9e6ca3591f39` | DRL-1.1 |
| SC3-V1 (sqlservr->shell / xp_cmdshell) | Splunk `Windows Sqlservr Spawning Shell` (`d33aac9f-030c-4830-8701-0c2dd75bb6cb`) | — | Apache-2.0 (splunk/security_content) |
| SC3-V1 (tham chiếu) | Elastic `Execution via MSSQL xp_cmdshell Stored Procedure` | — | Elastic License v2 (chỉ tham chiếu) |
| V2/V3/V4 | Tự viết (widen/threshold/context) dựa trên các nguồn trên + Sigma Correlation spec | — | MIT (phần tự viết) / DRL-1.1 (phần kế thừa) |

## Telemetry
| Thành phần | Nguồn | License |
| --- | --- | --- |
| Sysmon config (cắt gọn) | SwiftOnSecurity `sysmon-config`; Olaf Hartong `sysmon-modular` | SwiftOnSecurity: CC-BY-NC / xem repo; Olaf Hartong: GPLv3 |
| Event 1644 registry | Microsoft TechCommunity | Microsoft docs |
| Event 33205/15457 | Microsoft Learn; NetSPI PowerUpSQL | Microsoft docs; PowerUpSQL BSD-3 |

## Công cụ tấn công (KHÔNG kèm trong repo — người dựng lab tự tải)
| Tool | Nguồn | License |
| --- | --- | --- |
| Rubeus | GhostPack — https://github.com/GhostPack/Rubeus | BSD-3 |
| SharpHound | SpecterOps — https://github.com/SpecterOps/BloodHound | Apache-2.0 / GPLv3 (xem repo) |
| Atomic Red Team (mẫu lệnh tham chiếu) | Red Canary — https://github.com/redcanaryco/atomic-red-team | MIT |

## Cơ sở học thuật / phương pháp
- Axelsson, S. (2000). *The Base-Rate Fallacy and the Difficulty of Intrusion Detection.* ACM TISSEC. DOI 10.1145/357830.357849
- Davis & Goadrich (2006). *The Relationship Between Precision-Recall and ROC Curves.* ICML.
- Updyke et al. (2018). *GHOSTS: A Framework for Cyber-Warfare Exercise NPC Simulation.* CMU/SEI.
- SpecterOps — Funnel of Fidelity (Jared Atkinson).

## Lưu ý
- Toàn bộ dữ liệu bệnh nhân là giả lập. Mật khẩu chỉ dùng cho lab dùng một lần.
- Lab cố tình cấu hình sai; chỉ chạy trong môi trường cô lập.
