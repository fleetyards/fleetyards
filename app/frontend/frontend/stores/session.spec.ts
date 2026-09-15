import { describe, it, expect, beforeEach, vi } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import { queryClient } from "@/frontend/plugins/QueryClient";
import { getMySupporterClaimKeyQueryKey } from "@/services/fyApi";
import { useSessionStore } from "./session";

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  me: vi.fn(),
  destroySession: vi.fn(() => Promise.resolve()),
}));

describe("session store", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    queryClient.clear();
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
});
