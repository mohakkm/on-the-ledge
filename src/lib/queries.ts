import { query } from "@/lib/db";
import { DEMO_USER_ID } from "@/lib/demo-user";

export type UserRow = {
  user_id: number;
  first_name: string;
  last_name: string;
  email: string;
  monthly_income: number | string;
};

export type BudgetRow = {
  budget_id: number;
  user_id: number;
  budget_month: Date | string;
  total_amount: number | string;
};

export type CategoryBalanceRow = {
  category_id: number;
  category_name: string;
  allocated_amount: number | string;
  spent: number | string;
  remaining: number | string;
};

export type TransactionRow = {
  transaction_id: number;
  description: string | null;
  amount: number | string;
  category_name: string;
  transaction_date: Date | string;
};

export type CategoryOption = {
  category_id: number;
  category_name: string;
};

export async function getDemoUser(): Promise<UserRow | null> {
  const rows = await query<UserRow>(
    `SELECT user_id, first_name, last_name, email, monthly_income
     FROM users
     WHERE user_id = :userId
     LIMIT 1`,
    { userId: DEMO_USER_ID },
  );
  return rows[0] ?? null;
}

/** Latest budget for the demo user (by budget_month). */
export async function getCurrentBudget(
  userId: number = DEMO_USER_ID,
): Promise<BudgetRow | null> {
  const rows = await query<BudgetRow>(
    `SELECT budget_id, user_id, budget_month, total_amount
     FROM budgets
     WHERE user_id = :userId
     ORDER BY budget_month DESC
     LIMIT 1`,
    { userId },
  );
  return rows[0] ?? null;
}

export async function getCategoryBalances(
  budgetId: number,
): Promise<CategoryBalanceRow[]> {
  return query<CategoryBalanceRow>(
    `SELECT
        c.category_id,
        c.category_name,
        ba.allocated_amount,
        COALESCE(SUM(t.amount), 0) AS spent,
        ba.allocated_amount - COALESCE(SUM(t.amount), 0) AS remaining
     FROM budget_allocations ba
     JOIN categories c ON c.category_id = ba.category_id
     LEFT JOIN transactions t
       ON t.budget_id = ba.budget_id
      AND t.category_id = ba.category_id
     WHERE ba.budget_id = :budgetId
     GROUP BY c.category_id, c.category_name, ba.allocated_amount
     ORDER BY c.category_name`,
    { budgetId },
  );
}

export async function getUserTransactions(
  userId: number = DEMO_USER_ID,
): Promise<TransactionRow[]> {
  return query<TransactionRow>(
    `SELECT
        t.transaction_id,
        t.description,
        t.amount,
        c.category_name,
        t.transaction_date
     FROM transactions t
     JOIN categories c ON c.category_id = t.category_id
     WHERE t.user_id = :userId
     ORDER BY t.transaction_date DESC, t.transaction_id DESC`,
    { userId },
  );
}

export async function listCategories(): Promise<CategoryOption[]> {
  return query<CategoryOption>(
    `SELECT category_id, category_name
     FROM categories
     ORDER BY category_name`,
  );
}
