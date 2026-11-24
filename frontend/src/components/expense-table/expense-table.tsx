import {
  $,
  component$,
  useSignal,
  useStylesScoped$,
  useVisibleTask$,
  type QRL,
} from "@builder.io/qwik";
import {
  FilterChips,
  type Filter,
} from "~/components/filter-chips/filter-chips";
import { formatDate, formatMoney } from "~/lib/format";
import type { Expense } from "~/lib/types";

type ConfirmDeleteProps = {
  busy: boolean;
  onConfirm$: QRL<() => void>;
  onCancel$: QRL<() => void>;
};

// Inline "Delete this expense?" shown in place of the row's action buttons.
const ConfirmDelete = component$<ConfirmDeleteProps>((props) => {
  useStylesScoped$(`
    div {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      font-size: 14px;
    }
    button {
      height: 36px;
      padding: 0 12px;
      font-size: 14px;
    }
  `);

  const cancelRef = useSignal<HTMLButtonElement>();

  // Move focus here, since the delete button that had it is gone.
  // eslint-disable-next-line qwik/no-use-visible-task
  useVisibleTask$(() => {
    cancelRef.value?.focus();
  });

  return (
    <div role="group" aria-label="Delete this expense?">
      <span>Delete this expense?</span>
      <button
        type="button"
        class="btn-primary"
        onClick$={props.onConfirm$}
        disabled={props.busy}
      >
        {props.busy ? "Deleting…" : "Delete"}
      </button>
      <button
        ref={cancelRef}
        type="button"
        class="btn-secondary"
        onClick$={props.onCancel$}
        disabled={props.busy}
      >
        Cancel
      </button>
    </div>
  );
});

type ExpenseTableProps = {
  expenses: Expense[];
  onDelete$: QRL<(id: number) => Promise<void>>;
};

export const ExpenseTable = component$<ExpenseTableProps>((props) => {
  useStylesScoped$(`
    section {
      flex: 999 1 560px;
      min-width: 0;
      overflow: hidden;
    }
    .top {
      padding: 18px 20px;
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      border-bottom: 1px solid var(--line);
    }
    h2 {
      margin: 0;
      font-size: 18px;
      font-weight: 700;
    }
    .scroll {
      overflow-x: auto;
    }
    table {
      width: 100%;
      min-width: 560px;
      border-collapse: collapse;
      font-size: 15px;
    }
    th {
      padding: 12px 8px;
      text-align: left;
      color: var(--muted);
      font-size: 13px;
      font-weight: 600;
    }
    td {
      padding: 10px 8px;
    }
    th:first-child,
    td:first-child {
      padding-left: 20px;
    }
    tbody tr {
      border-top: 1px solid #efece8;
    }
    tbody tr:hover {
      background: #fbfaf8;
    }
    .date {
      font-family: var(--font-mono);
      font-size: 14px;
      color: var(--muted);
      white-space: nowrap;
    }
    .title {
      font-weight: 500;
    }
    .pill {
      display: inline-block;
      padding: 3px 10px;
      border-radius: 12px;
      background: var(--surface);
      color: #3d3835;
      font-size: 13px;
      font-weight: 500;
    }
    .amount {
      text-align: right;
      font-family: var(--font-mono);
      font-weight: 600;
      white-space: nowrap;
    }
    .actions {
      padding: 6px 16px;
      text-align: right;
      white-space: nowrap;
    }
    .delete {
      color: var(--red);
    }
    .no-match {
      padding: 32px 20px;
      text-align: center;
      color: var(--muted);
    }
  `);

  const filter = useSignal<Filter>("All");
  const confirmingId = useSignal<number | null>(null);
  const deleting = useSignal(false);

  const rows =
    filter.value === "All"
      ? props.expenses
      : props.expenses.filter((e) => e.category === filter.value);

  const confirmDelete = $(async () => {
    if (confirmingId.value === null) return;
    deleting.value = true;
    await props.onDelete$(confirmingId.value);
    deleting.value = false;
    confirmingId.value = null;
  });

  return (
    <section class="card" aria-label="Expense list">
      <div class="top">
        <h2>All expenses</h2>
        <FilterChips active={filter} />
      </div>

      <div class="scroll">
        <table>
          <thead>
            <tr>
              <th scope="col">Date</th>
              <th scope="col">Title</th>
              <th scope="col">Category</th>
              <th scope="col" class="amount">
                Amount
              </th>
              <th scope="col">
                <span class="visually-hidden">Actions</span>
              </th>
            </tr>
          </thead>
          <tbody>
            {rows.map((expense) => (
              <tr key={expense.id}>
                <td class="date">{formatDate(expense.date)}</td>
                <td class="title">{expense.title}</td>
                <td>
                  <span class="pill">{expense.category}</span>
                </td>
                <td class="amount">{formatMoney(expense.amount)}</td>
                <td class="actions">
                  {confirmingId.value === expense.id ? (
                    <ConfirmDelete
                      busy={deleting.value}
                      onConfirm$={confirmDelete}
                      onCancel$={() => (confirmingId.value = null)}
                    />
                  ) : (
                    <button
                      type="button"
                      class="icon-btn delete"
                      aria-label={`Delete ${expense.title}`}
                      onClick$={() => (confirmingId.value = expense.id)}
                    >
                      <svg
                        width="18"
                        height="18"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="1.8"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        aria-hidden="true"
                      >
                        <path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3" />
                      </svg>
                    </button>
                  )}
                </td>
              </tr>
            ))}
            {rows.length === 0 && (
              <tr>
                <td colSpan={5} class="no-match">
                  No {filter.value} expenses yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
});
