import { AddExpenseForm } from "@/components/AddExpenseForm";
import { listCategories, type CategoryOption } from "@/lib/queries";

export const dynamic = "force-dynamic";

export default async function AddExpensePage() {
  let categories: CategoryOption[] = [];
  let error: string | null = null;

  try {
    categories = await listCategories();
  } catch (err) {
    error =
      err instanceof Error
        ? err.message
        : "Could not load categories from MySQL.";
  }

  const defaultDate = "2026-09-07";

  return (
    <main>
      {error ? (
        <section>
          <h1>Add Expense</h1>
          <p className="error">Database error: {error}</p>
        </section>
      ) : (
        <AddExpenseForm categories={categories} defaultDate={defaultDate} />
      )}
    </main>
  );
}
