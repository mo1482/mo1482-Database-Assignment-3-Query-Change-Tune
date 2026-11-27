# Database Assignment 3 — Submission Package

This package is arranged **exactly by the grading breakdown (100 points)** from the assignment PDF. Each category has a separate SQL or written-answer file; the detailed reasoning is collected in `NOTES.md`.

## Contents in grading order

| Section | Points | File/folder |
|---|---:|---|
| 1–4 — Temp list, inserts, numbering, copy | 15 | `01_Tasks_1-4_Temp_List_Inserts_Numbering_Copy_15_Points/Tasks_1-4.sql` |
| 5 — Management reports | 22 | `02_Task_5_Management_Reports_22_Points/Task_5_Management_Reports.sql` |
| 6 — Reading the plan | 12 | `03_Task_6_Reading_the_Plan_12_Points/Task_6_Reading_the_Plan.sql` |
| 7 — Make it faster | 15 | `04_Task_7_Make_it_Faster_15_Points/Task_7_Make_it_Faster.sql` |
| 8–9 — Spill + one of each | 10 | `05_Tasks_8-9_Spill_and_Distinct_10_Points/Tasks_8-9_Spill_and_Distinct.sql` |
| 10 — The CTO's question | 5 | `06_Task_10_CTO_Question_5_Points/Task_10_INT_vs_GUID.md` |
| 11–13 — Changes, audit, sync | 15 | `07_Tasks_11-13_Changes_Audit_Sync_15_Points/Tasks_11-13_Changes_Audit_Sync.sql` |
| NOTES.md & readability | 6 | `NOTES.md` + `08_NOTES_and_Readability_6_Points/READABILITY_CHECKLIST.md` + this `README.md` |
| **Total** | **100** | |

## Before running

1. Read `NOTES.md`, especially the schema assumptions and the Task 6 rule conflict.
2. Connect SSMS to a **test copy** of `LmsTrainingLab`. The assignment PDF does not include the database backup or complete schema.
3. Confirm table/column names and data types. Adjust any schema assumptions to match your copy.
4. Run the SQL files in rubric order, one task section at a time. Tasks 8–9 share the practice table created in Task 8. Tasks 11–13 depend on objects made earlier.
5. Capture the real screenshots requested in Tasks 6–9 and save them in `Screenshots_Tasks_6-9/`. Follow that folder's `README.md`.
6. Follow the exact branch name and Pull Request title supplied by the Simulation Academy website; those values are not present in the PDF.

## Important limitations

- Only the assignment PDF was supplied, not a `LmsTrainingLab.bak` file or complete table definitions. Names not explicitly visible in the PDF are identified as assumptions in `NOTES.md`.
- Actual execution plans, spills, logical reads, CPU/elapsed time, and screenshots must come from your local SQL Server. They are not fabricated in this package.
- The Task 6 query printed in the assignment includes an `INNER JOIN`, while the general instruction says no `JOIN` anywhere. The SQL answer uses a scalar lookup to respect that rule; `NOTES.md` explains that its plan is not the same as the supplied query's plan.
