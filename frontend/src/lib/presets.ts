import type { Category } from "./types";

// Quick add chips at the top of the add form. Tapping one fills the
// title, amount and category. Editing presets isn't supported yet.
export const QUICK_ADD_PRESETS: {
  title: string;
  amount: number;
  category: Category;
}[] = [
  { title: "Tea", amount: 25, category: "Food" },
  { title: "Bus fare", amount: 30, category: "Travel" },
  { title: "Lunch", amount: 150, category: "Food" },
  { title: "Momo", amount: 180, category: "Food" },
  { title: "Phone recharge", amount: 500, category: "Bills" },
];
