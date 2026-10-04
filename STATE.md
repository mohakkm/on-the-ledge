# State — On-the-ledge

Handoff file for the next human or AI agent. Update this file after meaningful work. Do not mark work complete unless it exists in the repo.

## Project purpose

On-the-ledge is a purpose-based personal budgeting ledger. Users allocate monthly income into purpose categories and record expenses against those allocations. It is not a banking, UPI, payment, investment, or AI-advisor product.

## Current stage

**Review 2 MySQL backend package is in `database/`** (schema, seed, routines, demo queries).  
Verified on local MySQL **8.4.11**. Five tables only. No auth / no Review-2 frontend work.  
Legacy Review-1 copies also remain under `sql/` and the Next.js app under `src/`.

## Work completed

- Review 2 backend under `database/`:
  - `01_schema.sql`, `02_seed_data.sql`, `03_routines.sql`, `04_review2_demo_queries.sql`, `README.md`
  - View `v_budget_category_status`
  - Function `fn_remaining_allocation`
  - Procedures `sp_add_transaction`, `sp_add_transaction_safe`, `sp_user_month_spending` (cursor)
  - Triggers `trg_txn_before_insert`, `trg_txn_before_update` (no audit table)
- Review 1 Next.js demo still present under `src/` (not required for Review 2)
- Legacy SQL copies under `sql/`

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

1. Demo Review 2 from `database/README.md` execution order in Workbench.
2. Keep frontend/`src/` unchanged unless a later review asks for it.
3. Auth only when explicitly requested.

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
- Do not add a sixth business/audit table.
- Do not remove `transactions.budget_id`.
- Prefer `database/` as the Review 2 source of truth; do not casually wipe live MySQL data.
- Do not implement auth, UPI, banks, payments, AI, notifications, or analytics dashboards.
- Do not polish into a production fintech UI.
- Do not store remaining balances as table columns.
- Do not expose MySQL credentials or `mysql2` usage to client components.
- Do not delete `ARCHITECTURE.md`, `CHECKLIST.md`, or `STATE.md`.
- After meaningful work: update `STATE.md` and `CHECKLIST.md`; update `ARCHITECTURE.md` only when architecture changes.
