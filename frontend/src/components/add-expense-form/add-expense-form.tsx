import {
  $,
  component$,
  useSignal,
  useStore,
  useStylesScoped$,
  type QRL,
} from "@builder.io/qwik";
import { ExpenseFields } from "~/components/expense-fields/expense-fields";
import { FieldError } from "~/components/field/field";
import { api } from "~/lib/api";
import { today } from "~/lib/format";
import { QUICK_ADD_PRESETS } from "~/lib/presets";
import type { Expense, ExpenseInput } from "~/lib/types";

type AddExpenseFormProps = {
  // repeats: a monthly repeat was started, which may have added more expenses
  onAdded$: QRL<(expense: Expense, repeats: boolean) => void>;
};

export const AddExpenseForm = component$<AddExpenseFormProps>((props) => {
  useStylesScoped$(`
    form {
      flex: 1 1 300px;
      padding: 20px;
      display: flex;
      flex-direction: column;
      gap: 14px;
      border-radius: 12px;
    }
    h2 {
      margin: 0;
      font-size: 18px;
      font-weight: 700;
    }
    .presets {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
    }
    .presets button {
      height: 34px;
      padding: 0 12px;
      border: 1px solid var(--input-border);
      border-radius: 17px;
      background: var(--white);
      color: var(--ink);
      font-size: 13px;
      cursor: pointer;
    }
    .presets button:hover {
      background: var(--surface);
    }
    .presets .amount {
      color: var(--muted);
      font-variant-numeric: tabular-nums;
    }
  `);

  const values = useStore<ExpenseInput>({
    title: "",
    amount: "",
    category: "Food",
    payment_method: null,
    date: today(),
    note: "",
    repeat: false,
  });
  const errors = useSignal<Record<string, string>>({});
  const message = useSignal("");
  const saving = useSignal(false);

  const submit = $(async () => {
    saving.value = true;
    errors.value = {};
    message.value = "";

    const { repeat, ...expense } = values;
    const res = await api.post<Expense>("/expenses", expense);

    if (!res.ok) {
      saving.value = false;
      errors.value = res.error.errors;
      if (Object.keys(res.error.errors).length === 0) {
        message.value = res.error.message;
      }
      return;
    }

    if (repeat) {
      const rule = await api.post("/recurring-expenses", {
        expense_id: res.data.id,
      });
      if (!rule.ok) {
        message.value = `Saved, but it won't repeat: ${rule.error.message}`;
      }
    }
    saving.value = false;

    await props.onAdded$(res.data, repeat);
    // Keep category, payment method and date: the next expense is often similar.
    values.title = "";
    values.amount = "";
    values.note = "";
    values.repeat = false;
  });

  return (
    <form
      class="card"
      aria-labelledby="add-expense-heading"
      preventdefault:submit
      onSubmit$={submit}
      noValidate
    >
      <h2 id="add-expense-heading">Add expense</h2>
      <div class="presets" role="group" aria-label="Quick add">
        {QUICK_ADD_PRESETS.map((preset) => (
          <button
            key={preset.title}
            type="button"
            onClick$={() => {
              values.title = preset.title;
              values.amount = String(preset.amount);
              values.category = preset.category;
            }}
          >
            {preset.title} <span class="amount">{preset.amount}</span>
          </button>
        ))}
      </div>
      <ExpenseFields
        idPrefix="add"
        values={values}
        errors={errors.value}
        compact
      />
      <FieldError id="add-error" message={message.value} />
      <button type="submit" class="btn-primary" disabled={saving.value}>
        {saving.value ? "Adding…" : "Add expense"}
      </button>
    </form>
  );
});
