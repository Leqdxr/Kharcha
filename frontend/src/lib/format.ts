import type { Expense } from "./types";

export function formatMoney(amount: number): string {
  return "Rs. " + amount.toLocaleString("en-IN");
}

// "2026-11-24" -> "24 Nov 2026". Built from parts so the timezone can't shift the day.
export function formatDate(date: string): string {
  const [year, month, day] = date.split("-").map(Number);
  return new Date(year, month - 1, day).toLocaleDateString("en-GB", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

// Today's date as YYYY-MM-DD in local time, for date inputs.
export function today(): string {
  const now = new Date();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${now.getFullYear()}-${month}-${day}`;
}

// Newest first, same order as GET /expenses.
export function sortExpenses(expenses: Expense[]): Expense[] {
  return [...expenses].sort(
    (a, b) => b.date.localeCompare(a.date) || b.id - a.id,
  );
}
