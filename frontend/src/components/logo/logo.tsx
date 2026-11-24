import { component$, useStylesScoped$ } from "@builder.io/qwik";

export const Logo = component$(() => {
  useStylesScoped$(`
    .logo {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .name {
      font-weight: 700;
      font-size: 20px;
      letter-spacing: -0.01em;
    }
  `);

  return (
    <div class="logo">
      <svg
        width="30"
        height="30"
        viewBox="0 0 24 24"
        fill="none"
        stroke="#B42318"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
        aria-hidden="true"
      >
        <path d="M11 17h3v2a1 1 0 0 0 1 1h2a1 1 0 0 0 1-1v-3a3.16 3.16 0 0 0 2-2h1a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1h-1a5 5 0 0 0-2-4V3a4 4 0 0 0-3.2 1.6l-.3.4H11a6 6 0 0 0-6 6v1a5 5 0 0 0 2 4v3a1 1 0 0 0 1 1h2a1 1 0 0 0 1-1z" />
        <path d="M16 10h.01" />
        <path d="M2 8v1a2 2 0 0 0 2 2h1" />
      </svg>
      <span class="name">Kharcha</span>
    </div>
  );
});
