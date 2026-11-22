/*
================================================================================
Tệp: 01_clinic_lab_and_noise/his_mssql_database/Init_HIS_EMR_Schema.sql
Mô tả: Khởi tạo CSDL HIS_ClinicDB, bảng dbo.HoSoBenhAn (50 bệnh án điện tử đã ký số theo Thông tư 13/2025/TT-BYT), và phân quyền TỐI THIỂU cho 2 tài khoản dịch vụ.

Nguyên tắc phân quyền tối thiểu (least privilege) -> Kịch bản 3 tập trung vào leo thang đặc quyền các ràng buộc này:
  - SVC_HIS_Database: db_datareader + db_datawriter, nhưng bị DENY DELETE trên bảng
    bệnh án đã ký số. KHÔNG cấp sysadmin. Ở mức này thì hành vi bình thường của phần mềm
    HIS (SELECT/INSERT/UPDATE) vẫn chạy, nhưng không xóa được bệnh án đã ký.
  - SVC_HIS_Sync: tạo thêm 1 SQL Login (mixed mode) chỉ có db_datareader, để script
    sinh nhiễu Invoke-HISXmlSync chạy sqlcmd -U/-P kết nối được từ tiến trình bất kỳ.
  => Vì 2 tài khoản KHÔNG phải sysadmin, Kịch bản 3 bắt buộc phải leo thang (ALTER
     SERVER ROLE sysadmin ADD MEMBER ...) mới vượt qua DENY và tắt được Audit. Bước leo
     thang đó chính là điểm mốc để luật V4 bắt (Event 33205). Nếu cấp sẵn sysadmin ở
     đây thì không cần leo thanh vì tài khoản cơ bản đã có sẵn quyền và trái TT13.

Yêu cầu: SQL Server cài ở chế độ Mixed Mode (/SECURITYMODE=SQL) để tạo được SQL Login.
================================================================================
*/

USE [master];
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'HIS_ClinicDB')
BEGIN
    CREATE DATABASE [HIS_ClinicDB];
    PRINT N'[+] Đã khởi tạo CSDL Bệnh án điện tử HIS_ClinicDB.';
END
GO

-- 1a. Windows Login cho SVC_HIS_Database (tài khoản bị Kerberoast ở Kịch bản 2)
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = N'CLINIC\SVC_HIS_Database')
BEGIN
    CREATE LOGIN [CLINIC\SVC_HIS_Database] FROM WINDOWS WITH DEFAULT_DATABASE = [HIS_ClinicDB];
END
GO

-- 1b. SQL Login cho SVC_HIS_Sync (phần mềm HIS đồng bộ BHYT thường dùng SQL auth).
--     có bước này nên sqlcmd -U SVC_HIS_Sync -P Password123! trong script sinh nhiễu mới chạy được
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = N'SVC_HIS_Sync')
BEGIN
    CREATE LOGIN [SVC_HIS_Sync] WITH PASSWORD = N'Password123!', DEFAULT_DATABASE = [HIS_ClinicDB], CHECK_POLICY = OFF;
END
GO

USE [HIS_ClinicDB];
GO

