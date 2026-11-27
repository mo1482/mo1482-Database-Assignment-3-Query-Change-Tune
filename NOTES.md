# Database Assignment 3 — Complete Solution Notes

**Course:** Simulation Academy — .NET Diploma, Cycle 1  
**Assignment:** Query, Change & Tune Data  
**Database:** `LmsTrainingLab`  


## Submission layout — matches the 100-point rubric

| Rubric section | Points | Deliverable in this package |
|---|---:|---|
| **1–4 — Temp list, inserts, numbering, copy** | **15** | `01_Tasks_1-4_Temp_List_Inserts_Numbering_Copy_15_Points/Tasks_1-4.sql` |
| **5 — Management reports** | **22** | `02_Task_5_Management_Reports_22_Points/Task_5_Management_Reports.sql` (5.1–5.24) |
| **6 — Reading the plan** | **12** | `03_Task_6_Reading_the_Plan_12_Points/Task_6_Reading_the_Plan.sql` + Task 6 notes and evidence checklist |
| **7 — Make it faster** | **15** | `04_Task_7_Make_it_Faster_15_Points/Task_7_Make_it_Faster.sql` (7.1–7.8) |
| **8–9 — Spill + one of each** | **10** | `05_Tasks_8-9_Spill_and_Distinct_10_Points/Tasks_8-9_Spill_and_Distinct.sql` + evidence checklist |
| **10 — The CTO's question** | **5** | `06_Task_10_CTO_Question_5_Points/Task_10_INT_vs_GUID.md` |
| **11–13 — Changes, audit, sync** | **15** | `07_Tasks_11-13_Changes_Audit_Sync_15_Points/Tasks_11-13_Changes_Audit_Sync.sql` |
| **NOTES.md & readability** | **6** | This file (`NOTES.md`) and the root `README.md` |
| **Total** | **100** | All items above |

> Each rubric section has its own file/folder and is kept in the same order as the grading table in the assignment PDF. The explanatory notes remain consolidated in this root `NOTES.md`.

> **Important database/schema limitation**  
> The supplied 7-page PDF contains the task descriptions and the supplied Task 6 query, but it does not contain the `LmsTrainingLab` backup or the complete `CREATE TABLE` definitions. Consequently, no honest solution can guarantee every guessed column name against your local database. The SQL file uses the exact names visible in the assignment wherever available and conventional names elsewhere. Verify the assumptions below before running it. The demo results/screenshots included later are real outputs from the separate SQLite demo database and are explicitly labelled as such; no SQL Server execution-plan properties or logical-read values are fabricated.

## Global assignment rules

1. Put the task number above every answer.
2. Do not use `JOIN` syntax in the answers.
3. Task 5 must use one table per query and must not use subqueries.
4. Run the work on your own `LmsTrainingLab` copy and commit at least once per task on the exact branch supplied by the Simulation Academy website. Do not commit directly to `main`.
5. Submit the SQL files, screenshots for Tasks 6–9, and this `NOTES.md`.

## Schema verification before execution

Run these statements first in SSMS while connected to `LmsTrainingLab`:

```sql
SELECT name AS SchemaName
FROM sys.schemas
ORDER BY name;

SELECT
    OBJECT_SCHEMA_NAME(object_id) AS SchemaName,
    OBJECT_NAME(object_id) AS TableName,
    column_id,
    name AS ColumnName,
    TYPE_NAME(user_type_id) AS DataType,
    max_length,
    is_nullable
FROM sys.columns
WHERE OBJECTPROPERTY(object_id, 'IsUserTable') = 1
ORDER BY OBJECT_SCHEMA_NAME(object_id), OBJECT_NAME(object_id), column_id;
```

The inspection statements above are diagnostic only. The submitted solution queries themselves do not use `JOIN` syntax. In particular, verify these assumptions:

