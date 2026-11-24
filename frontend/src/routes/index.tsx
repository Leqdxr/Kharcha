import { component$, useVisibleTask$ } from "@builder.io/qwik";
import { useNavigate } from "@builder.io/qwik-city";
import { getToken } from "~/lib/auth";

// "/" has no page of its own: it sends you to the right place.
export default component$(() => {
  const nav = useNavigate();

  // The token lives in localStorage, so this has to run in the browser.
  // eslint-disable-next-line qwik/no-use-visible-task
  useVisibleTask$(() => {
    nav(getToken() ? "/expenses" : "/login", { replaceState: true });
  });

  return null;
});
