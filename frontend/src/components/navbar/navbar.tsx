import {
  $,
  component$,
  useContext,
  useSignal,
  useStylesScoped$,
} from "@builder.io/qwik";
import { Link, useLocation, useNavigate } from "@builder.io/qwik-city";
import { Logo } from "~/components/logo/logo";
import { api } from "~/lib/api";
import { clearAuth, getToken, saveAuth } from "~/lib/auth";
import { initials } from "~/lib/format";
import type { Calendar, User } from "~/lib/types";
import { UserContext } from "~/lib/user-context";

// Each tab has its own icon (24px viewBox line icons), so they read as
// separate sections at a glance.
const TABS = [
  {
    href: "/expenses/",
    label: "Expenses",
    // Receipt
    icon: "M6 3h12v18l-3-2-3 2-3-2-3 2V3zM9 8h6M9 12h6M9 16h3",
  },
  {
    href: "/tax/",
    label: "Tax & TDS",
    // Percent sign in a document
    icon: "M6 3h9l4 4v14H6V3zM15 3v4h4M9.5 17.5l6-7M10 11h.01M15 17h.01",
  },
  {
    href: "/udharo/",
    label: "Udharo",
    // Arrows going both ways: lent and borrowed
    icon: "M4 8h14l-3-3M20 16H6l3 3",
  },
];

const CALENDARS: { value: Calendar; label: string }[] = [
  { value: "bs", label: "BS" },
  { value: "ad", label: "AD" },
];

// Header on every logged-in page: logo, tabs, BS/AD switch, avatar, log out.
export const Navbar = component$(() => {
  useStylesScoped$(`
    header {
      border-bottom: 1px solid var(--line);
    }
    .bar {
      max-width: 1200px;
      margin: 0 auto;
      padding: 14px 32px;
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 12px 28px;
    }
    nav {
      display: flex;
      gap: 4px;
      padding: 4px;
      border-radius: 12px;
      background: var(--surface);
    }
    /* The tabs are rendered by <Link>, which scoped styles don't reach
       without :global(). */
    nav :global(a) {
      height: 40px;
      padding: 0 14px;
      display: inline-flex;
      align-items: center;
      gap: 8px;
      border-radius: 8px;
      color: var(--muted);
      text-decoration: none;
      font-size: 15px;
      font-weight: 500;
      white-space: nowrap;
      transition:
        background 0.15s,
        color 0.15s;
    }
    nav :global(a:hover) {
      background: #ece8e3;
      color: var(--ink);
    }
    nav :global(a[aria-current="page"]) {
      position: relative;
      background: var(--white);
      color: var(--red-dark);
      font-weight: 600;
      box-shadow: 0 1px 3px rgba(27, 25, 24, 0.12);
    }
    /* A short red bar under the active tab */
    nav :global(a[aria-current="page"]::after) {
      content: "";
      position: absolute;
      left: 14px;
      right: 14px;
      bottom: 4px;
      height: 2px;
      border-radius: 1px;
      background: var(--red);
    }
    nav :global(a[aria-current="page"] svg) {
      color: var(--red);
    }
    .right {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-left: auto;
    }
    .calendar {
      display: flex;
      border: 1px solid var(--input-border);
      border-radius: 8px;
      overflow: hidden;
    }
    .calendar button {
      height: 36px;
      padding: 0 12px;
      border: 0;
      background: var(--white);
      color: #3d3835;
      font-size: 13px;
      cursor: pointer;
    }
    .calendar button[aria-pressed="true"] {
      background: var(--ink);
      color: var(--white);
      font-weight: 600;
    }
    .avatar {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background: var(--red-tint);
      color: var(--red-dark);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 13px;
      font-weight: 600;
    }
    .logout {
      height: 44px;
      padding: 0 14px;
      font-size: 14px;
    }
    @media (max-width: 480px) {
      .bar {
        padding: 12px 16px;
      }
      nav {
        order: 1;
        flex-basis: 100%;
      }
      nav :global(a) {
        flex: 1;
        justify-content: center;
        padding: 0 8px;
        font-size: 14px;
      }
    }
  `);

  const nav = useNavigate();
  const loc = useLocation();
  const user = useContext(UserContext);
  const loggingOut = useSignal(false);

  const logout = $(async () => {
    loggingOut.value = true;
    // Log out locally even if the server call fails.
    await api.post("/logout");
    clearAuth();
    await nav("/login");
  });

  // Switch at once, then save. Put it back if saving fails.
  const setCalendar = $(async (calendar: Calendar) => {
    const before = user.value;
    if (!before || before.calendar === calendar) return;
    user.value = { ...before, calendar };
    const res = await api.put<User>("/settings", { calendar });
    const token = getToken();
    if (res.ok && token) {
      saveAuth(token, res.data);
      user.value = res.data;
    } else if (!res.ok) {
      user.value = before;
    }
  });

  return (
    <header>
      <div class="bar">
        <Logo />

        <nav aria-label="Main">
          {TABS.map((tab) => (
            <Link
              key={tab.href}
              href={tab.href}
              aria-current={
                loc.url.pathname.startsWith(tab.href) ? "page" : undefined
              }
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
                <path d={tab.icon} />
              </svg>
              {tab.label}
            </Link>
          ))}
        </nav>

        {user.value && (
          <div class="right">
            <div class="calendar" role="group" aria-label="Date format">
              {CALENDARS.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  aria-pressed={user.value?.calendar === option.value}
                  onClick$={() => setCalendar(option.value)}
                >
                  {option.label}
                </button>
              ))}
            </div>
            <span class="avatar" aria-hidden="true">
              {initials(user.value.name)}
            </span>
            <span class="visually-hidden">Logged in as {user.value.name}</span>
            <button
              type="button"
              class="btn-secondary logout"
              onClick$={logout}
              disabled={loggingOut.value}
            >
              {loggingOut.value ? "Logging out…" : "Log out"}
            </button>
          </div>
        )}
      </div>
    </header>
  );
});
