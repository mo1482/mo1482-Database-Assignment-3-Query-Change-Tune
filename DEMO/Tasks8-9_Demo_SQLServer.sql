/*
  SIMULATION ACADEMY — DATABASE ASSIGNMENT 3
  Submission section: Tasks 8, 9
  Execute against a TEST copy of LmsTrainingLab, after schema verification.
  Review NOTES.md before execution. Run sections one at a time.
*/

USE [LmsTrainingLab_Demo];
GO

/* ================================================================
   TASK 8 - WHEN THE ESTIMATE IS WRONG
   Create a large, skewed table; create a statistic before the skewed load and
   prevent automatic recomputation so the estimate is stale for the test.
   ================================================================ */

DROP TABLE IF EXISTS dbo.Assignment3_SpillLab;

CREATE TABLE dbo.Assignment3_SpillLab
(
    RowId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Assignment3_SpillLab PRIMARY KEY CLUSTERED,
    SkewKey INT NOT NULL,
    DistinctBucket INT NOT NULL,
    SortValue INT NOT NULL,
    Payload VARCHAR(500) NOT NULL,
    UniqueToken UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Assignment3_SpillLab_UniqueToken DEFAULT NEWID()
);

-- Small initial population; maximum SkewKey here is 100.
;WITH N AS
(
    SELECT CONVERT(INT, 1) AS n
    UNION ALL
    SELECT n + 1 FROM N WHERE n < 1000
)
INSERT INTO dbo.Assignment3_SpillLab (SkewKey, DistinctBucket, SortValue, Payload)
SELECT
    CONVERT(INT, (n % 100) + 1),
    CONVERT(INT, n % 50),
    CONVERT(INT, n),
    REPLICATE('A', 400)
FROM N
OPTION (MAXRECURSION 0);

-- Preserve the small distribution as the optimizer's stale histogram.
CREATE STATISTICS ST_Assignment3_SkewKey
ON dbo.Assignment3_SpillLab (SkewKey)
WITH FULLSCAN, NORECOMPUTE;

-- Large out-of-range population. The new SkewKey value is far beyond the
-- histogram's maximum of 100; the optimizer may estimate very few rows.
;WITH N AS
(
    SELECT CONVERT(INT, 1) AS n
    UNION ALL
    SELECT n + 1 FROM N WHERE n < 300000
)
INSERT INTO dbo.Assignment3_SpillLab (SkewKey, DistinctBucket, SortValue, Payload)
SELECT
    999999,
    CONVERT(INT, n % 1000),
    CONVERT(INT, 300000 - n),
    REPLICATE('Z', 400)
FROM N
OPTION (MAXRECURSION 0);

-- Run with Include Actual Execution Plan enabled (Ctrl+M in SSMS).
-- Look for Sort > Warnings > SpillToTempDb and compare Estimated Rows to Actual Rows.
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT SortValue, Payload
FROM dbo.Assignment3_SpillLab
WHERE SkewKey = 999999
ORDER BY SortValue DESC
OPTION (RECOMPILE, MAXDOP 1);
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- Fix the stale cardinality information, then repeat the exact same query.
UPDATE STATISTICS dbo.Assignment3_SpillLab ST_Assignment3_SkewKey WITH FULLSCAN;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT SortValue, Payload
FROM dbo.Assignment3_SpillLab
WHERE SkewKey = 999999
ORDER BY SortValue DESC
OPTION (RECOMPILE, MAXDOP 1);
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO


/* ================================================================
   TASK 9 - ONE OF EACH
   9.1 DISTINCT on an unindexed, repeated column.
   9.2 Stream Aggregate can use ordered input from an index.
   9.3 DISTINCT on a column already guaranteed unique.
   ================================================================ */

-- First plan: no index exists on DistinctBucket. Expect a Hash Match (Aggregate)
-- or a Sort + Stream Aggregate depending on data size and optimizer estimates.
SELECT DISTINCT DistinctBucket
FROM dbo.Assignment3_SpillLab;

-- Add an index whose key order supplies rows grouped by DistinctBucket.
IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.Assignment3_SpillLab')
      AND name = N'IX_Assignment3_SpillLab_DistinctBucket'
)
BEGIN
    CREATE INDEX IX_Assignment3_SpillLab_DistinctBucket
    ON dbo.Assignment3_SpillLab (DistinctBucket);
END;

-- With ordered input, SQL Server can often use Stream Aggregate and avoid
-- building a hash table or adding a separate Sort.
SELECT DISTINCT DistinctBucket
FROM dbo.Assignment3_SpillLab;

-- RowId is the clustered primary key and is already unique. SQL Server can
-- prove uniqueness and may remove the DISTINCT operation entirely.
SELECT DISTINCT RowId
FROM dbo.Assignment3_SpillLab;
GO
