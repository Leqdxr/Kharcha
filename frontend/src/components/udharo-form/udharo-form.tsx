import {
  $,
  component$,
  useContext,
  useSignal,
  useStore,
  useStylesScoped$,
  type QRL,
} from "@builder.io/qwik";
import { FieldError } from "~/components/field/field";
import { api } from "~/lib/api";
import { formatDate, today } from "~/lib/format";
import type { Udharo } from "~/lib/types";
import { UserContext } from "~/lib/user-context";

type UdharoFormProps = {
  onAdded$: QRL<(udharo: Udharo) => void>;
};

// "I lent money" / "I borrowed", person, amount, date, what for.
export const UdharoForm = component$<UdharoFormProps>((props) => {
  useStylesScoped$(`
    form {
      padding: 20px;
      display: flex;
      flex-direction: column;
      gap: 14px;
      border-radius: 12px;
    }
    h2 {
      margin: 0;
      font-size: 17px;
      font-weight: 700;
    }
    .direction {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 6px;
    }
    .direction button {
      height: 42px;
      border: 1px solid var(--input-border);
      border-radius: 8px;
      background: var(--white);
      color: var(--ink);
      font-size: 14px;
      cursor: pointer;
    }
    .direction button:hover {
      background: var(--surface);
    }
    .direction button[aria-pressed="true"] {
      border-color: var(--red);
      background: var(--red-tint);
      color: var(--red-dark);
      font-weight: 600;
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
    .input {
      height: 44px;
      padding: 0 12px;
    }
    .number {
      font-variant-numeric: tabular-nums;
    }
    .hint {
      font-size: 13px;
      color: var(--muted);
    }
  `);

  const user = useContext(UserContext);
  const calendar = user.value?.calendar ?? "bs";
  const values = useStore({
    direction: "lent" as Udharo["direction"],
    person: "",
    amount: "",
    date: today(),
    note: "",
  });
  const errors = useSignal<Record<string, string>>({});
  const message = useSignal("");
  const saving = useSignal(false);

  const submit = $(async () => {
    saving.value = true;
    errors.value = {};
    message.value = "";
    const res = await api.post<Udharo>("/udharos", { ...values });
    saving.value = false;
    if (!res.ok) {
      errors.value = res.error.errors;
      if (Object.keys(res.error.errors).length === 0) {
        message.value = res.error.message;
      }
      return;
    }
    await props.onAdded$(res.data);
    values.person = "";
    values.amount = "";
    values.note = "";
  });

  const errorProps = (field: string) =>
    errors.value[field]
      ? {
          "aria-invalid": "true" as const,
          "aria-describedby": `ud-${field}-error`,
        }
      : {};

  return (
    <form
      class="card"
      aria-labelledby="udharo-form-heading"
      preventdefault:submit
      onSubmit$={submit}
      noValidate
    >
      <h2 id="udharo-form-heading">Add udharo</h2>
      <div class="direction" role="group" aria-label="Direction">
        <button
          type="button"
          aria-pressed={values.direction === "lent"}
          onClick$={() => (values.direction = "lent")}
        >
          I lent money
        </button>
        <button
          type="button"
          aria-pressed={values.direction === "borrowed"}
          onClick$={() => (values.direction = "borrowed")}
        >
          I borrowed
        </button>
      </div>
      <div class="field">
        <label class="label" for="ud-person">
          Person
        </label>
        <input
          id="ud-person"
          class="input"
          type="text"
          placeholder="Name"
          value={values.person}
          onInput$={(_, el) => (values.person = el.value)}
          {...errorProps("person")}
        />
        <FieldError id="ud-person-error" message={errors.value.person} />
      </div>
      <div class="row">
        <div class="field">
          <label class="label" for="ud-amount">
            Amount (Rs.)
          </label>
          <input
            id="ud-amount"
            class="input number"
            type="number"
            inputMode="decimal"
            min="0"
            step="any"
            placeholder="0"
            value={values.amount}
            onInput$={(_, el) => (values.amount = el.value)}
            {...errorProps("amount")}
          />
          <FieldError id="ud-amount-error" message={errors.value.amount} />
        </div>
        <div class="field">
          <label class="label" for="ud-date">
            Date
          </label>
          <input
            id="ud-date"
            class="input"
            type="date"
            value={values.date}
            onInput$={(_, el) => (values.date = el.value)}
            {...errorProps("date")}
          />
          {calendar === "bs" && values.date && (
            <span class="hint">{formatDate(values.date, "bs")}</span>
          )}
          <FieldError id="ud-date-error" message={errors.value.date} />
        </div>
      </div>
      <div class="field">
        <label class="label" for="ud-note">
          What for
        </label>
        <input
          id="ud-note"
          class="input"
          type="text"
          maxLength={255}
          placeholder="e.g. Bus fare"
          value={values.note}
          onInput$={(_, el) => (values.note = el.value)}
          {...errorProps("note")}
        />
        <FieldError id="ud-note-error" message={errors.value.note} />
      </div>
      <FieldError id="ud-error" message={message.value} />
      <button type="submit" class="btn-primary" disabled={saving.value}>
        {saving.value ? "Adding…" : "Add"}
      </button>
    </form>
  );
});
