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
      background: var(--red-tint);
    }
    .panel img {
      max-width: 440px;
    }
    .tag {
      align-self: flex-end;
      font-variant-numeric: tabular-nums;
      font-size: 12px;
      font-weight: 600;
      letter-spacing: 0.06em;
      color: var(--red-dark);
    }
    .steps {
      max-width: 420px;
      margin: 0;
      padding: 0;
      list-style: none;
      display: flex;
      flex-direction: column;
      gap: 14px;
    }
    .steps li {
      display: flex;
      align-items: baseline;
      gap: 14px;
      font-size: 17px;
      line-height: 1.4;
    }
    .step-number {
      font-variant-numeric: tabular-nums;
      font-size: 13px;
      color: var(--red);
    }
    .row {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 16px;
    }
  `);

  const nav = useNavigate();
  const name = useSignal("");
  const email = useSignal("");
  const password = useSignal("");
  const passwordConfirmation = useSignal("");
  const loading = useSignal(false);
  const errors = useSignal<Record<string, string>>({});
  const message = useSignal("");

  // Already logged in? Skip the form.
  // eslint-disable-next-line qwik/no-use-visible-task
  useVisibleTask$(() => {
    if (getToken()) nav("/expenses", { replaceState: true });
  });

  const submit = $(async () => {
    errors.value = {};
    message.value = "";

    if (password.value !== passwordConfirmation.value) {
      errors.value = { password_confirmation: "Passwords don’t match." };
      return;
    }

    loading.value = true;
    const res = await api.post<AuthResponse>("/register", {
      name: name.value,
      email: email.value,
      password: password.value,
      password_confirmation: passwordConfirmation.value,
    });

    if (res.ok) {
      saveAuth(res.data.token, res.data.user);
      await nav("/expenses");
      return;
    }

    loading.value = false;
    errors.value = res.error.errors;
    if (Object.keys(res.error.errors).length === 0) {
      message.value = res.error.message;
    }
  });

  return (
    <div class="page">
      <main class="form-side">
        <form preventdefault:submit onSubmit$={submit} noValidate>
          <Logo />

          <div class="heading">
            <h1>Create your account</h1>
            <p class="subtitle">It takes less than a minute.</p>
          </div>

          <div class="fields">
            <TextField
              id="reg-name"
              label="Full name"
              placeholder="Your name"
              autoComplete="name"
              value={name}
              error={errors.value.name}
            />
            <TextField
              id="reg-email"
              label="Email"
              type="email"
              placeholder="you@example.com"
              autoComplete="email"
              value={email}
              error={errors.value.email}
            />
            <div class="row">
              <TextField
                id="reg-pass"
                label="Password"
                type="password"
                placeholder="8+ characters"
                autoComplete="new-password"
                value={password}
                error={errors.value.password}
              />
              <TextField
                id="reg-pass2"
                label="Confirm password"
                type="password"
                placeholder="Type it again"
                autoComplete="new-password"
                value={passwordConfirmation}
                error={errors.value.password_confirmation}
              />
            </div>
            <FieldError id="register-error" message={message.value} />
          </div>

          <button
            type="submit"
            class="btn-primary"
            disabled={loading.value}
            aria-busy={loading.value}
          >
            {loading.value ? "Creating account…" : "Create account"}
          </button>

          <p class="switch">
            Already have an account? <Link href="/login">Log in</Link>
          </p>
        </form>
      </main>

      <aside class="panel">
        <span class="tag">NEW ACCOUNT</span>
        <img
          src="/images/register.svg"
          alt="A person standing next to a large sign-up form"
          width={551}
          height={412}
        />
        <ul class="steps">
          <li>
            <span class="step-number">01</span>
            <span>Add an expense in three fields.</span>
          </li>
          <li>
            <span class="step-number">02</span>
            <span>Edit or delete anything later.</span>
          </li>
          <li>
            <span class="step-number">03</span>
            <span>See your monthly total, always up to date.</span>
          </li>
        </ul>
      </aside>
    </div>
  );
});

export const head: DocumentHead = {
  title: "Create account · Kharcha",
};
