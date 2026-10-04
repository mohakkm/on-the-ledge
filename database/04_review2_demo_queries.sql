-- ============================================================
-- ON-THE-LEDGE — REVIEW 2 DEMO QUERIES (MySQL Workbench)
-- Run section by section after:
--   01_schema.sql -> 02_seed_data.sql -> 03_routines.sql
--
-- Seed snapshot used by expected results:
--   5 users, 5 Sept budgets, 6 categories, 30 allocations, 5 txns
--   Aarav Food alloc 6000, spent 750 → remaining 5250
--   Aarav Rent alloc 10000, spent 10000 → remaining 0
--
-- Safe failure demos use sp_add_transaction_safe / restore steps
-- so seed data is not corrupted.
-- ============================================================

USE on_the_ledge;

-- ############################################################
-- MEMBER 1 — Experiment 4B: Constraints + Set Operations
-- ############################################################

-- ------------------------------------------------------------
-- 4B-A) Show constraint catalogue (talking point, not a test INSERT)
-- Expected: PK / FK / UNIQUE / CHECK names from information_schema.
-- ------------------------------------------------------------
SELECT tc.CONSTRAINT_NAME, tc.TABLE_NAME, tc.CONSTRAINT_TYPE
FROM information_schema.TABLE_CONSTRAINTS tc
WHERE tc.TABLE_SCHEMA = 'on_the_ledge'
ORDER BY tc.TABLE_NAME, tc.CONSTRAINT_TYPE, tc.CONSTRAINT_NAME;

-- DEFAULT example: monthly_income defaults to 0 when omitted.
-- Expected: temporary demo user with income 0; then rolled back.
START TRANSACTION;
INSERT INTO users (first_name, last_name, email)
VALUES ('Demo', 'Default', 'demo.default@example.com');
SELECT user_id, email, monthly_income
FROM users
WHERE email = 'demo.default@example.com';
-- Expected monthly_income = 0.00 from DEFAULT.
ROLLBACK;

-- CHECK / UNIQUE talking note (do not leave failed rows):
-- users.email UNIQUE, budgets.uq_user_month UNIQUE,
-- chk_income / chk_total_amount / chk_allocated_amount / chk_amount.

-- ------------------------------------------------------------
-- 4B-B) UNION — users who allocated Food OR spent on Food
-- Alloc side: all five users (complete seed). Expense side: Aarav, Riya.
-- Expected distinct users: Aarav, Riya, Kabir, Ananya, Vihaan.
-- ------------------------------------------------------------
SELECT u.user_id, u.first_name
FROM users u
JOIN budgets b ON b.user_id = u.user_id
JOIN budget_allocations ba ON ba.budget_id = b.budget_id
JOIN categories c ON c.category_id = ba.category_id
WHERE c.category_name = 'Food'
UNION
SELECT u.user_id, u.first_name
FROM users u
JOIN transactions t ON t.user_id = u.user_id
JOIN categories c ON c.category_id = t.category_id
WHERE c.category_name = 'Food';

-- ------------------------------------------------------------
-- 4B-C) UNION ALL — keep duplicates intentionally
-- Expected: 5 Food-allocation rows + 2 Food-expense rows = 7 rows.
-- Aarav and Riya appear on both sides.
-- ------------------------------------------------------------
SELECT u.first_name, 'Food allocation' AS source
FROM users u
JOIN budgets b ON b.user_id = u.user_id
JOIN budget_allocations ba ON ba.budget_id = b.budget_id
JOIN categories c ON c.category_id = ba.category_id
WHERE c.category_name = 'Food'
UNION ALL
SELECT u.first_name, 'Food expense' AS source
FROM users u
JOIN transactions t ON t.user_id = u.user_id
JOIN categories c ON c.category_id = t.category_id
WHERE c.category_name = 'Food';

-- ------------------------------------------------------------
-- 4B-D) INTERSECT — users who have a September budget AND have expenses
-- Expected: Aarav, Riya, Kabir, Ananya (not Vihaan — no transactions).
-- ------------------------------------------------------------
SELECT u.user_id, u.first_name
FROM users u
JOIN budgets b ON b.user_id = u.user_id
WHERE b.budget_month = '2026-09-01'
INTERSECT
SELECT u.user_id, u.first_name
FROM users u
JOIN transactions t ON t.user_id = u.user_id;

-- ------------------------------------------------------------
-- 4B-E) EXCEPT — users with a Sept budget but zero transactions
-- Expected: Vihaan only.
-- ------------------------------------------------------------
SELECT u.user_id, u.first_name
FROM users u
JOIN budgets b ON b.user_id = u.user_id
WHERE b.budget_month = '2026-09-01'
EXCEPT
SELECT u.user_id, u.first_name
FROM users u
JOIN transactions t ON t.user_id = u.user_id;


-- ############################################################
-- MEMBER 2 — Experiment 5: Subqueries, Joins, View
-- ############################################################

