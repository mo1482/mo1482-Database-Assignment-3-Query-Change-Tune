USE [LmsTrainingLab];
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'identity.Users') AND name = N'IX_Users_Email')
    CREATE INDEX IX_Users_Email ON identity.Users (Email) INCLUDE (FirstName, LastName);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'identity.Users') AND name = N'IX_Users_LastName')
    CREATE INDEX IX_Users_LastName ON identity.Users (LastName) INCLUDE (FirstName, Email);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'identity.Users') AND name = N'IX_Users_CreatedAtUtc')
    CREATE INDEX IX_Users_CreatedAtUtc ON identity.Users (CreatedAtUtc) INCLUDE (Email);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'finance.Payments') AND name = N'IX_Payments_PaidAtUtc')
    CREATE INDEX IX_Payments_PaidAtUtc ON finance.Payments (PaidAtUtc) INCLUDE (InvoiceId, Amount);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'finance.Invoices') AND name = N'IX_Invoices_Number')
    CREATE INDEX IX_Invoices_Number ON finance.Invoices (InvoiceNumber);
GO

-- 7.1 SLOW (run first for the before-plan):
SELECT Id, Email
FROM identity.Users
WHERE CreatedAtUtc >= '2026-03-01T00:00:00'
  AND CreatedAtUtc <  '2026-04-01T00:00:00';

-- 7.2 SLOW (run first for the before-plan):
SELECT Id, InvoiceId, Amount
FROM finance.Payments
WHERE PaidAtUtc >= DATEADD(DAY, -30, CONVERT(DATE, SYSUTCDATETIME()));

-- 7.3 SLOW:
SELECT Id, FirstName, LastName
FROM identity.Users
WHERE LastName LIKE N'Abd%';

-- 7.4 SLOW:
SELECT *
FROM operations.AuditLogs
WHERE Id = 50000;

-- 7.5 SLOW:
SELECT Id, TotalAmount, PaidAmount
FROM finance.Invoices
WHERE InvoiceNumber = 'LAB-INV-2026-000001';

-- 7.6 SLOW:
DECLARE @Email NVARCHAR(320) = N'student@example.com';
SELECT Id, FirstName, LastName
FROM identity.Users
WHERE Email = @Email;

-- 7.7 SLOW:
DECLARE @LastName NVARCHAR(100) = N'Hassan';
IF @LastName IS NULL
BEGIN
    SELECT Id, FirstName, Email
    FROM identity.Users;
END
ELSE
BEGIN
    SELECT Id, FirstName, Email
    FROM identity.Users
    WHERE LastName = @LastName;
END;

-- 7.8 Another non-SARGable condition and its range-based replacement.
SELECT Id, Email
FROM identity.Users
WHERE CreatedAtUtc >= '2026-03-15T00:00:00'
  AND CreatedAtUtc <  '2026-03-16T00:00:00';
GO
