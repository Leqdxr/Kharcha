import {
  component$,
  useSignal,
  useStylesScoped$,
  useVisibleTask$,
  type QRL,
} from "@builder.io/qwik";

type ConfirmDialogProps = {
  title: string;
  message: string;
  confirmLabel: string;
  onConfirm$: QRL<() => void>;
  onCancel$: QRL<() => void>;
};

// "Are you sure?" dialog before deleting something. Escape cancels.
export const ConfirmDialog = component$<ConfirmDialogProps>((props) => {
  useStylesScoped$(`
    .modal {
      max-width: 400px;
      padding: 24px;
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    h2 {
      margin: 0;
      font-size: 20px;
      font-weight: 700;
    }
    p {
      margin: 0;
      font-size: 15px;
      line-height: 1.5;
      color: var(--muted);
      overflow-wrap: anywhere;
    }
    .actions {
      padding-top: 8px;
      display: flex;
      justify-content: flex-end;
      gap: 10px;
    }
    button {
      font-size: 15px;
    }
  `);

  const cancelRef = useSignal<HTMLButtonElement>();

  // Focus Cancel (the safe choice); give focus back on close.
  // eslint-disable-next-line qwik/no-use-visible-task
  useVisibleTask$(({ cleanup }) => {
    const opener = document.activeElement as HTMLElement | null;
    cancelRef.value?.focus();
    cleanup(() => opener?.focus());
  });

  return (
    <div
      class="modal-backdrop"
      document:onKeyDown$={(event) => {
        if (event.key === "Escape") props.onCancel$();
      }}
    >
      <div
        class="modal"
        role="alertdialog"
        aria-modal="true"
        aria-labelledby="confirm-heading"
        aria-describedby="confirm-message"
      >
        <h2 id="confirm-heading">{props.title}</h2>
        <p id="confirm-message">{props.message}</p>
        <div class="actions">
          <button
            ref={cancelRef}
            type="button"
            class="btn-secondary"
            onClick$={props.onCancel$}
          >
            Cancel
          </button>
          <button type="button" class="btn-primary" onClick$={props.onConfirm$}>
            {props.confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
});
