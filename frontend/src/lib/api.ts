import { clearAuth, getToken } from "./auth";

type ApiError = {
  message: string;
  // First validation message per field, e.g. { email: "The email has already been taken." }
  errors: Record<string, string>;
};

type ApiResult<T> =
  | { ok: true; data: T }
  | { ok: false; error: ApiError };

const API_URL: string = import.meta.env.PUBLIC_API_URL;

async function request<T>(
  method: string,
  path: string,
  body?: unknown,
): Promise<ApiResult<T>> {
  const token = getToken();
  const headers: Record<string, string> = {
    Accept: "application/json",
    "Content-Type": "application/json",
  };
  if (token) headers.Authorization = `Bearer ${token}`;

  let res: Response;
  try {
    res = await fetch(API_URL + path, {
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  } catch {
    return {
      ok: false,
      error: { message: "Couldn't reach the server. Try again.", errors: {} },
    };
  }

  // A 401 with a token means the session expired. Without a token
  // (e.g. a wrong password on /login) it's a normal error to show.
  if (res.status === 401 && token) {
    clearAuth();
    window.location.assign("/login");
  }

  const data = res.status === 204 ? null : await res.json().catch(() => null);

  if (!res.ok) {
    const errors: Record<string, string> = {};
    for (const [field, messages] of Object.entries(data?.errors ?? {})) {
      errors[field] = (messages as string[])[0];
    }
    return {
      ok: false,
      error: {
        message: data?.message ?? "Something went wrong. Try again.",
        errors,
      },
    };
  }

  return { ok: true, data: data as T };
}

export const api = {
  get: <T>(path: string) => request<T>("GET", path),
  post: <T>(path: string, body?: unknown) => request<T>("POST", path, body),
  put: <T>(path: string, body?: unknown) => request<T>("PUT", path, body),
  del: <T = null>(path: string) => request<T>("DELETE", path),
};
