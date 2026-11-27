/*
  DATABASE ASSIGNMENT 3 — OPTIONAL NATIVE SQL SERVER DEMO DATABASE
  Creates a separate demo DB. Does NOT touch an existing LmsTrainingLab DB.
  Run once in SSMS. Designed for SQL Server 2016+ (no GENERATE_SERIES needed).
*/

IF DB_ID(N'LmsTrainingLab_Demo') IS NULL
    CREATE DATABASE [LmsTrainingLab_Demo];
GO
USE [LmsTrainingLab_Demo];
GO

IF SCHEMA_ID(N'identity') IS NULL EXEC(N'CREATE SCHEMA [identity]');
IF SCHEMA_ID(N'finance') IS NULL EXEC(N'CREATE SCHEMA [finance]');
IF SCHEMA_ID(N'operations') IS NULL EXEC(N'CREATE SCHEMA [operations]');
GO

IF OBJECT_ID(N'[identity].[StudentProfiles]', N'U') IS NULL
BEGIN
    CREATE TABLE [identity].[StudentProfiles]
    (
        Id INT NOT NULL CONSTRAINT PK_Demo_StudentProfiles PRIMARY KEY,
        StudentNumber VARCHAR(30) NOT NULL CONSTRAINT UQ_Demo_StudentProfiles_Number UNIQUE
    );
END;

IF OBJECT_ID(N'[identity].[Users]', N'U') IS NULL
BEGIN
    CREATE TABLE [identity].[Users]
    (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Demo_Users PRIMARY KEY,
        FirstName NVARCHAR(100) NOT NULL,
        LastName NVARCHAR(100) NOT NULL,
        Email VARCHAR(320) COLLATE Latin1_General_100_CI_AS NOT NULL,
        CreatedAtUtc DATETIME2(0) NOT NULL,
        LastLoginUtc DATETIME2(0) NULL
    );
END;

IF OBJECT_ID(N'[finance].[Invoices]', N'U') IS NULL
BEGIN
    CREATE TABLE [finance].[Invoices]
    (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Demo_Invoices PRIMARY KEY,
        InvoiceNumber VARCHAR(50) NOT NULL CONSTRAINT UQ_Demo_Invoices_Number UNIQUE,
        StudentId INT NOT NULL,
        TotalAmount DECIMAL(12,2) NOT NULL,
        PaidAmount DECIMAL(12,2) NOT NULL,
        DueAtUtc DATETIME2(0) NOT NULL,
        CONSTRAINT FK_Demo_Invoices_Student FOREIGN KEY (StudentId)
            REFERENCES [identity].[StudentProfiles](Id)
    );
END;

IF OBJECT_ID(N'[finance].[Payments]', N'U') IS NULL
BEGIN
    CREATE TABLE [finance].[Payments]
    (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Demo_Payments PRIMARY KEY,
        InvoiceId INT NOT NULL,
        Amount DECIMAL(12,2) NOT NULL,
        PaidAtUtc DATETIME2(0) NOT NULL
    );
END;

IF OBJECT_ID(N'[operations].[AuditLogs]', N'U') IS NULL
BEGIN
    CREATE TABLE [operations].[AuditLogs]
    (
        Id INT NOT NULL CONSTRAINT PK_Demo_AuditLogs PRIMARY KEY,
        EventText NVARCHAR(200) NOT NULL
    );
END;
GO

/* Create a tally table quickly by doubling its row count. */
IF OBJECT_ID(N'dbo.DemoNumbers', N'U') IS NOT NULL DROP TABLE dbo.DemoNumbers;
CREATE TABLE dbo.DemoNumbers (N INT NOT NULL PRIMARY KEY);
INSERT dbo.DemoNumbers(N) VALUES (1);
DECLARE @Last INT = 1;
WHILE @Last < 90000
BEGIN
    INSERT dbo.DemoNumbers(N)
    SELECT N + @Last
    FROM dbo.DemoNumbers
    WHERE N <= @Last AND N + @Last <= 90000;
    SET @Last = @Last * 2;
END;
GO

/* Students: 3,500 rows. */
INSERT [identity].[StudentProfiles](Id, StudentNumber)
SELECT N, CONCAT('STU-', RIGHT(CONCAT('000000', N), 6))
FROM dbo.DemoNumbers
WHERE N BETWEEN 1 AND 3500;

