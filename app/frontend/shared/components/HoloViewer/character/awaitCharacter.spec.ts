import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { awaitCharacter } from "./awaitCharacter";

const deferred = () => {
  let resolve!: (dressed: boolean) => void;
  let reject!: (error: Error) => void;
  const promise = new Promise<boolean>((res, rej) => {
    resolve = res;
    reject = rej;
  });

  return { promise, resolve, reject };
};

describe("awaitCharacter", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  const run = (
    loads: (Promise<boolean> | undefined)[],
    { stopped = () => false }: { stopped?: () => boolean } = {},
  ) => {
    const redress = vi.fn(() => Promise.resolve());
    let current = 0;
    const pending = () => loads[current];
    const result = awaitCharacter({
      pending,
      redress,
      stopped,
      timeout: 1000,
    }).then((inTime) => ({ inTime, redress }));

    return { result, next: () => (current += 1) };
  };

  it("does not wait without a character on its way", async () => {
    const { result } = run([undefined]);

    await expect(result).resolves.toMatchObject({ inTime: true });
  });

  it("waits until the figure is dressed in the character", async () => {
    const load = deferred();
    const { result, next } = run([load.promise, undefined]);
    let settled = false;
    void result.then(() => (settled = true));

    await vi.advanceTimersByTimeAsync(500);
    expect(settled).toBe(false);

    next();
    load.resolve(true);

    const { inTime, redress } = await result;
    expect(inTime).toBe(true);
    expect(redress).not.toHaveBeenCalled();
  });

  it("dresses the figure again when its own dressing was overtaken", async () => {
    const load = deferred();
    const { result, next } = run([load.promise, undefined]);

    next();
    load.resolve(false);

    const { redress } = await result;
    expect(redress).toHaveBeenCalledOnce();
  });

  it("waits for a newer character that started meanwhile", async () => {
    const first = deferred();
    const second = deferred();
    const { result, next } = run([first.promise, second.promise, undefined]);
    let settled = false;
    void result.then(() => (settled = true));

    next();
    first.resolve(true);
    await vi.advanceTimersByTimeAsync(0);
    expect(settled).toBe(false);

    next();
    second.resolve(true);

    await expect(result).resolves.toMatchObject({ inTime: true });
  });

  it("shows the figure when the dressing fails", async () => {
    const load = deferred();
    const { result, next } = run([load.promise, undefined]);

    next();
    load.reject(new Error("piece did not load"));

    await expect(result).resolves.toMatchObject({ inTime: true });
  });

  it("stops holding the figure back once the time is up", async () => {
    const load = deferred();
    const { result } = run([load.promise]);

    await vi.advanceTimersByTimeAsync(1000);

    await expect(result).resolves.toMatchObject({ inTime: false });
  });

  it("stops waiting once the viewer is gone", async () => {
    const { result } = run([deferred().promise], { stopped: () => true });

    await expect(result).resolves.toMatchObject({ inTime: true });
  });
});
