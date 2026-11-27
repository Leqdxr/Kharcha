import { component$, useStylesScoped$, type QRL } from "@builder.io/qwik";
import { formatMoney, formatMonth } from "~/lib/format";
import type { Category, Expense, Summary } from "~/lib/types";

type SummaryCardsProps = {
  month: string; // YYYY-MM
  // The selected month's expenses (without one waiting to be deleted)
  expenses: Expense[];
  // Gives the previous month's total, the budget and the days left
  summary: Summary;
  onEditBudget$: QRL<() => void>;
};

const ARROW_DOWN = "M12 5v14M6 13l6 6 6-6";
const ARROW_UP = "M12 19V5M6 11l6-6 6 6";
const DASH = "M5 12h14";

export const SummaryCards = component$<SummaryCardsProps>((props) => {
  useStylesScoped$(`
    section {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
      gap: 16px;
    }
    .card {
      border-radius: 12px;
      padding: 24px;
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    .total {
      gap: 8px;
      border-color: var(--red);
      background: var(--red);
      color: var(--white);
    }
    .label {
      font-size: 14px;
      font-weight: 500;
      color: var(--muted);
    }
    .total .label {
      color: var(--red-tint);
    }
    .big {
      font-variant-numeric: tabular-nums;
      font-size: 36px;
      font-weight: 600;
      letter-spacing: -0.02em;
    }
    .compare {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 14px;
    }
    .head {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 8px;
    }
    .edit {
      height: 32px;
      padding: 0 10px;
      border: 0;
      border-radius: 6px;
      background: transparent;
      color: var(--red);
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
    }
    .edit:hover {
      background: var(--surface);
    }
    .spent {
      font-variant-numeric: tabular-nums;
      font-size: 22px;
      font-weight: 600;
    }
    .of {
      font-size: 15px;
      font-weight: 500;
      color: var(--muted);
    }
    .track {
      height: 10px;
      border-radius: 5px;
      background: var(--surface);
      overflow: hidden;
    }
    .fill {
      height: 100%;
      border-radius: 5px;
      background: var(--red);
    }
    .fill.over {
      background: #7a1810;
    }
    .note {
      font-size: 14px;
      color: var(--muted);
    }
    .safe {
      padding-top: 10px;
      border-top: 1px solid var(--line);
      font-size: 14px;
      color: var(--muted);
    }
    .safe-amount {
      font-variant-numeric: tabular-nums;
      color: var(--ink);
    }
    .set-budget {
      align-self: flex-start;
      height: 44px;
      font-size: 15px;
    }
    .cat {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }
    .cat-row {
      display: flex;
      justify-content: space-between;
      gap: 8px;
      font-size: 14px;
    }
    .cat-name {
      font-weight: 600;
    }
    .cat-amount {
      font-variant-numeric: tabular-nums;
      color: #3d3835;
    }
    .cat .track {
      height: 6px;
      border-radius: 3px;
    }
    .cat .fill {
      border-radius: 3px;
    }
    @media (max-width: 480px) {
      .big {
        font-size: 30px;
      }
    }
  `);

  const { month, expenses, summary } = props;
  const total = expenses.reduce((sum, e) => sum + e.amount, 0);

  // Compared with last month
  let compareIcon = DASH;
  let compareText = "First month of data";
  if (summary.previous_total > 0) {
    const pct = Math.round(
      ((total - summary.previous_total) / summary.previous_total) * 100,
    );
    const previousName = formatMonth(summary.previous_month, "short");
    compareIcon = pct <= 0 ? ARROW_DOWN : ARROW_UP;
    compareText = `${Math.abs(pct)}% ${pct <= 0 ? "less" : "more"} than ${previousName}`;
  }

  // Budget
  const budget = summary.budget;
  const left = budget === null ? 0 : budget - total;
  let budgetPct = 0;
  if (budget) budgetPct = Math.min(100, Math.round((total / budget) * 100));
  else if (budget === 0 && total > 0) budgetPct = 100;
  let budgetNote = "";
  if (budget !== null) {
    budgetNote =
      left >= 0
        ? `${formatMoney(left)} left`
        : `Over budget by ${formatMoney(-left)}`;
  }

  // Safe to spend today: what's left, spread over the days left (current month only).
  const daysLeft = summary.days_left;
  const safeToSpend =
    budget !== null && left >= 0 && daysLeft
      ? Math.round(left / daysLeft)
      : null;

  // Where it went, high to low
  const byCategory = new Map<Category, number>();
  for (const e of expenses) {
    byCategory.set(e.category, (byCategory.get(e.category) ?? 0) + e.amount);
  }
  const breakdown = [...byCategory].sort((a, b) => b[1] - a[1]);

  return (
    <section aria-label="Summary">
      <div class="card total">
        <span class="label">Spent in {formatMonth(month, "short")}</span>
        <span class="big">{formatMoney(total)}</span>
        <span class="compare">
          <svg
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            aria-hidden="true"
          >
            <path d={compareIcon} />
          </svg>
          {compareText}
        </span>
      </div>

      <div class="card">
        <div class="head">
          <span class="label">Monthly budget</span>
          {budget !== null && (
            <button
              type="button"
              class="edit"
              aria-label="Edit monthly budget"
              onClick$={props.onEditBudget$}
            >
              Edit
            </button>
          )}
        </div>
        {budget === null ? (
          <>
            <span class="note">Set a monthly budget</span>
            <button
              type="button"
              class="btn-secondary set-budget"
              onClick$={props.onEditBudget$}
            >
              Set budget
            </button>
          </>
        ) : (
          <>
            <span class="spent">
              {formatMoney(total)}{" "}
              <span class="of">of {formatMoney(budget)}</span>
            </span>
            <div
              class="track"
              role="progressbar"
              aria-label="Budget used"
              aria-valuemin={0}
              aria-valuemax={100}
              aria-valuenow={budgetPct}
            >
              <div
                class={["fill", { over: left < 0 }]}
                style={{ width: `${budgetPct}%` }}
              />
            </div>
            <span class="note">{budgetNote}</span>
            {safeToSpend !== null && daysLeft && (
              <span class="safe">
                Safe to spend today{" "}
                <strong class="safe-amount">{formatMoney(safeToSpend)}</strong>
                {" · "}
                {daysLeft} {daysLeft === 1 ? "day" : "days"} left this month
              </span>
            )}
          </>
        )}
      </div>

      <div class="card">
        <span class="label">Where it went</span>
        {breakdown.length === 0 && <span class="note">Nothing spent yet.</span>}
        {breakdown.map(([category, amount]) => {
          const pct = total ? Math.round((amount / total) * 100) : 0;
          return (
            <div key={category} class="cat">
              <div class="cat-row">
                <span class="cat-name">{category}</span>
                <span class="cat-amount">
                  {formatMoney(amount)} · {pct}%
                </span>
              </div>
              <div class="track">
                <div class="fill" style={{ width: `${pct}%` }} />
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
});
