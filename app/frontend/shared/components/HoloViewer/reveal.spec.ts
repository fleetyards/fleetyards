import { afterEach, describe, expect, it, vi } from "vitest";
import { retarget, stepTween, type Tween } from "./reveal";

const tween = (overrides: Partial<Tween> = {}): Tween => ({
  value: 0,
  target: 1,
  perSecond: 4,
  apply: vi.fn(),
  ...overrides,
});

describe("stepTween", () => {
  afterEach(() => vi.unstubAllGlobals());

  it("eases towards its target a capped step at a time", () => {
    const fade = tween();

    // A long pause counts as one frame at most.
    expect(stepTween(fade, 5)).toBe(true);
    expect(fade.value).toBeCloseTo(4 / 30);

    while (stepTween(fade, 1 / 30));

    expect(fade.value).toBe(1);
    expect(fade.apply).toHaveBeenLastCalledWith(1);
  });

  it("stands still at its target", () => {
    const fade = tween({ value: 1 });

    expect(stepTween(fade, 1 / 60)).toBe(false);
    expect(fade.apply).not.toHaveBeenCalled();
  });

  it("jumps straight there where reduced motion is asked for", () => {
    vi.stubGlobal("matchMedia", () => ({ matches: true }));
    const fade = tween({ target: 0 });

    retarget(fade, 1);

    expect(fade.value).toBe(1);
    expect(fade.apply).toHaveBeenCalledWith(1);
  });
});