| Table | Columns assumed by the solution |
|---|---|
| `finance.Invoices` | `Id`, `InvoiceNumber`, `StudentId`, `TotalAmount`, `PaidAmount`, `DueAtUtc`, `CurrencyCode` |
| `finance.Payments` | `Id`, `InvoiceId`, `Amount`, `PaidAtUtc` |
| `identity.StudentProfiles` | `Id`, `StudentNumber` |
| `identity.Users` | `Id`, `FirstName`, `LastName`, `Email`, `PhoneNumber`, `CreatedAtUtc`, `LastLoginAtUtc` |
| `academic.Departments` | `Id`, `DepartmentCode`, `DepartmentName` |
| `academic.Courses` | `Id`, `DepartmentId`, `CourseCode`, `Title`, `CreditHours`, `PassMark`, `IsActive` |
| `academic.Terms` | `Id`, `TermName`, `StartDate`, `EndDate`, `RegistrationStartDate`, `RegistrationEndDate` |
| `academic.Sections` | `Id`, `TermId`; Task 4 dynamically copies the other ordinary columns |
| `academic.AttendanceSessions` | `Id`, `SectionId`, `SessionDate` |
| `academic.Enrollments` | `Status`, `FinalScore`, `LetterGrade` |
| `content.Lessons` | `Id`, `Title`, `EstimatedDurationMinutes`, `IsPublished` |
| `content.Announcements` | `Id`, `Title`, `Body`, `PublishedAtUtc`, `ExpiresAtUtc`, `IsPublished`, `TargetAudience` |
| `identity.Roles` | `Id`, `RoleName` |
| `operations.AuditLogs` | `Id`, `EventType`, `EntityName`, `EntityId`, `CreatedAtUtc`, `Details` |

The PDF explicitly shows these names in the Task 6 and Task 7 examples: `finance.Invoices`, `identity.StudentProfiles`, `identity.Users`, `finance.Payments`, `operations.AuditLogs`, `InvoiceNumber`, `StudentId`, `TotalAmount`, `PaidAmount`, `DueAtUtc`, `CreatedAtUtc`, `Email`, `LastName`, and `PaidAtUtc`. Other names are implementation assumptions and must be matched to the actual database.

---


## Demo database and screenshots for Tasks 6–9

The folder `09_Demo_Database_and_Screenshots/` contains a locally generated `LmsTrainingLab_Demo.sqlite` file plus six PNG evidence captures. The database contains 3,500 students, 18,000 invoices, 30,000 users, 90,000 payments, 50,000 audit logs, and 67,000 Task 8/9 practice rows. The sample generation is deterministic (seed `20261127`) and can be rerun with `build_demo.py`.

The screenshots are genuine output from **SQLite 3.46.1**, not screenshots from SSMS. In Task 6 the correlated scalar subquery is used to comply with the assignment-wide no-JOIN restriction. Task 7 demonstrates how range and prefix predicates change SQLite access from scans to indexed searches. Task 8 shows SQLite's real `USE TEMP B-TREE FOR ORDER BY` plan step and its removal after a composite index is created. Task 9 shows `USE TEMP B-TREE FOR DISTINCT`, then an indexed covering scan, then DISTINCT over a unique key.

**Do not submit the SQLite captures as if they were SQL Server actual execution plans.** SQLite has no SQL Server `SpillToTempDb` warning, spill-level property, memory-grant details, or `SET STATISTICS IO` logical reads. To obtain the actual SQL Server screenshots requested by the assignment, use `SQLServer_Demo_Database_Setup.sql` to create a separate SQL Server demo database, then run `Task6_Demo_SQLServer.sql`, `Task7_Demo_SQLServer.sql`, and `Tasks8-9_Demo_SQLServer.sql` in SSMS. Those native scripts were prepared but not executed in this environment because SQL Server tooling is unavailable.

See `09_Demo_Database_and_Screenshots/README.md` for the exact reproducibility and SSMS steps.

# Task 1 — The Finance Meeting

### 1.1 Working list

A local temporary table (`#FinanceLateInvoices`) is created with `SELECT ... INTO`. It exists only in the current SQL Server session and does not alter the permanent invoice data. The report shows the invoice number, student identifier, total, paid amount, remaining amount, due date, and days late.

The filter is:

- `DueAtUtc < SYSUTCDATETIME()` — the invoice is overdue.
- `ISNULL(PaidAmount, 0) < TotalAmount` — it is not fully paid.

### 1.2 Priority

The `CASE` is evaluated from top to bottom:

- **Urgent:** more than two calendar months overdue, or remaining balance greater than 10,000.
- **Medium:** not urgent and more than one calendar month overdue.
- **Low:** all remaining overdue/unpaid invoices.

`DATEADD(MONTH, -2, SYSUTCDATETIME())` follows calendar-month semantics, matching “more than two months” better than assuming every month is 30 days.

