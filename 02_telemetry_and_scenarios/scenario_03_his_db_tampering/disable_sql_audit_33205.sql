/*
================================================================================
Tep: 02_telemetry_and_scenarios/scenario_03_his_db_tampering/disable_sql_audit_33205.sql

KICH BAN 3 - PHA P5: tat SQL Server Audit de xoa dau vet (anti-forensics).
Chay trong LAB CO LAP (clinic.local)

*** PHAI CHAY CUOI CUNG *** (sau enable_xp_cmdshell va abuse_read_delete).
Ly do: chinh hanh dong tat audit nay sinh ra 33205 STATE=OFF - do la ban ghi
cuoi cung ma V4 bat. Moi hanh vi doc/xoa o cac file truoc phai dien ra khi audit
con ON moi co 33205. Neu chay file nay truoc thi mat sach ground truth cua P4.

TIEN DE: phien ket noi da o quyen sysadmin (P2). Chi sysadmin moi ALTER duoc audit.

TELEMETRY sinh ra de bat:
  - Event ID 33205 voi action_id/trang thai STATE = OFF tren audit
    [Audit_BaoVeDuLieuBenhAn_TT13]. Nguon phat hien tamper: Microsoft Learn
    "SQL Server Audit Records" + Elastic "MSSQL Audit Stopped or Tampered"
    (event.code 33205). Xem docs/PROVENANCE_detection_rules.md.
================================================================================
*/

SELECT SYSDATETIME() AS P5_BatDau;
GO

-- Tat Server Audit -> sinh Event ID 33205 STATE=OFF (moc V4 bat, severity Critical)
ALTER SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13] WITH (STATE = OFF);
GO

SELECT SYSDATETIME() AS P5_KetThuc;
GO