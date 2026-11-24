import { component$, useStylesScoped$ } from "@builder.io/qwik";
import { FieldError } from "~/components/field/field";
import { CATEGORIES, type ExpenseInput } from "~/lib/types";

type ExpenseFieldsProps = {
  // Prefix for input ids, so the add form and the edit modal don't clash
  idPrefix: string;
  values: ExpenseInput;
  errors: Record<string, string>;
  // 44px inputs (dashboard form) instead of 48px
  compact?: boolean;
};

// Title, Amount + Date, Category buttons, Note. Used by the add form and the edit modal.
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
  `);

  const { idPrefix, values, errors } = props;

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
    </div>
  );
});
