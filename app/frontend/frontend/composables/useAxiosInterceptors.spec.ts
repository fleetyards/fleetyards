import { createPinia, setActivePinia } from "pinia";
import { beforeEach, describe, expect, it, vi } from "vitest";

const destroySession = vi.fn(() => Promise.resolve());

vi.mock("@/services/fyApi", () => ({
  destroySession: () => destroySession(),
  me: vi.fn(),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ currentLocale: () => "en" }),
}));

import { useAxiosInterceptors } from "./useAxiosInterceptors";
import { useSessionStore } from "@/frontend/stores/session";
import { AXIOS_INSTANCE } from "@/services/axiosClient";

const respondWith = (status: number) => {
  AXIOS_INSTANCE.defaults.adapter = () =>
    Promise.reject({ response: { status } });
};

const signedIn = () => {
  const sessionStore = useSessionStore();
  sessionStore.login({ id: "user-1", username: "torlek" } as never);

  return sessionStore;
};

describe("useAxiosInterceptors", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    destroySession.mockClear();
    AXIOS_INSTANCE.interceptors.request.clear();
    AXIOS_INSTANCE.interceptors.response.clear();
    useAxiosInterceptors();
  });

  it("drops the local session on a 401 without signing out on the server", async () => {
    const sessionStore = signedIn();
    respondWith(401);

    await expect(AXIOS_INSTANCE.get("/models")).rejects.toBeDefined();

    expect(sessionStore.isAuthenticated).toBe(false);
    expect(sessionStore.currentUser).toBeUndefined();
    // Signing out here would spend the remember-me cookie: DELETE /sessions
    // authenticates with it and then deletes it.
    expect(destroySession).not.toHaveBeenCalled();
  });

  it("leaves the session alone for other errors", async () => {
    const sessionStore = signedIn();
    respondWith(500);

    await expect(AXIOS_INSTANCE.get("/models")).rejects.toBeDefined();

    expect(sessionStore.isAuthenticated).toBe(true);
  });

  it("still signs out on the server when the user asks to log out", async () => {
    const sessionStore = signedIn();

    await sessionStore.logout();

    expect(sessionStore.isAuthenticated).toBe(false);
    expect(destroySession).toHaveBeenCalledOnce();
  });
});
