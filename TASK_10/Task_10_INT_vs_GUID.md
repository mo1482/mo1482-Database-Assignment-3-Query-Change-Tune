# Scoring section: 10 — The CTO's Question (5 points)

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
