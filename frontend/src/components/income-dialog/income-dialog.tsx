import {
  $,
  component$,
  useContext,
  useSignal,
  useStore,
  useStylesScoped$,
  useVisibleTask$,
  type QRL,
} from "@builder.io/qwik";
import { FieldError } from "~/components/field/field";
import { api } from "~/lib/api";
import { formatDate, formatMoney, today } from "~/lib/format";
import type { Income, IncomeType, TaxSummary } from "~/lib/types";
import { UserContext } from "~/lib/user-context";

type IncomeDialogProps = {
  // TDS rates and labels from GET /tax/summary
  types: TaxSummary["types"];
  onClose$: QRL<() => void>;
  onSaved$: QRL<(income: Income) => void>;
};

// "15%", "1.5%", "6% final" or "slab" (salary)
export function rateText(type: TaxSummary["types"][IncomeType]): string {
  if (type.rate === null) return "slab";
  const pct = `${Math.round(type.rate * 1000) / 10}%`;
  return type.final ? `${pct} final` : pct;
}

// Add income: the TDS is filled in as gross x rate and can be changed.
// Salary TDS is always typed in.
export const IncomeDialog = component$<IncomeDialogProps>((props) => {
  useStylesScoped$(`
    .modal {
      max-width: 520px;
    }
    .header {
      padding: 20px 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      border-bottom: 1px solid var(--line);
    }
    h2 {
      margin: 0;
      font-size: 22px;
      font-weight: 700;
    }
    form {
      padding: 20px 24px 24px;
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .field {
      display: flex;
      flex-direction: column;
      gap: 6px;
    }
    .row {
      display: flex;
      gap: 12px;
    }
    .row .field {
      flex: 1;
      min-width: 0;
    }
    .number {
      font-variant-numeric: tabular-nums;
    }
    fieldset {
      margin: 0;
      padding: 0;
      border: 0;
    }
    legend {
      padding: 0;
      margin-bottom: 6px;
    }
    .types {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 6px;
    }
    .types button {
      min-height: 44px;
      padding: 0 12px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 8px;
      border: 1px solid var(--input-border);
      border-radius: 10px;
      background: var(--white);
      color: var(--ink);
      font-size: 14px;
      text-align: left;
      cursor: pointer;
    }
    .types button:hover {
      background: var(--surface);
    }
    .types button[aria-pressed="true"] {
      border: 1.5px solid var(--red);
      background: var(--red-tint);
      color: var(--red-dark);
      font-weight: 600;
    }
    .rate {
      flex: none;
      font-size: 12px;
      color: var(--muted);
    }
    .result {
      padding: 12px 14px;
      display: flex;
      flex-direction: column;
      gap: 6px;
      border-radius: 10px;
      background: var(--surface);
      font-size: 14px;
    }
    .result span {
      display: flex;
      justify-content: space-between;
    }
    .final {
      margin: 0;
      font-size: 13px;
      color: var(--muted);
    }
    .hint {
      font-size: 13px;
      color: var(--muted);
    }
    .optional {
      font-weight: 400;
      color: var(--muted);
    }
    @media (max-width: 480px) {
      .types {
        grid-template-columns: minmax(0, 1fr);
      }
    }
  `);

  const user = useContext(UserContext);
  const calendar = user.value?.calendar ?? "bs";
  const values = useStore({
    title: "",
    amount: "",
    type: "salary" as IncomeType,
    tds_amount: "",
    date: today(),
    note: "",
  });
  // Once the TDS is typed in, stop filling it from the rate.
  const tdsTyped = useSignal(false);
  const errors = useSignal<Record<string, string>>({});
  const message = useSignal("");
  const saving = useSignal(false);

  const fillTds = $(() => {
    const rate = props.types[values.type].rate;
    if (tdsTyped.value || rate === null) return;
    const amount = Number(values.amount);
    values.tds_amount = values.amount
      ? String(Math.round(amount * rate * 100) / 100)
      : "";
  });

  // eslint-disable-next-line qwik/no-use-visible-task
  useVisibleTask$(({ cleanup }) => {
    const opener = document.activeElement as HTMLElement | null;
    document.getElementById("income-amount")?.focus();
    cleanup(() => opener?.focus());
  });

  const save = $(async () => {
    saving.value = true;
    errors.value = {};
    message.value = "";
    const res = await api.post<Income>("/incomes", {
      ...values,
      tds_amount: values.tds_amount === "" ? 0 : values.tds_amount,
    });
    saving.value = false;
    if (!res.ok) {
      errors.value = res.error.errors;
      if (Object.keys(res.error.errors).length === 0) {
        message.value = res.error.message;
      }
      return;
    }
    await props.onSaved$(res.data);
  });

  const selected = props.types[values.type];
  const gross = Number(values.amount) || 0;
  const tds = Number(values.tds_amount) || 0;

  const errorProps = (field: string) =>
    errors.value[field]
      ? {
          "aria-invalid": "true" as const,
          "aria-describedby": `income-${field}-error`,
        }
      : {};

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
        aria-labelledby="income-heading"
      >
        <div class="header">
          <h2 id="income-heading">Add income</h2>
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
              stroke-width="2"
              stroke-linecap="round"
              aria-hidden="true"
            >
              <path d="M6 6l12 12M18 6L6 18" />
            </svg>
          </button>
        </div>

        <form preventdefault:submit onSubmit$={save} noValidate>
          <div class="row">
            <div class="field">
              <label class="label" for="income-amount">
                Amount before TDS (Rs.)
              </label>
              <input
                id="income-amount"
                class="input number"
                type="number"
                inputMode="decimal"
                min="0"
                step="any"
                placeholder="0"
                value={values.amount}
                onInput$={async (_, el) => {
                  values.amount = el.value;
                  await fillTds();
                }}
                {...errorProps("amount")}
              />
              <FieldError
                id="income-amount-error"
                message={errors.value.amount}
              />
            </div>
            <div class="field">
              <label class="label" for="income-date">
                Date
              </label>
              <input
                id="income-date"
                class="input"
                type="date"
                value={values.date}
                onInput$={(_, el) => (values.date = el.value)}
                {...errorProps("date")}
              />
              {calendar === "bs" && values.date && (
                <span class="hint">{formatDate(values.date, "bs")}</span>
              )}
              <FieldError id="income-date-error" message={errors.value.date} />
            </div>
          </div>

          <div class="field">
            <label class="label" for="income-title">
              From
            </label>
            <input
              id="income-title"
              class="input"
              type="text"
              placeholder="e.g. Logo design for a cafe"
              value={values.title}
              onInput$={(_, el) => (values.title = el.value)}
              {...errorProps("title")}
            />
            <FieldError id="income-title-error" message={errors.value.title} />
          </div>

          <fieldset {...errorProps("type")}>
            <legend class="label">Type of income</legend>
            <div class="types">
              {(Object.keys(props.types) as IncomeType[]).map((key) => (
                <button
                  key={key}
                  type="button"
                  aria-pressed={values.type === key}
                  onClick$={async () => {
                    values.type = key;
                    tdsTyped.value = false;
                    if (props.types[key].rate === null) values.tds_amount = "";
                    await fillTds();
                  }}
                >
                  <span>{props.types[key].label}</span>
                  <span class="rate">{rateText(props.types[key])}</span>
                </button>
              ))}
            </div>
            <FieldError id="income-type-error" message={errors.value.type} />
          </fieldset>

          <div class="field">
            <label class="label" for="income-tds">
              TDS cut (Rs.){" "}
              <span class="optional">
                {selected.rate === null
                  ? "from your payslip"
                  : `${rateText(selected)}, change it if needed`}
              </span>
            </label>
            <input
              id="income-tds"
              class="input number"
              type="number"
              inputMode="decimal"
              min="0"
              step="any"
              placeholder="0"
              value={values.tds_amount}
              onInput$={(_, el) => {
                values.tds_amount = el.value;
                tdsTyped.value = true;
              }}
              {...errorProps("tds_amount")}
            />
            <FieldError
              id="income-tds_amount-error"
              message={errors.value.tds_amount}
            />
          </div>

          <div class="result number">
            <span>
              <span>TDS cut ({rateText(selected)})</span>
              <span>{formatMoney(tds)}</span>
            </span>
            <span>
              <strong>You received</strong>
              <strong>{formatMoney(Math.max(0, gross - tds))}</strong>
            </span>
          </div>
          {selected.final && (
            <p class="final">
              Final withholding: this income won't be added to your yearly tax
              estimate.
            </p>
          )}

          <div class="field">
            <label class="label" for="income-note">
              Note <span class="optional">(optional)</span>
            </label>
            <input
              id="income-note"
              class="input"
              type="text"
              maxLength={255}
              value={values.note}
              onInput$={(_, el) => (values.note = el.value)}
              {...errorProps("note")}
            />
            <FieldError id="income-note-error" message={errors.value.note} />
          </div>

          <FieldError id="income-error" message={message.value} />
          <button type="submit" class="btn-primary" disabled={saving.value}>
            {saving.value
              ? "Saving…"
              : `Save income · ${formatDate(values.date || today(), calendar)}`}
          </button>
        </form>
      </div>
    </div>
  );
});
