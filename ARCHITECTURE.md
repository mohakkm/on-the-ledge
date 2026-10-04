# Architecture — On-the-ledge

## Project purpose

On-the-ledge is a purpose-based personal budgeting ledger. A user assigns available monthly income to named purpose categories and records expenses against those allocations. Remaining amounts are derived from allocations minus matching expenses.

The product is **not** currently a bank, UPI, payment, investment, or advice application. It does not connect to real bank accounts.

## Current architecture

Review-1 layers:

1. **MySQL 8.4 LTS** database `on_the_ledge` (local). Schema and seed already exist; SQL under `sql/` documents them but must not be re-applied casually.
2. **Next.js App Router** reads/writes MySQL through a **server-only** `mysql2/promise` connection pool.
3. **Handoff docs** (`ARCHITECTURE.md`, `CHECKLIST.md`, `STATE.md`).

There is no authentication, no Supabase, and no external financial APIs.

```
Browser (Next.js pages)
        |
        |  Server Components / Server Actions
        v
src/lib/db.ts  (mysql2/promise pool, env credentials)
        |
        v
MySQL 8.4  →  database on_the_ledge
```

## Technology stack

| Layer | Choice |
| --- | --- |
| Frontend | Next.js (App Router, TypeScript, Tailwind) |
| Database | **MySQL 8.4 LTS** (`on_the_ledge`), local |
| Driver | `mysql2` / `mysql2/promise` (server-side pool only) |
| Config | `.env.local` (`MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE`) |
| Schema reference | `sql/01_schema.sql`, `sql/02_seed.sql` (already applied; do not regenerate without instruction) |
| Not used | Supabase, PostgreSQL, Firebase, MongoDB |

## Database architecture

Five tables:

| Table | Role |
| --- | --- |
| `users` | People who own budgets and expenses |
| `budgets` | Monthly budgets (`budget_month`, `total_amount`) |
| `categories` | Shared purpose labels |
| `budget_allocations` | Amount assigned from a budget to a category (composite PK) |
| `transactions` | Expenses with `user_id`, **`budget_id`**, `category_id`, amount, description, date |

`transactions.budget_id` is intentional. Remaining is computed by joining `budget_allocations` to `transactions` on `(budget_id, category_id)`, not by date-matching alone.

Money uses `DECIMAL`. Primary keys are `INT AUTO_INCREMENT`.

## Table relationships

```
users 1:M budgets
users 1:M transactions
budgets 1:M transactions          (via budget_id)
categories 1:M transactions
budgets M:N categories  via  budget_allocations
```

## Frontend architecture

- Hardcoded Review-1 user: `user_id = 1` (Aarav) in `src/lib/demo-user.ts`.
- `/` — dashboard: current budget + category Allocated / Spent / Remaining.
- `/transactions` — list of that user’s transactions.
- `/add-expense` — form that inserts into `transactions` via a Server Action.
- `src/lib/db.ts` — pool; `src/lib/queries.ts` — read queries; `src/app/actions.ts` — insert.

## Current data flow

1. Server Component calls `getPool()` / `query()` with credentials from env.
2. Dashboard loads Aarav’s latest budget, then category balances with the join/group query from the seed sanity check.
3. Transactions page lists Aarav’s expenses joined to category names.
4. Add Expense inserts with Aarav’s `user_id`, current `budget_id`, chosen `category_id`, then revalidates and redirects to `/transactions`.

## Future architecture

Later phases may add auth, SQL views for remaining balances, stricter allocation constraints, and a polished UI — only when asked.

## Future integration points (not implemented)

- Authentication
- Bank account linking / UPI / payment gateways
- Investments / AI advice
- Notifications / analytics dashboards

## Important architectural decisions

1. **Ledger, not a bank.** No real-money movement.
2. **MySQL 8.4 is the database** — not Supabase / Postgres.
3. **Exactly five tables.** Do not add tables unless asked.
4. **`transactions.budget_id` is required and intentional.**
5. **Remaining amounts are calculated**, not stored.
6. **DB credentials never go to the client** — only Server Components / Actions / Route Handlers use `mysql2`.
7. **No auth yet** — hardcoded Aarav (`user_id = 1`).
8. **Do not regenerate schema/seed** unless explicitly instructed; live DB already has data.
