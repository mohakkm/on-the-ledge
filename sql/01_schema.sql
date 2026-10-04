-- ============================================================
-- ON-THE-LEDGE — REVIEW 1 SCHEMA
-- Purpose-based personal budgeting system
-- Target: MySQL 8.4 LTS
-- ============================================================

CREATE DATABASE IF NOT EXISTS on_the_ledge
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE on_the_ledge;

-- ------------------------------------------------------------
-- 1. USERS  (strong entity)
-- ------------------------------------------------------------
CREATE TABLE users (
    user_id         INT AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(50)  NOT NULL,
    middle_name     VARCHAR(50)  NULL,
    last_name       VARCHAR(50)  NOT NULL,
    email           VARCHAR(100) NOT NULL UNIQUE,
    monthly_income  DECIMAL(10,2) NOT NULL DEFAULT 0,
    CONSTRAINT chk_income CHECK (monthly_income >= 0)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2. BUDGETS  (strong entity, 1:M with USER)
-- ------------------------------------------------------------
CREATE TABLE budgets (
    budget_id       INT AUTO_INCREMENT PRIMARY KEY,
    user_id         INT NOT NULL,
    budget_month    DATE NOT NULL,          -- store as first-of-month, e.g. 2026-09-01
    total_amount    DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_budget_user FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_total_amount CHECK (total_amount > 0),
    CONSTRAINT uq_user_month UNIQUE (user_id, budget_month)   -- one budget per user per month
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 3. CATEGORIES  (strong entity, shared across users)
-- ------------------------------------------------------------
CREATE TABLE categories (
    category_id     INT AUTO_INCREMENT PRIMARY KEY,
    category_name   VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 4. BUDGET_ALLOCATIONS  (weak entity — resolves BUDGET M:N CATEGORY)
--    Identity depends on (budget_id, category_id)
-- ------------------------------------------------------------
CREATE TABLE budget_allocations (
    budget_id        INT NOT NULL,
    category_id      INT NOT NULL,
    allocated_amount DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (budget_id, category_id),
    CONSTRAINT fk_alloc_budget FOREIGN KEY (budget_id)
        REFERENCES budgets(budget_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_alloc_category FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_allocated_amount CHECK (allocated_amount >= 0)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 5. TRANSACTIONS
--    NOTE — deviation from the original spec: budget_id is added
--    here explicitly. Without it, "remaining amount" can only be
--    computed by matching transaction_date to a budget's month,
--    which breaks the moment a user has overlapping budgets or an
--    odd-dated entry. Explicit FK makes the Allocated->Spent->
--    Remaining query correct and unambiguous.
-- ------------------------------------------------------------
CREATE TABLE transactions (
    transaction_id    INT AUTO_INCREMENT PRIMARY KEY,
    user_id           INT NOT NULL,
    budget_id         INT NOT NULL,
    category_id       INT NOT NULL,
    amount            DECIMAL(10,2) NOT NULL,
    description       VARCHAR(255),
    transaction_date  DATE NOT NULL,
    CONSTRAINT fk_txn_user FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_txn_budget FOREIGN KEY (budget_id)
        REFERENCES budgets(budget_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_txn_category FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_amount CHECK (amount > 0)
) ENGINE=InnoDB;

SHOW TABLES;