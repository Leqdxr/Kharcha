import NepaliDate from "nepali-date-converter";
import type { Calendar, Expense } from "./types";

export function formatMoney(amount: number): string {
  return "Rs. " + amount.toLocaleString("en-IN");
}

// Today's date as YYYY-MM-DD in local time, for date inputs.
export function today(): string {
  return toIsoDate(new Date());
}

function toIsoDate(d: Date): string {
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${d.getFullYear()}-${month}-${day}`;
}

// "2026-11-26" -> local Date
function parseDate(date: string): Date {
  const [year, month, day] = date.split("-").map(Number);
  return new Date(year, month - 1, day);
}

// BS month names as the designs spell them. The library does the date
// conversion; only the names come from here, so web and mobile match.
const BS_MONTHS = [
  "Baisakh",
  "Jestha",
  "Asar",
  "Shrawan",
  "Bhadra",
  "Asoj",
  "Kartik",
  "Mangsir",
  "Poush",
  "Magh",
  "Falgun",
  "Chaitra",
];

// "2026-11-26" -> "10 Mangsir 2083" (BS) or "26 Nov 2026" (AD).
// Without the year: "10 Mangsir" or "26 Nov".
export function formatDate(
  date: string,
  calendar: Calendar,
  withYear = true,
): string {
  const d = parseDate(date);
  if (calendar === "bs") {
    const bs = NepaliDate.fromAD(d).getBS(); // month is 0-based
    const dayMonth = `${bs.date} ${BS_MONTHS[bs.month]}`;
    return withYear ? `${dayMonth} ${bs.year}` : dayMonth;
  }
  return d.toLocaleDateString("en-GB", {
    day: "numeric",
    month: "short",
    year: withYear ? "numeric" : undefined,
  });
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

// "2026-11" -> "15 Kartik – 14 Mangsir": the BS dates the AD month covers.
export function bsMonthRange(month: string): string {
  const first = monthDate(month);
  const last = new Date(first.getFullYear(), first.getMonth() + 1, 0);
  return `${formatDate(toIsoDate(first), "bs", false)} – ${formatDate(toIsoDate(last), "bs", false)}`;
}

// "2026-11", 1 -> "2026-12"
export function shiftMonth(month: string, by: number): string {
  const d = monthDate(month);
  d.setMonth(d.getMonth() + by);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

// "2026-11-24" -> "Today · 24 Nov" or "22 Nov" (or the BS date)
export function dayLabel(date: string, calendar: Calendar): string {
  const label = formatDate(date, calendar, false);
  return date === today() ? `Today · ${label}` : label;
}

// "Aagaman Koirala" -> "AK"
export function initials(name: string): string {
  return name
    .split(/\s+/)
    .slice(0, 2)
    .map((word) => word[0]?.toUpperCase() ?? "")
    .join("");
}