/* Users: 30,000 rows, including NULL last logins and repeated surname prefixes. */
INSERT [identity].[Users](FirstName, LastName, Email, CreatedAtUtc, LastLoginUtc)
SELECT
    CASE N % 8 WHEN 0 THEN N'Ali' WHEN 1 THEN N'Mona' WHEN 2 THEN N'Omar'
        WHEN 3 THEN N'Sara' WHEN 4 THEN N'Youssef' WHEN 5 THEN N'Nour'
        WHEN 6 THEN N'Hassan' ELSE N'Laila' END,
    CASE N % 10 WHEN 0 THEN N'Abdelrahman' WHEN 1 THEN N'Abdullah'
        WHEN 2 THEN N'Abdelaziz' WHEN 3 THEN N'Hassan' WHEN 4 THEN N'Ibrahim'
        WHEN 5 THEN N'Fathy' WHEN 6 THEN N'Metwally' WHEN 7 THEN N'Mahmoud'
        WHEN 8 THEN N'Nasser' ELSE N'Khalil' END,
    CONCAT('user', N, '@example', N % 17, '.com'),
    DATEADD(SECOND, (N * 7919) % 86400,
        DATEADD(DAY, (N * 17) % 1095, CONVERT(DATETIME2(0), '2024-01-01'))),
    CASE WHEN N % 13 = 0 THEN NULL
         ELSE DATEADD(DAY, N % 900, CONVERT(DATETIME2(0), '2024-01-01')) END
FROM dbo.DemoNumbers
WHERE N BETWEEN 1 AND 30000;

/* Invoices: 18,000 rows. */
;WITH InvoiceSeed AS
(
    SELECT N,
           CONVERT(DECIMAL(12,2), 500 + ((N * 7919) % 2450000) / 100.0) AS TotalAmount
    FROM dbo.DemoNumbers
    WHERE N BETWEEN 1 AND 18000
)
INSERT [finance].[Invoices](InvoiceNumber, StudentId, TotalAmount, PaidAmount, DueAtUtc)
SELECT
    CONCAT('LAB-INV-2026-', RIGHT(CONCAT('000000', N), 6)),
    ((N * 17) % 3500) + 1,
    TotalAmount,
    CASE WHEN N % 5 = 0 THEN TotalAmount
         ELSE CONVERT(DECIMAL(12,2), TotalAmount * ((N * 13) % 92) / 100.0) END,
    DATEADD(DAY, ((N * 37) % 256) - 210, CONVERT(DATETIME2(0), '2026-11-27'))
FROM InvoiceSeed;

/* Payments: 90,000 rows. */
INSERT [finance].[Payments](InvoiceId, Amount, PaidAtUtc)
SELECT
    ((N * 17) % 18000) + 1,
    CONVERT(DECIMAL(12,2), 25 + ((N * 137) % 897500) / 100.0),
    DATEADD(SECOND, -((N * 7919) % 62208000), CONVERT(DATETIME2(0), '2026-11-27 12:00:00'))
FROM dbo.DemoNumbers
WHERE N BETWEEN 1 AND 90000;

/* Audit logs: 50,000 rows. */
INSERT [operations].[AuditLogs](Id, EventText)
SELECT N, CONCAT(N'Audit event number ', N)
FROM dbo.DemoNumbers
WHERE N BETWEEN 1 AND 50000;
GO

DROP TABLE dbo.DemoNumbers;
GO

/* Basic verification: row counts should be 3,500 / 30,000 / 18,000 / 90,000 / 50,000. */
SELECT 'StudentProfiles' AS TableName, COUNT_BIG(*) AS RowCount FROM [identity].[StudentProfiles]
UNION ALL SELECT 'Users', COUNT_BIG(*) FROM [identity].[Users]
UNION ALL SELECT 'Invoices', COUNT_BIG(*) FROM [finance].[Invoices]
UNION ALL SELECT 'Payments', COUNT_BIG(*) FROM [finance].[Payments]
UNION ALL SELECT 'AuditLogs', COUNT_BIG(*) FROM [operations].[AuditLogs];
GO
