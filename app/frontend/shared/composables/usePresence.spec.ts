import { describe, expect, it, beforeEach } from "vitest";
import { usePresence } from "./usePresence";

const USER = "11111111-1111-1111-1111-111111111111";
const OTHER = "22222222-2222-2222-2222-222222222222";

beforeEach(() => {
  usePresence().resetPresence();
});

describe("usePresence", () => {
  it("falls back to the payload the page arrived with", () => {
    const { isOnline, lastActiveAt } = usePresence();

    expect(isOnline(USER, true)).toBe(true);
    expect(lastActiveAt(USER, "2026-09-20T10:00:00Z")).toBe(
      "2026-09-20T10:00:00Z",
    );
  });

  it("lets a transition win over the payload", () => {
    const { applyPresence, isOnline, lastActiveAt } = usePresence();

    applyPresence({
      userId: USER,
      online: false,
      lastActiveAt: "2026-09-20T12:00:00Z",
    });

    expect(isOnline(USER, true)).toBe(false);
    expect(lastActiveAt(USER, "2026-09-20T10:00:00Z")).toBe(
      "2026-09-20T12:00:00Z",
    );
  });

  it("keeps the payload's timestamp when the transition carries none", () => {
    const { applyPresence, lastActiveAt } = usePresence();

    applyPresence({ userId: USER, online: true, lastActiveAt: null });

    expect(lastActiveAt(USER, "2026-09-20T10:00:00Z")).toBe(
      "2026-09-20T10:00:00Z",
    );
  });

  it("answers for the user it was told about and nobody else", () => {
    const { applyPresence, isOnline } = usePresence();

    applyPresence({ userId: USER, online: true });

    expect(isOnline(USER, false)).toBe(true);
    expect(isOnline(OTHER, false)).toBe(false);
  });

  it("reads offline for a user nothing knows about", () => {
    expect(usePresence().isOnline(USER)).toBe(false);
    expect(usePresence().isOnline(undefined)).toBe(false);
  });

  it("drops everything it held on a reset", () => {
    const { applyPresence, resetPresence, isOnline } = usePresence();

    applyPresence({ userId: USER, online: false });
    resetPresence();

    expect(isOnline(USER, true)).toBe(true);
  });

  it("is one map for every caller", () => {
    usePresence().applyPresence({ userId: USER, online: true });

    expect(usePresence().isOnline(USER, false)).toBe(true);
  });
});
