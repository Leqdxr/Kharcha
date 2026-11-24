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
import type { Expense, ExpenseInput } from "~/lib/types";

type AddExpenseFormProps = {
  onAdded$: QRL<(expense: Expense) => void>;
};

export const AddExpenseForm = component$<AddExpenseFormProps>((props) => {
  useStylesScoped$(`
    form {
      flex: 1 1 300px;
      padding: 20px;
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    h2 {
      margin: 0;
      font-size: 18px;
      font-weight: 700;
    }
  `);

  const values = useStore<ExpenseInput>({
    title: "",
    amount: "",
    category: "Food",
    date: today(),
  });
  const errors = useSignal<Record<string, string>>({});
  const message = useSignal("");
  const saving = useSignal(false);

  const submit = $(async () => {
    saving.value = true;
    errors.value = {};
    message.value = "";

    const res = await api.post<Expense>("/expenses", { ...values });
    saving.value = false;

    if (!res.ok) {
      errors.value = res.error.errors;
      if (Object.keys(res.error.errors).length === 0) {
        message.value = res.error.message;
      }
      return;
    }

    await props.onAdded$(res.data);
    // Keep category and date: the next expense is often similar.
    values.title = "";
    values.amount = "";
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