### 1.3 Ordering

A numeric `CASE` puts Urgent before Medium before Low. Within each priority, remaining balance is descending, then invoice total descending.

**Note:** `StudentWhoOwes` is the student's `StudentNumber`, retrieved from `identity.StudentProfiles` using the `StudentId` to profile-key mapping shown in the supplied Task 6 query. The PDF does not provide a confirmed student display-name path, so the stable student number is used.

# Task 2 — A New Department

- **2.1:** Insert `DSAI` only if that department code does not already exist.
- **2.2:** Read the department's generated key into `@DSAIDepartmentId`, then create `DSAI-101` with 3 credits and pass mark 60.
- **2.3:** Store class dates 15 June–31 August 2027 and registration dates 1 May–10 June 2027.
- **2.4:** Add an announcement whose audience is all students and whose text says registration opens on 1 May 2027.
- **2.5:** Add the Teaching Assistant role if absent.

The statements are written to be re-runnable where a natural key is available. If your database uses different role or announcement columns, adjust their insert lists using the schema inspection query.

# Task 3 — Invoice Numbers

### 3.1 Sequence

`finance.InvoiceNumberSequence` is a `BIGINT` sequence. Unlike an `IDENTITY` column, it is not owned by one table, so multiple applications can request the next number. `CACHE 50` reduces sequence-allocation overhead; a server failure can leave gaps, which is acceptable for sequence-generated identifiers.

On first creation, the sequence starts one above the largest existing numeric suffix for the `LAB-INV-2026-` prefix, avoiding collisions with already-issued numbers. Once created, the sequence itself is independent of the invoice table and can be shared by multiple applications. The visible number is formatted as `LAB-INV-2026-000001`. The padding is a minimum of six digits; values above 999999 are kept in full rather than truncated.

### 3.2 New invoice

The script selects one existing student profile, requests a sequence value, and inserts an invoice for 4,500 EGP with no payment and a due date 30 days after the current UTC time. If the coursework expects a particular student, change the `TOP (1)` selection to that student's known key.

### 3.3 Rollback behavior

Sequence values are **not rolled back** with a transaction. Once `NEXT VALUE FOR` has allocated a number, rolling back the transaction does not return that number to the sequence. The later request therefore receives a higher number. Gaps are normal and must not be treated as corruption.

# Task 4 — Next Summer's Timetable

The script locates the term with the latest `EndDate` earlier than Summer 2027. It then dynamically reads the actual `academic.Sections` columns from system metadata and copies all ordinary insertable fields, replacing only `TermId`. Identity, computed, generated-always, and rowversion columns are omitted.

This avoids manually typing sections one by one and avoids inventing the full section schema. Before execution, verify that the copied section attributes do not contain a column that must be regenerated (for example, a globally unique section code). If they do, remove that column from the dynamic copy list or calculate a new value.

The verification query displays every section under the new term id.

# Task 5 — Management Reports

Every query below uses one base table and no subquery.

