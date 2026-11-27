USE [LmsTrainingLab];
GO

DROP TABLE IF EXISTS #FinanceLateInvoices;

SELECT
    i.Id AS InvoiceId,
    i.InvoiceNumber,
    (SELECT sp.StudentNumber
     FROM identity.StudentProfiles AS sp
     WHERE sp.Id = i.StudentId) AS StudentWhoOwes,
    i.TotalAmount AS InvoiceAmount,
    ISNULL(i.PaidAmount, 0) AS AmountPaid,
    i.TotalAmount - ISNULL(i.PaidAmount, 0) AS AmountRemaining,
    i.DueAtUtc,
    DATEDIFF(DAY, i.DueAtUtc, SYSUTCDATETIME()) AS DaysLate,
    CASE
        WHEN i.DueAtUtc < DATEADD(MONTH, -2, SYSUTCDATETIME())
          OR i.TotalAmount - ISNULL(i.PaidAmount, 0) > 10000
            THEN 'Urgent'
        WHEN i.DueAtUtc < DATEADD(MONTH, -1, SYSUTCDATETIME())
            THEN 'Medium'
        ELSE 'Low'
    END AS Priority
INTO #FinanceLateInvoices
FROM finance.Invoices AS i
WHERE i.DueAtUtc < SYSUTCDATETIME()
  AND ISNULL(i.PaidAmount, 0) < i.TotalAmount;

SELECT
    InvoiceId,
    InvoiceNumber,
    StudentWhoOwes,
    InvoiceAmount,
    AmountPaid,
    AmountRemaining,
    DueAtUtc,
    DaysLate,
    Priority
FROM #FinanceLateInvoices
ORDER BY
    CASE Priority WHEN 'Urgent' THEN 1 WHEN 'Medium' THEN 2 ELSE 3 END,
    AmountRemaining DESC,
    InvoiceAmount DESC;
GO

-- 2.1 Create the department only if it does not already exist.
IF NOT EXISTS
(
    SELECT 1
    FROM academic.Departments
    WHERE DepartmentCode = 'DSAI'
)
BEGIN
    INSERT INTO academic.Departments (DepartmentCode, DepartmentName)
    VALUES ('DSAI', N'Data Science & Artificial Intelligence');
END;

-- 2.2 Create the first course.
DECLARE @DSAIDepartmentId INT;
SELECT @DSAIDepartmentId = Id
FROM academic.Departments
WHERE DepartmentCode = 'DSAI';

IF @DSAIDepartmentId IS NULL
    THROW 51001, 'DSAI department was not found after the insert.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM academic.Courses
    WHERE CourseCode = 'DSAI-101'
)
BEGIN
    INSERT INTO academic.Courses
        (DepartmentId, CourseCode, Title, CreditHours, PassMark, IsActive)
    VALUES
        (@DSAIDepartmentId, 'DSAI-101', N'Introduction to Data Analysis', 3, 60, 1);
END;

-- 2.3 Create Summer 2027.
IF NOT EXISTS
(
    SELECT 1
    FROM academic.Terms
    WHERE TermName = N'Summer 2027'
)
BEGIN
    INSERT INTO academic.Terms
        (TermName, StartDate, EndDate, RegistrationStartDate, RegistrationEndDate)
    VALUES
        (N'Summer 2027', '2027-06-15', '2027-08-31', '2027-05-01', '2027-06-10');
END;

-- 2.4 Announcement addressed to all students.
IF NOT EXISTS
(
    SELECT 1
    FROM content.Announcements
    WHERE Title = N'Summer 2027 Registration Opens'
)
BEGIN
    INSERT INTO content.Announcements
        (Title, Body, PublishedAtUtc, IsPublished, TargetAudience)
    VALUES
        (N'Summer 2027 Registration Opens',
         N'Registration for Summer 2027 opens on 1 May 2027.',
         SYSUTCDATETIME(), 1, N'All Students');
END;

-- 2.5 Create the Teaching Assistant role.
IF NOT EXISTS
(
    SELECT 1
    FROM identity.Roles
    WHERE RoleName = N'Teaching Assistant'
)
BEGIN
    INSERT INTO identity.Roles (RoleName)
    VALUES (N'Teaching Assistant');
END;

-- Verification for Task 2.
SELECT * FROM academic.Departments WHERE DepartmentCode = 'DSAI';
SELECT * FROM academic.Courses WHERE CourseCode = 'DSAI-101';
SELECT * FROM academic.Terms WHERE TermName = N'Summer 2027';
SELECT * FROM content.Announcements WHERE Title = N'Summer 2027 Registration Opens';
SELECT * FROM identity.Roles WHERE RoleName = N'Teaching Assistant';
GO

-- 3.1 A sequence is independent of an invoice table and is shared by clients.
DECLARE @SequenceStartValue BIGINT;
SELECT @SequenceStartValue =
    ISNULL(MAX(TRY_CONVERT(BIGINT,
        RIGHT(InvoiceNumber,
            CASE WHEN CHARINDEX('-', REVERSE(InvoiceNumber)) > 0
                 THEN CHARINDEX('-', REVERSE(InvoiceNumber)) - 1
                 ELSE 0 END))), 0) + 1
