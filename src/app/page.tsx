import {
  getCategoryBalances,
  getCurrentBudget,
  getDemoUser,
  type BudgetRow,
  type CategoryBalanceRow,
  type UserRow,
} from "@/lib/queries";
import { formatInr, formatMonth } from "@/lib/format";

export const dynamic = "force-dynamic";

export default async function DashboardPage() {
  let user: UserRow | null = null;
  let budget: BudgetRow | null = null;
  let categories: CategoryBalanceRow[] = [];
  let error: string | null = null;

  try {
    user = await getDemoUser();
    budget = await getCurrentBudget();
    if (budget) {
      categories = await getCategoryBalances(budget.budget_id);
    }
  } catch (err) {
    error =
      err instanceof Error
        ? err.message
        : "Could not connect to MySQL. Check .env.local.";
  }

  if (error) {
    return (
      <main>
        <h1>Dashboard</h1>
        <section>
          <p className="error">Database error: {error}</p>
          <p>
            Copy <code>.env.example</code> to <code>.env.local</code>, set MySQL
            credentials for database <code>on_the_ledge</code>, then restart{" "}
            <code>npm run dev</code>.
          </p>
        </section>
      </main>
    );
  }

  if (!user || !budget) {
    return (
      <main>
        <h1>Dashboard</h1>
        <section>
          <p>No user or budget found for user_id = 1. Is the seed loaded?</p>
        </section>
      </main>
    );
  }

  const totalAllocated = categories.reduce(
    (sum, row) => sum + Number(row.allocated_amount),
    0,
  );
  const totalSpent = categories.reduce((sum, row) => sum + Number(row.spent), 0);

  return (
    <main>
      <header>
        <h1>Dashboard</h1>
        <p>
          {user.first_name} {user.last_name} — current budget for{" "}
          {formatMonth(budget.budget_month)}
        </p>
      </header>

      <section>
        <h2>Current budget</h2>
        <p>Budget ID: {budget.budget_id}</p>
        <p>Total amount: {formatInr(budget.total_amount)}</p>
        <p>Allocated (listed categories): {formatInr(totalAllocated)}</p>
        <p>Spent (listed categories): {formatInr(totalSpent)}</p>
        <p>
          Remaining (listed categories):{" "}
          {formatInr(totalAllocated - totalSpent)}
        </p>
      </section>

      <section>
        <h2>Categories</h2>
        {categories.length === 0 ? (
          <p>No allocations on this budget yet.</p>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Category</th>
                <th>Allocated</th>
                <th>Spent</th>
                <th>Remaining</th>
              </tr>
            </thead>
            <tbody>
              {categories.map((row) => (
                <tr key={row.category_id}>
                  <td>{row.category_name}</td>
                  <td>{formatInr(row.allocated_amount)}</td>
                  <td>{formatInr(row.spent)}</td>
                  <td>{formatInr(row.remaining)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </main>
  );
}
