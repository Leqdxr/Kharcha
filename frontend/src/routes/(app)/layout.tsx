import {
  component$,
  Slot,
  useContextProvider,
  useSignal,
  useVisibleTask$,
} from "@builder.io/qwik";
import { useNavigate } from "@builder.io/qwik-city";
import { Navbar } from "~/components/navbar/navbar";
import { api } from "~/lib/api";
import { getToken, getUser, saveAuth } from "~/lib/auth";
import type { User } from "~/lib/types";
import { UserContext } from "~/lib/user-context";

// Every logged-in page: checks the token, loads the user (with their
// settings) and shows the header with the tabs.
export default component$(() => {
  const nav = useNavigate();
  const user = useSignal<User | null>(null);
  useContextProvider(UserContext, user);

  // The token lives in localStorage, so this has to run in the browser.
  // eslint-disable-next-line qwik/no-use-visible-task
  useVisibleTask$(async () => {
    const token = getToken();
    if (!token) {
      await nav("/login", { replaceState: true });
      return;
    }
    const res = await api.get<User>("/user");
    if (res.ok) {
      saveAuth(token, res.data);
      user.value = res.data;
    } else {
      // Offline: fall back to the copy saved at login.
      user.value = getUser();
    }
  });

  return (
    <>
      <Navbar />
      {user.value && <Slot />}
    </>
  );
});
