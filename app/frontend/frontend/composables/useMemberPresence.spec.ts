import { describe, expect, it, beforeEach, vi } from "vitest";
import { usePresence } from "@/shared/composables/usePresence";

const flagEnabled = { value: true };

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({
    isFeatureEnabled: () => flagEnabled.value,
  }),
}));

const { useMemberPresence } = await import("./useMemberPresence");

const USER = "11111111-1111-1111-1111-111111111111";

beforeEach(() => {
  flagEnabled.value = true;
  usePresence().resetPresence();
});

describe("useMemberPresence", () => {
  it("draws no dot for a row the API declined to answer for", () => {
    expect(useMemberPresence().onlineFor({ userId: USER })).toBeUndefined();
  });

  it("draws no dot with the flag off, whatever the row says", () => {
    flagEnabled.value = false;

    expect(
      useMemberPresence().onlineFor({ userId: USER, online: true }),
    ).toBeUndefined();
  });

  it("reads the payload until a transition arrives", () => {
    const { onlineFor } = useMemberPresence();

    expect(onlineFor({ userId: USER, online: true })).toBe(true);

    usePresence().applyPresence({ userId: USER, online: false });

    expect(onlineFor({ userId: USER, online: true })).toBe(false);
  });

  it("takes the timestamp a transition carried", () => {
    const { lastActiveAtFor } = useMemberPresence();

    usePresence().applyPresence({
      userId: USER,
      online: false,
      lastActiveAt: "2026-09-20T12:00:00Z",
    });

    expect(
      lastActiveAtFor({ userId: USER, lastActiveAt: "2026-09-20T10:00:00Z" }),
    ).toBe("2026-09-20T12:00:00Z");
  });
});