| Item | Solution technique | Why it satisfies the request |
|---|---|---|
| 5.1 | `ORDER BY CreditHours DESC, Title` | Heaviest courses first; alphabetical within equal credit values. Friendly aliases are used as headings. |
| 5.2 | `TOP (5) ... ORDER BY NEWID()` | Produces a new random sample of five students on each execution. |
| 5.3 | Explicit checks for spaces, tabs, CR/LF, vertical tabs, form feeds, and non-breaking spaces | Checks whitespace missed by a test that only checks ordinary spaces. |
| 5.4 | Compare `Email` and `LOWER(Email)` under a binary collation | Finds uppercase letters even when the database default collation ignores case. |
| 5.5 | `CHARINDEX` checks | Finds missing `@`, an `@` in the first position, no dot after `@`, and multiple `@` symbols. |
| 5.6 | `DISTINCT` on the substring after `@` | Returns each email domain/provider once in alphabetical order. |
| 5.7 | Explicit NULL sort key followed by descending login time | Users with no login date are forced to the bottom. |
| 5.8 | `PaidAtUtc >= 2026-10-01 AND PaidAtUtc < 2026-11-01` | Half-open interval includes all times on 31 October, including late-night payments. |
| 5.9 | `AT TIME ZONE 'UTC' AT TIME ZONE 'Egypt Standard Time'` | Converts UTC to Cairo local time before filtering between 00:00 and 05:00. |
| 5.10 | `DATEDIFF` from a known Friday modulo 7 | Finds Fridays without depending on `SET DATEFIRST` or language. |
| 5.11 | Normalize common phone formatting, then test Egyptian mobile prefixes | Accepts local and international formats for Vodafone, Etisalat, Orange, and WE prefixes. |
| 5.12 | `LEFT`, `RIGHT`, and `REPLICATE('*', ...)` | Keeps the first 3 and last 2 characters visible; hides short values completely. |
| 5.13 | `REVERSE` + `CHARINDEX` + `RIGHT` + `TRY_CONVERT` | Extracts the suffix after the last dash and converts it to a numeric value for sorting. |
| 5.14 | `CASE` + `CONCAT` | Formats minutes as hours/minutes and returns `Not set` for NULL estimates. |
| 5.15 | `LIKE N'%[%]%'` | `[%]` represents a literal percent sign in a LIKE pattern. |
| 5.16 | `TOP (5) WITH TIES` | Includes all invoices tied with the fifth invoice's amount. |
| 5.17 | `TOP (10) PERCENT ... ORDER BY Amount DESC` | Returns the highest 10 percent of payments by amount. |
| 5.18 | `Location IS NULL OR Location <> 'Hall A'` | Keeps sections in other halls and sections that have no assigned location. |
| 5.19 | Balance calculation, `NULLIF`, and `DECIMAL(6,1)` | Shows payment state, overdue state, and one-decimal paid percentage; zero-total rows are excluded safely. |
| 5.20 | `OFFSET 40 FETCH NEXT 20` | Page 3 when page size is 20. A unique `Id` tie-breaker makes the ordering deterministic. |
| 5.21 | `WHERE Id > @LastSeenAuditId ORDER BY Id` | Keyset pagination reads the next 50 audit rows and remains efficient at deep pages when Id is indexed/clustered. |
| 5.22 | `TOP (10) ORDER BY PaidAtUtc DESC, Id DESC` | `TOP` without `ORDER BY` does not mean latest. |
| 5.23 | Normalize title, `GROUP BY`, `TOP (10)`, and duration `CASE` | Deduplicates titles ignoring edge spaces and case, shows character length, and classifies duration. |
| 5.24 | `GROUP BY` due month, currency, and payment state | Produces one row per requested combination and returns the 12 most recent due-month groups. |

### Important details for Task 5

- **5.3:** Checking only ordinary spaces misses tabs, line breaks, vertical tabs, form feeds, and non-breaking spaces. The query checks the Unicode code point at both ends and uses `DATALENGTH` versus `RTRIM` to detect trailing ordinary spaces even though SQL string comparisons can ignore trailing blanks. If the source system can import other Unicode whitespace characters, extend the list.
- **5.9:** The code assumes `PaidAtUtc` is stored as UTC. `Egypt Standard Time` is the SQL Server/Windows time-zone identifier expected on Windows installations. Check `sys.time_zone_info` if the server does not recognize it.
- **5.10:** `1900-01-05` is Friday. The remainder test is independent of `DATEFIRST`, unlike a raw `DATEPART(weekday, ...)` check.
- **5.11:** The query assumes phone numbers are stored with common spaces, hyphens, parentheses, plus signs, or dots only. If the database includes slashes or other formatting characters, normalize them too. It checks prefix, total length, and that the normalized value contains digits only; it does not verify that a number is currently assigned by a carrier.
- **5.12:** The requested masking is character-based. If the field contains punctuation, the visible first 3/last 2 are characters, not necessarily digits. For digits-only masking, strip punctuation first.
- **5.13:** `TRY_CONVERT` returns NULL instead of raising an error if the suffix contains non-numeric characters.
- **5.19:** `NULLIF(TotalAmount, 0)` protects the denominator; `TotalAmount > 0` also excludes zero-total invoices from the report.
- **5.23:** If several published lessons have the same normalized title but inconsistent duration estimates, the solution uses the maximum estimate as a conservative category. If your data guarantees duplicates share the same duration, this is immaterial. If the business rule wants the shortest or latest published lesson, an additional rule is needed to choose the representative row.
- **5.24:** The query returns aggregate counts and total outstanding amount for each group. It treats a NULL paid amount as zero.

