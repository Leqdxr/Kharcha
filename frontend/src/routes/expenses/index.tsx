import {
  $,
  component$,
  useSignal,
  useStylesScoped$,
  useVisibleTask$,
} from "@builder.io/qwik";
import { useNavigate, type DocumentHead } from "@builder.io/qwik-city";
import { AddExpenseForm } from "~/components/add-expense-form/add-expense-form";
import { EditExpenseModal } from "~/components/edit-expense-modal/edit-expense-modal";
import { EmptyState } from "~/components/empty-state/empty-state";
import { ExpenseTable } from "~/components/expense-table/expense-table";
import { Navbar } from "~/components/navbar/navbar";
import { SummaryCards } from "~/components/summary-cards/summary-cards";
import { api } from "~/lib/api";
import { getToken, getUser } from "~/lib/auth";
import { sortExpenses, today } from "~/lib/format";
import type { Expense, User } from "~/lib/types";

export default component$(() => {
  useStylesScoped$(`
    main {
      max-width: 1200px;
      margin: 0 auto;
      padding: 40px 32px 64px;
      display: flex;
      flex-direction: column;
      gap: 32px;
    }
    .heading {
      display: flex;
      flex-direction: column;
      gap: 6px;
    }
    .month {
      font-family: var(--font-mono);
      font-size: 13px;
      font-weight: 600;
      letter-spacing: 0.06em;
      color: var(--red);
    }
    h1 {
      margin: 0;
      font-size: 36px;
      line-height: 1.15;
      font-weight: 700;
      letter-spacing: -0.02em;
    }
    .content {
      display: flex;
      flex-wrap: wrap;
      gap: 24px;
      align-items: flex-start;
    }
    .status {
      padding: 48px 24px;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
      text-align: center;
      color: var(--muted);
    }
    .status p {
      margin: 0;
      font-size: 16px;
    }
    @media (max-width: 480px) {
      main {
        padding: 24px 16px 48px;
        gap: 24px;
      }
      h1 {
        font-size: 30px;
      }
    }
  `);

  const nav = useNavigate();
  const user = useSignal<User | null>(null);
  const expenses = useSignal<Expense[]>([]);
  const status = useSignal<"loading" | "ready" | "error">("loading");
  const notice = useSignal("");
  const editing = useSignal<Expense | null>(null);

  const loadExpenses = $(async () => {
    status.value = "loading";
    const res = await api.get<Expense[]>("/expenses");
    if (res.ok) {
      expenses.value = res.data;
      status.value = "ready";
    } else {
      status.value = "error";
    }
  });

  // localStorage is only available in the browser.
  // eslint-disable-next-line qwik/no-use-visible-task
  useVisibleTask$(async () => {
    if (!getToken()) {
      await nav("/login", { replaceState: true });
      return;
    }
    user.value = getUser();
    await loadExpenses();
  });

  const addExpense = $((expense: Expense) => {
    notice.value = "";
    expenses.value = sortExpenses([...expenses.value, expense]);
  });

  const saveExpense = $((saved: Expense) => {
    notice.value = "";
    expenses.value = sortExpenses(
      expenses.value.map((e) => (e.id === saved.id ? saved : e)),
    );
    editing.value = null;
  });

  const deleteExpense = $(async (id: number) => {
    notice.value = "";
    const res = await api.del(`/expenses/${id}`);
    if (!res.ok) {
      notice.value = `Couldn't delete the expense. ${res.error.message}`;
      return;
    }
    expenses.value = expenses.value.filter((e) => e.id !== id);
  });

  // The summary cards count this month only, e.g. "2026-11".
  const thisMonth = today().slice(0, 7);
  const monthExpenses = expenses.value.filter((e) =>
    e.date.startsWith(thisMonth),
  );
  const monthLabel = new Date()
    .toLocaleDateString("en-US", { month: "long", year: "numeric" })
    .toUpperCase();

  return (
    <>
      <Navbar user={user.value} />

      <main>
        <div class="heading">
          <span class="month">{monthLabel}</span>
          <h1>Your expenses</h1>
        </div>

        {status.value === "loading" && (
          <div class="card status" role="status">
            <p>Loading expenses…</p>
          </div>
        )}

        {status.value === "error" && (
          <div class="card status" role="alert">
            <p>Couldn’t load expenses. Try again.</p>
            <button
              type="button"
              class="btn-secondary"
              onClick$={loadExpenses}
            >
              Try again
            </button>
          </div>
        )}

        {status.value === "ready" && (
          <>
            <SummaryCards expenses={monthExpenses} />

            {notice.value && (
              <p class="field-error" role="alert">
                {notice.value}
              </p>
            )}

            <div class="content">
              {expenses.value.length > 0 ? (
                <ExpenseTable
                  expenses={expenses.value}
                  onEdit$={(expense) => (editing.value = expense)}
                  onDelete$={deleteExpense}
                />
              ) : (
                <EmptyState />
              )}
              <AddExpenseForm onAdded$={addExpense} />
            </div>
          </>
        )}
      </main>

      {editing.value && (
        <EditExpenseModal
          key={editing.value.id}
          expense={editing.value}
          onClose$={() => (editing.value = null)}
          onSaved$={saveExpense}
          onDelete$={deleteExpense}
        />
      )}
    </>
  );
});

export const head: DocumentHead = {
  title: "Expenses · Kharcha",
};
