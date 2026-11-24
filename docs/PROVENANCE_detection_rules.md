# Provenance bộ luật V1–V4 và dependency ngoài

Nguồn các luật, telemetry, tool. Mục 1 có cột "đã kiểm chứng lại" (mở detection.fyi /
research.splunk.com / elastic.co ngày 24/11/2026) kèm 2 điểm lệch.

## 1. Luật V1 (baseline "giải pháp hiện có")

### SC1-V1 (SharpHound / setspn)
- Nguồn: SigmaHQ `proc_creation_win_hktl_bloodhound_sharphound.yml`, Florian Roth.
- id gốc: `f376c8a7-a2d0-4ddc-aa0c-16c17236d962`
- GitHub: https://github.com/SigmaHQ/sigma/blob/master/rules/windows/process_creation/proc_creation_win_hktl_bloodhound_sharphound.yml
- detection.fyi: https://detection.fyi/sigmahq/sigma/windows/process_creation/proc_creation_win_hktl_bloodhound_sharphound
- MITRE: T1087.001/002, T1069.001/002, T1482, T1059.001
- **Lệch:** rule gốc chỉ bắt chữ ký SharpHound (`Product`/`Company`/`Image`). Nhánh
  `setspn -Q` trong `sc1_v1` là **tự thêm** để đại diện đường native loud. Cite thêm rule SigmaHQ "Potential SPN Enumeration Via Setspn.EXE" cho nhánh đó.

### SC2-V1 (Kerberoasting RC4 0x17)
- Nguồn: SigmaHQ `win_security_susp_rc4_kerberos.yml`, Florian Roth, 2017-02-06 (modified 2022-06-19).
- id gốc: `496a0e47-0a33-4dca-b009-9e6ca3591f39`
- GitHub: https://github.com/SigmaHQ/sigma/blob/master/rules/windows/builtin/security/win_security_susp_rc4_kerberos.yml
- detection.fyi: https://detection.fyi/sigmahq/sigma/windows/builtin/security/win_security_susp_rc4_kerberos/
- Logic gốc khớp repo: `4769` + `TicketOptions 0x40810000` + `0x17`, `reduction ServiceName endswith '$'`.
- Tham khảo nội tại: adsecurity.org/?p=3458, Trimarc "Detecting Kerberoasting Activity".
- **Lệch:** rule gốc `level: medium`, `status: test`; repo để `high`/`stable` (nâng vì HIS là tài sản trọng yếu).

### SC3-V1 (sqlservr.exe sinh shell / xp_cmdshell)
- Nguồn 1 (Elastic, License v2 chỉ tham chiếu): "Execution via MSSQL xp_cmdshell Stored Procedure", logic `process.parent.name:"sqlservr.exe"` + child cmd/powershell, T1059.003. https://www.elastic.co/guide/en/security/current/execution-via-mssql-xp-cmdshell-stored-procedure.html
  Repo luật: https://github.com/elastic/detection-rules
- Nguồn 2 (Splunk, Apache-2.0): "Windows Sqlservr Spawning Shell", id `d33aac9f-030c-4830-8701-0c2dd75bb6cb`, data source Sysmon 1 + Security 4688. https://research.splunk.com/endpoint/d33aac9f-030c-4830-8701-0c2dd75bb6cb/
- MITRE chuỗi Kịch bản 3: T1558.003 (P1) -> T1078/T1098 (P2) -> T1059.003 (P3) -> T1005 (P4a) -> T1485 (P4b) -> T1562.001 (P5).

## 2. Luật tự viết V2/V3/V4

### V2 (nới lỏng)
Không phải rule công bố sẵn mà là bản "widen" có chủ đích để chứng minh FP tăng mạnh nếu làm như vậy. Cite: các id V1 ở Mục 1
+ Axelsson 2000 (base-rate), DOI 10.1145/357830.357849.

### V3 (ngưỡng / cửa sổ trượt)
Viết bằng **Sigma Correlation** (`event_count`, `group-by`, `timespan`, `condition`), tương đương **Elastic Threshold rule**. Analogue thực tế (phát hiện theo bất thường thay vì chữ ký): Elastic prebuilt "Newly Observed RC4 Kerberos Service Ticket Request" (`new_terms`).
- https://sigmahq.io/docs/meta/correlations.html
- https://www.elastic.co/guide/en/security/current/rules-ui-create.html
- https://www.elastic.co/docs/reference/security/prebuilt-rules/rules/windows/credential_access_kerberos_service_ticket_rc4
- Ngưỡng là placeholder, tune từ baseline 7 ngày (ghi số + lý do).

