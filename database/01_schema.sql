-- ============================================================
-- ON-THE-LEDGE — REVIEW 2 SCHEMA (MySQL 8.4)
-- Exactly five business tables. Do not add more tables here.
--
-- Relationships (preserved from Review 1):
--   users 1:M budgets
--   budgets M:N categories  via  budget_allocations (budget_id, category_id)
--   users 1:M transactions
--   categories 1:M transactions
--   budgets 1:M transactions   (budget_id is intentional)
--
-- Categories = shared master data.
-- Budgets / allocations / transactions = user-specific via FKs.
-- ============================================================

CREATE DATABASE IF NOT EXISTS on_the_ledge
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE on_the_ledge;

-- Fresh install helper (safe for demo rebuilds).
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS budget_allocations;
DROP TABLE IF EXISTS budgets;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;

-- ------------------------------------------------------------
-- 1. USERS
-- Constraints shown: PRIMARY KEY, NOT NULL, UNIQUE, CHECK, DEFAULT
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
-- 2. BUDGETS  (each budget belongs to one user)
-- Constraints: PK, FK, NOT NULL, UNIQUE(user, month), CHECK
-- ------------------------------------------------------------
CREATE TABLE budgets (
    budget_id       INT AUTO_INCREMENT PRIMARY KEY,
    user_id         INT NOT NULL,
    budget_month    DATE NOT NULL,          -- first-of-month, e.g. 2026-09-01
    total_amount    DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_budget_user FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_total_amount CHECK (total_amount > 0),
    CONSTRAINT uq_user_month UNIQUE (user_id, budget_month)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 3. CATEGORIES  (common / shared master categories)
-- ------------------------------------------------------------
CREATE TABLE categories (
    category_id     INT AUTO_INCREMENT PRIMARY KEY,
    category_name   VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 4. BUDGET_ALLOCATIONS
-- Resolves budgets M:N categories. Composite PK = identity.
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
-- Belongs to a user, a budget (month wallet), and a category.
-- budget_id is intentional so Remaining is unambiguous.
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
