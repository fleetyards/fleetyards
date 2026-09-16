import { describe, it, expect, beforeEach, vi } from "vitest";
import { createApp } from "vue";
import { setActivePinia, createPinia } from "pinia";
import piniaPluginPersistedstate from "pinia-plugin-persistedstate";
import { queryClient } from "@/frontend/plugins/QueryClient";
import { getMySupporterClaimKeyQueryKey, me } from "@/services/fyApi";
import { useSessionStore } from "./session";

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  me: vi.fn(),
  destroySession: vi.fn(() => Promise.resolve()),
}));

// The plugin only applies to stores created by a pinia an app has installed:
// `pinia.use` queues a plugin until then.
const activatePersistence = () => {
  const pinia = createPinia();
  pinia.use(piniaPluginPersistedstate);
  createApp({}).use(pinia);
  setActivePinia(pinia);
};

describe("session store", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    queryClient.clear();
    localStorage.clear();
    vi.mocked(me).mockReset();
  });

  // The query behind it is disabled once the session is gone, and a disabled
  // query keeps handing out whatever is cached.
  it("drops the cached supporter claim key on logout", async () => {
    queryClient.setQueryData(getMySupporterClaimKeyQueryKey(), {
      key: "FY-7K2M-9QXD",
    });

    await useSessionStore().logout();

    expect(
      queryClient.getQueryData(getMySupporterClaimKeyQueryKey()),
    ).toBeUndefined();
  });

  // Everything else reads `authenticated`, so a `currentUser` that outlives it
  // is a state nothing recovers from: the login page reads the leftover account
  // and renders every OAuth button connected, which means disabled.
  it("drops a persisted user that no session backs", () => {
    localStorage.setItem(
      "session",
      JSON.stringify({
        authenticated: false,
        currentUser: { username: "marten", authConnections: ["discord"] },
      }),
    );

    activatePersistence();

    expect(useSessionStore().currentUser).toBeUndefined();
  });

  it("keeps a persisted user the session still backs", () => {
    localStorage.setItem(
      "session",
      JSON.stringify({
        authenticated: true,
        currentUser: { username: "marten", authConnections: ["discord"] },
      }),
    );

    activatePersistence();

    expect(useSessionStore().currentUser?.username).toBe("marten");
  });

  // A 401 on a parallel request clears the session while this one is in flight.
  it("does not put the user back after the session was cleared", async () => {
    const store = useSessionStore();
    vi.mocked(me).mockImplementation(async () => {
      store.clearSession();

      return { username: "marten" } as Awaited<ReturnType<typeof me>>;
    });

    store.login({ username: "marten" } as Awaited<ReturnType<typeof me>>);
    await store.refreshUser();

    expect(store.currentUser).toBeUndefined();
  });
});
