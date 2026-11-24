import {
  $,
  component$,
  useSignal,
  useStylesScoped$,
  useVisibleTask$,
} from "@builder.io/qwik";
import { useNavigate, type DocumentHead } from "@builder.io/qwik-city";
import { AddExpenseForm } from "~/components/add-expense-form/add-expense-form";
import { BudgetDialog } from "~/components/budget-dialog/budget-dialog";
import { ConfirmDialog } from "~/components/confirm-dialog/confirm-dialog";
import { EditExpenseModal } from "~/components/edit-expense-modal/edit-expense-modal";
import { EmptyState } from "~/components/empty-state/empty-state";
import { ExpenseList } from "~/components/expense-list/expense-list";
import { Navbar } from "~/components/navbar/navbar";
import { SummaryCards } from "~/components/summary-cards/summary-cards";
import { UndoToast } from "~/components/undo-toast/undo-toast";
import { api } from "~/lib/api";
import { getToken, getUser, saveAuth } from "~/lib/auth";
import {
  formatMoney,
  formatMonth,
  shiftMonth,
  sortExpenses,
  today,
} from "~/lib/format";
import type { Expense, Summary, User } from "~/lib/types";

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
    .month-bar {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
    }
    .switcher {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .switcher button {
      width: 44px;
      height: 44px;
      flex: none;
      border: 1px solid var(--input-border);
      border-radius: 22px;
      background: var(--white);
      color: var(--ink);
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
    }
    .switcher button:hover:not(:disabled) {
      background: var(--surface);
    }
    .switcher button:disabled {
      opacity: 0.35;
      cursor: not-allowed;
    }
    h1 {
      margin: 0 8px;
      min-width: 250px;
      text-align: center;
      font-size: 32px;
      line-height: 1.2;
      font-weight: 700;
      letter-spacing: -0.02em;
    }
    .count {
      font-size: 15px;
      color: var(--muted);
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
        margin: 0;
        min-width: 0;
        flex: 1;
        font-size: 24px;
      }
      .switcher {
        width: 100%;
      }
    }
  `);

  const nav = useNavigate();
  const user = useSignal<User | null>(null);
  const month = useSignal(today().slice(0, 7)); // YYYY-MM
  const expenses = useSignal<Expense[]>([]);
  const summary = useSignal<Summary | null>(null);
  const status = useSignal<"loading" | "ready" | "error">("loading");
  const notice = useSignal("");
  const editing = useSignal<Expense | null>(null);
  const editingBudget = useSignal(false);
  const search = useSignal("");
  // The expense waiting for "Delete this expense?" to be confirmed
  const confirming = useSignal<Expense | null>(null);
  // A deleted expense waiting 5 seconds for Undo before the DELETE is sent
  const pendingDelete = useSignal<{ expense: Expense; timer: number } | null>(
    null,
  );

  const sendDelete = $(async (expense: Expense) => {
    const res = await api.del(`/expenses/${expense.id}`);
    if (!res.ok) {
      notice.value = `Couldn't delete "${expense.title}". ${res.error.message}`;
      if (expense.date.startsWith(month.value)) {
        expenses.value = sortExpenses([...expenses.value, expense]);
      }
    }
  });

  // Send the waiting DELETE now (before reloading or deleting another one).
  const flushDelete = $(async () => {
    const pending = pendingDelete.value;
    if (!pending) return;
    clearTimeout(pending.timer);
    pendingDelete.value = null;
    await sendDelete(pending.expense);
  });

  const loadMonth = $(async () => {
    await flushDelete();
    status.value = "loading";
    const [list, totals] = await Promise.all([
      api.get<Expense[]>(`/expenses?month=${month.value}`),
      api.get<Summary>(`/summary?month=${month.value}`),
    ]);
    if (list.ok && totals.ok) {
      expenses.value = list.data;
      summary.value = totals.data;
      status.value = "ready";
    } else {
      status.value = "error";
    }
  });

  const changeMonth = $(async (by: number) => {
    notice.value = "";
    month.value = shiftMonth(month.value, by);
    await loadMonth();
  });

  const saveBudget = $((saved: User) => {
    if (summary.value) {
      summary.value = { ...summary.value, budget: saved.monthly_budget };
    }
    const token = getToken();
    if (token) saveAuth(token, saved);
    user.value = saved;
    editingBudget.value = false;
  });

  // localStorage is only available in the browser.
  // eslint-disable-next-line qwik/no-use-visible-task
  useVisibleTask$(async () => {
    if (!getToken()) {
      await nav("/login", { replaceState: true });
      return;
    }
    user.value = getUser();
    await loadMonth();
  });

  const addExpense = $(async (expense: Expense) => {
    notice.value = "";
    // Added to another month: show that month.
    if (!expense.date.startsWith(month.value)) {
      month.value = expense.date.slice(0, 7);
      await loadMonth();
      return;
    }
    expenses.value = sortExpenses([...expenses.value, expense]);
  });

  const saveExpense = $((saved: Expense) => {
    notice.value = "";
    const others = expenses.value.filter((e) => e.id !== saved.id);
    // Moved to another month: it leaves this list.
    expenses.value = saved.date.startsWith(month.value)
      ? sortExpenses([...others, saved])
      : others;
    editing.value = null;
  });

  const deleteExpense = $(async (expense: Expense) => {
    notice.value = "";
    await flushDelete();
    expenses.value = expenses.value.filter((e) => e.id !== expense.id);
    const timer = window.setTimeout(() => {
      if (pendingDelete.value?.expense.id === expense.id) flushDelete();
    }, 5000);
    pendingDelete.value = { expense, timer };
  });

  const undoDelete = $(() => {
    const pending = pendingDelete.value;
    if (!pending) return;
    clearTimeout(pending.timer);
    pendingDelete.value = null;
    expenses.value = sortExpenses([...expenses.value, pending.expense]);
  });

  const isCurrentMonth = month.value === today().slice(0, 7);
  const count = expenses.value.length;

  return (
    <>
      <Navbar user={user.value} search={search} />

      <main>
        <div class="month-bar">
          <div class="switcher">
            <button
              type="button"
              aria-label="Previous month"
              onClick$={() => changeMonth(-1)}
            >
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                aria-hidden="true"
              >
                <path d="M15 6l-6 6 6 6" />
              </svg>
            </button>
            <h1 aria-live="polite">{formatMonth(month.value, "long")}</h1>
            <button
              type="button"
              aria-label="Next month"
              disabled={isCurrentMonth}
              onClick$={() => changeMonth(1)}
            >
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                aria-hidden="true"
              >
                <path d="M9 6l6 6-6 6" />
              </svg>
            </button>
          </div>
          {status.value === "ready" && (
            <span class="count">
              {count} {count === 1 ? "expense" : "expenses"}{" "}
              {isCurrentMonth
                ? "this month"
                : `in ${formatMonth(month.value, "short")}`}
            </span>
          )}
        </div>

        {status.value === "loading" && (
          <div class="card status" role="status">
            <p>Loading expenses…</p>
          </div>
        )}

        {status.value === "error" && (
          <div class="card status" role="alert">
            <p>Couldn’t load expenses. Try again.</p>
            <button type="button" class="btn-secondary" onClick$={loadMonth}>
              Try again
            </button>
          </div>
        )}

        {status.value === "ready" && summary.value && (
          <>
            <SummaryCards
              month={month.value}
              expenses={expenses.value}
              summary={summary.value}
              onEditBudget$={() => (editingBudget.value = true)}
            />

            {notice.value && (
              <p class="field-error" role="alert">
                {notice.value}
              </p>
            )}

            <div class="content">
              {expenses.value.length > 0 ? (
                <ExpenseList
                  expenses={expenses.value}
                  search={search.value}
                  onEdit$={(expense) => (editing.value = expense)}
                  onDelete$={(expense) => (confirming.value = expense)}
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
          onDelete$={(expense) => {
            // Close the edit modal first, then ask "Delete this expense?"
            editing.value = null;
            confirming.value = expense;
          }}
        />
      )}

      {confirming.value && (
        <ConfirmDialog
          title="Delete this expense?"
          message={`“${confirming.value.title}” (${formatMoney(confirming.value.amount)}) will be deleted.`}
          confirmLabel="Delete"
          onCancel$={() => (confirming.value = null)}
          onConfirm$={async () => {
            const expense = confirming.value;
            confirming.value = null;
            if (expense) await deleteExpense(expense);
          }}
        />
      )}

      {pendingDelete.value && (
        <UndoToast
          title={pendingDelete.value.expense.title}
          onUndo$={undoDelete}
        />
      )}

      {editingBudget.value && summary.value && (
        <BudgetDialog
          budget={summary.value.budget}
          onClose$={() => (editingBudget.value = false)}
          onSaved$={saveBudget}
        />
      )}
    </>
  );
});

export const head: DocumentHead = {
  title: "Expenses · Kharcha",
};