-- 2. Khởi tạo bảng dbo.HoSoBenhAn chứa dữ liệu nhạy cảm được bảo vệ theo TT 13/2025/TT-BYT
IF OBJECT_ID(N'dbo.HoSoBenhAn', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[HoSoBenhAn] (
        [MaBenhAn]      VARCHAR(20)   NOT NULL PRIMARY KEY,
        [SoCCCD]        CHAR(12)      NOT NULL,
        [MaTheBHYT]     VARCHAR(15)   NOT NULL,
        [HoTen]         NVARCHAR(100) NOT NULL,
        [NgaySinh]      DATE          NOT NULL,
        [ChanDoanICD10] NVARCHAR(255) NOT NULL,
        [PhacDoDieuTri] NVARCHAR(500) NOT NULL,
        [BacSiDieuTri]  VARCHAR(50)   NOT NULL,
        [ChuKySoPKI]    VARCHAR(128)  NOT NULL,
        [DaKySoTT13]    BIT           NOT NULL DEFAULT 1, -- 1 = Hồ sơ đã ký số, khóa xóa theo TT 13/2025/TT-BYT
        [NgayCapNhat]   DATETIME2     NOT NULL DEFAULT SYSDATETIME()
    );
    PRINT N'[+] Đã tạo bảng dbo.HoSoBenhAn.';
END
GO

-- 3. Chèn tự động 50 bản ghi hồ sơ bệnh án điện tử mẫu
SET NOCOUNT ON;
IF NOT EXISTS (SELECT 1 FROM [dbo].[HoSoBenhAn])
BEGIN
    DECLARE @i INT = 1;
    WHILE @i <= 50
    BEGIN
        DECLARE @MaBA VARCHAR(20)  = 'BA2026_' + RIGHT('0000' + CAST(@i AS VARCHAR(4)), 4);
        DECLARE @CCCD CHAR(12)     = '001204' + RIGHT('000000' + CAST((100000 + @i) AS VARCHAR(6)), 6);
        -- Mã thẻ BHYT 15 ký tự: 2 chữ + 13 số (khớp regex bên log_anonymizer)
        DECLARE @BHYT VARCHAR(15)  = 'DN' + RIGHT('0000000000000' + CAST((4010120000000 + @i) AS VARCHAR(13)), 13);
        DECLARE @BacSi VARCHAR(50) = 'CLINIC\BS_BacSi' + RIGHT('000' + CAST(((@i % 60) + 1) AS VARCHAR(3)), 3);

        DECLARE @HoTen NVARCHAR(100) = CASE (@i % 8)
            WHEN 0 THEN N'Nguyễn Văn An (' + CAST(@i AS NVARCHAR(4)) + N')'
            WHEN 1 THEN N'Trần Thị Bình (' + CAST(@i AS NVARCHAR(4)) + N')'
            WHEN 2 THEN N'Lê Hoàng Cường (' + CAST(@i AS NVARCHAR(4)) + N')'
            WHEN 3 THEN N'Phạm Minh Dũng (' + CAST(@i AS NVARCHAR(4)) + N')'
            WHEN 4 THEN N'Hoàng Thu Hà (' + CAST(@i AS NVARCHAR(4)) + N')'
            WHEN 5 THEN N'Vũ Quốc Khánh (' + CAST(@i AS NVARCHAR(4)) + N')'
            WHEN 6 THEN N'Đặng Ngọc Lan (' + CAST(@i AS NVARCHAR(4)) + N')'
            ELSE        N'Bùi Xuân Mạnh (' + CAST(@i AS NVARCHAR(4)) + N')'
        END;

        DECLARE @ICD NVARCHAR(255) = CASE (@i % 4)
            WHEN 0 THEN N'I10 - Tăng huyết áp vô căn (nguyên phát)'
            WHEN 1 THEN N'E11.9 - Đái tháo đường tuýp 2 chưa biến chứng'
            WHEN 2 THEN N'J20.9 - Viêm phế quản cấp'
            ELSE        N'K29.7 - Viêm dạ dày mạn tính HP(+)'
        END;

        DECLARE @PhacDo NVARCHAR(500) = CASE (@i % 4)
            WHEN 0 THEN N'Amlodipin 5mg x 30 viên (1 viên/ngày); Kiểm soát huyết áp định kỳ.'
            WHEN 1 THEN N'Metformin 850mg x 60 viên (2 viên/ngày sau ăn); Xét nghiệm HbA1c.'
            WHEN 2 THEN N'Augmentin 1g x 14 viên; Acetylcystein 200mg x 15 gói.'
            ELSE        N'Rabeprazol 20mg + Bismuth + Amoxicillin + Clarithromycin (14 ngày).'
        END;

        DECLARE @HashPKI VARCHAR(128) = LOWER(CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @MaBA + @CCCD + 'TT13_2025_BYT'), 2));

        INSERT INTO [dbo].[HoSoBenhAn] (
            [MaBenhAn], [SoCCCD], [MaTheBHYT], [HoTen], [NgaySinh],
            [ChanDoanICD10], [PhacDoDieuTri], [BacSiDieuTri], [ChuKySoPKI], [DaKySoTT13]
        )
        VALUES (
            @MaBA, @CCCD, @BHYT, @HoTen, DATEADD(DAY, -(@i * 120), '1995-01-01'),
            @ICD, @PhacDo, @BacSi, @HashPKI, 1
        );

        SET @i = @i + 1;
    END
    PRINT N'[+] Đã nạp thành công 50 hồ sơ bệnh án điện tử mẫu vào dbo.HoSoBenhAn.';
END
GO

-- ============================================================================
-- 4. PHÂN QUYỀN TỐI THIỂU
-- ============================================================================

-- 4a. SVC_HIS_Database: đọc + ghi, NHƯNG bị khóa quyền xóa bệnh án đã ký số (TT 13/2025/TT-BYT)
CREATE USER [CLINIC\SVC_HIS_Database] FOR LOGIN [CLINIC\SVC_HIS_Database];
ALTER ROLE [db_datareader] ADD MEMBER [CLINIC\SVC_HIS_Database];
ALTER ROLE [db_datawriter] ADD MEMBER [CLINIC\SVC_HIS_Database];
GRANT EXECUTE TO [CLINIC\SVC_HIS_Database];
-- Chốt TT13: tài khoản dịch vụ không được xóa bệnh án. Chỉ sysadmin mới bypass được DENY
-- => Kịch bản 3 buộc phải leo thang lên sysadmin-> hành vi cần bắt.
DENY DELETE ON [dbo].[HoSoBenhAn] TO [CLINIC\SVC_HIS_Database];
GO

-- 4b. SVC_HIS_Sync: chỉ đọc (phục vụ đồng bộ XML BHYT và tra cứu lẻ trong script sinh nhiễu)
CREATE USER [SVC_HIS_Sync] FOR LOGIN [SVC_HIS_Sync];
ALTER ROLE [db_datareader] ADD MEMBER [SVC_HIS_Sync];
GO

PRINT N'[+] Đã cấp quyền tối thiểu: SVC_HIS_Database (đọc/ghi, cấm xóa bệnh án đã ký), SVC_HIS_Sync (chỉ đọc).';
GO
