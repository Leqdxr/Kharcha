import { createContextId, type Signal } from "@builder.io/qwik";
import type { User } from "./types";

// The logged-in user, provided by the logged-in layout (routes/(app)/layout.tsx).
// Pages inside that layout only render once it is loaded.
export const UserContext = createContextId<Signal<User | null>>("user");
