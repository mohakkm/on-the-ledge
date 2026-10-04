# On-the-Ledge

On-the-Ledge is a purpose-based personal budgeting application.

Instead of only recording where money was spent, the project helps users assign a monthly budget to categories such as Rent, Food, Travel, Shopping, Entertainment, and Savings. Expenses are then recorded against these allocations to show how much remains for each category.

## Status

Under construction.

The database foundation and budgeting logic are currently being developed. The frontend will be expanded later.

## Core Features

- Multiple users with separate budgets and transactions
- Monthly budget creation
- Category-wise budget allocation
- Expense transaction logging
- Remaining-budget calculation
- Database validation for invalid or over-budget expenses

## Technology

- MySQL 8.0+
- MySQL Workbench
- Next.js and TypeScript for the application interface

## Local Setup

### 1. Clone the repository

```
git clone <repository-url>
cd on-the-ledge
```

### 2. Install dependencies

```
npm install
```

### 3. Configure local environment variables

Create a `.env.local` file using `.env.example` as a reference.

```
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=on_the_ledge
DB_USER=root
DB_PASSWORD=your_local_mysql_password
```

Do not commit `.env.local`.

### 4. Set up MySQL

Open MySQL Workbench, connect to your local MySQL server, and run these files in order:

```
database/01_schema.sql
database/02_seed_data.sql
database/03_routines.sql
```

To explore and test the database features, open:

```
database/04_review2_demo_queries.sql
```

### 5. Run the application

```
npm run dev
```

Open `http://localhost:3000` in a browser.

## Database Structure

```
users
  ├── budgets
  │     └── budget_allocations ── categories
  └── transactions ────────────── categories
```

Each user’s budget and transaction data is tied to their own user ID. Categories are shared master entries, while allocations and expenses remain separate for every user.