import { component$ } from "@builder.io/qwik";
import type { Category } from "~/lib/types";

const PATHS: Record<Category, string> = {
  Food: "M7 3v8M5 3v4a2 2 0 0 0 4 0V3M7 11v10M17 3c-2 0-3 2-3 5s1 4 3 4v9",
  Travel: "M5 6h14v9a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6zM5 11h14M8 20v-3M16 20v-3",
  Bills: "M13 3L5 14h6l-1 7 8-11h-6l1-7z",
  Other: "M3 12V4h8l10 10-8 8L3 12zM7.5 7.5h.01",
};

type CategoryIconProps = {
  category: Category;
  size?: number;
};

// Line icon for a category (decorative, the category name is always shown as text too).
export const CategoryIcon = component$<CategoryIconProps>((props) => {
  const size = props.size ?? 20;
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.8"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
    >
      <path d={PATHS[props.category]} />
    </svg>
  );
});
