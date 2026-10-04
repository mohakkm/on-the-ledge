# On-the-ledge

Purpose-based personal budgeting ledger (Review 1).

Handoff docs: [ARCHITECTURE.md](./ARCHITECTURE.md), [CHECKLIST.md](./CHECKLIST.md), [STATE.md](./STATE.md).  
Schema reference (already applied to local MySQL): `sql/`.

## Stack

- Next.js (App Router)
- **MySQL 8.4 LTS**, database `on_the_ledge`
- `mysql2/promise` server-side pool (credentials in `.env.local` only)

## Setup

1. Copy `.env.example` → `.env.local` and fill MySQL credentials.
2. Confirm MySQL is running and `on_the_ledge` is already seeded (do not re-run schema casually).
3. Install and run:

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000). Review 1 UI hardcodes `user_id = 1` (Aarav).

Routes: `/` dashboard, `/transactions`, `/add-expense`.
