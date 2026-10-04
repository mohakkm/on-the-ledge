-- ============================================================
-- ON-THE-LEDGE — REVIEW 2 SEED DATA
-- Complete initial dataset for university demo.
--
-- Counts:
--   users               5
--   budgets             5  (one September 2026 wallet each)
--   categories          6  (shared master list)
--   budget_allocations 30  (every user × all six categories)
--   transactions        5  (kept; all within allocations)
--
-- Rule: for each budget, SUM(allocated_amount) = total_amount.
-- Remaining is never stored — derived by view/function only.
-- Run AFTER 01_schema.sql. Prefer: schema -> seed -> routines.
-- ============================================================

USE on_the_ledge;

-- Clear data for re-seed demos (keeps table definitions).
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE transactions;
TRUNCATE TABLE budget_allocations;
TRUNCATE TABLE budgets;
TRUNCATE TABLE categories;
TRUNCATE TABLE users;
SET FOREIGN_KEY_CHECKS = 1;

-- ------------------------------------------------------------
-- 1. USERS (5)
-- ------------------------------------------------------------
INSERT INTO users (first_name, last_name, email, monthly_income) VALUES
('Aarav',  'Sharma', 'aarav.sharma@example.com',  30000),
('Riya',   'Mehta',  'riya.mehta@example.com',    35000),
('Kabir',  'Shah',   'kabir.shah@example.com',    28000),
('Ananya', 'Rao',    'ananya.rao@example.com',    40000),
('Vihaan', 'Patel',  'vihaan.patel@example.com',  32000);

-- ------------------------------------------------------------
-- 2. BUDGETS (5) — one September 2026 wallet per user
-- ------------------------------------------------------------
INSERT INTO budgets (user_id, budget_month, total_amount) VALUES
(1, '2026-09-01', 30000),
(2, '2026-09-01', 35000),
(3, '2026-09-01', 28000),
(4, '2026-09-01', 40000),
(5, '2026-09-01', 32000);

-- ------------------------------------------------------------
-- 3. CATEGORIES (6) — shared master list
-- IDs after insert: 1 Rent, 2 Food, 3 Travel,
--                   4 Shopping, 5 Entertainment, 6 Savings
-- ------------------------------------------------------------
INSERT INTO categories (category_name) VALUES
('Rent'),
('Food'),
('Travel'),
('Shopping'),
('Entertainment'),
('Savings');

-- ------------------------------------------------------------
-- 4. BUDGET_ALLOCATIONS (30) — every budget × all six categories
-- Each block sums exactly to that budget's total_amount.
-- ------------------------------------------------------------

-- Aarav budget_id=1, total 30000
INSERT INTO budget_allocations (budget_id, category_id, allocated_amount) VALUES
(1, 1, 10000),  -- Rent
(1, 2,  6000),  -- Food
(1, 3,  2500),  -- Travel
(1, 4,  3000),  -- Shopping
(1, 5,  1500),  -- Entertainment
(1, 6,  7000);  -- Savings
-- Sum = 30000

-- Riya budget_id=2, total 35000
INSERT INTO budget_allocations (budget_id, category_id, allocated_amount) VALUES
(2, 1, 12000),  -- Rent
(2, 2,  7000),  -- Food
(2, 3,  3000),  -- Travel
(2, 4,  4000),  -- Shopping
(2, 5,  2000),  -- Entertainment
(2, 6,  7000);  -- Savings
-- Sum = 35000

-- Kabir budget_id=3, total 28000
INSERT INTO budget_allocations (budget_id, category_id, allocated_amount) VALUES
(3, 1,  9000),  -- Rent
(3, 2,  5000),  -- Food
(3, 3,  4000),  -- Travel
(3, 4,  2500),  -- Shopping
(3, 5,  1500),  -- Entertainment
(3, 6,  6000);  -- Savings
-- Sum = 28000

-- Ananya budget_id=4, total 40000
INSERT INTO budget_allocations (budget_id, category_id, allocated_amount) VALUES
(4, 1, 14000),  -- Rent
(4, 2,  7000),  -- Food
(4, 3,  4000),  -- Travel
(4, 4,  8000),  -- Shopping
(4, 5,  2000),  -- Entertainment
(4, 6,  5000);  -- Savings
-- Sum = 40000

-- Vihaan budget_id=5, total 32000
INSERT INTO budget_allocations (budget_id, category_id, allocated_amount) VALUES
(5, 1, 11000),  -- Rent
(5, 2,  6000),  -- Food
(5, 3,  3000),  -- Travel
(5, 4,  3500),  -- Shopping
(5, 5,  1500),  -- Entertainment
(5, 6,  7000);  -- Savings
-- Sum = 32000

-- ------------------------------------------------------------
-- 5. TRANSACTIONS (5) — retained sample expenses
-- Each uses an allocated category and stays within that amount.
-- Aarav Rent uses the full 10000 so "exceeds allocation" demos work.
-- ------------------------------------------------------------
INSERT INTO transactions (user_id, budget_id, category_id, amount, description, transaction_date) VALUES
(1, 1, 1, 10000, 'September rent payment',          '2026-09-01'),
(1, 1, 2,   750, 'Swiggy order',                     '2026-09-05'),
(2, 2, 2,  1200, 'Grocery shopping - Big Bazaar',    '2026-09-03'),
(3, 3, 3,  2500, 'Flight ticket - Chennai to Mumbai','2026-09-04'),
(4, 4, 4,  3000, 'Amazon order - clothing',          '2026-09-06');

-- ------------------------------------------------------------
-- Verify counts
-- ------------------------------------------------------------
SELECT 'users' AS tbl, COUNT(*) AS n FROM users
UNION ALL SELECT 'budgets', COUNT(*) FROM budgets
UNION ALL SELECT 'categories', COUNT(*) FROM categories
UNION ALL SELECT 'budget_allocations', COUNT(*) FROM budget_allocations
UNION ALL SELECT 'transactions', COUNT(*) FROM transactions;

-- Verify each budget's allocations sum to total_amount (all diffs = 0)
SELECT
    u.first_name,
    b.budget_id,
    b.total_amount,
    SUM(ba.allocated_amount) AS allocation_sum,
    b.total_amount - SUM(ba.allocated_amount) AS difference
FROM budgets b
JOIN users u ON u.user_id = b.user_id
JOIN budget_allocations ba ON ba.budget_id = b.budget_id
GROUP BY u.first_name, b.budget_id, b.total_amount
ORDER BY b.budget_id;
