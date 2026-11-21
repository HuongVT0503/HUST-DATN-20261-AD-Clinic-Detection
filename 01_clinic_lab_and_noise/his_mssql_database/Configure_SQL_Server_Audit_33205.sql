/*
================================================================================
Tệp: 01_clinic_lab_and_noise/his_mssql_database/Configure_SQL_Server_Audit_33205.sql
Mô tả: Kích hoạt cơ chế ghi vết kiểm toán SQL Server Audit đẩy vào Windows Application
       Event Log (Event ID 33205) phục vụ giám sát theo Thông tư 13/2025/TT-BYT , .
================================================================================
*/

USE [master];
GO

-- 1. Xóa Server Audit cũ nếu tồn tại để đảm bảo tính tất định (Idempotent)
IF EXISTS (SELECT 1 FROM sys.server_audit_specifications WHERE name = N'Audit_Server_Tamper_Spec')
BEGIN
    ALTER SERVER AUDIT SPECIFICATION [Audit_Server_Tamper_Spec] WITH (STATE = OFF);
    DROP SERVER AUDIT SPECIFICATION [Audit_Server_Tamper_Spec];
END
GO

IF EXISTS (SELECT 1 FROM sys.server_audits WHERE name = N'Audit_BaoVeDuLieuBenhAn_TT13')
BEGIN
    ALTER SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13] WITH (STATE = OFF);
    DROP SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13];
END
GO

-- 2. Khởi tạo Server Audit đẩy sự kiện vào Windows Application Log (Sinh Event ID 33205)
CREATE SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13]
TO APPLICATION_LOG
WITH (
    QUEUE_DELAY = 1000,
    ON_FAILURE = CONTINUE
);
GO

ALTER SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13] WITH (STATE = ON);
GO

-- 3. Giám sát hành vi cố tình tắt hoặc sửa đổi cấu hình Audit ở cấp Server (AUDIT_CHANGE_GROUP)
CREATE SERVER AUDIT SPECIFICATION [Audit_Server_Tamper_Spec]
FOR SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13]
    ADD (AUDIT_CHANGE_GROUP)
WITH (STATE = ON);
GO

-- 4. Giám sát mọi thao tác SELECT, INSERT, UPDATE, DELETE trên bảng dbo.HoSoBenhAn
USE [HIS_ClinicDB];
GO

IF EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name = N'Audit_BangHoSoBenhAn_Spec')
BEGIN
    ALTER DATABASE AUDIT SPECIFICATION [Audit_BangHoSoBenhAn_Spec] WITH (STATE = OFF);
    DROP DATABASE AUDIT SPECIFICATION [Audit_BangHoSoBenhAn_Spec];
END
GO

CREATE DATABASE AUDIT SPECIFICATION [Audit_BangHoSoBenhAn_Spec]
FOR SERVER AUDIT [Audit_BaoVeDuLieuBenhAn_TT13]
    ADD (SELECT, INSERT, UPDATE, DELETE ON OBJECT::[dbo].[HoSoBenhAn] BY [public]),
    ADD (SCHEMA_OBJECT_CHANGE_GROUP),
    ADD (AUDIT_CHANGE_GROUP)
WITH (STATE = ON);
GO

PRINT N'[+] Đã kích hoạt thành công Server Audit [Audit_BaoVeDuLieuBenhAn_TT13] -> Sinh Event ID 33205 trong Application Log!';
GO