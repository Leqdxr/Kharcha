import {
  $,
  component$,
  useContext,
  useSignal,
  useStylesScoped$,
  useVisibleTask$,
} from "@builder.io/qwik";
import type { DocumentHead } from "@builder.io/qwik-city";
import { ConfirmDialog } from "~/components/confirm-dialog/confirm-dialog";
import {
  IncomeDialog,
  rateText,
} from "~/components/income-dialog/income-dialog";
import { api } from "~/lib/api";
import { getToken, saveAuth } from "~/lib/auth";
import { formatDate, formatMoney } from "~/lib/format";
import type { Income, TaxSummary, User } from "~/lib/types";
import { UserContext } from "~/lib/user-context";

// 1000000 -> "10 lakh"
function lakh(amount: number): string {
  return `${amount / 100000} lakh`;
}

// "Up to 10 lakh · 1%", "10–15 lakh · 10%", "Above 40 lakh · 29%"
function slabLabel(slab: TaxSummary["slabs"][number]): string {
  const pct = `${Math.round(slab.rate * 100)}%`;
  if (slab.from === 0) return `Up to ${lakh(slab.to ?? 0)} · ${pct}`;
  if (slab.to === null) return `Above ${lakh(slab.from)} · ${pct}`;
  return `${slab.from / 100000}–${lakh(slab.to)} · ${pct}`;
}

