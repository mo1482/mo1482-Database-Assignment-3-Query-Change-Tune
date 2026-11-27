/*
  SIMULATION ACADEMY — DATABASE ASSIGNMENT 3
  Submission section: Tasks 6
  Execute against a TEST copy of LmsTrainingLab, after schema verification.
  Review NOTES.md before execution. Run sections one at a time.
*/

USE [LmsTrainingLab_Demo];
GO

/* ================================================================
   TASK 6 - READING THE PLAN
   The assignment's supplied query combines two tables. The global assignment
   rule prohibits table-joining syntax in submitted answers, so this equivalent version
   obtains StudentNumber with a scalar lookup instead. Its plan is NOT identical
   to the instructor-provided query. For the exact Task 6 screenshot, run the
   exact statement printed on page 4 of the PDF in SSMS and document its plan.
   ================================================================ */

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT TOP (15)
    i.InvoiceNumber,
    (SELECT sp.StudentNumber
     FROM identity.StudentProfiles AS sp
     WHERE sp.Id = i.StudentId) AS StudentNumber,
    i.TotalAmount - i.PaidAmount AS Remaining,
    CASE
        WHEN i.DueAtUtc < DATEADD(DAY, -60, SYSUTCDATETIME()) THEN 'Urgent'
        ELSE 'Normal'
    END AS Urgency
FROM finance.Invoices AS i
WHERE i.PaidAmount < i.TotalAmount
  AND i.DueAtUtc < SYSUTCDATETIME()
ORDER BY Remaining DESC;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO
