import {
  component$,
  useSignal,
  useStylesScoped$,
  useVisibleTask$,
  type QRL,
} from "@builder.io/qwik";

type ConfirmDeleteProps = {
  busy: boolean;
  onConfirm$: QRL<() => void>;
  onCancel$: QRL<() => void>;
};

// Inline "Delete this expense?" that replaces a Delete button.
export const ConfirmDelete = component$<ConfirmDeleteProps>((props) => {
  useStylesScoped$(`
    div {
      display: inline-flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 8px;
      font-size: 14px;
    }
    button {
      height: 36px;
      padding: 0 12px;
      font-size: 14px;
    }
  `);

  const cancelRef = useSignal<HTMLButtonElement>();

  // Move focus here, since the Delete button that had it is gone.
  // eslint-disable-next-line qwik/no-use-visible-task
  useVisibleTask$(() => {
    cancelRef.value?.focus();
  });

  return (
    <div role="group" aria-label="Delete this expense?">
      <span>Delete this expense?</span>
      <button
        type="button"
        class="btn-primary"
        onClick$={props.onConfirm$}
        disabled={props.busy}
      >
        {props.busy ? "Deleting…" : "Delete"}
      </button>
      <button
        ref={cancelRef}
        type="button"
        class="btn-secondary"
        onClick$={props.onCancel$}
        disabled={props.busy}
      >
        Cancel
      </button>
    </div>
  );
});
