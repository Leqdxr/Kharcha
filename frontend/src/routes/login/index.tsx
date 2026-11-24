import {
  $,
  component$,
  useSignal,
  useStylesScoped$,
  useVisibleTask$,
} from "@builder.io/qwik";
import { Link, useNavigate, type DocumentHead } from "@builder.io/qwik-city";
import { FieldError, TextField } from "~/components/field/field";
import { Logo } from "~/components/logo/logo";
import { api } from "~/lib/api";
import { getToken, saveAuth } from "~/lib/auth";
import type { AuthResponse } from "~/lib/types";
import authStyles from "~/styles/auth.css?inline";

export default component$(() => {
  useStylesScoped$(authStyles);
  useStylesScoped$(`
    .panel {
      background: var(--surface);
    }
    .panel img {
      max-width: 520px;
    }
    .intro {
      max-width: 420px;
      padding: 24px 28px;
      border-radius: 8px;
      background: var(--white);
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .eyebrow {
      font-family: var(--font-mono);
      font-size: 12px;
      font-weight: 600;
      letter-spacing: 0.06em;
      color: var(--red);
    }
    .intro-title {
      margin: 0;
      font-size: 26px;
      line-height: 1.25;
      font-weight: 600;
      letter-spacing: -0.01em;
    }
    .intro-text {
      margin: 0;
      font-size: 15px;
      line-height: 1.5;
      color: var(--muted);
    }
  `);

  const nav = useNavigate();
  const email = useSignal("");
  const password = useSignal("");
  const loading = useSignal(false);
  const errors = useSignal<Record<string, string>>({});
  const message = useSignal("");

  // Already logged in? Skip the form.
  // eslint-disable-next-line qwik/no-use-visible-task
  useVisibleTask$(() => {
    if (getToken()) nav("/expenses", { replaceState: true });
  });

  const submit = $(async () => {
    loading.value = true;
    errors.value = {};
    message.value = "";

    const res = await api.post<AuthResponse>("/login", {
      email: email.value,
      password: password.value,
    });

    if (res.ok) {
      saveAuth(res.data.token, res.data.user);
      await nav("/expenses");
      return;
    }

    loading.value = false;
    errors.value = res.error.errors;
    // Field errors show under their inputs; anything else (like a wrong password) shows above the button.
    if (Object.keys(res.error.errors).length === 0) {
      message.value = res.error.message;
    }
  });

  return (
    <div class="page">
      <aside class="panel">
        <Logo />
        <img
          src="/images/login.svg"
          alt="Two cats standing on either side of the word WELCOME"
          width={889}
          height={459}
        />
        <div class="intro">
          <span class="eyebrow">YOUR MONEY, IN ONE LIST</span>
          <p class="intro-title">Know where every rupee goes.</p>
          <p class="intro-text">
            Write down what you spend. See your total for the month at a
            glance.
          </p>
        </div>
      </aside>

      <main class="form-side">
        <form preventdefault:submit onSubmit$={submit} noValidate>
          <div class="heading">
            <h1>Welcome back</h1>
            <p class="subtitle">Log in to see this month’s spending.</p>
          </div>

          <div class="fields">
            <TextField
              id="login-email"
              label="Email"
              type="email"
              placeholder="you@example.com"
              autoComplete="email"
              value={email}
              error={errors.value.email}
            />
            <TextField
              id="login-password"
              label="Password"
              type="password"
              placeholder="At least 8 characters"
              autoComplete="current-password"
              value={password}
              error={errors.value.password}
            />
            <FieldError id="login-error" message={message.value} />
          </div>

          <button
            type="submit"
            class="btn-primary"
            disabled={loading.value}
            aria-busy={loading.value}
          >
            {loading.value ? "Logging in…" : "Log in"}
          </button>

          <p class="switch">
            New here? <Link href="/register">Create an account</Link>
          </p>
        </form>
      </main>
    </div>
  );
});

export const head: DocumentHead = {
  title: "Log in · Kharcha",
};
