import {
  $,
  component$,
  useSignal,
  useStore,
  useStylesScoped$,
  useVisibleTask$,
  type QRL,
} from "@builder.io/qwik";
import { ExpenseFields } from "~/components/expense-fields/expense-fields";
import { FieldError } from "~/components/field/field";
import { api } from "~/lib/api";
import type { Expense, ExpenseInput } from "~/lib/types";

type EditExpenseModalProps = {
  expense: Expense;
  onClose$: QRL<() => void>;
  // repeatChanged: a monthly repeat was started or stopped
  onSaved$: QRL<(expense: Expense, repeatChanged: boolean) => void>;
  onDelete$: QRL<(expense: Expense) => void>;
};

export const EditExpenseModal = component$<EditExpenseModalProps>((props) => {
  useStylesScoped$(`
    .header {
      padding: 22px 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      border-bottom: 1px solid var(--line);
    }
    .header-text {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }
    .eyebrow {
      font-variant-numeric: tabular-nums;
      font-size: 12px;
      font-weight: 600;
      letter-spacing: 0.06em;
      color: var(--red);
    }
    h2 {
      margin: 0;
      font-size: 22px;
      font-weight: 700;
      letter-spacing: -0.01em;
    }
    form {
      padding: 24px;
      display: flex;
      flex-direction: column;
      gap: 18px;
    }
    .footer {
      padding-top: 8px;
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
    }
    .delete-btn {
      height: 44px;
      padding: 0 12px;
      display: inline-flex;
      align-items: center;
      gap: 8px;
      border: 0;
      border-radius: 6px;
      background: transparent;
      color: var(--red);
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
    }
    .delete-btn:hover {
      background: var(--surface);
    }
    .footer-right {
      display: flex;
      gap: 10px;
    }
    .footer-right button {
      font-size: 15px;
    }
  `);

  const values = useStore<ExpenseInput>({
    title: props.expense.title,
    amount: String(props.expense.amount),
    category: props.expense.category,
    payment_method: props.expense.payment_method,
    date: props.expense.date,
    note: props.expense.note ?? "",
    repeat: props.expense.recurring_expense_id !== null,
  });
  const errors = useSignal<Record<string, string>>({});
  const message = useSignal("");
  const saving = useSignal(false);

  // On open: focus the first input. On close: give focus back to whatever opened the modal.
  // eslint-disable-next-line qwik/no-use-visible-task
  useVisibleTask$(({ cleanup }) => {
    const opener = document.activeElement as HTMLElement | null;
    document.getElementById("edit-title")?.focus();
    cleanup(() => opener?.focus());
  });

  const save = $(async () => {
    saving.value = true;
    errors.value = {};
    message.value = "";

    const { repeat, ...expense } = values;
    const res = await api.put<Expense>(
      `/expenses/${props.expense.id}`,
      expense,
    );

    if (!res.ok) {
      saving.value = false;
      errors.value = res.error.errors;
      if (Object.keys(res.error.errors).length === 0) {
        message.value = res.error.message;
      }
      return;
    }

    // Start or stop repeating.
    const ruleId = props.expense.recurring_expense_id;
    const repeatChanged = repeat !== (ruleId !== null);
    if (repeatChanged) {
      const rule = repeat
        ? await api.post("/recurring-expenses", { expense_id: res.data.id })
        : await api.del(`/recurring-expenses/${ruleId}`);
      if (!rule.ok) {
        saving.value = false;
        message.value = `Saved, but the repeat didn't change: ${rule.error.message}`;
        return;
      }
    }
    saving.value = false;

    await props.onSaved$(res.data, repeatChanged);
  });

  return (
    <div
      class="modal-backdrop"
      document:onKeyDown$={(event) => {
        if (event.key === "Escape") props.onClose$();
      }}
    >
      <div
        class="modal"
        role="dialog"
        aria-modal="true"
        aria-labelledby="edit-heading"
      >
        <div class="header">
          <div class="header-text">
            <span class="eyebrow">EXPENSE #{props.expense.id}</span>
            <h2 id="edit-heading">Edit expense</h2>
          </div>
          <button
            type="button"
            class="icon-btn"
            aria-label="Close"
            onClick$={props.onClose$}
          >
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1.8"
              stroke-linecap="round"
              aria-hidden="true"
            >
              <path d="M6 6l12 12M18 6L6 18" />
            </svg>
          </button>
        </div>

        <form preventdefault:submit onSubmit$={save} noValidate>
          <ExpenseFields
            idPrefix="edit"
            values={values}
            errors={errors.value}
          />
          <FieldError id="edit-error" message={message.value} />

          <div class="footer">
            <button
              type="button"
              class="delete-btn"
              onClick$={() => props.onDelete$(props.expense)}
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
              Delete
            </button>
            <div class="footer-right">
              <button
                type="button"
                class="btn-secondary"
                onClick$={props.onClose$}
              >
                Cancel
              </button>
              <button type="submit" class="btn-primary" disabled={saving.value}>
                {saving.value ? "Saving…" : "Save changes"}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
});
