import {
  $,
  component$,
  useContext,
  useSignal,
  useStylesScoped$,
  useVisibleTask$,
} from "@builder.io/qwik";
import type { DocumentHead } from "@builder.io/qwik-city";
import { SplitBill } from "~/components/split-bill/split-bill";
import { UdharoForm } from "~/components/udharo-form/udharo-form";
import { api } from "~/lib/api";
import { formatDate, formatMoney, initials } from "~/lib/format";
import type { Udharo } from "~/lib/types";
import { UserContext } from "~/lib/user-context";

const TOAST_MS = 5000;

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
    .intro {
      display: flex;
      flex-direction: column;
      gap: 6px;
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
    .number {
      font-variant-numeric: tabular-nums;
    }
    .cards {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 16px;
    }
    .cards .card {
      border-radius: 12px;
      padding: 22px;
      display: flex;
      flex-direction: column;
      gap: 6px;
    }
    .card-label {
      font-size: 14px;
      font-weight: 500;
      color: var(--muted);
    }
    .card-value {
      font-size: 28px;
      font-weight: 600;
    }
    .owe {
      color: var(--red-dark);
    }
    .cards .net {
      border-color: var(--ink);
      background: var(--ink);
      color: var(--white);
    }
    .net .card-label {
      color: var(--input-border);
    }
    .content {
      display: flex;
      flex-wrap: wrap;
      gap: 24px;
      align-items: flex-start;
    }
    .lists {
      flex: 999 1 560px;
      min-width: 0;
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .list {
      border-radius: 12px;
      overflow: hidden;
    }
    .list-head {
      padding: 14px 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      background: var(--row-hover);
      border-bottom: 1px solid var(--line);
    }
    h2 {
      margin: 0;
      font-size: 16px;
      font-weight: 700;
    }
    .list-total {
      font-size: 14px;
      font-weight: 600;
    }
    .empty {
      margin: 0;
      padding: 24px 20px;
      color: var(--muted);
      font-size: 15px;
    }
    ul {
      margin: 0;
      padding: 0;
      list-style: none;
    }
    li {
      display: flex;
      align-items: center;
      gap: 14px;
      padding: 14px 16px 14px 20px;
      border-bottom: 1px solid #efece8;
    }
    li:last-child {
      border-bottom: 0;
    }
    .initials {
      width: 44px;
      height: 44px;
      flex: none;
      border-radius: 50%;
      background: var(--surface);
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 600;
      font-size: 14px;
      color: #3d3835;
    }
    .text {
      flex: 1;
      min-width: 0;
      display: flex;
      flex-direction: column;
      gap: 2px;
    }
    .name {
      font-weight: 600;
      font-size: 15px;
      overflow-wrap: anywhere;
    }
    .sub {
      font-size: 13px;
      color: var(--muted);
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .amount {
      font-weight: 600;
      font-size: 16px;
      white-space: nowrap;
    }
    .settle {
      flex: none;
      height: 40px;
      padding: 0 16px;
      font-size: 14px;
    }
    .toast {
      position: fixed;
      left: 50%;
      bottom: 24px;
      z-index: 20;
      transform: translateX(-50%);
      width: min(560px, calc(100% - 32px));
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      padding: 12px 12px 12px 18px;
      border-radius: 10px;
      background: var(--ink);
      color: var(--white);
      font-size: 15px;
      box-shadow: 0 12px 30px rgba(0, 0, 0, 0.25);
    }
    .toast button {
      flex: none;
      height: 36px;
      padding: 0 14px;
      border: 0;
      border-radius: 6px;
      background: var(--white);
      color: var(--ink);
      font-weight: 600;
      font-size: 14px;
      cursor: pointer;
    }
    .side {
      flex: 1 1 340px;
      display: flex;
      flex-direction: column;
      gap: 16px;
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
      li {
        gap: 10px;
        padding: 12px;
      }
      .initials {
        display: none;
      }
    }
  `);

  const user = useContext(UserContext);
  const udharos = useSignal<Udharo[]>([]);
  const status = useSignal<"loading" | "ready" | "error">("loading");
  const notice = useSignal("");
  // The entry just settled, while its Undo toast shows
  const settled = useSignal<Udharo | null>(null);

  const load = $(async () => {
    const res = await api.get<Udharo[]>("/udharos");
    if (res.ok) {
      udharos.value = res.data;
      status.value = "ready";
    } else {
      status.value = "error";
    }
  });

  // eslint-disable-next-line qwik/no-use-visible-task
  useVisibleTask$(async () => {
    await load();
  });

  const settle = $(async (udharo: Udharo) => {
    notice.value = "";
    const res = await api.post(`/udharos/${udharo.id}/settle`);
    if (!res.ok) {
      notice.value = `Couldn't settle with ${udharo.person}. ${res.error.message}`;
      return;
    }
    udharos.value = udharos.value.filter((u) => u.id !== udharo.id);
    settled.value = udharo;
    setTimeout(() => {
      // A newer settle has its own toast; leave that one.
      if (settled.value?.id === udharo.id) settled.value = null;
    }, TOAST_MS);
  });

  const undo = $(async () => {
    const udharo = settled.value;
    settled.value = null;
    if (!udharo) return;
    const res = await api.post(`/udharos/${udharo.id}/unsettle`);
    if (!res.ok) {
      notice.value = `Couldn't undo. ${res.error.message}`;
      return;
    }
    await load();
  });

  const calendar = user.value?.calendar ?? "bs";
  const sum = (list: Udharo[]) => list.reduce((s, u) => s + u.amount, 0);
  const owesYou = udharos.value.filter((u) => u.direction === "lent");
  const youOwe = udharos.value.filter((u) => u.direction === "borrowed");
  const net = sum(owesYou) - sum(youOwe);
  const sections = [
    { title: "They owe you", items: owesYou },
    { title: "You owe", items: youOwe },
  ];

  return (
    <main>
      <div class="intro">
        <h1>Udharo</h1>
        <p>Money you lent to friends and money you borrowed, in one place.</p>
      </div>

      {status.value === "loading" && (
        <div class="card status" role="status">
          Loading udharo…
        </div>
      )}

      {status.value === "error" && (
        <div class="card status" role="alert">
          <p>Couldn’t load udharo. Try again.</p>
          <button type="button" class="btn-secondary" onClick$={load}>
            Try again
          </button>
        </div>
      )}

      {status.value === "ready" && (
        <>
          <section class="cards" aria-label="Udharo summary">
            <div class="card">
              <span class="card-label">Friends owe you</span>
              <span class="card-value number">{formatMoney(sum(owesYou))}</span>
            </div>
            <div class="card">
              <span class="card-label">You owe</span>
              <span class="card-value number owe">
                {formatMoney(sum(youOwe))}
              </span>
            </div>
            <div class="card net">
              <span class="card-label">If everyone settled today</span>
              <span class="card-value number">
                {net >= 0 ? "+ " : "− "}
                {formatMoney(Math.abs(net))}
              </span>
            </div>
          </section>

          {notice.value && (
            <p class="field-error" role="alert">
              {notice.value}
            </p>
          )}

          <div class="content">
            <div class="lists">
              {sections.map((section) => (
                <section
                  key={section.title}
                  class="card list"
                  aria-label={section.title}
                >
                  <div class="list-head">
                    <h2>{section.title}</h2>
                    <span class="list-total number">
                      {formatMoney(sum(section.items))}
                    </span>
                  </div>
                  {section.items.length === 0 ? (
                    <p class="empty">All settled. Nothing here.</p>
                  ) : (
                    <ul>
                      {section.items.map((udharo) => (
                        <li key={udharo.id}>
                          <span class="initials" aria-hidden="true">
                            {initials(udharo.person)}
                          </span>
                          <div class="text">
                            <span class="name">{udharo.person}</span>
                            <span class="sub">
                              {udharo.note
                                ? `${udharo.note} · since `
                                : "Since "}
                              {formatDate(udharo.date, calendar, false)}
                            </span>
                          </div>
                          <span class="amount number">
                            {formatMoney(udharo.amount)}
                          </span>
                          <button
                            type="button"
                            class="btn-primary settle"
                            aria-label={`Settle with ${udharo.person}`}
                            onClick$={() => settle(udharo)}
                          >
                            Settle
                          </button>
                        </li>
                      ))}
                    </ul>
                  )}
                </section>
              ))}
            </div>

            <div class="side">
              <UdharoForm
                onAdded$={(udharo) => {
                  udharos.value = [udharo, ...udharos.value];
                }}
              />
              <SplitBill onSplit$={load} />
            </div>
          </div>
        </>
      )}

      {settled.value && (
        <div class="toast" role="status">
          <span>Settled with {settled.value.person.split(" ")[0]}.</span>
          <button type="button" onClick$={undo}>
            Undo
          </button>
        </div>
      )}
    </main>
  );
});

export const head: DocumentHead = {
  title: "Udharo · Kharcha",
};