-- ------------------------------------------------------------
-- 5-A) Subquery (WHERE) — expenses larger than that user's average
-- Expected: Aarav rent 10000 (avg of Aarav's two txns = 5375).
-- ------------------------------------------------------------
SELECT t.transaction_id, u.first_name, t.amount, t.description
FROM transactions t
JOIN users u ON u.user_id = t.user_id
WHERE t.amount > (
    SELECT AVG(t2.amount)
    FROM transactions t2
    WHERE t2.user_id = t.user_id
);

-- ------------------------------------------------------------
-- 5-B) Subquery (FROM) — per-user spend totals, then filter
-- Expected: spend > 2000 → Aarav 10750, Kabir 2500, Ananya 3000
--           (Riya 1200 excluded).
-- ------------------------------------------------------------
SELECT s.user_id, u.first_name, s.total_spent
FROM (
    SELECT t.user_id, SUM(t.amount) AS total_spent
    FROM transactions t
    GROUP BY t.user_id
) AS s
JOIN users u ON u.user_id = s.user_id
WHERE s.total_spent > 2000
ORDER BY s.total_spent DESC;

-- ------------------------------------------------------------
-- 5-C) INNER JOIN — budgets with allocations (all five now)
-- Expected: 30 rows (5 budgets × 6 categories).
-- ------------------------------------------------------------
SELECT b.budget_id, u.first_name, c.category_name, ba.allocated_amount
FROM budgets b
INNER JOIN users u ON u.user_id = b.user_id
INNER JOIN budget_allocations ba ON ba.budget_id = b.budget_id
INNER JOIN categories c ON c.category_id = ba.category_id
ORDER BY b.budget_id, c.category_name;

-- ------------------------------------------------------------
-- 5-D) LEFT JOIN — every allocation, even with zero spending
-- Expected: Savings / unused categories show spent_amount conceptually
-- as missing expense rows (NULL from transactions side).
-- Talk: remaining is derived later by the view, not stored.
-- ------------------------------------------------------------
SELECT
    u.first_name,
    c.category_name,
    ba.allocated_amount,
    t.amount AS one_expense_amount,
    t.description
FROM budget_allocations ba
JOIN budgets b ON b.budget_id = ba.budget_id
JOIN users u ON u.user_id = b.user_id
JOIN categories c ON c.category_id = ba.category_id
LEFT JOIN transactions t
       ON t.budget_id = ba.budget_id
      AND t.category_id = ba.category_id
WHERE b.budget_month = '2026-09-01'
  AND u.user_id = 1
ORDER BY c.category_name;
-- Expected for Aarav: Rent + Food have expense rows; others NULL.

-- ------------------------------------------------------------
-- 5-E) Useful VIEW — allocated / spent / remaining
-- Expected sample: Aarav Rent remaining 0; Aarav Food remaining 5250.
-- Allocation sums still equal each budget total (check with GROUP BY).
-- ------------------------------------------------------------
SELECT *
FROM v_budget_category_status
ORDER BY budget_id, category_name;

SELECT
    user_name,
    budget_id,
    SUM(allocated_amount) AS allocation_sum
FROM v_budget_category_status
GROUP BY user_name, budget_id
ORDER BY budget_id;
-- Expected sums: Aarav 30000, Riya 35000, Kabir 28000,
--                Ananya 40000, Vihaan 32000.


-- ############################################################
-- MEMBER 3 — Experiment 6: Function + Procedure
-- ############################################################

-- ------------------------------------------------------------
-- 6-A) Function — remaining Food allocation on Aarav's budget
-- Expected: 6000 - 750 = 5250.00
-- ------------------------------------------------------------
SELECT fn_remaining_allocation(1, 2) AS aarav_food_remaining;

-- Function — remaining Rent (fully spent)
-- Expected: 0.00
SELECT fn_remaining_allocation(1, 1) AS aarav_rent_remaining;

-- Function — no such allocation row (fake category_id)
-- Expected: NULL
SELECT fn_remaining_allocation(1, 99) AS missing_allocation_remaining;

-- ------------------------------------------------------------
-- 6-B) Procedure sp_add_transaction — valid Food expense for Aarav
-- Expected: inserts successfully; Food remaining becomes 5000.
-- Wrapped in ROLLBACK so seed stays clean after the talk.
-- ------------------------------------------------------------
START TRANSACTION;
CALL sp_add_transaction(
    1, 1, 2, 250.00,
    'Demo chai snack (will roll back)',
    '2026-09-07'
);
SELECT fn_remaining_allocation(1, 2) AS food_remaining_after_demo_insert;
-- Expected temporarily: 5000.00
ROLLBACK;
SELECT fn_remaining_allocation(1, 2) AS food_remaining_restored;
-- Expected: 5250.00 again


-- ############################################################
-- MEMBER 4 — Cursor, Trigger, Exception Handling
-- ############################################################

