# State — On-the-ledge

Handoff file for the next human or AI agent. Update this file after meaningful work. Do not mark work complete unless it exists in the repo.

## Project purpose

On-the-ledge is a purpose-based personal budgeting ledger. Users allocate monthly income into purpose categories and record expenses against those allocations. It is not a banking, UPI, payment, investment, or AI-advisor product.

## Current stage

**Review 1 app connected to local MySQL 8.4 (`on_the_ledge`).**  
Schema/seed already exist in MySQL; `sql/` is documentation of that model.  
Phase 2 (SQL views / intelligence) has not started. No auth.

## Work completed

- MySQL schema + seed documented in `sql/01_schema.sql` and `sql/02_seed.sql` (already applied locally)
- Next.js App Router UI with three routes: Dashboard, Transactions, Add Expense
- Server-only `mysql2/promise` pool (`src/lib/db.ts`) using env vars
- Category Allocated / Spent / Remaining via join of `budget_allocations` + `transactions`
- Add Expense persists through a Server Action into `transactions` (includes `budget_id`)
- Removed Supabase-oriented docs and the old TypeScript in-memory seed demo
- Architecture / checklist / state updated for MySQL

## Current implementation

Hardcoded demo user: **Aarav**, `user_id = 1` (`src/lib/demo-user.ts`).  
Current budget = latest row in `budgets` for that user (`ORDER BY budget_month DESC`).  
Add Expense always attaches the new row to that current `budget_id`.

Pages:

- `/` — dashboard
- `/transactions` — transaction list
- `/add-expense` — insert form

## Database status

| Item | Status |
| --- | --- |
| Engine | **MySQL 8.4 LTS** |
| Database name | `on_the_ledge` |
| Table count | 5 |
| `transactions.budget_id` | Present and intentional |
| Schema regeneration | **Do not** re-run without instruction |
| Supabase | **Not used** |
| Remaining stored as a column | No (calculated) |

## Frontend status

| Item | Status |
| --- | --- |
| Next.js | Yes |
| Live MySQL reads | Yes (when `.env.local` is set) |
| Live MySQL writes (Add Expense) | Yes |
| Auth | Not implemented (hardcoded user 1) |
| Production UI polish | No |

## Known limitations

- Requires correct `.env.local` (see `.env.example`); without it, pages show a DB error message.
- Only Aarav is used in the UI.
- Seed has allocations only for some categories/budgets (Aarav: Rent + Food).
- Add Expense does not enforce remaining-budget caps.
- No automated tests.

## Current next steps

1. Ensure `.env.local` points at the local MySQL instance and restart `npm run dev`.
2. Manually verify Dashboard / Transactions / Add Expense against seeded Aarav data.
3. Optionally start Phase 2 remaining-balance views in MySQL.
4. Auth only when explicitly requested.

## Future implementations

Do not build unless asked: auth, UPI, bank APIs, payments, investments, AI, notifications, analytics dashboards, polished fintech UI.

## Important decisions

- **MySQL 8.4**, not Supabase/Postgres.
- Remaining amounts are derived with SQL joins.
- `budget_id` on `transactions` is required.
- Credentials never ship to the client.
- Do not regenerate schema/seed without explicit instruction.

## Things future AI agents must NOT change without explicit instruction

- Do **not** introduce Supabase, Firebase, MongoDB, or Postgres as the app database.
- Do not add a sixth table.
- Do not remove `transactions.budget_id`.
- Do not regenerate or wipe `sql/` / the live MySQL data unless asked.
- Do not implement auth, UPI, banks, payments, AI, notifications, or analytics dashboards.
- Do not polish into a production fintech UI.
- Do not store remaining balances as table columns.
- Do not expose MySQL credentials or `mysql2` usage to client components.
- Do not delete `ARCHITECTURE.md`, `CHECKLIST.md`, or `STATE.md`.
- After meaningful work: update `STATE.md` and `CHECKLIST.md`; update `ARCHITECTURE.md` only when architecture changes.
