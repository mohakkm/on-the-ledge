-- ============================================================
-- ON-THE-LEDGE — REVIEW 1 SEED DATA
-- Exactly 5 records per table, realistic budgeting scenario
-- ============================================================

USE on_the_ledge;

-- 1. USERS
INSERT INTO users (first_name, last_name, email, monthly_income) VALUES
('Aarav',  'Sharma', 'aarav.sharma@example.com',  30000),
('Riya',   'Mehta',  'riya.mehta@example.com',    35000),
('Kabir',  'Shah',   'kabir.shah@example.com',    28000),
('Ananya', 'Rao',    'ananya.rao@example.com',    40000),
('Vihaan', 'Patel',  'vihaan.patel@example.com',  32000);

-- 2. BUDGETS (one Sept 2026 budget per user)
INSERT INTO budgets (user_id, budget_month, total_amount) VALUES
(1, '2026-09-01', 30000),
(2, '2026-09-01', 35000),
(3, '2026-09-01', 28000),
(4, '2026-09-01', 40000),
(5, '2026-09-01', 32000);

-- 3. CATEGORIES
INSERT INTO categories (category_name) VALUES
('Rent'),
('Food'),
('Travel'),
('Shopping'),
('Entertainment');

-- 4. BUDGET_ALLOCATIONS (5 rows; budget 1 shows the M:N nature with 2 categories)
INSERT INTO budget_allocations (budget_id, category_id, allocated_amount) VALUES
(1, 1, 10000),   -- Aarav's budget -> Rent
(1, 2, 5000),    -- Aarav's budget -> Food
(2, 2, 6000),    -- Riya's budget  -> Food
(3, 3, 4000),    -- Kabir's budget -> Travel
(4, 4, 8000);    -- Ananya's budget -> Shopping

-- 5. TRANSACTIONS
INSERT INTO transactions (user_id, budget_id, category_id, amount, description, transaction_date) VALUES
(1, 1, 1, 10000, 'September rent payment',            '2026-09-01'),
(1, 1, 2,   750, 'Swiggy order',                       '2026-09-05'),
(2, 2, 2,  1200, 'Grocery shopping - Big Bazaar',       '2026-09-03'),
(3, 3, 3,  2500, 'Flight ticket - Chennai to Mumbai',   '2026-09-04'),
(4, 4, 4,  3000, 'Amazon order - clothing',             '2026-09-06');

-- Sanity check: Allocated -> Spent -> Remaining per category
SELECT
    b.budget_id,
    c.category_name,
    ba.allocated_amount,
    COALESCE(SUM(t.amount), 0) AS spent,
    ba.allocated_amount - COALESCE(SUM(t.amount), 0) AS remaining
FROM budget_allocations ba
JOIN budgets b     ON b.budget_id = ba.budget_id
JOIN categories c  ON c.category_id = ba.category_id
LEFT JOIN transactions t
    ON t.budget_id = ba.budget_id AND t.category_id = ba.category_id
GROUP BY b.budget_id, c.category_name, ba.allocated_amount
ORDER BY b.budget_id, c.category_name;