### V4 (ngữ cảnh + pháp lý)
- Kerckhoffs: whitelist neo vào trường KDC xác thực (4769 TargetUserName/IpAddress), không neo vào nội dung filter (xem Mục 5 ở dưới).
- Funnel of Fidelity (SpecterOps, Jared Atkinson): khung "lọc từ luật lỏng -> high-fidelity".
- Chốt chặn TT13: cấm xóa bệnh án đã ký số-> nhánh critical không whitelist cho ai
  (`docs/legal_compliance_2025_2026/Thong_Tu_13_2025_TT_BYT_BenhAnDienTu.md`).

## 3. Telemetry
- Sysmon: SwiftOnSecurity sysmon-config (https://github.com/SwiftOnSecurity/sysmon-config); Olaf Hartong sysmon-modular (https://github.com/olafhartong/sysmon-modular).
- Event 1644: Microsoft TechCommunity https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/how-to-find-expensive-inefficient-and-long-running-ldap-queries/ba-p/257859
- Event 33205/15457: Microsoft Learn "SQL Server Audit Records" https://learn.microsoft.com/en-us/sql/relational-databases/security/auditing/sql-server-audit-records ; Elastic "MSSQL Audit Stopped or Tampered" (event.code 33205).

## 4. Dependency ngoài (không nằm trong repo, người dựng lab tự tải)
- SharpHound (BloodHound): https://github.com/SpecterOps/BloodHound: chỉ cần cho SC1 bản đầy đủ; SC1 tối thiểu dùng setspn native.
- Rubeus (GhostPack): https://github.com/GhostPack/Rubeus: cần cho SC2 pha 0x17. Cơ chế `/tgtdeleg` ép KDC cấp vé RC4 trên account có bật RC4; không dùng `/rc4opsec` (cờ này loại account đã bật AES->  bỏ SVC_HIS_Database). Pha 2B (0x12) dùng .NET native. Nguồn: Rubeus README + harmj0y "Kerberoasting Revisited" (https://specterops.io/blog/2019/02/20/kerberoasting-revisited/).
- Atomic Red Team: https://github.com/redcanaryco/atomic-red-team: chỉ dùng làm mẫu lệnh tham chiếu (ánh xạ T-code của baseline), KHÔNG phải runner. Tấn công hiện thực bằng script native để kiểm soát ground-truth.
- Leo thang SQL (SC3 P2, single-user mode): Microsoft Learn "Connect to SQL Server When System Administrators Are Locked Out".

## 5. Vì sao whitelist V4 không vi phạm Kerckhoffs
Nguyên tắc: an toàn không được dựa vào việc kẻ tấn công không biết cơ chế.
- SC2-V4 (4769, do KDC sinh): luôn có TargetUserName + IpAddress thật, attacker từ WS01 không giả được. Whitelist "bỏ qua khi người xin vé là SVC_HIS_Sync" dù attacker biết vẫn không lách được (trừ khi chiếm chính SVC_HIS_Sync-> bài toán khác). 
- SC1-V4 (1644): tùy phiên bản có thể chỉ có IP nguồn. Neo theo IP (SRV02) vẫn thỏa Kerckhoffs vì IP nguồn LDAP/Kerberos (TCP có xác thực) không giả được từ WS01 khi chưa chiếm SRV02 (lúc đó SC3 bắt).

## 6. Kiểm tra Event 1644 có lộ danh tính không (làm 1 lần, sau khi có 1644 thật)
- Kibana: Discover-> `event.code: "1644"`-> mở 1 document -> tab JSON -> đọc `winlog.event_data.*` xem có trường nào (SubjectUserName/User) chứa tên tài khoản không rỗng.
- Hoặc DC01: `Get-WinEvent -LogName "Directory Service" -FilterXPath "*[System[(EventID=1644)]]" -MaxEvents 1 | Format-List *`
- Có danh tính dạng field -> SC1-V4 neo danh tính + IP. Chỉ có IP -> neo theo IP (SRV02).