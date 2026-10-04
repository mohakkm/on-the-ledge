"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { execute } from "@/lib/db";
import { DEMO_USER_ID } from "@/lib/demo-user";
import { getCurrentBudget } from "@/lib/queries";

export type AddExpenseState = {
  error?: string;
};

export async function addExpense(
  _prev: AddExpenseState,
  formData: FormData,
): Promise<AddExpenseState> {
  const description = String(formData.get("description") ?? "").trim();
  const amount = Number(formData.get("amount"));
  const categoryId = Number(formData.get("category_id"));
  const transactionDate = String(formData.get("transaction_date") ?? "");

  if (!description) {
    return { error: "Description is required." };
  }
  if (!Number.isFinite(amount) || amount <= 0) {
    return { error: "Amount must be a positive number." };
  }
  if (!Number.isInteger(categoryId) || categoryId <= 0) {
    return { error: "Choose a category." };
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(transactionDate)) {
    return { error: "Date must be YYYY-MM-DD." };
  }

  const budget = await getCurrentBudget(DEMO_USER_ID);
  if (!budget) {
    return { error: "No budget found for this user." };
  }

  await execute(
    `INSERT INTO transactions
       (user_id, budget_id, category_id, amount, description, transaction_date)
     VALUES
       (:userId, :budgetId, :categoryId, :amount, :description, :transactionDate)`,
    {
      userId: DEMO_USER_ID,
      budgetId: budget.budget_id,
      categoryId,
      amount,
      description,
      transactionDate,
    },
  );

  revalidatePath("/");
  revalidatePath("/transactions");
  revalidatePath("/add-expense");
  redirect("/transactions");
}
