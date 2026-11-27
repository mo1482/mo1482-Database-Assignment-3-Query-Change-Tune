USE [LmsTrainingLab];
GO

-- 5.1 Course catalog; friendly headings; most credits first, then title.
SELECT
    CourseCode AS [Course Code],
    Title AS [Course Title],
    CreditHours AS [Credit Hours]
FROM academic.Courses
ORDER BY CreditHours DESC, Title ASC;

-- 5.2 Five random students, with a new random sample on each execution.
SELECT TOP (5)
    Id,
    StudentNumber
FROM identity.StudentProfiles
ORDER BY NEWID();

-- 5.3 Leading/trailing whitespace. Use code-point checks so tabs and other
SELECT Id, Email
FROM identity.Users
WHERE UNICODE(LEFT(Email, 1)) IN (32, 9, 10, 11, 12, 13, 160)
   OR UNICODE(RIGHT(Email, 1)) IN (32, 9, 10, 11, 12, 13, 160)
   OR DATALENGTH(Email) <> DATALENGTH(RTRIM(Email));

-- 5.4 Binary collation makes the case comparison case-sensitive even when the
-- database's default collation is case-insensitive.
SELECT Id, Email
FROM identity.Users
WHERE Email COLLATE Latin1_General_100_BIN2
   <> LOWER(Email) COLLATE Latin1_General_100_BIN2;

-- 5.5 Clearly invalid email addresses: no @, @ as first character, or no dot
-- after @. Multiple @ characters are also flagged as invalid.
SELECT Id, Email
FROM identity.Users
WHERE Email IS NULL
   OR CHARINDEX('@', Email) = 0
   OR CHARINDEX('@', Email) = 1
   OR CHARINDEX('.', Email, CHARINDEX('@', Email) + 1) = 0
   OR (LEN(Email) - LEN(REPLACE(Email, '@', ''))) <> 1;

-- 5.6 The domain/provider part after @, once per provider, alphabetically.
SELECT DISTINCT
    SUBSTRING(Email, CHARINDEX('@', Email) + 1, 320) AS EmailProvider
FROM identity.Users
WHERE CHARINDEX('@', Email) > 1
  AND CHARINDEX('.', Email, CHARINDEX('@', Email) + 1) > 0
ORDER BY EmailProvider;

-- 5.7 Most recently logged-in users first; never-logged-in users last.
SELECT Id, FirstName, LastName, Email, LastLoginAtUtc
FROM identity.Users
ORDER BY
    CASE WHEN LastLoginAtUtc IS NULL THEN 1 ELSE 0 END,
    LastLoginAtUtc DESC,
    Id DESC;

-- 5.8 Half-open date range includes every instant on 31 October 2026.
SELECT Id, InvoiceId, Amount, PaidAtUtc
FROM finance.Payments
WHERE PaidAtUtc >= '2026-10-01T00:00:00'
  AND PaidAtUtc <  '2026-11-01T00:00:00'
ORDER BY PaidAtUtc;

-- 5.9 Convert UTC to Cairo time before applying the local 00:00-05:00 filter.
SELECT
    Id,
    InvoiceId,
    Amount,
    PaidAtUtc AT TIME ZONE 'UTC' AT TIME ZONE 'Egypt Standard Time' AS PaidAtCairo
FROM finance.Payments
WHERE CONVERT(TIME(0), PaidAtUtc AT TIME ZONE 'UTC' AT TIME ZONE 'Egypt Standard Time')
      >= '00:00:00'
  AND CONVERT(TIME(0), PaidAtUtc AT TIME ZONE 'UTC' AT TIME ZONE 'Egypt Standard Time')
      < '05:00:00'
ORDER BY PaidAtUtc;

-- 5.10 Friday test independent of SET DATEFIRST and language settings.
-- 1900-01-05 was a Friday; a zero remainder means Friday.
SELECT Id, SectionId, SessionDate
FROM academic.AttendanceSessions
WHERE DATEDIFF(DAY, CONVERT(DATE, '19000105', 112), CONVERT(DATE, SessionDate)) % 7 = 0
ORDER BY SessionDate;

