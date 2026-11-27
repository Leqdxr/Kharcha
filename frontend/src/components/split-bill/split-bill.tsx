import {
  $,
  component$,
  useSignal,
  useStore,
  useStylesScoped$,
  type QRL,
} from "@builder.io/qwik";
import { FieldError } from "~/components/field/field";
import { api } from "~/lib/api";
import { formatMoney } from "~/lib/format";
import { CATEGORIES, type Category } from "~/lib/types";

type SplitBillProps = {
  onSplit$: QRL<() => void>;
};

// "Sujan", "Priya", "Anish" -> "Sujan, Priya and Anish"
function joinNames(names: string[]): string {
  return names.length < 2
    ? names.join("")
    : `${names.slice(0, -1).join(", ")} and ${names[names.length - 1]}`;
}

// A bill you paid, split equally. Friends' shares are whole rupees and
// you take the remainder. Each friend owes you their share, and your
// share is added as an expense.
export const SplitBill = component$<SplitBillProps>((props) => {
  useStylesScoped$(`
    form {
      padding: 20px;
      display: flex;
      flex-direction: column;
      gap: 12px;
      border-radius: 12px;
    }
    .head {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
    }
    h2 {
      margin: 0;
      font-size: 17px;
      font-weight: 700;
    }
    .paid {
      font-size: 13px;
      color: var(--muted);
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
    .add-friend {
      display: flex;
      gap: 8px;
    }
    .add-friend .btn-secondary {
      height: 44px;
      flex: none;
      font-size: 15px;
    }
    .people {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
    }
    .person {
      height: 32px;
      padding: 0 6px 0 12px;
      display: inline-flex;
      align-items: center;
      gap: 2px;
      border: 1px solid var(--input-border);
      border-radius: 16px;
      background: var(--white);
      font-size: 13px;
    }
    .you {
      padding: 0 12px;
      border-color: var(--ink);
      background: var(--ink);
      color: var(--white);
      font-weight: 600;
    }
    .remove {
      width: 24px;
      height: 24px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      border: 0;
      border-radius: 12px;
      background: transparent;
      color: var(--muted);
      cursor: pointer;
    }
    .remove:hover {
      background: var(--surface);
      color: var(--ink);
    }
    .categories {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
    }
    .categories button {
      height: 34px;
      padding: 0 12px;
      border: 1px solid var(--input-border);
      border-radius: 17px;
      background: var(--white);
      color: var(--ink);
      font-size: 13px;
      cursor: pointer;
    }
    .categories button[aria-pressed="true"] {
      border-color: var(--red);
      background: var(--red-tint);
      color: var(--red-dark);
      font-weight: 600;
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
    .preview {
      margin: 0;
      font-size: 14px;
      color: #3d3835;
    }
    .split-btn {
      height: 44px;
      border: 1px solid var(--red);
      border-radius: 8px;
      background: var(--white);
      color: var(--red);
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
    }
    .split-btn:hover {
      background: var(--red-tint);
    }
    .split-btn:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }
    .done {
      margin: 0;
      font-size: 14px;
      color: var(--muted);
    }
  `);

  const values = useStore({
    title: "",
    total: "",
    category: "Food" as Category,
    friends: [] as string[],
  });
  const friendName = useSignal("");
  const errors = useSignal<Record<string, string>>({});
  const message = useSignal("");
  const done = useSignal("");
  const saving = useSignal(false);

  const addFriend = $(() => {
    const name = friendName.value.trim();
    if (name && !values.friends.includes(name)) {
      values.friends = [...values.friends, name];
    }
    friendName.value = "";
  });

  const submit = $(async () => {
    // Enter in the friend's name box adds the friend instead of splitting.
    if (document.activeElement?.id === "split-friend") {
      await addFriend();
      return;
    }
    saving.value = true;
    errors.value = {};
    message.value = "";
    done.value = "";
    const res = await api.post("/udharos/split", { ...values });
    saving.value = false;
    if (!res.ok) {
      errors.value = res.error.errors;
      // Errors for one friend's name ("friends.0") show as one message.
      const friendError = Object.entries(res.error.errors).find(([key]) =>
        key.startsWith("friends."),
      );
      if (friendError)
        errors.value = { ...errors.value, friends: friendError[1] };
      if (Object.keys(res.error.errors).length === 0) {
        message.value = res.error.message;
      }
      return;
    }
    done.value = `Split "${values.title}" with ${joinNames(values.friends)}.`;
    values.title = "";
    values.total = "";
    values.friends = [];
    await props.onSplit$();
  });

  const total = Number(values.total) || 0;
  const people = values.friends.length + 1;
  const share = Math.floor(total / people);
  const yours = Math.round((total - share * (people - 1)) * 100) / 100;
  const canSplit = values.friends.length > 0 && share >= 1;

  const errorProps = (field: string) =>
    errors.value[field]
      ? {
          "aria-invalid": "true" as const,
          "aria-describedby": `split-${field}-error`,
        }
      : {};

  return (
    <form
      class="card"
      aria-labelledby="split-heading"
      preventdefault:submit
      onSubmit$={submit}
      noValidate
    >
      <div class="head">
        <h2 id="split-heading">Split a bill</h2>
        <span class="paid">You paid</span>
      </div>
      <div class="row">
        <div class="field">
          <label class="label" for="split-title">
            What for
          </label>
          <input
            id="split-title"
            class="input"
            type="text"
            placeholder="e.g. Khaja set"
            value={values.title}
            onInput$={(_, el) => (values.title = el.value)}
            {...errorProps("title")}
          />
          <FieldError id="split-title-error" message={errors.value.title} />
        </div>
        <div class="field">
          <label class="label" for="split-total">
            Total (Rs.)
          </label>
          <input
            id="split-total"
            class="input number"
            type="number"
            inputMode="decimal"
            min="0"
            step="any"
            placeholder="0"
            value={values.total}
            onInput$={(_, el) => (values.total = el.value)}
            {...errorProps("total")}
          />
          <FieldError id="split-total-error" message={errors.value.total} />
        </div>
      </div>

      <div class="field">
        <label class="label" for="split-friend">
          Friends
        </label>
        <div class="add-friend">
          <input
            id="split-friend"
            class="input"
            type="text"
            placeholder="Name, then Add"
            bind:value={friendName}
            {...errorProps("friends")}
          />
          <button type="button" class="btn-secondary" onClick$={addFriend}>
            Add
          </button>
        </div>
        <div class="people" aria-label="People in the split">
          <span class="person you">You</span>
          {values.friends.map((friend) => (
            <span key={friend} class="person">
              {friend}
              <button
                type="button"
                class="remove"
                aria-label={`Remove ${friend}`}
                onClick$={() =>
                  (values.friends = values.friends.filter((f) => f !== friend))
                }
              >
                <svg
                  width="14"
                  height="14"
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
            </span>
          ))}
        </div>
        <FieldError id="split-friends-error" message={errors.value.friends} />
      </div>

      <fieldset>
        <legend class="label">Your share goes to</legend>
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
      </fieldset>

      {canSplit && (
        <p class="preview">
          Split equally: <strong class="number">{formatMoney(share)}</strong>{" "}
          each. {joinNames(values.friends)}{" "}
          {values.friends.length === 1 ? "will owe" : "will each owe"} you{" "}
          {formatMoney(share)}, and your {formatMoney(yours)} is added to your{" "}
          {values.category} expenses.
        </p>
      )}
      <FieldError id="split-error" message={message.value} />
      <button
        type="submit"
        class="split-btn"
        disabled={saving.value || !canSplit}
      >
        {saving.value ? "Splitting…" : "Split and add to udharo"}
      </button>
      {done.value && (
        <p class="done" role="status">
          {done.value}
        </p>
      )}
    </form>
  );
});
