import { describe, it, expect, beforeEach, vi } from "vitest";
import { createApp } from "vue";
import { setActivePinia, createPinia } from "pinia";
import piniaPluginPersistedstate from "pinia-plugin-persistedstate";
import { queryClient } from "@/frontend/plugins/QueryClient";
import {
  getFleetRsiVerificationQueryKey,
  getMyRsiVerificationQueryKey,
  getMySupporterClaimKeyQueryKey,
  destroySession,
  me,
} from "@/services/fyApi";
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

  // What a text's contract, event and user tokens resolve to is the reader's
  // own answer, which the next one in the same tab must not inherit.
  it("forgets the resolved tokens on login and on logout", async () => {
    const key = ["catalogueLookup", ["user:mortik"]];
    const answer = { items: [{ token: "user:mortik", type: "User" }] };
    const user = { username: "mortik" } as Parameters<
      ReturnType<typeof useSessionStore>["login"]
    >[0];

    queryClient.setQueryData(key, answer);
    useSessionStore().login(user);

    expect(queryClient.getQueryData(key)).toBeUndefined();

    queryClient.setQueryData(key, answer);
    await useSessionStore().logout();

    expect(queryClient.getQueryData(key)).toBeUndefined();
  });

  // The reset on clearing the session can refetch under the cookie logout is
  // about to destroy, so the lookup is asked again once it is gone.
  it("asks for the resolved tokens again after the session is destroyed", async () => {
    const order: string[] = [];
    vi.mocked(destroySession).mockImplementationOnce(async () => {
      order.push("destroySession");

      return { code: "success", message: "" };
    });
    const reset = vi
      .spyOn(queryClient, "resetQueries")
      .mockImplementation(async (filters) => {
        if (
          filters &&
          "queryKey" in filters &&
          filters.queryKey?.[0] === "catalogueLookup"
        ) {
          order.push("reset");
        }
      });

    await useSessionStore().logout();

    expect(order.at(-1)).toBe("reset");
    expect(order).toContain("destroySession");
    reset.mockRestore();
  });

  it("drops the reader's cached verification token on logout", async () => {
    queryClient.setQueryData(getMyRsiVerificationQueryKey(), {
      token: "FLEETYARDS-ABCDEFGHIJ",
    });

    await useSessionStore().logout();

    expect(
      queryClient.getQueryData(getMyRsiVerificationQueryKey()),
    ).toBeUndefined();
  });

  it("drops a fleet's cached verification token on logout", async () => {
    queryClient.setQueryData(getFleetRsiVerificationQueryKey("maru"), {
      token: "FLEETYARDS-ABCDEFGHIJ",
    });

    await useSessionStore().logout();

    expect(
      queryClient.getQueryData(getFleetRsiVerificationQueryKey("maru")),
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

  // Sign out and back in -- a shared machine, a second account -- while a
  // refresh for the first account is still in flight. `authenticated` is true
  // again by the time it answers, so the boolean alone cannot tell the two
  // sessions apart: it would hand the account now signed in the profile,
  // connections and access of the one before it.
  it("does not hand a new session the account before it", async () => {
    const store = useSessionStore();
    store.login({
      id: "a",
      username: "marten",
    } as Awaited<ReturnType<typeof me>>);

    vi.mocked(me).mockImplementation(async () => {
      store.clearSession();
      store.login({
        id: "b",
        username: "gustav",
      } as Awaited<ReturnType<typeof me>>);

      return { id: "a", username: "marten" } as Awaited<ReturnType<typeof me>>;
    });

    await store.refreshUser();

    expect(store.currentUser?.username).toBe("gustav");
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
