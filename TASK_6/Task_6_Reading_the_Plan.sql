USE [LmsTrainingLab];
GO

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
