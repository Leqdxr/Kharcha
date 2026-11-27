import { component$, useContext, useStylesScoped$ } from "@builder.io/qwik";
import { FieldError } from "~/components/field/field";
import { formatDate } from "~/lib/format";
import {
  CATEGORIES,
  PAYMENT_LABELS,
  type ExpenseInput,
  type PaymentMethod,
} from "~/lib/types";
import { UserContext } from "~/lib/user-context";

type ExpenseFieldsProps = {
  // Prefix for input ids, so the add form and the edit modal don't clash
  idPrefix: string;
  values: ExpenseInput;
  errors: Record<string, string>;
  // 44px inputs (dashboard form) instead of 48px
  compact?: boolean;
};

// Title, Amount + Date, Category, Paid with, Note and Repeat every month.
// Used by the add form and the edit modal.
export const ExpenseFields = component$<ExpenseFieldsProps>((props) => {
  useStylesScoped$(`
    .fields {
      display: flex;
      flex-direction: column;
      gap: 14px;
    }
    .row {
      display: flex;
      gap: 12px;
    }
    .row .field {
      flex: 1;
      min-width: 0;
    }
    .field {
      display: flex;
      flex-direction: column;
      gap: 6px;
    }
    .amount {
      font-variant-numeric: tabular-nums;
    }
    .date {
      padding: 0 8px;
      font-size: 14px;
    }
    .compact .input {
      height: 44px;
      padding: 0 12px;
    }
    .compact .date {
      padding: 0 8px;
    }
    fieldset {
      margin: 0;
      padding: 0;
      border: 0;
      display: flex;
      flex-direction: column;
      gap: 6px;
    }
    legend {
      padding: 0;
      margin-bottom: 6px;
    }
    .categories {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 6px;
    }
    .categories button {
      height: 40px;
      border: 1px solid var(--input-border);
      border-radius: 6px;
      background: var(--white);
      color: var(--ink);
      font-size: 14px;
      cursor: pointer;
    }
    .categories button:hover {
      background: var(--surface);
    }
    .categories button[aria-pressed="true"] {
      border-color: var(--red);
      background: var(--red-tint);
      color: var(--red-dark);
      font-weight: 600;
    }
    textarea.input {
      height: auto;
      padding: 10px 12px;
      resize: vertical;
    }
    .optional {
      font-weight: 400;
      color: var(--muted);
    }
    .hint {
      font-size: 13px;
      color: var(--muted);
    }
    .methods {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
    }
    .methods button {
      height: 36px;
      padding: 0 12px;
      border: 1px solid var(--input-border);
      border-radius: 18px;
      background: var(--white);
      color: var(--ink);
      font-size: 14px;
      cursor: pointer;
    }
    .methods button:hover {
      background: var(--surface);
    }
    .methods button[aria-pressed="true"] {
      border-color: var(--red);
      background: var(--red-tint);
      color: var(--red-dark);
      font-weight: 600;
    }
    .repeat {
      width: 100%;
      border: 0;
      color: var(--ink);
      text-align: left;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      min-height: 44px;
      padding: 8px 12px;
      border-radius: 8px;
      background: var(--surface);
      cursor: pointer;
    }
    .repeat-text {
      display: flex;
      flex-direction: column;
      gap: 2px;
      font-size: 14px;
    }
    .switch {
      flex: none;
      position: relative;
      width: 44px;
      height: 26px;
      border-radius: 13px;
      background: #c9c3bc;
    }
    .repeat[aria-checked="true"] .switch {
      background: var(--red);
    }
    .switch::after {
      content: "";
      position: absolute;
      top: 3px;
      left: 3px;
      width: 20px;
      height: 20px;
      border-radius: 10px;
      background: var(--white);
      transition: left 0.15s;
    }
    .repeat[aria-checked="true"] .switch::after {
      left: 21px;
    }
  `);

  const { idPrefix, values, errors } = props;
  const user = useContext(UserContext);
  const calendar = user.value?.calendar ?? "bs";

  // The methods turned on in settings, plus the expense's own if it was turned off since.
  const methods: PaymentMethod[] = [...(user.value?.payment_methods ?? [])];
  if (values.payment_method && !methods.includes(values.payment_method)) {
    methods.push(values.payment_method);
  }

  const errorProps = (field: string) =>
    errors[field]
      ? {
          "aria-invalid": "true" as const,
          "aria-describedby": `${idPrefix}-${field}-error`,
        }
      : {};

  return (
    <div class={["fields", { compact: props.compact }]}>
      <div class="field">
        <label class="label" for={`${idPrefix}-title`}>
          Title
        </label>
        <input
          id={`${idPrefix}-title`}
          class="input"
          type="text"
          placeholder="e.g. Lunch"
          value={values.title}
          onInput$={(_, el) => (values.title = el.value)}
          {...errorProps("title")}
        />
        <FieldError id={`${idPrefix}-title-error`} message={errors.title} />
      </div>

      <div class="row">
        <div class="field">
          <label class="label" for={`${idPrefix}-amount`}>
            Amount (Rs.)
          </label>
          <input
            id={`${idPrefix}-amount`}
            class="input amount"
            type="number"
            inputMode="decimal"
            min="0"
            step="any"
            placeholder="0"
            value={values.amount}
            onInput$={(_, el) => (values.amount = el.value)}
            {...errorProps("amount")}
          />
          <FieldError id={`${idPrefix}-amount-error`} message={errors.amount} />
        </div>

        <div class="field">
          <label class="label" for={`${idPrefix}-date`}>
            Date
          </label>
          <input
            id={`${idPrefix}-date`}
            class="input date"
            type="date"
            value={values.date}
            onInput$={(_, el) => (values.date = el.value)}
            {...errorProps("date")}
          />
          {calendar === "bs" && values.date && (
            <span class="hint">{formatDate(values.date, "bs")}</span>
          )}
          <FieldError id={`${idPrefix}-date-error`} message={errors.date} />
        </div>
      </div>

      <fieldset {...errorProps("category")}>
        <legend class="label">Category</legend>
        <div class="categories">
          {CATEGORIES.map((category) => (
            <button
              key={category}
              type="button"
              aria-pressed={values.category === category}
              onClick$={() => (values.category = category)}
            >
              {category}
            </button>
          ))}
        </div>
        <FieldError
          id={`${idPrefix}-category-error`}
          message={errors.category}
        />
      </fieldset>

      {methods.length > 0 && (
        <fieldset {...errorProps("payment_method")}>
          <legend class="label">
            Paid with <span class="optional">(optional)</span>
          </legend>
          <div class="methods">
            {methods.map((method) => (
              <button
                key={method}
                type="button"
                aria-pressed={values.payment_method === method}
                onClick$={() =>
                  // Pressing the selected one again clears it.
                  (values.payment_method =
                    values.payment_method === method ? null : method)
                }
              >
                {PAYMENT_LABELS[method]}
              </button>
            ))}
          </div>
          <FieldError
            id={`${idPrefix}-payment_method-error`}
            message={errors.payment_method}
          />
        </fieldset>
      )}

      <div class="field">
        <label class="label" for={`${idPrefix}-note`}>
          Note <span class="optional">(optional)</span>
        </label>
        <textarea
          id={`${idPrefix}-note`}
          class="input"
          rows={2}
          maxLength={255}
          placeholder="Who, where, why"
          value={values.note}
          onInput$={(_, el) => (values.note = el.value)}
          {...errorProps("note")}
        />
        <FieldError id={`${idPrefix}-note-error`} message={errors.note} />
      </div>

      <button
        type="button"
        role="switch"
        class="repeat"
        aria-checked={values.repeat}
        onClick$={() => (values.repeat = !values.repeat)}
      >
        <span class="repeat-text">
          <strong>Repeat every month</strong>
          <span class="hint">
            {values.repeat
              ? `On day ${Number(values.date.slice(8)) || "–"} of each month`
              : "Off"}
          </span>
        </span>
        <span class="switch" aria-hidden="true" />
      </button>
    </div>
  );
});