# Task 6 — Reading the Plan

The exact query in the assignment PDF is the collection-screen query. It filters invoices that are overdue and not fully paid, calculates the remaining amount, labels invoices more than 60 days overdue as Urgent, orders by remaining amount descending, and returns at most 15 rows.

**Rule conflict to be aware of:** the PDF's supplied Task 6 query itself contains an `INNER JOIN`, while the general instructions say “No JOIN anywhere in your answers.” The SQL file therefore provides a scalar-subquery equivalent to honor the no-table-joining submission rule. That equivalent does **not** have the same execution plan as the instructor's supplied statement. For the requested screenshot of the exact screen query, execute the original query from page 4 as provided by the instructor and confirm with the evaluator whether the supplied query is exempt from the no-JOIN rule. Do not claim the scalar-subquery plan is the original query's plan.

### Expected operators (hypothesis, not a claimed actual plan)

The actual operator choices depend on row counts, indexes, statistics, compatibility level, and parameter values. For the PDF's original query, plausible operators include:

1. **Scan or Seek on `finance.Invoices`:** SQL Server must find overdue, not-fully-paid invoices. Existing indexes determine whether a seek is possible. A scan is plausible if many rows qualify or no useful index exists.
2. **Filter:** Applies `PaidAmount < TotalAmount` and `DueAtUtc < current UTC time` if these predicates are not fully represented by an access method.
3. **Join operator for the supplied query:** The plan may use Nested Loops, Hash Match, or Merge Join depending on estimated row counts and available indexes. The exact plan must be read from SSMS; do not guess which one occurred.
4. **Compute Scalar:** Calculates remaining balance and urgency expression.
5. **Sort:** Needed for `ORDER BY Remaining DESC` unless an access path supplies the requested order. Sorting may require a memory grant and can spill to tempdb.
6. **Top:** Enforces `TOP (15)`. The optimizer may combine Top with Sort as a Top N Sort.

### How to capture the required evidence in SSMS

1. Open a new query window in `LmsTrainingLab`.
2. Press **Ctrl+M** (Include Actual Execution Plan).
3. Run:
   ```sql
   SET STATISTICS IO ON;
   SET STATISTICS TIME ON;
   -- Paste the exact Task 6 query from page 4 of the PDF here.
   SET STATISTICS TIME OFF;
   SET STATISTICS IO OFF;
   ```
4. Save a screenshot of the **Messages** tab showing logical reads and CPU/elapsed time.
5. Save a screenshot of the **Execution Plan** tab with all operators visible.
6. Click each operator and capture its **Properties**. At minimum inspect:
   - Physical Operation and Logical Operation
   - Estimated Number of Rows and Actual Number of Rows
   - Estimated Number of Executions and Actual Number of Executions
   - Estimated I/O Cost, Estimated CPU Cost, and Estimated Subtree Cost
   - Actual Number of Rows Read (where available)
   - Predicate / Seek Predicates
   - Output List
   - Memory Grant and spill warning properties (for Sort/Hash operators)
   - Warnings, conversions, and residual predicates
7. Put the measured values into the table below; do not fill these with guessed values.

| Measurement | Your actual value |
|---|---|
| Logical reads — Invoices | Fill from STATISTICS IO |
| Logical reads — StudentProfiles | Fill from STATISTICS IO |
| CPU time | Fill from STATISTICS TIME |
| Elapsed time | Fill from STATISTICS TIME |
| Estimated rows at main filter | Fill from plan properties |
| Actual rows at main filter | Fill from plan properties |
| Sort spill warning | Yes/No from actual plan |
| Operators observed | List the actual operators |

# Task 7 — Make It Faster

First run the five index statements in the SQL file. They match the list on page 5 of the PDF:

- `IX_Users_Email` on `identity.Users(Email)` including first and last name.
- `IX_Users_LastName` on `identity.Users(LastName)` including first name and email.
- `IX_Users_CreatedAtUtc` on `identity.Users(CreatedAtUtc)` including email.
- `IX_Payments_PaidAtUtc` on `finance.Payments(PaidAtUtc)` including invoice id and amount.
- `IX_Invoices_Number` on `finance.Invoices(InvoiceNumber)`.

