import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createRsiRateLimiter } from "./RsiRateLimiter";

describe("createRsiRateLimiter", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("hands out the first minute's budget at once", () => {
    const limiter = createRsiRateLimiter(2);

    expect(limiter.tryTake()).toBe(true);
    expect(limiter.tryTake()).toBe(true);
    expect(limiter.tryTake()).toBe(false);
  });

  it("waits for the next minute once the budget is spent", async () => {
    const limiter = createRsiRateLimiter(1);
    limiter.tryTake();

    let taken = false;
    void limiter.take().then(() => (taken = true));

    await vi.advanceTimersByTimeAsync(59_000);
    expect(taken).toBe(false);

    await vi.advanceTimersByTimeAsync(1_500);
    expect(taken).toBe(true);
  });
});
