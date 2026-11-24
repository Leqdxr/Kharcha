export const CATEGORIES = ["Food", "Travel", "Bills", "Other"] as const;

export type Category = (typeof CATEGORIES)[number];

export type User = {
  id: number;
  name: string;
  email: string;
};

export type Expense = {
  id: number;
  title: string;
  amount: number;
  category: Category;
  date: string; // YYYY-MM-DD
};

// What the add and edit forms hold (input values are strings).
export type ExpenseInput = {
  title: string;
  amount: string;
  category: Category;
  date: string;
};

// Response from POST /login and POST /register
export type AuthResponse = {
  user: User;
  token: string;
};
