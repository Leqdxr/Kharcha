export type Category = "Food" | "Travel" | "Bills" | "Other";

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
