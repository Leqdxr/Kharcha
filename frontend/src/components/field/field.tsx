import { component$, useStylesScoped$, type Signal } from "@builder.io/qwik";

type FieldErrorProps = {
  id: string;
  message?: string;
};

// Red validation message shown under an input.
export const FieldError = component$<FieldErrorProps>(({ id, message }) => {
  if (!message) return null;

  return (
    <p id={id} class="field-error" role="alert">
      <svg
        width="16"
        height="16"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
        aria-hidden="true"
      >
        <circle cx="12" cy="12" r="9" />
        <path d="M12 8v5M12 16.5v.01" />
      </svg>
      {message}
    </p>
  );
});

type TextFieldProps = {
  id: string;
  label: string;
  value: Signal<string>;
  type?: "text" | "email" | "password";
  placeholder?: string;
  autoComplete?: string;
  error?: string;
};

// Label + input + error message.
export const TextField = component$<TextFieldProps>((props) => {
  useStylesScoped$(`
    .field {
      display: flex;
      flex-direction: column;
      gap: 6px;
    }
  `);

  const errorId = `${props.id}-error`;

  return (
    <div class="field">
      <label class="label" for={props.id}>
        {props.label}
      </label>
      <input
        id={props.id}
        class="input"
        type={props.type ?? "text"}
        placeholder={props.placeholder}
        autoComplete={props.autoComplete}
        bind:value={props.value}
        aria-invalid={props.error ? "true" : undefined}
        aria-describedby={props.error ? errorId : undefined}
      />
      <FieldError id={errorId} message={props.error} />
    </div>
  );
});