-- ------------------------------------------------------------
-- 6-C) Cursor procedure — Aarav September total via row-by-row sum
-- Expected: 10000 + 750 = 10750.00
-- ------------------------------------------------------------
SET @aarav_sept_total = NULL;
CALL sp_user_month_spending(1, '2026-09-01', @aarav_sept_total);
SELECT @aarav_sept_total AS aarav_september_spending;

-- Cursor — Vihaan September (full allocations, but no expenses)
-- Expected: 0.00
SET @vihaan_sept_total = NULL;
CALL sp_user_month_spending(5, '2026-09-01', @vihaan_sept_total);
SELECT @vihaan_sept_total AS vihaan_september_spending;

-- ------------------------------------------------------------
-- 6-D) Trigger FAIL #1 — exceeds remaining Rent allocation
-- Seed already spent 10000/10000 on Rent. Extra ₹1 must fail.
-- ------------------------------------------------------------
SET @status = NULL;
CALL sp_add_transaction_safe(
    1, 1, 1, 1.00,
    'Should fail: rent over allocation',
    '2026-09-08',
    @status
);
SELECT @status AS trigger_demo_exceeds_allocation;
-- Expected: FAILED: Rejected: amount exceeds remaining category allocation.
SELECT COUNT(*) AS txn_count_still_five FROM transactions;
-- Expected: 5

-- ------------------------------------------------------------
-- 6-E) Trigger FAIL #2 — category not allocated
-- All six categories are seeded for every user, so temporarily
-- remove Aarav Savings (no Savings expenses in seed), demo fail,
-- then restore the allocation so seed stays complete.
-- ------------------------------------------------------------
DELETE FROM budget_allocations
WHERE budget_id = 1 AND category_id = 6;

SET @status = NULL;
CALL sp_add_transaction_safe(
    1, 1, 6, 100.00,
    'Should fail: Savings temporarily not allocated',
    '2026-09-08',
    @status
);
SELECT @status AS trigger_demo_not_allocated;
-- Expected: FAILED: Rejected: category is not allocated on this budget.

-- Restore Aarav Savings allocation (7000)
INSERT INTO budget_allocations (budget_id, category_id, allocated_amount)
VALUES (1, 6, 7000);

SELECT COUNT(*) AS txn_count_still_five FROM transactions;
SELECT SUM(allocated_amount) AS aarav_alloc_sum_restored
FROM budget_allocations
WHERE budget_id = 1;
-- Expected alloc sum restored: 30000

-- ------------------------------------------------------------
-- 6-F) Trigger FAIL #3 — no monthly budget for October
-- Aarav only has 2026-09-01 budget. October date must fail.
-- ------------------------------------------------------------
SET @status = NULL;
CALL sp_add_transaction_safe(
    1, 1, 2, 100.00,
    'Should fail: October has no budget',
    '2026-10-02',
    @status
);
SELECT @status AS trigger_demo_no_monthly_budget;
SELECT COUNT(*) AS txn_count_still_five FROM transactions;

-- ------------------------------------------------------------
-- 6-G) Safe SUCCESS path (optional), then delete demo row
-- ------------------------------------------------------------
SET @status = NULL;
CALL sp_add_transaction_safe(
    1, 1, 2, 200.00,
    'Valid food demo row — delete after talk',
    '2026-09-09',
    @status
);
SELECT @status AS safe_success_status;
-- Expected: SUCCESS: transaction saved.
DELETE FROM transactions
WHERE description = 'Valid food demo row — delete after talk';
SELECT COUNT(*) AS txn_count_final FROM transactions;
-- Expected final seed size: 5

-- ------------------------------------------------------------
-- 6-H) BEFORE UPDATE trigger — cannot inflate Rent past allocation
-- Run the UPDATE alone in Workbench if you want the error on screen.
-- ------------------------------------------------------------
-- UPDATE transactions SET amount = 10001 WHERE transaction_id = 1;
-- Expected error text: Rejected: amount exceeds remaining category allocation.
SELECT transaction_id, amount
FROM transactions
WHERE transaction_id = 1;
-- Expected: amount still 10000.

-- Final integrity snapshot for the panel
SELECT * FROM v_budget_category_status ORDER BY budget_id, category_name;

SELECT
    u.first_name,
    b.total_amount AS budget_total,
    SUM(ba.allocated_amount) AS allocation_sum,
    b.total_amount - SUM(ba.allocated_amount) AS difference
FROM budgets b
JOIN users u ON u.user_id = b.user_id
JOIN budget_allocations ba ON ba.budget_id = b.budget_id
GROUP BY u.first_name, b.total_amount, b.budget_id
ORDER BY b.budget_id;

SELECT COUNT(*) AS users_n FROM users;
SELECT COUNT(*) AS budgets_n FROM budgets;
SELECT COUNT(*) AS categories_n FROM categories;
SELECT COUNT(*) AS allocations_n FROM budget_allocations;
SELECT COUNT(*) AS transactions_n FROM transactions;
-- Expected counts: 5, 5, 6, 30, 5
