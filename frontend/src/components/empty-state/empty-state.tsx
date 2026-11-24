import { component$, useStylesScoped$ } from "@builder.io/qwik";

// Shown instead of the table when the user has no expenses.
export const EmptyState = component$(() => {
  useStylesScoped$(`
    section {
      flex: 999 1 560px;
      min-width: 0;
      padding: 48px 24px;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 20px;
      text-align: center;
    }
    img {
      height: 170px;
      width: auto;
    }
    h2 {
      margin: 4px 0 0;
      font-size: 26px;
      font-weight: 700;
      letter-spacing: -0.01em;
    }
    p {
      margin: 0;
      max-width: 400px;
      font-size: 16px;
      line-height: 1.5;
      color: var(--muted);
    }
    button {
      padding: 0 22px;
    }
  `);

  return (
    <section class="card" aria-labelledby="empty-heading">
      <img src="/images/money.svg" alt="" width={159} height={170} />
      <h2 id="empty-heading">No expenses yet</h2>
      <p>Add your first one and your monthly total will show up here.</p>
      <button
        type="button"
        class="btn-primary"
        onClick$={() => document.getElementById("add-title")?.focus()}
      >
        Add your first expense
      </button>
    </section>
  );
});
