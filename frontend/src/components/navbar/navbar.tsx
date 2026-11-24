import { $, component$, useSignal, useStylesScoped$ } from "@builder.io/qwik";
import { Link, useNavigate } from "@builder.io/qwik-city";
import { Logo } from "~/components/logo/logo";
import { api } from "~/lib/api";
import { clearAuth } from "~/lib/auth";
import type { User } from "~/lib/types";

// "Aagaman Koirala" -> "AK"
function initials(name: string): string {
  return name
    .split(/\s+/)
    .slice(0, 2)
    .map((word) => word[0]?.toUpperCase() ?? "")
    .join("");
}

// "Aagaman Koirala" -> "Aagaman K."
function shortName(name: string): string {
  const [first, last] = name.trim().split(/\s+/);
  return last ? `${first} ${last[0].toUpperCase()}.` : first;
}

type NavbarProps = {
  user: User | null;
};

export const Navbar = component$<NavbarProps>((props) => {
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
      justify-content: space-between;
      gap: 16px;
    }
    .left,
    .right {
      display: flex;
      align-items: center;
    }
    .left {
      gap: 32px;
    }
    .right {
      gap: 12px;
    }
    .nav-link {
      padding: 10px 14px;
      border-radius: 6px;
      background: var(--red-tint);
      color: var(--red-dark);
      text-decoration: none;
      font-weight: 600;
      font-size: 15px;
    }
    .avatar {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background: #eae5df;
      color: #5a544f;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 11px;
      font-weight: 600;
    }
    .name {
      font-size: 15px;
      font-weight: 500;
    }
    .logout {
      height: 44px;
      padding: 0 14px;
      font-size: 14px;
    }
  `);

  const nav = useNavigate();
  const loggingOut = useSignal(false);

  const logout = $(async () => {
    loggingOut.value = true;
    // Log out locally even if the server call fails.
    await api.post("/logout");
    clearAuth();
    await nav("/login");
  });

  return (
    <header>
      <div class="bar">
        <div class="left">
          <Logo />
          <nav aria-label="Main">
            <Link href="/expenses" class="nav-link" aria-current="page">
              Expenses
            </Link>
          </nav>
        </div>

        {props.user && (
          <div class="right">
            <span class="avatar" aria-hidden="true">
              {initials(props.user.name)}
            </span>
            <span class="name">{shortName(props.user.name)}</span>
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