-- 5.11 Egyptian mobile numbers. The expression removes common formatting.
SELECT
    Id,
    PhoneNumber
FROM identity.Users
WHERE
    (
        (
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumber, ' ', ''), '-', ''), '(', ''), ')', ''), '+', ''), '.', '') LIKE '01[0125]%'
            AND LEN(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumber, ' ', ''), '-', ''), '(', ''), ')', ''), '+', ''), '.', '')) = 11
        )
        OR
        (
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumber, ' ', ''), '-', ''), '(', ''), ')', ''), '+', ''), '.', '') LIKE '201[0125]%'
            AND LEN(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumber, ' ', ''), '-', ''), '(', ''), ')', ''), '+', ''), '.', '')) = 12
        )
        OR
        (
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumber, ' ', ''), '-', ''), '(', ''), ')', ''), '+', ''), '.', '') LIKE '00201[0125]%'
            AND LEN(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumber, ' ', ''), '-', ''), '(', ''), ')', ''), '+', ''), '.', '')) = 14
        )
    )
    AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumber, ' ', ''), '-', ''), '(', ''), ')', ''), '+', ''), '.', '') NOT LIKE '%[^0-9]%';

-- 5.12 Show first 3 and last 2 characters only; short values are fully hidden.
SELECT
    Id,
    PhoneNumber,
    CASE
        WHEN PhoneNumber IS NULL THEN NULL
        WHEN LEN(PhoneNumber) <= 5 THEN REPLICATE('*', LEN(PhoneNumber))
        ELSE LEFT(PhoneNumber, 3)
             + REPLICATE('*', LEN(PhoneNumber) - 5)
             + RIGHT(PhoneNumber, 2)
    END AS MaskedPhoneNumber
FROM identity.Users;

-- 5.13 Convert the numeric suffix after the final dash to a real integer.
SELECT
    Id,
    InvoiceNumber,
    TRY_CONVERT(BIGINT,
        RIGHT(InvoiceNumber,
            CASE WHEN CHARINDEX('-', REVERSE(InvoiceNumber)) > 0
                 THEN CHARINDEX('-', REVERSE(InvoiceNumber)) - 1
                 ELSE 0 END)
    ) AS InvoiceRunningNumber
FROM finance.Invoices
WHERE CHARINDEX('-', InvoiceNumber) > 0
ORDER BY InvoiceRunningNumber;

-- 5.14 Human-readable lesson duration. NULL becomes Not set.
SELECT
    Id,
    Title,
    CASE
        WHEN EstimatedDurationMinutes IS NULL THEN N'Not set'
        WHEN EstimatedDurationMinutes >= 60
            THEN CONCAT(EstimatedDurationMinutes / 60, N' h ',
                        EstimatedDurationMinutes % 60, N' min')
        ELSE CONCAT(EstimatedDurationMinutes, N' min')
    END AS LessonLength
FROM content.Lessons;

-- 5.15 A literal percent sign in LIKE is written as [%].
SELECT Id, Title, Body
FROM content.Announcements
WHERE Body LIKE N'%[%]%' OR Title LIKE N'%[%]%';

-- 5.16 TOP WITH TIES returns every invoice sharing the fifth-place amount.
SELECT TOP (5) WITH TIES
    Id, InvoiceNumber, TotalAmount
FROM finance.Invoices
ORDER BY TotalAmount DESC;

-- 5.17 Largest 10 percent of payments by amount.
SELECT TOP (10) PERCENT
    Id, InvoiceId, Amount, PaidAtUtc
FROM finance.Payments
ORDER BY Amount DESC;

-- 5.18 Keep NULL locations as well as locations other than Hall A.
SELECT Id, SectionCode, Location
FROM academic.Sections
WHERE Location IS NULL OR Location <> N'Hall A'
ORDER BY SectionCode;

