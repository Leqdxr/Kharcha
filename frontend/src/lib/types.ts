export const CATEGORIES = ["Food", "Travel", "Bills", "Other"] as const;

export type Category = (typeof CATEGORIES)[number];

export type User = {
  id: number;
  name: string;
  email: string;
  monthly_budget: number | null;
};

export type Expense = {
  id: number;
  title: string;
  amount: number;
  category: Category;
  date: string; // YYYY-MM-DD
  note: string | null;
};

// What the add and edit forms hold (input values are strings).
export type ExpenseInput = {
  title: string;
  amount: string;
  category: Category;
  date: string;
  note: string;
};

// Response from GET /summary?month=YYYY-MM
export type Summary = {
  month: string; // YYYY-MM
  total: number;
  count: number;
  previous_month: string;
  previous_total: number;
  budget: number | null;
  by_category: { category: Category; total: number }[];
};

// Response from POST /login and POST /register
export type AuthResponse = {
  user: User;
  token: string;
};
