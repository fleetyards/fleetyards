import { describe, it, expect, beforeEach, vi } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import { me } from "@/services/fyApi";
import { useAppStore } from "./app";
import { useSessionStore } from "./session";

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  me: vi.fn(),
}));

describe("app store", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.mocked(me).mockReset();
  });

  // A store-version bump resets everything, and a refresh already in flight
  // would land behind it -- writing currentUser next to authenticated: false,
  // which is the state a signed-out visitor reads as a signed-in account.
  it("drops an in-flight refresh when it hard-resets the session", async () => {
    const sessionStore = useSessionStore();
    sessionStore.login({
      id: "a",
      username: "marten",
    } as Awaited<ReturnType<typeof me>>);

    vi.mocked(me).mockImplementation(async () => {
      useAppStore().resetAll(true);

      return { id: "a", username: "marten" } as Awaited<ReturnType<typeof me>>;
    });

    await sessionStore.refreshUser();

    expect(sessionStore.authenticated).toBe(false);
    expect(sessionStore.currentUser).toBeUndefined();
  });
});
