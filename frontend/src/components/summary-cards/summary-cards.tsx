import { component$, useStylesScoped$ } from "@builder.io/qwik";
import { formatMoney } from "~/lib/format";
import type { Expense } from "~/lib/types";

type SummaryCardsProps = {
  // Only this month's expenses
  expenses: Expense[];
};

export const SummaryCards = component$<SummaryCardsProps>((props) => {
  useStylesScoped$(`
    section {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 16px;
    }
    .card {
      padding: 24px;
      display: flex;
      flex-direction: column;
      gap: 10px;
    }
    .total {
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
    .number {
      font-family: var(--font-mono);
      font-size: 34px;
      font-weight: 600;
      letter-spacing: -0.02em;
    }
    .category {
      font-size: 26px;
      font-weight: 700;
      line-height: 1.3;
    }
    .category-amount {
      font-family: var(--font-mono);
      font-size: 18px;
      font-weight: 500;
      color: var(--muted);
    }
  `);

  const total = props.expenses.reduce((sum, e) => sum + e.amount, 0);

  const byCategory = new Map<string, number>();
  for (const e of props.expenses) {
    byCategory.set(e.category, (byCategory.get(e.category) ?? 0) + e.amount);
  }
  let biggest: [string, number] | null = null;
  for (const entry of byCategory) {
    if (!biggest || entry[1] > biggest[1]) biggest = entry;
  }

  return (
    <section aria-label="Summary">
      <div class="card total">
        <span class="label">Spent this month</span>
        <span class="number">{formatMoney(total)}</span>
      </div>
      <div class="card">
        <span class="label">Entries</span>
        <span class="number">{props.expenses.length}</span>
      </div>
      <div class="card">
        <span class="label">Biggest category</span>
        {biggest ? (
          <span class="category">
            {biggest[0]}{" "}
            <span class="category-amount">{formatMoney(biggest[1])}</span>
          </span>
        ) : (
          <span class="category">None yet</span>
        )}
      </div>
    </section>
  );
});
