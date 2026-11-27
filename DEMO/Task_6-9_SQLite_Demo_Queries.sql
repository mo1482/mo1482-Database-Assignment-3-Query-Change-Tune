-- SQLite 3.46.1 demo companion queries. Run against LmsTrainingLab_Demo.sqlite.
-- These are not T-SQL; SQL Server queries remain in the numbered task folders.

-- TASK 6: correlated scalar lookup avoids JOIN syntax.
SELECT i.invoice_number,
       (SELECT sp.student_number FROM student_profiles AS sp WHERE sp.id = i.student_id) AS student_number,
       i.total_amount - i.paid_amount AS remaining,
       CASE WHEN i.due_at_utc < datetime('2026-11-27 12:00:00', '-60 days')
            THEN 'Urgent' ELSE 'Normal' END AS urgency
FROM invoices AS i
WHERE i.paid_amount < i.total_amount
  AND i.due_at_utc < '2026-11-27 12:00:00'
ORDER BY remaining DESC
LIMIT 15;

-- TASK 7.1 BEFORE / AFTER
EXPLAIN QUERY PLAN
SELECT id,email FROM users
WHERE strftime('%Y',created_at_utc)='2026' AND strftime('%m',created_at_utc)='03';
CREATE INDEX IF NOT EXISTS IX_users_created_at ON users(created_at_utc);
EXPLAIN QUERY PLAN
SELECT id,email FROM users
WHERE created_at_utc >= '2026-03-01 00:00:00'
  AND created_at_utc <  '2026-04-01 00:00:00';

-- TASK 7.2 BEFORE / AFTER
EXPLAIN QUERY PLAN
SELECT id,invoice_id,amount FROM payments
WHERE julianday('2026-11-27 12:00:00') - julianday(paid_at_utc) <= 30;
CREATE INDEX IF NOT EXISTS IX_payments_paid_at ON payments(paid_at_utc);
EXPLAIN QUERY PLAN
SELECT id,invoice_id,amount FROM payments
WHERE paid_at_utc >= datetime('2026-11-27 12:00:00','-30 days');

-- TASK 7.3 BEFORE / AFTER
EXPLAIN QUERY PLAN SELECT id,first_name,last_name FROM users WHERE substr(last_name,1,3)='Abd';
CREATE INDEX IF NOT EXISTS IX_users_last_name ON users(last_name);
PRAGMA case_sensitive_like=ON;
EXPLAIN QUERY PLAN SELECT id,first_name,last_name FROM users WHERE last_name LIKE 'Abd%';

-- TASK 7.4 BEFORE / AFTER
EXPLAIN QUERY PLAN SELECT * FROM audit_logs WHERE id+1=50001;
EXPLAIN QUERY PLAN SELECT * FROM audit_logs WHERE id=50000;

-- TASK 8: unindexed sort and then supporting index.
PRAGMA temp_store=FILE;
PRAGMA cache_size=-1024;
EXPLAIN QUERY PLAN
SELECT sort_value,payload FROM assignment3_spilllab
WHERE skew_key=999999 ORDER BY sort_value DESC;
CREATE INDEX IF NOT EXISTS IX_spilllab_key_sort
ON assignment3_spilllab(skew_key,sort_value DESC);
EXPLAIN QUERY PLAN
SELECT sort_value,payload FROM assignment3_spilllab
WHERE skew_key=999999 ORDER BY sort_value DESC;

-- TASK 9: DISTINCT without an index, then with an ordered covering index, then unique PK.
EXPLAIN QUERY PLAN SELECT DISTINCT distinct_bucket FROM assignment3_spilllab;
CREATE INDEX IF NOT EXISTS IX_spilllab_distinct_bucket
ON assignment3_spilllab(distinct_bucket);
EXPLAIN QUERY PLAN SELECT DISTINCT distinct_bucket FROM assignment3_spilllab;
EXPLAIN QUERY PLAN SELECT DISTINCT row_id FROM assignment3_spilllab;
