-- ============================================================
-- ON-THE-LEDGE — REVIEW 2 ROUTINES (MySQL 8.4)
-- Experiment 5 view + Experiment 6 function / procedures / triggers
--
-- Objects created:
--   VIEW  v_budget_category_status
--   FUNCTION  fn_remaining_allocation(budget_id, category_id)
--   PROCEDURE sp_add_transaction(...)
--   PROCEDURE sp_add_transaction_safe(...)   -- EXIT HANDLER + ROLLBACK
--   PROCEDURE sp_user_month_spending(...)    -- cursor total
--   TRIGGER   trg_txn_before_insert
--   TRIGGER   trg_txn_before_update
--
-- No audit / extra business tables.
-- ============================================================

USE on_the_ledge;

-- Drop old objects for clean re-run in Workbench
DROP VIEW IF EXISTS v_budget_category_status;
DROP FUNCTION IF EXISTS fn_remaining_allocation;
DROP PROCEDURE IF EXISTS sp_add_transaction;
DROP PROCEDURE IF EXISTS sp_add_transaction_safe;
DROP PROCEDURE IF EXISTS sp_user_month_spending;
DROP TRIGGER IF EXISTS trg_txn_before_insert;
DROP TRIGGER IF EXISTS trg_txn_before_update;

-- ------------------------------------------------------------
-- VIEW: budget + user + category + allocated / spent / remaining
-- Expected: one row per allocation (30 with complete seed);
--           Aarav Rent remaining = 0; Aarav Food remaining = 5250.
-- ------------------------------------------------------------
CREATE VIEW v_budget_category_status AS
SELECT
    b.budget_id,
    b.budget_month,
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS user_name,
    c.category_id,
    c.category_name,
    ba.allocated_amount,
    COALESCE(SUM(t.amount), 0) AS spent_amount,
    ba.allocated_amount - COALESCE(SUM(t.amount), 0) AS remaining_amount
FROM budget_allocations ba
JOIN budgets b      ON b.budget_id = ba.budget_id
JOIN users u        ON u.user_id = b.user_id
JOIN categories c   ON c.category_id = ba.category_id
LEFT JOIN transactions t
       ON t.budget_id = ba.budget_id
      AND t.category_id = ba.category_id
GROUP BY
    b.budget_id,
    b.budget_month,
    u.user_id,
    u.first_name,
    u.last_name,
    c.category_id,
    c.category_name,
    ba.allocated_amount;

-- ============================================================
-- FUNCTION: remaining allocation for one budget + category
-- ============================================================
DELIMITER //

