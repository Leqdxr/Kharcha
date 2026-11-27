import {
  component$,
  useContext,
  useSignal,
  useStylesScoped$,
  type QRL,
} from "@builder.io/qwik";
import { CategoryIcon } from "~/components/category-icon/category-icon";
import {
  FilterChips,
  type Filter,
} from "~/components/filter-chips/filter-chips";
import { dayLabel, formatMoney } from "~/lib/format";
import { PAYMENT_LABELS, type Expense } from "~/lib/types";
import { UserContext } from "~/lib/user-context";

// "Food · eSewa · Repeats monthly · note"
function subLine(expense: Expense): string {
  return [
    expense.category,
    expense.payment_method && PAYMENT_LABELS[expense.payment_method],
    expense.recurring_expense_id !== null && "Repeats monthly",
    expense.note,
  ]
    .filter(Boolean)
    .join(" · ");
}

type ExpenseListProps = {
  // The month's expenses, newest first
  expenses: Expense[];
  onEdit$: QRL<(expense: Expense) => void>;
  onDelete$: QRL<(expense: Expense) => void>;
};

export const ExpenseList = component$<ExpenseListProps>((props) => {
  useStylesScoped$(`
    section {
      flex: 999 1 560px;
      min-width: 0;
      border-radius: 12px;
      overflow: hidden;
    }
    .tools {
      padding: 16px 20px;
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      border-bottom: 1px solid var(--line);
    }
    .search {
      position: relative;
      flex: 0 1 260px;
    }
    .search svg {
      position: absolute;
      left: 12px;
      top: 11px;
    }
    .search input {
      width: 100%;
      height: 40px;
      padding: 0 14px 0 38px;
      border: 1px solid var(--input-border);
      border-radius: 20px;
      background: var(--row-hover);
      color: var(--ink);
      font-size: 14px;
    }
    .search input:focus {
      outline: 2px solid var(--red);
      outline-offset: 1px;
    }
    .day {
      display: flex;
      justify-content: space-between;
      gap: 12px;
      padding: 10px 20px;
      background: var(--row-hover);
      border-bottom: 1px solid #efece8;
      font-size: 13px;
      font-weight: 600;
      color: var(--muted);
    }
    .number {
      font-variant-numeric: tabular-nums;
    }
    ul {
      margin: 0;
      padding: 0;
      list-style: none;
    }
    li {
      display: flex;
      align-items: center;
      gap: 14px;
      padding: 10px 12px 10px 20px;
      border-bottom: 1px solid #efece8;
    }
    li:hover {
      background: var(--row-hover);
    }
    .icon {
      width: 40px;
      height: 40px;
      flex: none;
      border-radius: 10px;
      background: var(--surface);
      color: #3d3835;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .text {
      flex: 1;
      min-width: 0;
      display: flex;
      flex-direction: column;
      gap: 2px;
    }
    .title {
      font-size: 15px;
      font-weight: 600;
      overflow-wrap: anywhere;
    }
    .sub {
      font-size: 13px;
      color: var(--muted);
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .amount {
      font-variant-numeric: tabular-nums;
      font-size: 15px;
      font-weight: 600;
      white-space: nowrap;
    }
    .actions {
      display: flex;
      flex: none;
    }
    .delete {
      color: var(--red);
    }
    .no-match {
      margin: 0;
      padding: 48px 20px;
      text-align: center;
      color: var(--muted);
      font-size: 15px;
    }
    @media (max-width: 480px) {
      li {
        gap: 10px;
        padding: 10px 4px 10px 12px;
      }
      .search {
        flex-basis: 100%;
      }
      .tools,
      .day {
        padding-left: 12px;
        padding-right: 12px;
      }
    }
  `);

  const filter = useSignal<Filter>("All");
  const search = useSignal("");
  const user = useContext(UserContext);
  const calendar = user.value?.calendar ?? "bs";

  const query = search.value.trim().toLowerCase();
  const shown = props.expenses.filter(
    (e) =>
      (filter.value === "All" || e.category === filter.value) &&
      (!query ||
        e.title.toLowerCase().includes(query) ||
        (e.note ?? "").toLowerCase().includes(query)),
  );

  // Consecutive expenses with the same date form one day group.
  const days: { date: string; items: Expense[] }[] = [];
  for (const expense of shown) {
    const last = days[days.length - 1];
    if (last?.date === expense.date) last.items.push(expense);
    else days.push({ date: expense.date, items: [expense] });
  }

  return (
    <section class="card" aria-label="Expense list">
      <div class="tools">
        <FilterChips active={filter} />
        <div class="search" role="search">
          <label for="search" class="visually-hidden">
            Search expenses
          </label>
          <svg
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="var(--muted)"
            stroke-width="2"
            stroke-linecap="round"
            aria-hidden="true"
          >
            <circle cx="11" cy="11" r="7" />
            <path d="M20 20l-3.5-3.5" />
          </svg>
          <input
            id="search"
            type="search"
            placeholder="Search by title or note"
            bind:value={search}
          />
        </div>
      </div>

      {shown.length === 0 && (
        <p class="no-match">
          {query
            ? "No expenses match your search."
            : `No ${filter.value} expenses this month.`}
        </p>
      )}

      {days.map((day) => (
        <div key={day.date}>
          <div class="day">
            <span>{dayLabel(day.date, calendar)}</span>
            <span class="number">
              {formatMoney(day.items.reduce((sum, e) => sum + e.amount, 0))}
            </span>
          </div>
          <ul>
            {day.items.map((expense) => (
              <li key={expense.id}>
                <span class="icon">
                  <CategoryIcon category={expense.category} />
                </span>
                <div class="text">
                  <span class="title">{expense.title}</span>
                  <span class="sub">{subLine(expense)}</span>
                </div>
                <span class="amount">{formatMoney(expense.amount)}</span>
                <div class="actions">
                  <button
                    type="button"
                    class="icon-btn"
                    aria-label={`Edit ${expense.title}`}
                    onClick$={() => props.onEdit$(expense)}
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
                      <path d="M4 20h4L19 9l-4-4L4 16v4z" />
                      <path d="M13.5 6.5l4 4" />
                    </svg>
                  </button>
                  <button
                    type="button"
                    class="icon-btn delete"
                    aria-label={`Delete ${expense.title}`}
                    onClick$={() => props.onDelete$(expense)}
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
                </div>
              </li>
            ))}
          </ul>
        </div>
      ))}
    </section>
  );
});