| Item | Problem | Faster version | Why it is better |
|---|---|---|---|
| 7.1 | `YEAR()` and `MONTH()` are applied to the indexed date column. | Use `CreatedAtUtc >= '2026-03-01' AND CreatedAtUtc < '2026-04-01'`. | A range predicate can use an index seek. |
| 7.2 | `DATEDIFF` is evaluated for each row. | `PaidAtUtc >= DATEADD(DAY,-30,SYSUTCDATETIME())`. | The column is left untouched and compared with a calculated boundary. |
| 7.3 | `LEFT(LastName,3)` transforms the column. | `LastName LIKE N'Abd%'`. | A prefix pattern can use an index on LastName. A leading wildcard would not have the same property. |
| 7.4 | Arithmetic is applied to `Id`. | `Id = 50000`. | Rearranging `Id + 1 = 50001` removes the function from the column. |
| 7.5 | Unicode literal may force conversion if `InvoiceNumber` is `VARCHAR`. | Use `'LAB-INV-2026-000001'` (non-Unicode literal). | Match the value type to the column type. Verify the actual column type; if the column is NVARCHAR, use an NVARCHAR value instead. |
| 7.6 | `UPPER(Email)` applies a function to the indexed column. | Under a case-insensitive database collation, use `Email = @Email`. | The indexed column is not transformed and the collation already makes the comparison case-insensitive. Verify the actual database collation and match the variable type to the column. |
| 7.7 | Optional `OR` predicate can produce one plan unsuitable for both NULL and non-NULL. | Branch with `IF @LastName IS NULL ... ELSE ... WHERE LastName=@LastName`. | Each branch compiles a simpler predicate and can use an appropriate access path. `OPTION (RECOMPILE)` is another option when justified. |
| 7.8 | Example: `CONVERT(date, CreatedAtUtc) = '2026-03-15'`. | Use a half-open date range from March 15 inclusive to March 16 exclusive. | Avoids transforming every date value and keeps index usage possible. |

### How to measure “before” and “after”

For each 7.1–7.8 example:

1. Enable **Include Actual Execution Plan** (Ctrl+M).
2. Run the original slow query with `SET STATISTICS IO ON; SET STATISTICS TIME ON;`.
3. Record logical reads, CPU time, elapsed time, and operator shape. Screenshot the plan.
4. Run the corrected query with the same data and parameter value.
5. Record the same measurements and screenshot the new plan.
6. Compare **logical reads** first. They are usually more stable than elapsed time on a shared machine.
7. Explain the change: Scan to Seek (if it happens), fewer rows read, fewer logical reads, lower CPU, or no implicit conversion warning.

Do not write made-up read counts or timing values. They are specific to your database copy and SQL Server environment.

# Task 8 — When the Estimate Is Wrong

The SQL creates `dbo.Assignment3_SpillLab`, inserts a small population, creates a statistic, then inserts 300,000 rows with a new out-of-range `SkewKey = 999999`. The statistic is marked `NORECOMPUTE` so its histogram remains based on the earlier population. The query filters on the new value and sorts a wide payload.

### What to look for

- **Estimated rows:** the optimizer's prediction based on statistics and cardinality estimation.
- **Actual rows:** the number of rows that really reached the operator at runtime.
- **Memory grant:** memory requested for the Sort/Hash work area before execution.
- **Sort spill:** if the grant is insufficient, SQL Server writes sort runs to tempdb and merges them later.
- **Spill level:** the level/depth of the spill process. A higher level generally means additional passes/merge work were needed; interpret it together with the warning properties and actual runtime.
- **Why it is slow:** tempdb I/O, extra read/write work, and merge passes replace an in-memory sort. The discrepancy between estimated and actual rows is the root cause in this exercise.

### Fix

The second run executes `UPDATE STATISTICS ... WITH FULLSCAN` and repeats the query. The updated histogram should represent the new distribution better, allowing a more appropriate estimate and memory grant. Capture both plans and verify the warning is gone or materially reduced. If your SQL Server build/data does not produce a spill automatically, increase the skewed row count or payload size in the test table; do not claim a spill unless the actual plan shows one.

### Required screenshots

1. First actual plan with the Sort operator's warning icon visible.
2. Sort operator properties expanded to show the spill warning, spill level, and estimated/actual row counts where available.
3. Second actual plan after statistics update, showing the changed estimate and warning status.
4. Messages tab with logical reads and CPU/elapsed time before and after.

