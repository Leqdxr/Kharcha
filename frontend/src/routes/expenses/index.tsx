import {
  $,
  component$,
  useSignal,
  useStylesScoped$,
  useVisibleTask$,
} from "@builder.io/qwik";
import { useNavigate, type DocumentHead } from "@builder.io/qwik-city";
import { AddExpenseForm } from "~/components/add-expense-form/add-expense-form";
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
  `);

  const nav = useNavigate();
  const user = useSignal<User | null>(null);
  const expenses = useSignal<Expense[]>([]);
  const loaded = useSignal(false);
  const notice = useSignal("");

  // localStorage is only available in the browser.
  // eslint-disable-next-line qwik/no-use-visible-task
  useVisibleTask$(async () => {
    if (!getToken()) {
      await nav("/login", { replaceState: true });
      return;
    }
    user.value = getUser();

    const res = await api.get<Expense[]>("/expenses");
    if (res.ok) expenses.value = res.data;
    loaded.value = true;
  });

  const addExpense = $((expense: Expense) => {
    expenses.value = sortExpenses([...expenses.value, expense]);
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

        <SummaryCards expenses={monthExpenses} />

        {notice.value && (
          <p class="field-error" role="alert">
            {notice.value}
          </p>
        )}

        {loaded.value && (
          <div class="content">
            {expenses.value.length > 0 ? (
              <ExpenseTable
                expenses={expenses.value}
                onDelete$={deleteExpense}
              />
            ) : (
              <EmptyState />
            )}
            <AddExpenseForm onAdded$={addExpense} />
          </div>
        )}
      </main>
    </>
  );
});

export const head: DocumentHead = {
  title: "Expenses · Kharcha",
};