-- 5.19 Money still owed; NULLIF prevents division by zero.
SELECT
    Id,
    InvoiceNumber,
    TotalAmount,
    ISNULL(PaidAmount, 0) AS PaidAmount,
    TotalAmount - ISNULL(PaidAmount, 0) AS AmountOwed,
    CASE WHEN ISNULL(PaidAmount, 0) > 0 THEN 'Partially paid' ELSE 'Not paid' END AS PaymentState,
    CASE WHEN DueAtUtc < SYSUTCDATETIME() THEN 'Overdue' ELSE 'Not overdue' END AS DueState,
    CONVERT(DECIMAL(6,1),
        100.0 * ISNULL(PaidAmount, 0) / NULLIF(TotalAmount, 0)
    ) AS PercentagePaid
FROM finance.Invoices
WHERE TotalAmount > 0
  AND ISNULL(PaidAmount, 0) < TotalAmount
ORDER BY AmountOwed DESC, DueAtUtc ASC;

-- 5.20 Page 3, 20 users per page, newest first (OFFSET is zero-based).
SELECT Id, FirstName, LastName, Email, CreatedAtUtc
FROM identity.Users
ORDER BY CreatedAtUtc DESC, Id DESC
OFFSET 40 ROWS FETCH NEXT 20 ROWS ONLY;

-- 5.21 Keyset pagination for millions of audit rows. Supply the last Id already
-- displayed by the client; the next page starts strictly after that value.
DECLARE @LastSeenAuditId BIGINT = 50000; -- replace with the last displayed Id
SELECT TOP (50) Id, EventType, EntityName, EntityId, CreatedAtUtc, Details
FROM operations.AuditLogs
WHERE Id > @LastSeenAuditId
ORDER BY Id ASC;

-- 5.22 TOP without ORDER BY is arbitrary, not the latest ten. Use the time column.
SELECT TOP (10)
    Id, InvoiceId, Amount, PaidAtUtc
FROM finance.Payments
ORDER BY PaidAtUtc DESC, Id DESC;

-- 5.23 Ten longest published lesson titles over 40 characters. GROUP BY on the
SELECT TOP (10)
    UPPER(LTRIM(RTRIM(Title))) AS NormalizedTitle,
    LEN(LTRIM(RTRIM(Title))) AS TitleLength,
    CASE
        WHEN MAX(EstimatedDurationMinutes) IS NULL THEN 'Not set'
        WHEN MAX(EstimatedDurationMinutes) <= 15 THEN 'Quick'
        WHEN MAX(EstimatedDurationMinutes) <= 45 THEN 'Standard'
        ELSE 'Long'
    END AS DurationCategory
FROM content.Lessons
WHERE IsPublished = 1
  AND LEN(LTRIM(RTRIM(Title))) > 40
GROUP BY UPPER(LTRIM(RTRIM(Title))), LEN(LTRIM(RTRIM(Title)))
ORDER BY TitleLength DESC, NormalizedTitle ASC;

-- 5.24 One row per due-month/currency/payment-state combination; latest 12 months.
SELECT TOP (12)
    CONVERT(CHAR(7), DueAtUtc, 126) AS DueMonth,
    CurrencyCode,
    CASE
        WHEN ISNULL(PaidAmount, 0) > 0 THEN 'Partially paid'
        ELSE 'Not paid'
    END AS PaymentState,
    COUNT_BIG(*) AS InvoiceCount,
    SUM(TotalAmount - ISNULL(PaidAmount, 0)) AS TotalOutstanding
FROM finance.Invoices
WHERE DueAtUtc < SYSUTCDATETIME()
  AND TotalAmount > ISNULL(PaidAmount, 0)
GROUP BY
    CONVERT(CHAR(7), DueAtUtc, 126),
    CurrencyCode,
    CASE
        WHEN ISNULL(PaidAmount, 0) > 0 THEN 'Partially paid'
        ELSE 'Not paid'
    END
ORDER BY DueMonth DESC, CurrencyCode ASC, PaymentState ASC;
GO
