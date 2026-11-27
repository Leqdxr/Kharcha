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

const TABS = [
  { href: "/expenses/", label: "Expenses" },
  { href: "/tax/", label: "Tax & TDS" },
  { href: "/udharo/", label: "Udharo" },
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
      flex-wrap: wrap;
      gap: 4px;
    }
    nav a {
      padding: 10px 14px;
      border-radius: 8px;
      color: #3d3835;
      text-decoration: none;
      font-size: 15px;
      font-weight: 500;
    }
    nav a:hover {
      background: var(--surface);
      color: #3d3835;
    }
    nav a[aria-current="page"] {
      background: var(--red-tint);
      color: var(--red-dark);
      font-weight: 600;
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
