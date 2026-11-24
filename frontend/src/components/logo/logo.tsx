import { component$, useStylesScoped$ } from "@builder.io/qwik";

export const Logo = component$(() => {
  useStylesScoped$(`
    .logo {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .mark {
      width: 32px;
      height: 32px;
      border-radius: 6px;
      background: var(--red);
      color: var(--white);
      display: flex;
      align-items: center;
      justify-content: center;
      font-family: var(--font-mono);
      font-weight: 600;
      font-size: 16px;
    }
    .name {
      font-weight: 700;
      font-size: 20px;
      letter-spacing: -0.01em;
    }
  `);

  return (
    <div class="logo">
      <span class="mark" aria-hidden="true">
        K
      </span>
      <span class="name">Kharcha</span>
    </div>
  );
});
