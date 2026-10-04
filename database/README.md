# On-the-Ledge — Review 2 MySQL Backend

Purpose-based personal budgeting ledger. **Review 2 is database-only** (no frontend work in this folder).

## Five tables only

| Table | Role |
| --- | --- |
| `users` | Strong entity |
| `budgets` | Each budget belongs to one user |
| `categories` | Shared master categories |
| `budget_allocations` | Resolves budgets M:N categories via `(budget_id, category_id)` |
| `transactions` | Belongs to user + budget + category (`budget_id` is intentional) |

Do **not** add business/audit tables for the trigger demo.

## Files

| File | Purpose |
| --- | --- |
| `01_schema.sql` | Create DB + five tables + constraints |
| `02_seed_data.sql` | Exactly 5 rows per table (trigger-safe) |
| `03_routines.sql` | View, function, procedures, triggers |
| `04_review2_demo_queries.sql` | Experiment 4B / 5 / 6 demos for Workbench |
| `README.md` | This guide |

Target engine: **MySQL 8.4** (MySQL 8.0.31+ required for `INTERSECT` / `EXCEPT`).

## Exact Workbench execution order

1. Open MySQL Workbench → connect to local MySQL 8.4.
2. Run **`01_schema.sql`** (whole file). Confirms five tables.
3. Run **`02_seed_data.sql`** (whole file). Confirms 5 rows each.
4. Run **`03_routines.sql`** (whole file).  
   - Uses `DELIMITER //` for routines/triggers.  
   - Workbench handles this; do not split mid-routine.
5. Open **`04_review2_demo_queries.sql`** and run **section by section** (highlight one block → Execute).  
   - Failed-trigger demos use `sp_add_transaction_safe` so seed stays at 5 transactions.
6. Optional clean rebuild later: re-run steps 2 → 3 → 4 (schema already present) or 1 → 4 from scratch.

Recommended first-load order:

```text
01_schema.sql  →  02_seed_data.sql  →  03_routines.sql  →  04_review2_demo_queries.sql
```

If you re-run seed **after** triggers exist, inserts still succeed because every seed expense is within an allocated category for that month.

## Objects created in Review 2

- **View:** `v_budget_category_status` — budget, user, category, allocated, spent, remaining  
- **Function:** `fn_remaining_allocation(budget_id, category_id)`  
- **Procedures:**  
  - `sp_add_transaction` — insert expense  
  - `sp_add_transaction_safe` — `DECLARE EXIT HANDLER FOR SQLEXCEPTION` + `ROLLBACK` + status message  
  - `sp_user_month_spending` — cursor totals a user’s spend for one budget month  
- **Triggers:** `trg_txn_before_insert`, `trg_txn_before_update`  
  Reject when: no monthly budget for user/date, category not allocated, or amount exceeds remaining allocation.

## Four-member demo division

### Member 1 — Constraints and set operations (Experiment 4B)

File section: **MEMBER 1** in `04_review2_demo_queries.sql`  
Show: PK / FK / NOT NULL / UNIQUE / CHECK / DEFAULT, then `UNION`, `UNION ALL`, `INTERSECT`, `EXCEPT`.  
Talking points: Vihaan appears in `EXCEPT` (has budget, no expenses).

### Member 2 — Subqueries, joins, and view (Experiment 5)

File section: **MEMBER 2**  
Show: subquery in `WHERE`, subquery in `FROM`, `INNER JOIN`, `LEFT JOIN` (Vihaan NULL allocation), then `SELECT * FROM v_budget_category_status`.

### Member 3 — Function and procedure (Experiment 6 start)

File section: **MEMBER 3**  
Show: `fn_remaining_allocation(1,2) = 4250`, rent remaining `0`, then `sp_add_transaction` inside `START TRANSACTION` / `ROLLBACK`.

### Member 4 — Cursor, trigger, and exception handling (Experiment 6)

File section: **MEMBER 4**  
Show: `sp_user_month_spending` for Aarav (= 10750), three safe failed inserts via `sp_add_transaction_safe` (exceed / not allocated / no October budget), confirm `COUNT(*) = 5` still, mention BEFORE UPDATE rule.

## Seed snapshot (for viva)

- Users: Aarav, Riya, Kabir, Ananya, Vihaan  
- Budgets: one September 2026 wallet each  
- Allocations: Aarav Rent 10000 + Food 5000; Riya Food; Kabir Travel; Ananya Shopping  
- Vihaan: budget only (no allocations / no transactions) — LEFT JOIN + EXCEPT demos  
- Aarav Rent fully spent → easy “exceeds allocation” trigger demo  

## Out of scope for Review 2

Frontend, auth, UPI/bank APIs, payments, AI, notifications, extra tables.
