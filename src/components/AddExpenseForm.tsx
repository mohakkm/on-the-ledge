"use client";

import { useActionState } from "react";
import { addExpense, type AddExpenseState } from "@/app/actions";
import type { CategoryOption } from "@/lib/queries";

type Props = {
  categories: CategoryOption[];
  defaultDate: string;
};

const initialState: AddExpenseState = {};

export function AddExpenseForm({ categories, defaultDate }: Props) {
  const [state, formAction, pending] = useActionState(addExpense, initialState);

  return (
    <form action={formAction}>
      <h1>Add Expense</h1>
      <p>
        Inserts a row into <code>transactions</code> for Aarav&apos;s current
        budget. Credentials stay on the server.
      </p>

      {state.error ? <p className="error">{state.error}</p> : null}

      <label>
        Description
        <input name="description" type="text" required maxLength={255} />
      </label>

      <label>
        Amount (INR)
        <input name="amount" type="number" min="0.01" step="0.01" required />
      </label>

      <label>
        Category
        <select name="category_id" required defaultValue="">
          <option value="" disabled>
            Select category
          </option>
          {categories.map((category) => (
            <option key={category.category_id} value={category.category_id}>
              {category.category_name}
            </option>
          ))}
        </select>
      </label>

      <label>
        Date
        <input
          name="transaction_date"
          type="date"
          required
          defaultValue={defaultDate}
        />
      </label>

      <button type="submit" disabled={pending}>
        {pending ? "Saving…" : "Save expense"}
      </button>
    </form>
  );
}