FROM finance.Invoices
WHERE InvoiceNumber LIKE 'LAB-INV-2026-%';

IF @SequenceStartValue < 1 SET @SequenceStartValue = 1;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.sequences
    WHERE object_id = OBJECT_ID(N'finance.InvoiceNumberSequence')
)
BEGIN
    DECLARE @CreateSequenceSql NVARCHAR(MAX) =
        N'CREATE SEQUENCE finance.InvoiceNumberSequence AS BIGINT START WITH '
        + CONVERT(NVARCHAR(30), @SequenceStartValue)
        + N' INCREMENT BY 1 CACHE 50 NO CYCLE;';
    EXEC sys.sp_executesql @CreateSequenceSql;
END;
GO

-- 3.2 Insert an invoice for an existing student. The student is selected
-- deterministically; replace the ORDER BY with a chosen StudentNumber if needed.
DECLARE @ExistingStudentId INT;
SELECT TOP (1) @ExistingStudentId = Id
FROM identity.StudentProfiles
ORDER BY Id;

IF @ExistingStudentId IS NULL
    THROW 51002, 'There is no existing student in identity.StudentProfiles.', 1;

DECLARE @InvoiceSequenceValue BIGINT = NEXT VALUE FOR finance.InvoiceNumberSequence;
DECLARE @GeneratedInvoiceNumber VARCHAR(50) =
    'LAB-INV-2026-' +
    CASE
        WHEN @InvoiceSequenceValue < 1000000
            THEN RIGHT('000000' + CONVERT(VARCHAR(20), @InvoiceSequenceValue), 6)
        ELSE CONVERT(VARCHAR(20), @InvoiceSequenceValue)
    END;

INSERT INTO finance.Invoices
    (InvoiceNumber, StudentId, TotalAmount, PaidAmount, CurrencyCode, DueAtUtc)
OUTPUT
    inserted.Id,
    inserted.InvoiceNumber,
    inserted.StudentId,
    inserted.TotalAmount,
    inserted.PaidAmount,
    inserted.DueAtUtc
VALUES
    (@GeneratedInvoiceNumber, @ExistingStudentId, 4500.00, 0.00, 'EGP',
     DATEADD(DAY, 30, SYSUTCDATETIME()));
GO

-- 3.3 Sequence values are NOT transactional. A ROLLBACK does not return a
-- consumed sequence number to the sequence. The second value will be higher.
DECLARE @NumberTakenInsideTransaction BIGINT;
BEGIN TRANSACTION;
    SET @NumberTakenInsideTransaction = NEXT VALUE FOR finance.InvoiceNumberSequence;
    SELECT @NumberTakenInsideTransaction AS NumberTakenInsideTransaction;
ROLLBACK TRANSACTION;

SELECT NEXT VALUE FOR finance.InvoiceNumberSequence AS NumberAfterRollback;
GO

DECLARE @NewTermId INT;
DECLARE @NewTermStartDate DATE = '2027-06-15';
DECLARE @SourceTermId INT;
DECLARE @InsertColumns NVARCHAR(MAX);
DECLARE @SelectColumns NVARCHAR(MAX);
DECLARE @CopySql NVARCHAR(MAX);

SELECT @NewTermId = Id
FROM academic.Terms
WHERE TermName = N'Summer 2027';

IF @NewTermId IS NULL
    THROW 51003, 'Summer 2027 term was not found. Complete Task 2.3 first.', 1;

SELECT TOP (1) @SourceTermId = Id
FROM academic.Terms
WHERE EndDate < @NewTermStartDate
  AND Id <> @NewTermId
ORDER BY EndDate DESC, Id DESC;

IF @SourceTermId IS NULL
    THROW 51004, 'No earlier term exists from which sections can be copied.', 1;

SELECT
    @InsertColumns = STRING_AGG(CONVERT(NVARCHAR(MAX), QUOTENAME(c.name)), N', '),
    @SelectColumns = STRING_AGG
    (
        CONVERT(NVARCHAR(MAX),
            CASE WHEN c.name = N'TermId'
                 THEN N'@NewTermId AS ' + QUOTENAME(c.name)
                 ELSE N's.' + QUOTENAME(c.name)
            END),
        N', '
    )
FROM sys.columns AS c
WHERE c.object_id = OBJECT_ID(N'academic.Sections')
  AND c.is_identity = 0
  AND c.is_computed = 0
  AND c.generated_always_type = 0
  AND c.system_type_id <> 189; 

IF @InsertColumns IS NULL OR COL_LENGTH(N'academic.Sections', N'TermId') IS NULL
    THROW 51005, 'Could not discover the expected academic.Sections columns.', 1;

SET @CopySql = N'
    INSERT INTO academic.Sections (' + @InsertColumns + N')
    SELECT ' + @SelectColumns + N'
    FROM academic.Sections AS s
    WHERE s.TermId = @SourceTermId;';

EXEC sys.sp_executesql
    @CopySql,
    N'@NewTermId INT, @SourceTermId INT',
    @NewTermId = @NewTermId,
    @SourceTermId = @SourceTermId;

SELECT @SourceTermId AS CopiedFromTermId, @NewTermId AS CopiedToTermId;
SELECT *
FROM academic.Sections
WHERE TermId = @NewTermId
ORDER BY Id;
GO
