USE [LmsTrainingLab];
GO

-- 11.1 Raise every DSAI course's pass mark to 65.
UPDATE academic.Courses
SET PassMark = 65
WHERE CourseCode LIKE 'DSAI-%'
  AND (PassMark IS NULL OR PassMark <> 65);

-- 11.2 Grade finished enrollments which have a final score.
UPDATE academic.Enrollments
SET LetterGrade = CASE
    WHEN FinalScore >= 90 THEN 'A'
    WHEN FinalScore >= 80 THEN 'B'
    WHEN FinalScore >= 70 THEN 'C'
    WHEN FinalScore >= 60 THEN 'D'
    ELSE 'F'
END
WHERE Status = 'Completed'
  AND FinalScore IS NOT NULL;

-- 11.3 Remove the Teaching Assistant role.
DELETE FROM identity.Roles
WHERE RoleName = N'Teaching Assistant';

-- 11.4 Reusable empty-after-load staging table. Deliberately no FK constraint:
-- staging files may arrive before all referenced business rows are reconciled.
IF OBJECT_ID(N'finance.PaymentImportStaging', N'U') IS NULL
BEGIN
    CREATE TABLE finance.PaymentImportStaging
    (
        StagingId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PaymentImportStaging PRIMARY KEY,
        ExternalPaymentReference NVARCHAR(100) NOT NULL,
        InvoiceId BIGINT NOT NULL,
        Amount DECIMAL(18,2) NOT NULL,
        PaidAtUtc DATETIME2(7) NOT NULL,
        SourceFile NVARCHAR(260) NULL,
        StagedAtUtc DATETIME2(7) NOT NULL CONSTRAINT DF_PaymentImportStaging_StagedAtUtc DEFAULT SYSUTCDATETIME()
    );
END;

-- Start this load from an empty staging area, even after an interrupted prior run.
TRUNCATE TABLE finance.PaymentImportStaging;

INSERT INTO finance.PaymentImportStaging
    (ExternalPaymentReference, InvoiceId, Amount, PaidAtUtc, SourceFile)
VALUES
    (N'IMPORT-DEMO-001', 1, 1250.00, '2026-10-01T08:00:00', N'payments-202610.csv'),
    (N'IMPORT-DEMO-002', 2,  750.00, '2026-10-01T08:05:00', N'payments-202610.csv'),
    (N'IMPORT-DEMO-003', 3,  500.00, '2026-10-01T08:10:00', N'payments-202610.csv');

SELECT * FROM finance.PaymentImportStaging;

-- TRUNCATE is faster than DELETE when there are no foreign-key references,
-- triggers, or other restrictions. It also resets the identity counter.
TRUNCATE TABLE finance.PaymentImportStaging;

-- 11.5 Drop only the practice table created by this assignment. Do not drop
-- the operational staging table above, the LMS tables, or production indexes.
DROP TABLE IF EXISTS dbo.Assignment3_SpillLab;
GO

-- 12.1 Create the audit schema and table if needed.
IF SCHEMA_ID(N'audit') IS NULL EXEC(N'CREATE SCHEMA audit');
GO
IF OBJECT_ID(N'audit.CoursePassMarkHistory', N'U') IS NULL
BEGIN
    CREATE TABLE audit.CoursePassMarkHistory
    (
        HistoryId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CoursePassMarkHistory PRIMARY KEY,
        CourseId INT NOT NULL,
        CourseCode VARCHAR(30) NOT NULL,
        OldPassMark DECIMAL(5,2) NULL,
        NewPassMark DECIMAL(5,2) NULL,
        ChangedAtUtc DATETIME2(7) NOT NULL,
        ChangedBy SYSNAME NOT NULL
    );
END;

DECLARE @AuditDepartmentCode VARCHAR(20) = 'DSAI';
DECLARE @AuditNewPassMark DECIMAL(5,2) = 70;

UPDATE academic.Courses
SET PassMark = @AuditNewPassMark
OUTPUT
    inserted.Id,
    inserted.CourseCode,
    deleted.PassMark,
    inserted.PassMark,
    SYSUTCDATETIME(),
    ORIGINAL_LOGIN()
INTO audit.CoursePassMarkHistory
    (CourseId, CourseCode, OldPassMark, NewPassMark, ChangedAtUtc, ChangedBy)
