import { component$, useStylesScoped$, type QRL } from "@builder.io/qwik";

type UndoToastProps = {
  title: string;
  onUndo$: QRL<() => void>;
};

// Dark toast at the bottom: Deleted "Groceries" [Undo]
export const UndoToast = component$<UndoToastProps>((props) => {
  useStylesScoped$(`
    div {
      position: fixed;
      left: 50%;
      bottom: 24px;
      z-index: 20;
      transform: translateX(-50%);
      max-width: calc(100% - 32px);
      display: flex;
      align-items: center;
      gap: 16px;
      padding: 10px 10px 10px 20px;
      border-radius: 10px;
      background: var(--ink);
      color: var(--white);
      box-shadow: 0 12px 32px rgba(0, 0, 0, 0.2);
      font-size: 15px;
    }
    span {
      min-width: 0;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    button {
      height: 44px;
      flex: none;
      padding: 0 14px;
      border: 0;
      border-radius: 6px;
      background: var(--white);
      color: var(--ink);
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
    }
    button:hover {
      background: var(--surface);
    }
  `);

  return (
    <div role="status">
      <span>Deleted “{props.title}”</span>
      <button type="button" onClick$={props.onUndo$}>
        Undo
      </button>
    </div>
  );
});