CREATE FUNCTION fn_remaining_allocation(
    p_budget_id   INT,
    p_category_id INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_alloc_ok  INT DEFAULT 0;
    DECLARE v_allocated DECIMAL(10,2) DEFAULT 0;
    DECLARE v_spent     DECIMAL(10,2) DEFAULT 0;

    SELECT COUNT(*), COALESCE(MAX(ba.allocated_amount), 0)
      INTO v_alloc_ok, v_allocated
      FROM budget_allocations ba
     WHERE ba.budget_id = p_budget_id
       AND ba.category_id = p_category_id;

    -- No allocation row => NULL (demo uses a non-existent category_id)
    IF v_alloc_ok = 0 THEN
        RETURN NULL;
    END IF;

    SELECT COALESCE(SUM(t.amount), 0)
      INTO v_spent
      FROM transactions t
     WHERE t.budget_id = p_budget_id
       AND t.category_id = p_category_id;

    RETURN v_allocated - v_spent;
END //

-- ============================================================
-- PROCEDURE: add a transaction (business insert)
-- Triggers enforce budget / allocation / remaining rules.
-- ============================================================
CREATE PROCEDURE sp_add_transaction(
    IN p_user_id           INT,
    IN p_budget_id         INT,
    IN p_category_id       INT,
    IN p_amount            DECIMAL(10,2),
    IN p_description       VARCHAR(255),
    IN p_transaction_date  DATE
)
BEGIN
    INSERT INTO transactions (
        user_id, budget_id, category_id, amount, description, transaction_date
    ) VALUES (
        p_user_id, p_budget_id, p_category_id, p_amount, p_description, p_transaction_date
    );
END //

-- ============================================================
-- PROCEDURE: safe add with exception handling
-- On any SQL error: ROLLBACK and return a readable status.
-- ============================================================
CREATE PROCEDURE sp_add_transaction_safe(
    IN  p_user_id           INT,
    IN  p_budget_id         INT,
    IN  p_category_id       INT,
    IN  p_amount            DECIMAL(10,2),
    IN  p_description       VARCHAR(255),
    IN  p_transaction_date  DATE,
    OUT p_status            VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Read diagnostics BEFORE ROLLBACK clears the useful message.
        GET DIAGNOSTICS CONDITION 1 p_status = MESSAGE_TEXT;
        ROLLBACK;
        IF p_status IS NULL OR p_status = '' THEN
            SET p_status = 'FAILED: transaction rolled back due to a SQL exception.';
        ELSE
            SET p_status = CONCAT('FAILED: ', p_status);
        END IF;
    END;

    START TRANSACTION;

    CALL sp_add_transaction(
        p_user_id, p_budget_id, p_category_id,
        p_amount, p_description, p_transaction_date
    );

    COMMIT;
    SET p_status = 'SUCCESS: transaction saved.';
END //

-- ============================================================
-- CURSOR PROCEDURE: sum a user's spending for one budget month
-- Reads each matching transaction amount one row at a time.
-- ============================================================
CREATE PROCEDURE sp_user_month_spending(
    IN  p_user_id      INT,
    IN  p_budget_month DATE,          -- pass first-of-month, e.g. 2026-09-01
    OUT p_total_spent  DECIMAL(10,2)
)
BEGIN
    DECLARE v_done    INT DEFAULT 0;
    DECLARE v_amount  DECIMAL(10,2) DEFAULT 0;
    DECLARE v_budgets INT DEFAULT 0;

    -- Cursor reads matching expense amounts one row at a time.
    DECLARE cur_txn CURSOR FOR
        SELECT t.amount
          FROM transactions t
          JOIN budgets b ON b.budget_id = t.budget_id
         WHERE t.user_id = p_user_id
           AND b.budget_month = p_budget_month;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    SET p_total_spent = 0;

    SELECT COUNT(*)
      INTO v_budgets
      FROM budgets b
     WHERE b.user_id = p_user_id
       AND b.budget_month = p_budget_month;

    IF v_budgets = 0 THEN
        SET p_total_spent = 0;
    ELSE
        OPEN cur_txn;

        read_loop: LOOP
            FETCH cur_txn INTO v_amount;
            IF v_done = 1 THEN
                LEAVE read_loop;
            END IF;
            SET p_total_spent = p_total_spent + v_amount;
        END LOOP;

        CLOSE cur_txn;
    END IF;
END //

-- ============================================================
-- BEFORE INSERT TRIGGER
-- Reject when: no monthly budget, category not allocated,
-- or amount exceeds remaining allocation.
-- ============================================================
CREATE TRIGGER trg_txn_before_insert
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE v_budget_ok INT DEFAULT 0;
    DECLARE v_alloc_ok  INT DEFAULT 0;
    DECLARE v_allocated DECIMAL(10,2) DEFAULT 0;
    DECLARE v_spent     DECIMAL(10,2) DEFAULT 0;

    -- 1) Monthly budget must exist for this user + budget_id,
    --    and transaction month must match budget_month.
    SELECT COUNT(*)
      INTO v_budget_ok
      FROM budgets b
     WHERE b.budget_id = NEW.budget_id
       AND b.user_id = NEW.user_id
       AND b.budget_month = DATE_FORMAT(NEW.transaction_date, '%Y-%m-01');

    IF v_budget_ok = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: no monthly budget for this user/date.';
    END IF;

    -- 2) Category must be allocated on that budget.
    SELECT COUNT(*), COALESCE(MAX(ba.allocated_amount), 0)
      INTO v_alloc_ok, v_allocated
      FROM budget_allocations ba
     WHERE ba.budget_id = NEW.budget_id
       AND ba.category_id = NEW.category_id;

    IF v_alloc_ok = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: category is not allocated on this budget.';
    END IF;

    -- 3) Must not exceed remaining allocation.
    SELECT COALESCE(SUM(t.amount), 0)
      INTO v_spent
      FROM transactions t
     WHERE t.budget_id = NEW.budget_id
       AND t.category_id = NEW.category_id;

    IF (v_spent + NEW.amount) > v_allocated THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: amount exceeds remaining category allocation.';
    END IF;
END //

-- ============================================================
-- BEFORE UPDATE TRIGGER (same business rules)
-- Spent sum excludes the row being updated.
-- ============================================================
CREATE TRIGGER trg_txn_before_update
BEFORE UPDATE ON transactions
FOR EACH ROW
BEGIN
    DECLARE v_budget_ok INT DEFAULT 0;
    DECLARE v_alloc_ok  INT DEFAULT 0;
    DECLARE v_allocated DECIMAL(10,2) DEFAULT 0;
    DECLARE v_spent     DECIMAL(10,2) DEFAULT 0;

    SELECT COUNT(*)
      INTO v_budget_ok
      FROM budgets b
     WHERE b.budget_id = NEW.budget_id
       AND b.user_id = NEW.user_id
       AND b.budget_month = DATE_FORMAT(NEW.transaction_date, '%Y-%m-01');

    IF v_budget_ok = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: no monthly budget for this user/date.';
    END IF;

    SELECT COUNT(*), COALESCE(MAX(ba.allocated_amount), 0)
      INTO v_alloc_ok, v_allocated
      FROM budget_allocations ba
     WHERE ba.budget_id = NEW.budget_id
       AND ba.category_id = NEW.category_id;

    IF v_alloc_ok = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: category is not allocated on this budget.';
    END IF;

    SELECT COALESCE(SUM(t.amount), 0)
      INTO v_spent
      FROM transactions t
     WHERE t.budget_id = NEW.budget_id
       AND t.category_id = NEW.category_id
       AND t.transaction_id <> OLD.transaction_id;

    IF (v_spent + NEW.amount) > v_allocated THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rejected: amount exceeds remaining category allocation.';
    END IF;
END //

DELIMITER ;

-- Confirm routines exist
SHOW FULL TABLES WHERE Table_type = 'VIEW';
SHOW FUNCTION STATUS WHERE Db = 'on_the_ledge';
SHOW PROCEDURE STATUS WHERE Db = 'on_the_ledge';
SHOW TRIGGERS FROM on_the_ledge;