# Task 9 — One of Each

### First DISTINCT

The first `SELECT DISTINCT DistinctBucket` uses an unindexed column with repeated values. Without ordered input, SQL Server commonly uses **Hash Match (Aggregate)** to build groups/unique values. It hashes each key into an in-memory hash structure and emits one representative for each distinct key. It can spill if the hash table exceeds available memory.

### Cheaper alternative: Stream Aggregate

**Stream Aggregate** consumes rows already ordered by the grouping/distinct key. Because equal values arrive together, it can compare the current key with the previous key and emit a value when the key changes. This generally requires less memory than a hash aggregate.

SQL Server can use it efficiently when an index provides the needed order, such as an index whose leading key is `DistinctBucket`. The SQL file creates such an index and reruns the same DISTINCT query. The optimizer may choose an ordered index scan plus Stream Aggregate.

### DISTINCT on a unique column

`RowId` is the clustered primary key and is guaranteed unique. The optimizer knows that the result cannot contain duplicates and can remove the DISTINCT operation entirely (or show only a simple index/clustered scan/seek). Verify the actual plan and describe exactly what it shows.

### Required screenshots

1. Actual plan for DISTINCT on unindexed `DistinctBucket`.
2. Actual plan after creating the `DistinctBucket` index.
3. Actual plan for DISTINCT on unique `RowId`.

# Task 10 — The CTO's Question: INT vs GUID

| Consideration | INT / BIGINT | GUID (`uniqueidentifier`) |
|---|---|---|
| Storage | INT = 4 bytes; BIGINT = 8 bytes. Compact keys. | 16 bytes. Larger rows and indexes. |
| Index locality | Sequential identity/sequence values usually insert near the end of an ascending index. | Random GUIDs can insert across the index, causing page splits and fragmentation. |
| Distributed generation | Usually requires a central sequence/identity service or allocation strategy. | Can be generated independently by multiple applications/services with extremely low collision probability. |
| Predictability | Sequential values are easy to enumerate and may reveal approximate record counts. | Random GUIDs are difficult to guess, but should not be treated as authorization/security. |
| Joins and foreign keys | Smaller indexes and better cache density. | Larger foreign keys and indexes throughout the schema. |
| Replication / offline creation | Needs coordination or preallocated ranges. | Useful when records are created offline or across independent systems. |
| Human readability | Smaller and easier to inspect. | Long and inconvenient to communicate. |

**Recommendation:** choose `INT` for ordinary internal tables when the database controls creation and scale is within the type's range. Choose `BIGINT` when the expected row count may exceed the INT range. Choose GUIDs where independent distributed creation, offline operation, or merging data from multiple systems is a real requirement. If a GUID is clustered, consider a sequential strategy such as `NEWSEQUENTIALID()` where appropriate, while understanding its operational/security trade-offs. A common compromise is a compact sequential clustered key plus a GUID public identifier.

# Task 11 — End of Semester Changes

- **11.1:** The update changes every course whose code begins `DSAI-` to pass mark 65. This avoids a lookup statement and stays within the no-JOIN rule. If the database has a reliable `DepartmentId` and the code prefix is not guaranteed, use that key instead.
- **11.2:** Only finished/completed enrollments with a non-NULL `FinalScore` are graded. The CASE order is descending threshold: 90=A, 80=B, 70=C, 60=D, below 60=F.
- **11.3:** Delete the Teaching Assistant role by its name. If roles are referenced by a foreign key, SQL Server may reject the delete; in that case follow the LMS's assignment policy (for example, remove dependent role mappings first) rather than disabling constraints.
- **11.4:** The staging table is created once and accepts three demo rows. `TRUNCATE TABLE` empties it quickly and resets identity. TRUNCATE is not allowed when restricted by foreign keys, indexed views, or other dependencies; the staging design intentionally omits a foreign key. The three invoice IDs are demonstration values because the PDF does not provide real invoice IDs.
- **11.5:** Only the practice table created for Tasks 8–9 is dropped. The staging table is retained because it is an operational object requested by Task 11.4. The LMS tables and indexes are not dropped.

# Task 12 — The Auditors Are Coming

### 12.1 Pass-mark history

