import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { useSyncExtension } from "./useSyncExtension";
import { FleetyardsSyncAction } from "@/frontend/lib/FleetyardsSyncHandler";

// What the extension's content script does with a request: answer it on the
// same window.
const answerWith = (answer: (request: { action: string }) => object) => {
  const onMessage = (event: MessageEvent) => {
    if (event.data?.direction !== "fy") return;

    const request = JSON.parse(event.data.message);
    window.dispatchEvent(
      new MessageEvent("message", {
        source: window,
        data: {
          direction: "fy-sync",
          message: JSON.stringify(answer(request)),
        },
      }),
    );
  };
  window.addEventListener("message", onMessage);

  return () => window.removeEventListener("message", onMessage);
};

describe("useSyncExtension", () => {
  let stopAnswering: (() => void) | undefined;

  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    stopAnswering?.();
    stopAnswering = undefined;
    vi.useRealTimers();
  });

  it("resolves with the answer to its own action", async () => {
    stopAnswering = answerWith((request) =>
      request.action === "identify"
        ? { action: "identify", code: 200, payload: { handle: "Pilot" } }
        : { action: request.action, code: 500 },
    );

    const answer = useSyncExtension().request(FleetyardsSyncAction.IDENTIFY);
    await vi.runAllTimersAsync();

    await expect(answer).resolves.toMatchObject({
      code: 200,
      payload: { handle: "Pilot" },
    });
  });

  it("sends the parameters along with the action", async () => {
    const seen: object[] = [];
    stopAnswering = answerWith((request) => {
      seen.push(request);
      return { action: request.action, code: 200 };
    });

    const answer = useSyncExtension().request(
      FleetyardsSyncAction.VERIFY_WRITE,
      { token: "FLEETYARDS-ABCDEFGHIJ" },
    );
    await vi.runAllTimersAsync();
    await answer;

    expect(seen).toEqual([
      { action: "verify-write", token: "FLEETYARDS-ABCDEFGHIJ" },
    ]);
  });

  it("rejects when nothing answers", async () => {
    const answer = useSyncExtension().request(
      FleetyardsSyncAction.IDENTIFY,
      {},
      1000,
    );
    const failed = expect(answer).rejects.toThrow("no answer");

    await vi.advanceTimersByTimeAsync(1000);

    await failed;
  });

  it("supports an action the health check lists", async () => {
    stopAnswering = answerWith(() => ({
      action: "health",
      code: 200,
      payload: { version: "1.3.0", actions: ["health", "verify-write"] },
    }));

    const supported = useSyncExtension().supports(
      FleetyardsSyncAction.VERIFY_WRITE,
    );
    await vi.runAllTimersAsync();

    await expect(supported).resolves.toBe(true);
  });

  it("does not support anything on an extension without the list", async () => {
    stopAnswering = answerWith(() => ({ action: "health", code: 200 }));

    const supported = useSyncExtension().supports(
      FleetyardsSyncAction.VERIFY_WRITE,
    );
    await vi.runAllTimersAsync();

    await expect(supported).resolves.toBe(false);
  });

  it("does not support anything without an extension", async () => {
    const supported = useSyncExtension().supports(
      FleetyardsSyncAction.VERIFY_WRITE,
    );
    await vi.runAllTimersAsync();

    await expect(supported).resolves.toBe(false);
  });
});