// Quote a CSV field when it has a comma, quote or line break.
function csvField(value: string | number): string {
  const text = String(value);
  return /[",\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

export default component$(() => {
  useStylesScoped$(`
    main {
      max-width: 1200px;
      margin: 0 auto;
      padding: 36px 32px 64px;
      display: flex;
      flex-direction: column;
      gap: 28px;
    }
    .top {
      display: flex;
      flex-wrap: wrap;
      align-items: flex-end;
      justify-content: space-between;
      gap: 16px;
    }
    .intro {
      display: flex;
      flex-direction: column;
      gap: 6px;
    }
    .eyebrow {
      font-size: 13px;
      font-weight: 600;
      letter-spacing: 0.06em;
      color: var(--red);
    }
    h1 {
      margin: 0;
      font-size: 34px;
      line-height: 1.15;
      font-weight: 700;
      letter-spacing: -0.02em;
    }
    .intro p {
      margin: 0;
      font-size: 15px;
      color: var(--muted);
    }
    .actions {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
    }
    .actions button {
      height: 46px;
      font-size: 15px;
    }
    .number {
      font-variant-numeric: tabular-nums;
    }
    .cards {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
      gap: 16px;
    }
    .cards .card {
      border-radius: 12px;
      padding: 24px;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .card-label {
      font-size: 14px;
      font-weight: 500;
      color: var(--muted);
    }
    .card-value {
      font-size: 26px;
      font-weight: 600;
    }
    .card-note {
      font-size: 14px;
      color: var(--muted);
    }
    .cards .result {
      border-color: var(--red);
      background: var(--red);
      color: var(--white);
    }
    .result .card-label {
      color: var(--red-tint);
    }
    .result .card-value {
      font-size: 36px;
      letter-spacing: -0.02em;
    }
    .result .card-note {
      color: var(--white);
    }
    .content {
      display: flex;
      flex-wrap: wrap;
      gap: 24px;
      align-items: flex-start;
    }
    .incomes {
      flex: 999 1 600px;
      min-width: 0;
      border-radius: 12px;
      overflow: hidden;
    }
    .section-head {
      padding: 16px 20px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      border-bottom: 1px solid var(--line);
    }
    h2 {
      margin: 0;
      font-size: 18px;
      font-weight: 700;
    }
    .count {
      font-size: 14px;
      color: var(--muted);
    }
    .scroll {
      overflow-x: auto;
    }
    table {
      width: 100%;
      min-width: 680px;
      border-collapse: collapse;
      font-size: 15px;
    }
    th {
      padding: 12px 8px;
      text-align: left;
      font-size: 13px;
      font-weight: 600;
      color: var(--muted);
    }
    td {
      padding: 12px 8px;
      border-top: 1px solid #efece8;
      vertical-align: middle;
    }
    th:first-child,
    td:first-child {
      padding-left: 20px;
    }
    .right {
      text-align: right;
      white-space: nowrap;
    }
    .date {
      font-size: 13px;
      color: var(--muted);
      white-space: nowrap;
    }
    .source {
      display: flex;
      flex-direction: column;
      gap: 3px;
    }
    .source strong {
      font-weight: 600;
    }
    .type {
      align-self: flex-start;
      padding: 2px 8px;
      border-radius: 10px;
      background: var(--surface);
      font-size: 12px;
      font-weight: 500;
      color: #3d3835;
    }
    .tds {
      color: var(--red-dark);
      font-weight: 600;
    }
    .small {
      font-size: 12px;
      color: var(--muted);
    }
    .received {
      font-weight: 600;
    }
    .total-row td {
      border-top: 2px solid var(--line);
      background: var(--row-hover);
      font-weight: 600;
    }
    .delete {
      color: var(--red);
    }
    .empty {
      margin: 0;
      padding: 40px 20px;
      text-align: center;
      color: var(--muted);
    }
    .side {
      flex: 1 1 340px;
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .side .card {
      border-radius: 12px;
      padding: 20px;
      display: flex;
      flex-direction: column;
      gap: 14px;
    }
    .side h2 {
      font-size: 17px;
    }
    .lines {
      display: flex;
      flex-direction: column;
      gap: 6px;
      font-size: 14px;
    }
    .line {
      display: flex;
      justify-content: space-between;
      gap: 12px;
    }
    .line span:first-child {
      color: var(--muted);
    }
    .slabs {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .slab {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }
    .slab-row {
      display: flex;
      justify-content: space-between;
      font-size: 13px;
    }
    .slab-row span:first-child {
      font-weight: 600;
    }
    .track {
      height: 6px;
      border-radius: 3px;
      background: var(--surface);
      overflow: hidden;
    }
    .fill {
      height: 100%;
      border-radius: 3px;
      background: var(--red);
    }
    .ssf {
      display: flex;
      align-items: flex-start;
      gap: 10px;
      padding: 12px;
      border-radius: 8px;
      background: var(--surface);
      font-size: 14px;
      cursor: pointer;
    }
    .ssf input {
      width: 18px;
      height: 18px;
      margin: 1px 0 0;
      accent-color: var(--red);
    }
    .rates {
      display: flex;
      flex-direction: column;
      font-size: 14px;
    }
    .rates .line {
      padding: 7px 0;
      border-bottom: 1px solid #efece8;
    }
    .rates .line:last-child {
      border-bottom: 0;
    }
    .rates .line span:first-child {
      color: var(--ink);
    }
    .disclaimer {
      margin: 0;
      font-size: 13px;
      line-height: 1.5;
      color: var(--muted);
    }
    .status {
      padding: 48px 24px;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
      color: var(--muted);
    }
    @media (max-width: 480px) {
      main {
        padding: 24px 16px 48px;
        gap: 24px;
      }
      h1 {
        font-size: 28px;
      }
    }
  `);

  const user = useContext(UserContext);
  const summary = useSignal<TaxSummary | null>(null);
  const incomes = useSignal<Income[]>([]);
  const status = useSignal<"loading" | "ready" | "error">("loading");
  const adding = useSignal(false);
  const deleting = useSignal<Income | null>(null);
  const notice = useSignal("");

  const load = $(async () => {
    const [totals, list] = await Promise.all([
      api.get<TaxSummary>("/tax/summary"),
      api.get<Income[]>("/incomes"),
    ]);
    if (!totals.ok || !list.ok) {
      status.value = "error";
      return;
    }
    const { start, end } = totals.data.fiscal_year;
    summary.value = totals.data;
    incomes.value = list.data.filter((i) => i.date >= start && i.date <= end);
    status.value = "ready";
  });

  // eslint-disable-next-line qwik/no-use-visible-task
  useVisibleTask$(async () => {
    await load();
  });

  const setSsf = $(async (on: boolean) => {
    notice.value = "";
    const res = await api.put<User>("/settings", { ssf_contributor: on });
    if (!res.ok) {
      notice.value = `Couldn't save the SSF setting. ${res.error.message}`;
      return;
    }
    const token = getToken();
    if (token) saveAuth(token, res.data);
    user.value = res.data;
    await load();
  });

  const exportCsv = $(() => {
    const data = summary.value;
    if (!data) return;
    const rows = [
      ["Date (AD)", "Date (BS)", "Title", "Type", "Gross", "TDS", "Received"],
      ...incomes.value.map((i) => [
        i.date,
        formatDate(i.date, "bs"),
        i.title,
        data.types[i.type].label,
        i.amount,
        i.tds_amount,
        Math.round((i.amount - i.tds_amount) * 100) / 100,
      ]),
    ];
    const csv = rows.map((row) => row.map(csvField).join(",")).join("\n");
    const url = URL.createObjectURL(new Blob([csv], { type: "text/csv" }));
    const link = document.createElement("a");
    link.href = url;
    link.download = `kharcha-income-${data.fiscal_year.label.replace("/", "-")}.csv`;
    link.click();
    URL.revokeObjectURL(url);
  });

  const calendar = user.value?.calendar ?? "bs";
  const data = summary.value;

  return (
    <main>
      <div class="top">
        <div class="intro">
          <span class="eyebrow">
            FISCAL YEAR {data?.fiscal_year.label ?? ""}
          </span>
          <h1>Tax &amp; TDS</h1>
          <p>
            {data &&
              `${formatDate(data.fiscal_year.start, calendar)} – ${formatDate(data.fiscal_year.end, calendar)} · `}
            Track income, the tax cut from it, and what you may get back.
          </p>
        </div>
        {data && (
          <div class="actions">
            <button
              type="button"
              class="btn-secondary"
              onClick$={exportCsv}
              disabled={incomes.value.length === 0}
            >
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                aria-hidden="true"
              >
                <path d="M12 4v11M7 10l5 5 5-5M5 20h14" />
              </svg>
              Export CSV
            </button>
            <button
              type="button"
              class="btn-primary"
              onClick$={() => (adding.value = true)}
            >
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2.2"
                stroke-linecap="round"
                aria-hidden="true"
              >
                <path d="M12 5v14M5 12h14" />
              </svg>
              Add income
            </button>
          </div>
        )}
      </div>

      {status.value === "loading" && (
        <div class="card status" role="status">
          Loading your tax summary…
        </div>
      )}

      {status.value === "error" && (
        <div class="card status" role="alert">
          <p>Couldn’t load your tax summary. Try again.</p>
          <button type="button" class="btn-secondary" onClick$={load}>
            Try again
          </button>
        </div>
      )}

      {status.value === "ready" && data && (
        <>
          <section class="cards" aria-label="Tax summary">
            <div class="card result">
              <span class="card-label">
                {data.result >= 0 ? "You may get back" : "You may still owe"}
              </span>
              <span class="card-value number">
                {formatMoney(Math.round(Math.abs(data.result)))}
              </span>
              <span class="card-note">
                {data.result >= 0
                  ? "More TDS was cut than your estimated tax. Claim it when you file."
                  : "Your TDS so far won’t cover your estimated tax."}
              </span>
            </div>
            <div class="card">
              <span class="card-label">TDS cut from your income</span>
              <span class="card-value number">
                {formatMoney(Math.round(data.tds_so_far))}
              </span>
              <span class="card-note">
                So far this year
                {data.final_tds > 0 &&
                  ` · plus ${formatMoney(Math.round(data.final_tds))} final tax on interest and dividends`}
              </span>
            </div>
            <div class="card">
              <span class="card-label">Estimated tax for the year</span>
              <span class="card-value number">
                {formatMoney(Math.round(data.estimated_tax))}
              </span>
              <span class="card-note">
                On {formatMoney(Math.round(data.taxable_income))} projected
                income · {data.effective_rate.toFixed(1)}% effective
              </span>
            </div>
          </section>

          {notice.value && (
            <p class="field-error" role="alert">
              {notice.value}
            </p>
          )}

          <div class="content">
            <section class="card incomes" aria-labelledby="income-heading-list">
              <div class="section-head">
                <h2 id="income-heading-list">Income this year</h2>
                <span class="count">
                  {incomes.value.length}{" "}
                  {incomes.value.length === 1 ? "entry" : "entries"}
                </span>
              </div>
              {incomes.value.length === 0 ? (
                <p class="empty">
                  No income yet this fiscal year. Add your salary or a payment
                  to see your estimate.
                </p>
              ) : (
                <div class="scroll">
                  <table>
                    <thead>
                      <tr>
                        <th scope="col">Date</th>
                        <th scope="col">Source</th>
                        <th scope="col" class="right">
                          Gross
                        </th>
                        <th scope="col" class="right">
                          TDS
                        </th>
                        <th scope="col" class="right">
                          Received
                        </th>
                        <th scope="col">
                          <span class="visually-hidden">Actions</span>
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {incomes.value.map((income) => (
                        <tr key={income.id}>
                          <td class="date number">
                            {formatDate(income.date, calendar)}
                          </td>
                          <td>
                            <div class="source">
                              <strong>{income.title}</strong>
                              <span class="type">
                                {data.types[income.type].label}
                                {data.types[income.type].final && " · final"}
                              </span>
                            </div>
                          </td>
                          <td class="right number">
                            {income.amount.toLocaleString("en-IN")}
                          </td>
                          <td class="right">
                            <span class="tds number">
                              {income.tds_amount.toLocaleString("en-IN")}
                            </span>
                            <br />
                            <span class="small">
                              {rateText(data.types[income.type])}
                            </span>
                          </td>
                          <td class="right number received">
                            {(income.amount - income.tds_amount).toLocaleString(
                              "en-IN",
                            )}
                          </td>
                          <td class="right">
                            <button
                              type="button"
                              class="icon-btn delete"
                              aria-label={`Delete ${income.title}`}
                              onClick$={() => (deleting.value = income)}
                            >
                              <svg
                                width="18"
                                height="18"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="1.8"
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                aria-hidden="true"
                              >
                                <path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3" />
                              </svg>
                            </button>
                          </td>
                        </tr>
                      ))}
                      <tr class="total-row">
                        <td colSpan={2}>Total so far</td>
                        <td class="right number">
                          {data.totals.gross.toLocaleString("en-IN")}
                        </td>
                        <td class="right number tds">
                          {data.totals.tds.toLocaleString("en-IN")}
                        </td>
                        <td class="right number">
                          {data.totals.received.toLocaleString("en-IN")}
                        </td>
                        <td />
                      </tr>
                    </tbody>
                  </table>
                </div>
              )}
            </section>

            <div class="side">
              <section class="card" aria-labelledby="how-heading">
                <h2 id="how-heading">How we worked it out</h2>
                <div class="lines number">
                  <div class="line">
                    <span>Salary, projected for 12 months</span>
                    <span>{data.projected_salary.toLocaleString("en-IN")}</span>
                  </div>
                  <div class="line">
                    <span>Service fees and rent</span>
                    <span>{data.totals.other.toLocaleString("en-IN")}</span>
                  </div>
                  {data.totals.final > 0 && (
                    <div class="line">
                      <span>Interest and dividends (final tax)</span>
                      <span>not counted</span>
                    </div>
                  )}
                </div>
                <div class="slabs">
                  {data.slabs.map((slab) => {
                    const width =
                      slab.to === null
                        ? slab.taxable > 0
                          ? 100
                          : 0
                        : Math.round(
                            (slab.taxable / (slab.to - slab.from)) * 100,
                          );
                    return (
                      <div key={slab.from} class="slab">
                        <div class="slab-row">
                          <span>
                            {slabLabel(slab)}
                            {slab.waived && " (waived)"}
                          </span>
                          <span class="number">
                            {slab.taxable > 0
                              ? formatMoney(Math.round(slab.tax))
                              : "–"}
                          </span>
                        </div>
                        <div class="track">
                          <div class="fill" style={{ width: `${width}%` }} />
                        </div>
                      </div>
                    );
                  })}
                </div>
                <label class="ssf">
                  <input
                    type="checkbox"
                    checked={data.ssf_contributor}
                    onChange$={(_, el) => setSsf(el.checked)}
                  />
                  <span>
                    <strong>I contribute to SSF</strong>
                    <br />
                    <span class="small">
                      The 1% Social Security Tax is waived for SSF contributors.
                    </span>
                  </span>
                </label>
              </section>

              <section class="card" aria-labelledby="rates-heading">
                <h2 id="rates-heading">TDS rates used</h2>
                <div class="rates">
                  {Object.entries(data.types).map(([key, type]) => (
                    <div key={key} class="line">
                      <span>{type.label}</span>
                      <span class="number">
                        {type.rate === null ? "by slab" : rateText(type)}
                      </span>
                    </div>
                  ))}
                </div>
              </section>

              <p class="disclaimer">
                Estimate only, using FY {data.fiscal_year.label} slabs. It isn't
                tax advice. Check with a tax professional or the Inland Revenue
                Department before you file.
              </p>
            </div>
          </div>
        </>
      )}

      {adding.value && data && (
        <IncomeDialog
          types={data.types}
          onClose$={() => (adding.value = false)}
          onSaved$={async () => {
            adding.value = false;
            await load();
          }}
        />
      )}

      {deleting.value && (
        <ConfirmDialog
          title="Delete this income?"
          message={`“${deleting.value.title}” (${formatMoney(deleting.value.amount)}) will be deleted and your estimate updated.`}
          confirmLabel="Delete"
          onCancel$={() => (deleting.value = null)}
          onConfirm$={async () => {
            const income = deleting.value;
            deleting.value = null;
            if (!income) return;
            const res = await api.del(`/incomes/${income.id}`);
            if (!res.ok) {
              notice.value = `Couldn't delete "${income.title}". ${res.error.message}`;
              return;
            }
            await load();
          }}
        />
      )}
    </main>
  );
});

export const head: DocumentHead = {
  title: "Tax & TDS · Kharcha",
};
