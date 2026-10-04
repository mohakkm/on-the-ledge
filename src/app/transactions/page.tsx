import {
  getUserTransactions,
  type TransactionRow,
} from "@/lib/queries";
import { formatInr, toDateInputValue } from "@/lib/format";

export const dynamic = "force-dynamic";

export default async function TransactionsPage() {
  let rows: TransactionRow[] = [];
  let error: string | null = null;

  try {
    rows = await getUserTransactions();
  } catch (err) {
    error =
      err instanceof Error
        ? err.message
        : "Could not load transactions from MySQL.";
  }

  return (
    <main>
      <header>
        <h1>Transactions</h1>
        <p>Expenses for Aarav (user_id = 1).</p>
      </header>

      <section>
        {error ? (
          <p className="error">Database error: {error}</p>
        ) : rows.length === 0 ? (
          <p>No transactions yet.</p>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Date</th>
                <th>Description</th>
                <th>Category</th>
                <th>Amount</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.transaction_id}>
                  <td>{toDateInputValue(row.transaction_date)}</td>
                  <td>{row.description ?? "—"}</td>
                  <td>{row.category_name}</td>
                  <td>{formatInr(row.amount)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </main>
  );
}
