import { component$, useStylesScoped$, type Signal } from "@builder.io/qwik";
import { CATEGORIES, type Category } from "~/lib/types";

export type Filter = Category | "All";

type FilterChipsProps = {
  active: Signal<Filter>;
};

export const FilterChips = component$<FilterChipsProps>((props) => {
  useStylesScoped$(`
    div {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
    }
    button {
      height: 36px;
      padding: 0 14px;
      border-radius: 18px;
      border: 1px solid var(--input-border);
      background: var(--white);
      color: var(--ink);
      font-size: 14px;
      cursor: pointer;
    }
    button:hover {
      background: var(--surface);
    }
    button[aria-pressed="true"] {
      border-color: var(--ink);
      background: var(--ink);
      color: var(--white);
      font-weight: 600;
    }
  `);

  const filters: Filter[] = ["All", ...CATEGORIES];

  return (
    <div role="group" aria-label="Filter by category">
      {filters.map((filter) => (
        <button
          key={filter}
          type="button"
          aria-pressed={props.active.value === filter}
          onClick$={() => (props.active.value = filter)}
        >
          {filter}
        </button>
      ))}
    </div>
  );
});
