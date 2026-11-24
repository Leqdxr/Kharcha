import {
  $,
  component$,
  useSignal,
  useStylesScoped$,
  useVisibleTask$,
  type QRL,
} from "@builder.io/qwik";
import { ConfirmDialog } from "~/components/confirm-dialog/confirm-dialog";
import { FieldError } from "~/components/field/field";
import { api } from "~/lib/api";
import type { User } from "~/lib/types";

type BudgetDialogProps = {
  budget: number | null;
  onClose$: QRL<() => void>;
  onSaved$: QRL<(user: User) => void>;
};

// Small dialog to set or clear the monthly budget (PUT /budget).
export const BudgetDialog = component$<BudgetDialogProps>((props) => {
  useStylesScoped$(`
    .modal {
      max-width: 400px;
    }
    form {
      padding: 24px;
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    h2 {
      margin: 0;
      font-size: 20px;
      font-weight: 700;
    }
    .field {
      display: flex;
      flex-direction: column;
      gap: 6px;
    }
    .input {
      font-variant-numeric: tabular-nums;
    }
    .actions {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
    }
    .actions-right {
      display: flex;
      gap: 10px;
      margin-left: auto;
    }
    .clear {
      height: 44px;
      padding: 0 12px;
      border: 0;
      border-radius: 6px;
      background: transparent;
      color: var(--red);
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
    }
    .clear:hover {
      background: var(--surface);
    }
    button {
      font-size: 15px;
    }
  `);

  const amount = useSignal(props.budget === null ? "" : String(props.budget));
  const error = useSignal("");
  const saving = useSignal(false);
  const confirmingRemove = useSignal(false);

  // eslint-disable-next-line qwik/no-use-visible-task
  useVisibleTask$(({ cleanup }) => {
    const opener = document.activeElement as HTMLElement | null;
    document.getElementById("budget-amount")?.focus();
    cleanup(() => opener?.focus());
  });

  const save = $(async (budget: number | null) => {
    saving.value = true;
    error.value = "";
    const res = await api.put<User>("/budget", { monthly_budget: budget });
    saving.value = false;
    if (!res.ok) {
      error.value = res.error.errors.monthly_budget ?? res.error.message;
      return;
    }
    await props.onSaved$(res.data);
  });

  if (confirmingRemove.value) {
    return (
      <ConfirmDialog
        title="Remove your monthly budget?"
        message="The budget bar will be hidden until you set a new one."
        confirmLabel="Remove"
        onCancel$={() => (confirmingRemove.value = false)}
        onConfirm$={async () => {
          confirmingRemove.value = false;
          await save(null);
        }}
      />
    );
  }

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
        aria-labelledby="budget-heading"
      >
        <form
          preventdefault:submit
          onSubmit$={() =>
            save(amount.value.trim() === "" ? null : Number(amount.value))
          }
          noValidate
        >
          <h2 id="budget-heading">Monthly budget</h2>
          <div class="field">
            <label class="label" for="budget-amount">
              Amount (Rs.)
            </label>
            <input
              id="budget-amount"
              class="input"
              type="number"
              inputMode="numeric"
              min="0"
              step="1"
              placeholder="e.g. 20000"
              value={amount.value}
              // Not bind:value: on a number input it stores a number, not text.
              onInput$={(_, el) => (amount.value = el.value)}
              aria-invalid={error.value ? "true" : undefined}
              aria-describedby={error.value ? "budget-error" : undefined}
            />
            <FieldError id="budget-error" message={error.value} />
          </div>
          <div class="actions">
            {props.budget !== null && (
              <button
                type="button"
                class="clear"
                disabled={saving.value}
                onClick$={() => (confirmingRemove.value = true)}
              >
                Remove budget
              </button>
            )}
            <div class="actions-right">
              <button
                type="button"
                class="btn-secondary"
                onClick$={props.onClose$}
              >
                Cancel
              </button>
              <button type="submit" class="btn-primary" disabled={saving.value}>
                {saving.value ? "Saving…" : "Save"}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
});