The history table stores course key/code, previous pass mark (`deleted.PassMark`), new pass mark (`inserted.PassMark`), UTC timestamp, and `ORIGINAL_LOGIN()`. `UPDATE ... OUTPUT ... INTO` captures the before/after values as part of the **same update statement**, avoiding a separate read that could race with another update.

The example changes the DSAI department's courses to 70. That target is illustrative because the PDF does not specify the new pass mark for Task 12.1. Change `@AuditDepartmentCode` and `@AuditNewPassMark` to the department/mark you choose. The Task 11 pass mark of 65 is a separate requested update.

### 12.2 Expired announcement archive

`DELETE ... OUTPUT deleted... INTO archive.Announcements` moves the original deleted values into the archive within one statement. The cutoff is strictly earlier than six months before current UTC time. The archive table is retained and is not removed in cleanup.

# Task 13 — The Nightly Website Sync

The website catalog contains one row per course code and a visibility flag.

The single `MERGE` statement handles all cases:

1. **Matched and changed:** update title/credit hours; set visible to 1.
2. **Not matched by target:** insert a new active course.
3. **Not matched by source:** the course is no longer active (or no longer exists); set `IsVisible = 0` instead of deleting it.
4. **Matched and unchanged:** no action, so reruns are idempotent.

The `OUTPUT $action` result displays what the run changed. To test the required behavior in a test database:

- Rename one existing course in `academic.Courses`.
- Set `IsActive = 0` for a different existing course.
- Execute the sync once and verify one update for the renamed course and one visibility update for the deactivated course.
- Execute it again. It should return no action rows if nothing else changed.
- Execute it a third time. It should still return no action rows.

Use a transaction and rollback if you only want to demonstrate the test without retaining the sample course changes. Do not run this test against production data.

---

## Task 13 test preparation (safe demonstration)

Use this block in a test database. It selects two distinct existing active courses, changes one title, deactivates another, then leaves the transaction open while you run the Task 13 `MERGE` statement three times. The first run should report the two changes; runs two and three should report no output rows. Roll back after checking the results so the sample modifications are not retained.

```sql
BEGIN TRANSACTION;

DECLARE @CourseToRename VARCHAR(30);
DECLARE @CourseToDeactivate VARCHAR(30);

SELECT TOP (1) @CourseToRename = CourseCode
FROM academic.Courses
WHERE IsActive = 1
ORDER BY CourseCode;

SELECT TOP (1) @CourseToDeactivate = CourseCode
FROM academic.Courses
WHERE IsActive = 1
  AND CourseCode <> @CourseToRename
ORDER BY CourseCode;

IF @CourseToRename IS NULL OR @CourseToDeactivate IS NULL
    THROW 51100, 'At least two active courses are required for the sync test.', 1;

UPDATE academic.Courses
SET Title = CONCAT(Title, N' [SYNC TEST]')
WHERE CourseCode = @CourseToRename;

UPDATE academic.Courses
SET IsActive = 0
WHERE CourseCode = @CourseToDeactivate;

-- Run the Task 13 MERGE statement from the SQL file three times here.
-- Inspect OUTPUT after each run: changes on run 1; no rows on runs 2 and 3.

ROLLBACK TRANSACTION;
```

The test has to use the same `MERGE` statement three times; do not replace the single-statement sync with three separate data-change statements.

# Final submission checklist

- [ ] Verify the actual schema and adjust assumed column names/data types.
- [ ] Execute Tasks 1–5 in order; confirm Task 5 uses exactly one table per query and no subqueries.
- [x] Build and include the independent SQLite demo database plus genuine SQLite plan screenshots for Tasks 6–9.
- [ ] In SSMS, execute Task 6 on SQL Server and capture its actual plan, logical reads, CPU time, elapsed time, and operator properties.
- [ ] In SSMS, save before/after SQL Server plans and `STATISTICS IO` / `STATISTICS TIME` comparisons for each of Task 7.1–7.8.
- [ ] In SSMS, capture the actual Task 8 Sort spill warning and post-statistics plan. Do not invent spill level or row estimates.
- [ ] In SSMS, capture all three actual Task 9 SQL Server plans.
- [ ] Execute Tasks 11–13 in a test database and verify output.
- [ ] Create at least one commit per task on the exact branch from the Simulation Academy website.
- [ ] Open the pull request using the exact title from the website.
- [ ] Submit `.sql` file(s), screenshots for Tasks 6–9, and this `NOTES.md`.
