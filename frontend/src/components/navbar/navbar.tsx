import {
  $,
  component$,
  useSignal,
  useStylesScoped$,
  type Signal,
} from "@builder.io/qwik";
import { useNavigate } from "@builder.io/qwik-city";
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

type NavbarProps = {
  user: User | null;
  // Filters the expense list by title or note
  search: Signal<string>;
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
      gap: 16px 24px;
    }
    .search {
      position: relative;
      flex: 1 1 280px;
      max-width: 440px;
    }
    .search svg {
      position: absolute;
      left: 14px;
      top: 13px;
    }
    .search input {
      width: 100%;
      height: 44px;
      padding: 0 16px 0 42px;
      border: 1px solid var(--input-border);
      border-radius: 22px;
      background: var(--row-hover);
      color: var(--ink);
      font-size: 15px;
    }
    .search input:focus {
      outline: 2px solid var(--red);
      outline-offset: 1px;
    }
    .right {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-left: auto;
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
      .search {
        order: 1;
        flex-basis: 100%;
        max-width: none;
      }
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
        <Logo />

        <div class="search" role="search">
          <label for="search" class="visually-hidden">
            Search expenses
          </label>
          <svg
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="var(--muted)"
            stroke-width="2"
            stroke-linecap="round"
            aria-hidden="true"
          >
            <circle cx="11" cy="11" r="7" />
            <path d="M20 20l-3.5-3.5" />
          </svg>
          <input
            id="search"
            type="search"
            placeholder="Search by title or note"
            bind:value={props.search}
          />
        </div>

        {props.user && (
          <div class="right">
            <span class="avatar" aria-hidden="true">
              {initials(props.user.name)}
            </span>
            <span class="visually-hidden">Logged in as {props.user.name}</span>
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
