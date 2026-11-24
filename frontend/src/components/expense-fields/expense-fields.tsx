import { component$, useStylesScoped$ } from "@builder.io/qwik";
import { FieldError } from "~/components/field/field";
import { CATEGORIES, type Category, type ExpenseInput } from "~/lib/types";

type ExpenseFieldsProps = {
  // Prefix for input ids, so the add form and the edit modal don't clash
  idPrefix: string;
  values: ExpenseInput;
  errors: Record<string, string>;
  // 44px inputs (dashboard form) instead of 48px
  compact?: boolean;
};

// Title, Amount + Category, Date. Used by the add form and the edit modal.
export const ExpenseFields = component$<ExpenseFieldsProps>((props) => {
  useStylesScoped$(`
    .fields {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .row {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 16px;
    }
    .field {
      display: flex;
      flex-direction: column;
      gap: 6px;
    }
    .amount {
      font-family: var(--font-mono);
    }
    .compact .input {
      height: 44px;
      padding: 0 12px;
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
          <FieldError
            id={`${idPrefix}-amount-error`}
            message={errors.amount}
          />
        </div>

        <div class="field">
          <label class="label" for={`${idPrefix}-category`}>
            Category
          </label>
          <select
            id={`${idPrefix}-category`}
            class="input"
            onChange$={(_, el) => (values.category = el.value as Category)}
            {...errorProps("category")}
          >
            {CATEGORIES.map((category) => (
              <option
                key={category}
                value={category}
                selected={values.category === category}
              >
                {category}
              </option>
            ))}
          </select>
          <FieldError
            id={`${idPrefix}-category-error`}
            message={errors.category}
          />
        </div>
      </div>

      <div class="field">
        <label class="label" for={`${idPrefix}-date`}>
          Date
        </label>
        <input
          id={`${idPrefix}-date`}
          class="input"
          type="date"
          value={values.date}
          onInput$={(_, el) => (values.date = el.value)}
          {...errorProps("date")}
        />
        <FieldError id={`${idPrefix}-date-error`} message={errors.date} />
      </div>
    </div>
  );
});
