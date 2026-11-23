# Provenance bộ luật V1 và các dependency ngoài (nguồn để cite trong quyển)

File này ghi lại nguồn các luật V1 (baseline "giải pháp hiện có") và các tool/telemetry ngoài. 

## 1. Luật V1 (baseline kế thừa)

### SC1-V1 (SharpHound / setspn)
- Nguồn: SigmaHQ `proc_creation_win_hktl_bloodhound_sharphound.yml`
- id gốc: `f376c8a7-a2d0-4ddc-aa0c-16c17236d962`
- Tác giả gốc: Florian Roth (Nextron Systems)
- Link: https://github.com/SigmaHQ/sigma/blob/master/rules/windows/process_creation/proc_creation_win_hktl_bloodhound_sharphound.yml
- MITRE: T1087.001/002, T1069.001/002, T1482, T1059.001

### SC2-V1 (Kerberoasting RC4 0x17)
- Nguồn: SigmaHQ `win_security_susp_rc4_kerberos.yml` ("Suspicious Kerberos RC4 Ticket Encryption")
- id gốc: `496a0e47-0a33-4dca-b009-9e6ca3591f39`
- Tác giả gốc: Florian Roth (Nextron Systems), ngày 2017-02-06
- Link: https://github.com/SigmaHQ/sigma/blob/master/rules/windows/builtin/security/win_security_susp_rc4_kerberos.yml
- Tham khảo nội tại của luật đó: Sean Metcalf (adsecurity.org/?p=3458), Trimarc "Detecting Kerberoasting Activity"

### SC3-V1 (sqlservr.exe sinh shell / xp_cmdshell)
- Nguồn 1: Elastic prebuilt "Execution via MSSQL xp_cmdshell Stored Procedure", tác giả Elastic
  - Link: https://www.elastic.co/guide/en/security/current/execution-via-mssql-xp-cmdshell-stored-procedure.html
  - Repo luật: https://github.com/elastic/detection-rules (tìm execution_via_mssql_xp_cmdshell_stored_procedure)
- Nguồn 2: Splunk ESCU "Windows Sqlservr Spawning Shell", tác giả Splunk Threat Research Team
  - id: `d33aac9f-030c-4830-8701-0c2dd75bb6cb`
  - Link: https://research.splunk.com/endpoint/d33aac9f-030c-4830-8701-0c2dd75bb6cb/
- MITRE: T1059.003

## 2. Telemetry

### Sysmon base config
- SwiftOnSecurity sysmon-config: https://github.com/SwiftOnSecurity/sysmon-config
- Olaf Hartong sysmon-modular: https://github.com/olafhartong/sysmon-modular
- Event ID 1644 (LDAP expensive/inefficient query): Microsoft TechCommunity
  https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/how-to-find-expensive-inefficient-and-long-running-ldap-queries/ba-p/257859

### SQL Server Audit (Event ID 33205, 15457)
- Microsoft Learn "SQL Server Audit Records": https://learn.microsoft.com/en-us/sql/relational-databases/security/auditing/sql-server-audit-records
- Elastic "MSSQL Audit Stopped or Tampered" (phát hiện tắt audit qua event.code 33205)

## 3. Dependency ngoài (tool KHÔNG nằm trong repo, người dựng lab phải tự tải)

- SharpHound.exe (collector BloodHound): https://github.com/SpecterOps/BloodHound
  (repo cũ: https://github.com/BloodHoundAD/SharpHound). Chỉ cần cho Kịch bản 1 bản đầy đủ;
  Kịch bản 1 tối thiểu dùng setspn native, không cần SharpHound.
- Rubeus.exe (GhostPack): https://github.com/GhostPack/Rubeus. Cần cho Kịch bản 2 pha 0x17.
  0x17 vs 0x12 và /tgtdeleg, /rc4opsec: Rubeus README + The Hacker Recipes https://www.thehacker.recipes/ad/movement/kerberos/kerberoast
- Atomic Red Team (mẫu lệnh tấn công): https://github.com/redcanaryco/atomic-red-team

## 4. Kỹ thuật leo thang SQL (Kịch bản 3, pha P2)

- Microsoft Learn "Connect to SQL Server When System Administrators Are Locked Out" (single-user mode): https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/connect-to-sql-server-when-system-administrators-are-locked-out
- NetSPI PowerUpSQL (impersonate service account, EXECUTE AS, TRUSTWORTHY abuse): https://github.com/NetSPI/PowerUpSQL
- Microsoft Learn `EXECUTE AS` và `TRUSTWORTHY`: tra trên learn.microsoft.com trước khi cite.