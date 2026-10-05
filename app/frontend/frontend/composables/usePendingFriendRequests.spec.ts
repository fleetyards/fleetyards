import { describe, expect, it, vi, beforeEach } from "vitest";

const pendingCount = ref<{ count: number } | undefined>(undefined);
const queryOptions = vi.fn();

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useFriendsPendingCount: (options: unknown) => {
    queryOptions(options);

    return { data: pendingCount };
  },
}));

const authenticated = ref(true);

vi.mock("@/frontend/stores/session", () => ({
  useSessionStore: () => ({
    get isAuthenticated() {
      return authenticated.value;
    },
  }),
}));

import { usePendingFriendRequests } from "./usePendingFriendRequests";

describe("usePendingFriendRequests", () => {
  beforeEach(() => {
    pendingCount.value = { count: 3 };
    authenticated.value = true;
    queryOptions.mockClear();
  });

  it("counts what is waiting", () => {
    expect(usePendingFriendRequests().count.value).toBe(3);
  });

  it("asks for nothing when nobody is signed in", () => {
    authenticated.value = false;
    const { count } = usePendingFriendRequests();

    expect(count.value).toBe(0);
    expect(queryOptions.mock.calls[0][0].query.enabled.value).toBe(false);
  });

  it("reads as empty before the first answer", () => {
    pendingCount.value = undefined;

    expect(usePendingFriendRequests().count.value).toBe(0);
  });
});
