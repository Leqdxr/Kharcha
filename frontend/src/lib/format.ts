import type { Expense } from "./types";

export function formatMoney(amount: number): string {
  return "Rs. " + amount.toLocaleString("en-IN");
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

// Parse "2026-11" into a local Date on the 1st of that month.
function monthDate(month: string): Date {
  const [year, m] = month.split("-").map(Number);
  return new Date(year, m - 1, 1);
}

// "2026-11" -> "November 2026" (style "long") or "November" (style "short").
export function formatMonth(month: string, style: "long" | "short"): string {
  return monthDate(month).toLocaleDateString("en-GB", {
    month: "long",
    year: style === "long" ? "numeric" : undefined,
  });
}

// "2026-11", 1 -> "2026-12"
export function shiftMonth(month: string, by: number): string {
  const d = monthDate(month);
  d.setMonth(d.getMonth() + by);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

// "2026-11-24" -> "Today · 24 Nov" or "22 Nov"
export function dayLabel(date: string): string {
  const [year, month, day] = date.split("-").map(Number);
  const label = new Date(year, month - 1, day).toLocaleDateString("en-GB", {
    day: "numeric",
    month: "short",
  });
  return date === today() ? `Today · ${label}` : label;
}