WHERE DepartmentId =
      (SELECT Id FROM academic.Departments WHERE DepartmentCode = @AuditDepartmentCode)
  AND ISNULL(PassMark, -1) <> @AuditNewPassMark;

SELECT *
FROM audit.CoursePassMarkHistory
WHERE CourseCode LIKE 'DSAI-%'
ORDER BY HistoryId DESC;

-- 12.2 The archive schema/table stores the deleted row's original values.
IF SCHEMA_ID(N'archive') IS NULL EXEC(N'CREATE SCHEMA archive');
GO
IF OBJECT_ID(N'archive.Announcements', N'U') IS NULL
BEGIN
    CREATE TABLE archive.Announcements
    (
        AnnouncementId INT NOT NULL,
        Title NVARCHAR(200) NOT NULL,
        Body NVARCHAR(MAX) NULL,
        PublishedAtUtc DATETIME2(7) NULL,
        ExpiresAtUtc DATETIME2(7) NULL,
        IsPublished BIT NOT NULL,
        TargetAudience NVARCHAR(100) NULL,
        ArchivedAtUtc DATETIME2(7) NOT NULL,
        ArchivedBy SYSNAME NOT NULL
    );
END;

DELETE FROM content.Announcements
OUTPUT
    deleted.Id,
    deleted.Title,
    deleted.Body,
    deleted.PublishedAtUtc,
    deleted.ExpiresAtUtc,
    deleted.IsPublished,
    deleted.TargetAudience,
    SYSUTCDATETIME(),
    ORIGINAL_LOGIN()
INTO archive.Announcements
    (AnnouncementId, Title, Body, PublishedAtUtc, ExpiresAtUtc,
     IsPublished, TargetAudience, ArchivedAtUtc, ArchivedBy)
WHERE ExpiresAtUtc < DATEADD(MONTH, -6, SYSUTCDATETIME());

SELECT TOP (50) *
FROM archive.Announcements
ORDER BY ArchivedAtUtc DESC;
GO

IF SCHEMA_ID(N'website') IS NULL EXEC(N'CREATE SCHEMA website');
GO
IF OBJECT_ID(N'website.CourseCatalog', N'U') IS NULL
BEGIN
    CREATE TABLE website.CourseCatalog
    (
        CourseCode VARCHAR(30) NOT NULL CONSTRAINT PK_WebsiteCourseCatalog PRIMARY KEY,
        Title NVARCHAR(200) NOT NULL,
        CreditHours TINYINT NOT NULL,
        IsVisible BIT NOT NULL,
        LastSyncedAtUtc DATETIME2(7) NOT NULL
    );
END;

MERGE website.CourseCatalog AS Target
USING
(
    SELECT CourseCode, Title, CreditHours
    FROM academic.Courses
    WHERE IsActive = 1
) AS Source
ON Target.CourseCode = Source.CourseCode
WHEN MATCHED AND
(
       ISNULL(Target.Title, N'') <> ISNULL(Source.Title, N'')
    OR Target.CreditHours <> Source.CreditHours
    OR Target.IsVisible = 0
)
THEN UPDATE SET
    Target.Title = Source.Title,
    Target.CreditHours = Source.CreditHours,
    Target.IsVisible = 1,
    Target.LastSyncedAtUtc = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET
THEN INSERT (CourseCode, Title, CreditHours, IsVisible, LastSyncedAtUtc)
     VALUES (Source.CourseCode, Source.Title, Source.CreditHours, 1, SYSUTCDATETIME())
WHEN NOT MATCHED BY SOURCE AND Target.IsVisible = 1
THEN UPDATE SET
    Target.IsVisible = 0,
    Target.LastSyncedAtUtc = SYSUTCDATETIME()
OUTPUT
    $action AS SyncAction,
    COALESCE(inserted.CourseCode, deleted.CourseCode) AS CourseCode,
    deleted.Title AS OldTitle,
    inserted.Title AS NewTitle,
    deleted.IsVisible AS OldVisibility,
    inserted.IsVisible AS NewVisibility;

-- The first run returns INSERT/UPDATE actions as applicable. A second run with
-- no underlying course changes should return no rows. A third run also no rows.
SELECT *
FROM website.CourseCatalog
ORDER BY CourseCode;
GO

