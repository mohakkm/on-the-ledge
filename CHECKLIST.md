# Checklist — On-the-ledge

## PHASE 1 — DATABASE FOUNDATION

- [x] Choose the Review-1 table set: `users`, `budgets`, `categories`, `budget_allocations`, `transactions`
- [x] Document relationships (`users` 1:M `budgets`, `budgets` M:N `categories` through `budget_allocations`, `users`/`budgets`/`categories` → `transactions` with intentional `budget_id` FK)
- [x] MySQL 8.4 schema documented in `sql/01_schema.sql`
- [x] Sample data documented in `sql/02_seed.sql` (5 rows per table)
- [x] Live local MySQL database `on_the_ledge` created and seeded (outside this app; do not re-run casually)
- [x] Confirm app targets MySQL via `mysql2` (not Supabase / Postgres)

## PHASE 2 — DATABASE INTELLIGENCE

- [ ] Add a SQL view (or routine) for category remaining = allocated − spent
- [ ] Add a SQL view for budget remaining = budget total − spent
- [ ] Decide whether allocation totals must be constrained to `<= budgets.total_amount`
- [ ] Add any extra indexes justified by remaining-balance queries
- [ ] Keep reusable query examples for reviews
- [ ] Keep intelligence in SQL; do not move remaining balances into stored columns unless explicitly instructed

## PHASE 3 — APPLICATION / MVP

- [x] Initialize the Next.js application
- [x] Connect Next.js to local MySQL with server-side `mysql2/promise` pool + env vars
- [x] Dashboard: current budget + categories Allocated / Spent / Remaining (join query)
- [x] Transactions page: list for hardcoded `user_id = 1` (Aarav)
- [x] Add Expense form: insert into `transactions` (Server Action)
- [x] Remove in-memory / TypeScript seed demo path
- [x] Keep handoff docs accurate (`ARCHITECTURE.md`, `CHECKLIST.md`, `STATE.md`)
- [ ] Add real authentication (not required for Review 1)
- [ ] Keep the UI basic until an explicit polish pass is requested
