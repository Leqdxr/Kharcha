export const CATEGORIES = ["Food", "Travel", "Bills", "Other"] as const;

export type Category = (typeof CATEGORIES)[number];

export const PAYMENT_METHODS = [
  "cash",
  "esewa",
  "khalti",
  "bank_card",
  "mobile_banking",
] as const;

export type PaymentMethod = (typeof PAYMENT_METHODS)[number];

export const PAYMENT_LABELS: Record<PaymentMethod, string> = {
  cash: "Cash",
  esewa: "eSewa",
  khalti: "Khalti",
  bank_card: "Bank card",
  mobile_banking: "Mobile banking",
};

// How dates are shown. They are always stored and sent as AD YYYY-MM-DD.
export type Calendar = "bs" | "ad";

export type User = {
  id: number;
  name: string;
  email: string;
  monthly_budget: number | null;
  calendar: Calendar;
  ssf_contributor: boolean;
  payment_methods: PaymentMethod[];
};

export type Expense = {
  id: number;
  title: string;
  amount: number;
  category: Category;
  payment_method: PaymentMethod | null;
  date: string; // YYYY-MM-DD
  note: string | null;
  // Set when the expense was made by (or started) a monthly repeat
  recurring_expense_id: number | null;
};

// What the add and edit forms hold (input values are strings).
export type ExpenseInput = {
  title: string;
  amount: string;
  category: Category;
  payment_method: PaymentMethod | null;
  date: string;
  note: string;
  repeat: boolean;
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
  // Only for the current month; null otherwise
  days_left: number | null;
  // Null without a budget or for other months
  safe_to_spend: number | null;
};

export type IncomeType =
  | "salary"
  | "service_pan"
  | "service_vat"
  | "rent"
  | "interest"
  | "dividend";

export type Income = {
  id: number;
  title: string;
  amount: number;
  type: IncomeType;
  tds_amount: number;
  date: string;
  note: string | null;
};

// Response from GET /tax/summary (current fiscal year)
export type TaxSummary = {
  fiscal_year: { label: string; start: string; end: string };
  // rate is null for salary: the TDS is typed in
  types: Record<IncomeType, { label: string; rate: number | null; final: boolean }>;
  ssf_contributor: boolean;
  totals: {
    gross: number;
    tds: number;
    received: number;
    salary: number;
    salary_tds: number;
    salary_months: number;
    other: number;
    other_tds: number;
    final: number;
  };
  projected_salary: number;
  taxable_income: number;
  slabs: {
    from: number;
    to: number | null;
    rate: number;
    taxable: number;
    tax: number;
    waived: boolean;
  }[];
  estimated_tax: number;
  effective_rate: number;
  tds_so_far: number;
  final_tds: number;
  adjustable_tds_year_end: number;
  // Positive: you may get money back. Negative: you may still owe.
  result: number;
};

export type Udharo = {
  id: number;
  person: string;
  amount: number;
  // lent = they owe me, borrowed = I owe them
  direction: "lent" | "borrowed";
  note: string | null;
  date: string;
  settled_at: string | null;
};

// Response from POST /login and POST /register
export type AuthResponse = {
  user: User;
  token: string;
};
