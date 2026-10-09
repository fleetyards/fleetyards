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

  it("stops waiting once aborted", async () => {
    const limiter = createRsiRateLimiter(1);
    limiter.tryTake();

    const abort = new AbortController();
    let returned = false;
    void limiter.take(abort.signal).then(() => (returned = true));

    abort.abort();
    await vi.advanceTimersByTimeAsync(500);

    expect(returned).toBe(true);
    expect(limiter.tryTake()).toBe(false);
  });

  // A list crawl that used little of its budget must not hand the price pass
  // a burst above the limit.
  it("carries no unused budget over", async () => {
    const limiter = createRsiRateLimiter(2);

    await vi.advanceTimersByTimeAsync(180_000);

    expect(limiter.tryTake()).toBe(true);
    expect(limiter.tryTake()).toBe(true);
    expect(limiter.tryTake()).toBe(false);
  });
});
